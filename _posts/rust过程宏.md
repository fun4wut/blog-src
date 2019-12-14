---
title: Rust过程宏实现Python-Fire
date: 2019-12-13 21:00:37
tags: 
 - Rust
 - 过程宏
 - 造轮子
toc: true
categories: 经验分享
---
[Python-Fire]()是一个简单易用的库，它能够将Python函数转变成 `CLI` 形式，将函数的参数作为命令行参数来读入，举个例子：
```python
# main.py
import fire
def add(fst, snd):
    print(fst + snd)
if __name__ == '__main__':
    fire.Fire(add)
```
命令行输入 `python3 main.py 1 2`，成功输出 `3`。

这对于程序的快速验证时非常有效的，用户也无需反复修改源代码来改变输入参数，只需改变命令行参数即可。

很奇怪，Rust社区并没有相应的实现，在查阅了 [crates.io]() 发现只有一个假lib之后，决定自己撕一个出来。而这个lib的核心，就是本篇文章的主角：过程宏。

<!-- more -->

## 过程宏简介

传统的宏类似于字符串匹配与替换，局限性较大，且十分依赖递归，较难编写。而过程宏的写法是过程式的，同时还支持以下更强大的特性：

1. 自定义 `derive`
2. 施加属性
3. 拟函数语法

核心功能就是编译期对 `AST` 进行修改，从而完成减少很多代码冗余。（当然利用过程宏实现的很多功能，其他语言通过运行时的反射一样能做到，而且也更容易调试一些）

## 大致思路

我理想中的 `Fire` 是这个样子的：
```rust
#[fire]
fn add(a: i32, b: i32) {
    println!("{}", a+b);
}
fn main() {
    add_fire();
}
```

`fire` 过程宏作用于 `add` 函数，在编译时新声明一个函数 `add_fire` ，该函数读取命令行参数，并将其喂给 `add` 来执行。

我这个人比较懒，解析命令行参数不想自己手撕，所幸我们可以通过 `clap` 来解析。那么我们的过程宏要做的事情就很简单：读取函数名和参数列表，并构造上一段所说的新函数即可。

## 工具介绍

写任何过程宏，都少不了`syn`、`quote`这两个lib。

首先是`syn` ，它在包中定义了大量的 `Structs` 和 `Enums` ，对应的是 Rust 源码中的各种元素。如 `ast.ident` 成员对应的 `Ident` 类型， `ast.generics` 成员对应的 `Generics` 类型等。后文中主要用的是 `syn::Item` 中相关的一系列类型。

至于 `quote`,它的作用 `quote!` 块中出现的插值变量转换为标记流的。这里的插值变量可以是 `syn` 中的任何类型。

除此之外， quote! 块中还支持重复插值，也就是和 macro_rules! 中 `$()*` 类似的操作，只需要将 `$` 替换为 `#` 即可。只要实现了 `IntoIterator` 这个 trait 的类型，包括 `std::vec::Vec` 都可以在 quote! 块中使用重复展开


## 目录结构

由于我们使用了第三方的crate（clap），所以需要导出两个东西：宏和clap相关的`struct`。但是rust的过程宏和其他的常规crate相比比较特殊，其是作为类似于编译器插件的角色，所以过程宏的crate，只能导出一个过程宏。

为此，我们可以曲线救国，用父crate引入子crate的过程宏，并和clap一起重新导出。

故项目的目录结构大致如下：
```
├── Cargo.toml
├── fire-rs-core
│  ├── Cargo.toml
│  └── src
│     └── lib.rs
├── src
│  └── lib.rs
└── tests
   └── progress.rs
```
`fire-rs-core`就是过程宏crate。

## 项目创建

在项目内部新建该子crate：`cargo new --lib fire-rs-core`。

修改父crate的配置文件，使用本地路径形式导入子crate。
```toml
[dependencies]
fire-rs-core = {path="./fire-rs-core"}
clap = "2.33"
```

修改子crate的配置文件，这里我们要使用 `ItemFn` 特性，所以开启了 `syn` 的full feature。
```toml
[lib]
proc-macro = true

[dependencies]
syn = {version = "1.0", features = ["full"]}
quote = "1.0"
```

## 具体实现

### 过程宏骨架

我们先搭一个过程宏大概的样子出来。
```rust
extern crate proc_macro;
use proc_macro::TokenStream;

#[proc_macro_attribute]
pub fn fire(_head: TokenStream, body: TokenStream) -> TokenStream {
    match syn::parse::<Item>(body).unwrap() {
        Item::Fn(func) => {
            /* */
        }
        _ => panic!("gg"),
    }
}
```
我们用`#[proc_macro_attribute]` 来标注这个函数为过程宏，它接收标记流作为参数，并返回一个标记流。

函数体内，我们使用 `syn` 对该标记流进行解析，因为我们的目标是函数，所以非函数类型应当直接 `panic` 掉。我们的主要逻辑都会在第一个 match臂中书写。

### 函数元数据的获取

我们需要目标函数这几个元数据：

- 函数名称
- 参数的名字
- 参数的类型

同时，我们的宏是不支持 `method` 和复杂参数的，所以遇到`self` 和复杂参数需要panic。

```rust
let ident = &func.sig.ident;
let inputs = &func.sig.inputs;
let args = inputs
    .iter()
    .map(|fnc| match fnc {
        FnArg::Typed(pt) => match pt.pat.deref() {
            Pat::Ident(pat_ident) => &pat_ident.ident,
            _ => panic!("complex pattern is not supported!"),
        },
        _ => panic!("associated function is not supported!"), // 排除self参数
    })
    .collect::<Vec<_>>();
```
细心的你会发现，这里我的代码却并没有去获取参数的类型，这里先留一个悬念，后面会提到。

### 构造新函数

拿到必要的数据，我们现在就能着手去构造新的函数了！

首先我们需要给新函数取个名字，命名规则就是在原函数名后面加上`_fire`。使用 `format_ident` 来创建，该宏会返回一个新的`ident`
```rust
let fire_ident = format_ident!("{}_fire", ident);
```
接下来我们要使用 `quote!` 来生成函数声明了。
```rust
let gen = quote! {
    pub fn #fire_ident() {
        use fire_rs::{App, Arg}
        let app = App::new("demo")
            .arg(Arg::with_name("args") 
                .takes_value(true)
                .multiple(true));
    }
    #func
}
gen.into()
```
这里有几点是值得注意的：

1. 被 `quote!` 包裹的块会变为 `TokenStream`, 但不是函数签名中的 `TokenStream`,需要调用一下 `into`。
2. 与自定义`derive`不同，属性宏是会直接在原AST上进行修改（而不是添加），所以原函数也需要一并写到 `quote!` 块中。
3. 第三行我导入了 `fire_rs`，也就是父crate，但是我却并没有把父crate写入依赖（写了会造成循环引用)。这样能run是因为编译器检查时，不会对宏里面的内容是否合法进行检测，而我们真正使用这个lib的时候，用的不是这个宏crate，而是父crate，而当编译器对宏展开，开始检查crate引用时，`fire_rs` 这个crate时显然在依赖中的。


### CLI设置

对于参数类型，有两种，一种是位置参数 `./demo 1 2`，一种是命名参数 `./demo --a 1 --b 2`，在上面我们已经设置了cli的位置参数，接下来我们需要设置命名参数。
```rust
    let mut app = App::new("demo")
        .arg(Arg::with_name("args") 
            .takes_value(true)
            .multiple(true));
    #(
        let args = Arg::with_name(stringify!(#args))
            .takes_value(true)
            .long(stringify!(#args)); // 利用stringify将ident转化为字符串
        app = app.arg(args);
    )*
    let matches = app.get_matches();
```
注意点：
1. `app`变为了`mutable`。
2. 使用 `stringify!` 宏将token转化成了字符串，这一方法十分好用。
3. 使用 `#()*` 对 `args` 进行了迭代。
4. 由于变量遮蔽特性，我们可以在同一个作用域下重复定义 `args`。

利用迭代生成出来的宏展开大概是这个样子：
```rust
    let mut app = App::new("demo")
        .arg(Arg::with_name("args") 
            .takes_value(true)
            .multiple(true));
    let args = Arg::with_name("a")
        .takes_value(true)
        .long("a"); 
    app = app.arg(args);
    let args = Arg::with_name("b")
        .takes_value(true)
        .long("b"); 
    app = app.arg(args);
```

### 参数类型的匹配

cli已经生成完毕，现在我们要做的是对输入进行匹配，为了我们的解析方便，规定两种参数不能混用。所以首先需要判断参数类型，这里规定出现了一次命名参数，那么就全部按照命名参数进行匹配。
```rust
// 通用处理逻辑
let common = quote! {
    let mut ifs = false; // 是否出现命名参数
    #(
        ifs = ifs || matches.is_present(stringify!(#args));
    )*
    if ifs { // 命名参数
        /* TODO */
    }
    else { //位置参数
        /* TODO */
    }
};
```
这里我们如法炮制，使用`#()*`进行迭代插值。

### 调用目标函数

判断完命令行参数类型，就可以执行到最后一步，调用目标函数了。对于两种命令行参数类型，处理的方式是不同的。

#### 处理命名参数

```rust
if ifs {
    #ident(#(matches.value_of(stringify!(#args)).unwrap().parse().unwrap()),*);
}
```
语句比较长，我们拆分开来看。

1. 首先我们是调用目标函数，所以是`#ident()`，这里 `#ident`就是目标函数名。
2. 内部又是一个 `#(),*` 插值，不难理解，这是对 `args` 的迭代（args有几个，参数个数就有多少个）
3. `matches.value_of(stringify!(#args)).unwrap().parse().unwrap()`，写这么复杂其实完全是 `unwrap` 的锅，不去看 `unwrap`，这里的逻辑就是找到名字为`stringify!(#args)`的命名参数，再利用`parse`转化到对应参数类型。注意我没有使用`parse::<>`的泛型调用方式。

**上文提到的没去提取目标函数参数类型的原因在此将揭开。**

我们知道，Rust的类型推导是基于上下文的，举个例子：
```rust
let mut v = Vec::new();
```
这里没去指定Vec的泛型参数，显然编译器不知道 `v`到底是什么类型，但是如果加上这一行：
```rust
let mut v = Vec::new();
v.push("fire");
```
那么编译器就能反应过来了，因为你加了一个 `&str` 类型的元素，那么 `v` 的类型就一定是 `Vec<&str>`。

回到这里，`parse()`，我们不需要显示的指定出泛型参数，正是因为编译器能过够通过目标函数参数类型，自动添加上泛型参数。

#### 处理位置参数

处理位置参数，相比命名参数需要考虑更多case。
```rust
else {
    let mut v = matches.values_of("args").unwrap_or_default();
    #ident(#(
        {
            let #args = 0; // 为了能迭代，让args随便出现一下
            v.next().unwrap().parse().unwrap()//块表达式的值
        }
    ),*);
}
```
1. 无参目标函数 `fn foo () {}` ，直接对匹配结果进行`unwrap`会panic。所以使用 `unwrap_or_default()` 方法，值为 `None` 时返回默认值（空的 `Vec` ）
2. 位置参数只需要知道目标函数参数列表的长度，对它的名字其实是不关心的，但是 `#()*` 迭代是必须要迭代内容出现的。我们利用了块表达式的特性，让 `args` 随意出现一下，然后块表达式的返回值就是目标函数的参数。

### 逻辑拆分

过程宏到此其实是已经完成了，已经可以发布了，但是我们还漏了十分重要的一步：测试。

仔细一想，我们的宏到目前，是难以测试的，因为我们需要对二进制程序进行测试，比较困难。

但是我们的二进制本身的逻辑是必然没有问题的，因为我们所依赖的CLI构建器已经经过了严格的测试，所以，我们只需要对匹配的逻辑进行测试就行了。

那么为了我们的测试，我们需要对 `_fire` 函数进行拆分成几个函数：
1. `_app` 函数：构建 `clap` 的App
2. `_stdin` 函数：从标准输入读取命令行参数，传给app执行。
3. `_slice` 函数：从数组切片中读取命令行参数，传给app执行，便于测试。
3. `_fire` 函数：整合了 `_app` 和 `_stdin` ，方便用户直接使用。

具体怎么拆分不加赘述，详情参见[我的github](https://github.com/fun4wut/fire-rs/blob/master/fire-rs-core/src/lib.rs)，函数签名可以直接照搬 `clap` 的函数签名。

### 测试

过程宏没有必要（也没法）单元测试，这里我们在父crate中进行整合测试。

父crate的 `Cargo.toml` 中添加：
```toml
[[test]]
name = "tests"
path = "tests/progress.rs"
```
指定了 `tests` 目录为整合测试的目录，`progress.rs` 为目标文件。

打开 `progrss.rs`，我们对这几个情况进行测试
- 无参数
- 双参数
- 命名参数
- 忽略多余的参数

举一个case作为例子：
```rust
#[test]
fn with_name() {
    #[fire]
    fn foo(int: i32, long: i64) {}
    let app = foo_app();
    foo_slice(app, &["demo", "--int", "4", "--long", "8"])
}
```
更多的case可以自己去构造。直接命令行输入 `cargo test` 即可开始测试。

## 总结

如此，一个过程宏就算是写完了，比较粗糙，算是抛砖引玉吧。

现已发布至[crates.io](https://crates.io/crates/fire-rs)，欢迎各位尝鲜。

有任何意见及建议，或者想看完整代码，也欢迎来[github](https://github.com/fun4wut/fire-rs)点star/提issue，感谢。

