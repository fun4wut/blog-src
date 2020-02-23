---
title: 简易KV内存数据库的实现
date: 2019-08-06 14:59:08
tags: 
 - Rust
 - 数据库
top_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/18-8-29/post-bg.jpg
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200223141119.png
categories: 经验分享
---

7月中旬的时候看到了一篇知乎上的关于搭建 `pastebin` 服务的文章 https://zhuanlan.zhihu.com/p/73961522 

作者没有利用redis，而是用rust手撕了一个简易的内存存储，遂引起了我的兴趣，在核心数据结构照着该作者来之外，加入了其他的feature。<del>当然也被 `rust` 编译器按在地上摩擦了很久。</del>

首选先明确我们的数据库需要实现哪些功能。

1. 保存数据
2. 根据key读取数据
3. 淘汰不常使用的数据
4. 过期删除
5. 硬盘二级存储

<!--more-->

摆上我的项目 repo: https://github.com/fun4wut/naive-pastebin

## 数据存储

为了同时实现数据保存+淘汰数据，LRU是一个非常好的选择。

故主存储数据结构选用 `linked-hashmap` 。提供 `O(1)` 的访问、插入和删除。



## 过期清除

最简单的过期检测就是定时遍历 `LinkedHashMap`，检查数据是否过期，删除所有过期的数据。

这种方法的时间复杂度是 O(n)，每个单位操作是访问、判断、删除，有两次哈希表操作。

过期检测的要求是有序遍历过期时间，删除对应的键，插入和删除时不能有大量的移动。因此，答案是平衡树，寻找最小键、插入、删除都是 O(logn)。具体是 `BTreeMap`，B 树是多叉平衡树，时间复杂度是 O(Blog(B,n))，少量的堆分配和 CPU 缓存友好性使它实际上比二叉平衡树快很多。

使用 B 树做过期索引会使保存的时间复杂度变为 O(Blog(B,n))，批量淘汰变为 O(nBlog(B,n))，过期删除变为 O(nBlog(B,n))，而查找仍是 O(1).

另起一个线程定时运行过期检测删除机制，为存储加个锁即可。

> 该部分摘自[https://zhuanlan.zhihu.com/p/73961522/#%E6%95%B0%E6%8D%AE%E5%AD%98%E5%82%A8](https://zhuanlan.zhihu.com/p/73961522/#数据存储)



## Key的选择

纳秒时间戳具有自增、不重复的特性，对于一个单机服务来说，它就是完美的发号器。

但是在Web服务的时候，用一串时间戳，未免太丑，我们还需要一个短网址加密。

幸运的是，`Rust` 已经有了这样的短网址库，没必要自己写了。

[https://crates.io/crates/short-crypt](https://crates.io/crates/short-crypt)



## 碰撞问题

并发量一高，Key依然会发生碰撞，这里原作者采用的方法是将时间 `+1s` ,但其实这十分 **naive**。

采用随机加上0-256个(u8) 个纳秒，即可完美解决问题。



## 二级存储

被LRU淘汰掉的数据需要有个去处，硬盘无疑是个非常好的选择。

这里参照 `redis` 的解决方式，首先通过SHA1算法把Key转化成一个40个字符的Hash值，然后把Hash值的前两位作为一级目录，然后把Hash值的三四位作 为二级目录，最后把Hash值作为文件名，类似于“/0b/ee/0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33” 形式。

二级存储采用 **懒删除** 机制。意思是当用户请求的数据在硬盘时，先查看记录在硬盘里的过期时间，若已过期，将其删除，并返回未找到。



## 数据备份

内存数据库，数据没有丝毫保障，需要一个备份措施来进行容灾。

主要有两种选择：`snapshot` 和 `log`。

但是由于摸了，这里没做，想了解更多可以自行搜索【逃



## Rust踩坑

在使用rust的时候踩了无数的坑，并最终放弃治疗。把遇到的问题和解决问题记录于此。

### 无法返回局部变量的引用

原因很简单：局部变量在作用域结束之后就会销毁，所以这个引用会成为 **野指针**。

解决办法：

1. 直接返回资源本身（最直接的办法）
2. 使用 `Box` 包装资源，同时返回该 `Box`
3. 使用智能指针包装，如 `Arc` / `Rc`

详情参见 http://bryce.fisher-fleig.org/blog/strategies-for-returning-references-in-rust/index.html

### 泛型trait Deserialize需要生命周期标识

举个例子

```rust
pub struct DiskStore<K, V>
    where
        K: ToArray,
        V: Serialize + Deserialize
{
    //....
}
```

这里就会报错。

解决办法：使用 `DeserializeOwned` 来获得所有权版本的 `trait`

### 使用 ? 运算符返回自定义错误

在 `rust` 中，`?` 的作用是 `unwrap` + 错误向上传递。

在很多时候，我们的 `Error` 是自定义的，但是 `?` 传递的 Error 并没法转成自定义的 Error。

为此，我们需要实现它们的 `From` trait。

```rust
impl From<std::io::Error> for StoreError {
    fn from(e: std::io::Error) -> Self {
        IOErr(e)
    }
}

impl From<Box<ErrorKind>> for StoreError {
    fn from(e: Box<ErrorKind>) -> Self {
        BinCodeErr(e)
    }
}

impl From<NoneError> for StoreError {
    fn from(_: NoneError) -> Self {
        NoneErr
    }
}
```

详情参见 https://lotabout.me/2017/rust-error-handling/

### 将 可变引用 转化为 非可变引用

```rust
let mut tmp = String::from("2333"); // mutable reference
&*tmp // now it's immutable
```

### 对两个条件分支下，分别使用不可变应用和可变引用，borrow checker的报错

感觉是生命周期的问题

```rust
fn foo(x: &mut u8) -> Option<&u8> {
    if let Some(y) = bar(x) {
        return Some(y) // comment this out to calm compiler
    }
    bar(x)
}

fn bar(x: &mut u8) -> Option<&u8> { Some(x) }
```

报错：

```
error[E0499]: cannot borrow `*x` as mutable more than once at a time
 --> src/main.rs:7:9
  |
4 |     if let Some(y) = bar(x) {
  |                          - first mutable borrow occurs here
...
7 |     bar(x)
  |         ^ second mutable borrow occurs here
8 | }
  | - first borrow ends here
```

理论上 `bar(x)` 的生命周期应该在这个分支末尾就已经结束了，但是编译器还是认为 它在函数最后才会被销毁。

解决办法：使用 `polonius` 编译参数

```
cargo rustc -- -Z polonius
```

### 异步文件IO问题【未解决】

在这个问题上，Windows和Linux给出的性能完全不一样【不清楚原因】

Windows下写操作【并发量为50】：

- 阻塞：135.27 [#/sec](https://git.fun4go.top/fun4wut/naive-pastebin/src/branch/master/mean)
- 异步：459.24 [#/sec](https://git.fun4go.top/fun4wut/naive-pastebin/src/branch/master/mean)
- 多线程：304.62 [#/sec](https://git.fun4go.top/fun4wut/naive-pastebin/src/branch/master/mean)

Linux下写操作【并发量为50】

- 阻塞：3516.39 [#/sec](https://git.fun4go.top/fun4wut/naive-pastebin/src/branch/master/mean)
- 异步：1744.39 [#/sec](https://git.fun4go.top/fun4wut/naive-pastebin/src/branch/master/mean)
- 多线程：3053.63 [#/sec](https://git.fun4go.top/fun4wut/naive-pastebin/src/branch/master/mean)

且先不论Win和Linux的整体性能差距。单看各方式的性能比较，windows下异步是最快的，而linux下异步确实最慢的，阻塞调用竟然最快【？？？】



## 总结

这里我想多吐槽一下Rust语言，其实我对Rust的类型系统很有好感， `Option/Result` 、`trait` 、 `pattern match`  、 `algebra data type` 等等的设计都非常对我口味。

遗憾的是它的所有权机制太硬核了，不碰生命周期还好，一旦涉及到，报错就是十几个一报的。

要求程序员进行内存管理真的太难了，未来一定是属于 GC 的！