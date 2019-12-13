---
title: Rust过程宏实现Python-Fire
date: 2019-12-13 21:00:37
tags: 
 - Rust
 - 过程宏
 - 造轮子
toc: true
categories: 学习笔记
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

【To Be Continued】