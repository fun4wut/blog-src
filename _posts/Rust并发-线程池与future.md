---
title: Rust并发-线程池与future
date: 2019-10-26 16:00:37
tags: 
 - Rust
 - 并发
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200223140120.png
categories: 学习笔记
---

在[Rust官方教程](https://doc.rust-lang.org/book/ch16-00-concurrency.html)中，并发部分的标题叫做 **Fearless Concurrency**。并介绍了利用线程池来构建一个微型web服务器。服务器本身只是返回了HTTP报文，没有什么特别的地方。 

比较有意思的点在于并发处理上，在查阅了一些资料后，我决定自己动手，用不同的并发方式取构建Web服务器，并通过 `ab` ， `wrk` 等压力测试工具来评测各种并发方式的效率。

完整代码可在我的 [Github](https://github.com/fun4wut/naive-concurrent) 上查看

<!--more-->

## 各种并发方式简介

### 单线程同步

作为对照组，单线程同步方式是最为简单，无并发的。以此来看看最简单的处理TCP流的办法。

```rust
pub fn handle_connection(mut stream: TcpStream) {
    let mut buffer = [0; 512];

    stream.read(&mut buffer).unwrap();
    // 写入HTML报文
    let contents = std::fs::read_to_string("index.html").unwrap();

    let response = format!(
        "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n{}",
        contents
    );
    // 模拟真实环境，加入10ms的延时
    std::thread::sleep(Duration::from_millis(TIMEOUT));
    //    println!("{:?} handling...", std::thread::current().id());
    stream.write(response.as_bytes()).unwrap();
    stream.flush().unwrap();
}
```

一言以蔽之，就是接收，写入HTTP报文，返回。

那么主函数也就非常显然了

```rust
pub fn block_main() -> std::io::Result<()> {
    // 绑定监听地址
    let listener = TcpListener::bind(ADDR)?;
    // 对每个到来的TCP包，执行handle操作
    for stream in listener.incoming() {
        handle_connection(stream.unwrap())
    }
    Ok(())
}
```

### 单线程异步

**前置知识：什么是异步？如果你对JS，Kotlin等比较了解，那一定对这个不陌生。如果不清楚请自行谷歌。**

Rust的异步语法刚敲定不久，async/await 即将在11月进入stable，由于本文写于10月，暂时使用 `nightly` 版本进行构建。

异步的方式能让我们以非常小的代价顶住高并发，尤其是在Web服务器这种IO密集型的任务上。

我们使用 `async-std` 这一库，API完全复制的标准库，不过改成了异步方式，零学习成本。

```rust
use async_std::{
    fs, io,
    net::{TcpListener, TcpStream},
    prelude::*,
    task,
};
use futures_timer::Delay;
use std::time::Duration;
async fn async_handle(mut stream: TcpStream) -> io::Result<()> {
    let mut buffer = [0; 512];
    stream.read(&mut buffer).await?;
    let contents = fs::read_to_string("index.html").await?;
    let response = format!(
        "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n{}",
        contents
    );
    // 模拟真实环境，加入10ms的延时
    Delay::new(Duration::from_millis(TIMEOUT)).await;
    println!("{:?} handling...", task::current().id());
    stream.write(response.as_bytes()).await?;
    stream.flush().await?;
    Ok(())
}
pub async fn async_main() -> io::Result<()> {
    let listener = TcpListener::bind(ADDR).await?;
    let mut incoming = listener.incoming();
    while let Some(stream) = incoming.next().await {
        let stream: TcpStream = stream?;
        task::spawn(async_handle(stream));
    }
    Ok(())
}
```

实现方式几乎和单线程阻塞方式完全一致，唯一的一点不同在于

```rust
while let Some(stream) = incoming.next().await {
    let stream: TcpStream = stream?;
    task::spawn(async_handle(stream));
}
```

没有使用  `for in ` 是因为改语法目前还不支持异步表达式。

### 基于channel的线程池

> Do not communicate by sharing memory; instead, share memory by communicating.

大概是对Go的赞同，Rust的并发，线程间更倾向于通过 `channel` 进行通信。

这样就有了一个比较容易想到的构建方法——使用channel来传递消息（任务）。

#### 类型定义

我们的消息是什么？是一个在堆上分配的闭包

```rust
// 要传递的闭包，Send来线程间传递，'static生命周期意味着贯穿整个程序，因为不知道该线程执行多久
type Job = Box<dyn FnOnce() + Send + 'static>;
```

那我们要传递别的消息怎么办？不仅是闭包，比如停机通知之类的？使用枚举

```rust
/// 传递的信息，有可能是新的任务，或是终止信息
enum Message {
    NewJob(Job),
    Terminate,
}
```

使用怎样的管道？按照设想，管道的输入只有一个主线程来派发任务，输出端则是有N个工作线程来等待任务。所以理想的管道是一个 `单生产者多消费者（spmc）` 模型，可惜标准库只提供了 `多生产者单消费者（mpsc）`模型，我们只好曲线救国，用 `Mutex` 互斥锁保证了同一时刻只有一个线程能获取到消息。 `Arc` 来跨线程共享。

```rust
// 接收者，使用了引用计数和互斥锁来保证多所有者共享和互斥访问
type Receiver = Arc<Mutex<mpsc::Receiver<Message>>>;
```

#### 线程池初始化

根据给定线程数量来初始化，传递给线程Receiver，以传输来自 channel 上的消息

```rust
pub fn new(size: usize) -> Self {
    assert!(size > 0);
    // 创建通道
    let (sender, receiver) = mpsc::channel();
    // 包装一下接收者
    let receiver = Arc::new(Mutex::new(receiver));
    Self {
        workers: (0..size)
        .map(|i| Worker::new(i, Arc::clone(&receiver)))
        .collect::<_>(),
        sender, // 发送者
    }
}
```

#### 任务执行

工作线程内部该如何执行？使用loop来进行循环

```rust
loop {
    let message = receiver.lock().unwrap().recv().unwrap();
    match message {
        // 收到任务消息，执行任务
        Message::NewJob(job) => {
            println!("Worker {} got a job; executing.", id);
            job();
        }
        // 收到终止消息，结束loop
        Message::Terminate => {
            println!("Worker {} was told to terminate.", id);
            break;
        }
    }
}
```

#### 任务添加

显然，构造一个Message，通过 channel 传输即可

```rust
let message = Message::NewJob(box f);
self.sender.send(message).unwrap();
```

#### 停机处理

如何关闭一个线程池？我们需要向channel中发送 `Message:Terminate`  的消息。

```rust
impl Drop for ThreadPool {
    fn drop(&mut self) {
        println!("Sending terminate message to all workers.");
        // 先发送停机message
        for _ in &mut self.workers {
            self.sender.send(Message::Terminate).unwrap();
        }
        println!("Shutting down all workers.");
        // 等待所有worker关闭
        for worker in &mut self.workers {
            println!("Shutting down worker {}", worker.id);
            // 利用take将线程从worker中取出
            if let Some(thread) = worker.thread.take() {
                thread.join().unwrap();
            }
        }
    }
}
```

这里我们遍历了两遍，第一遍发送消息，第二遍等待线程  `join`。两者能不能放在一个循环中？

**答案是不可以，因为存在着你等待线程1停机，但实际上是线程2收到停机消息的死锁情况。**



#### 改进

标准库中虽然没有 `spmc` ，但是第三方crate [crossbeam](https://docs.rs/crossbeam/0.7.2/crossbeam/) 提供了 `mpmc` 的实现，更让人感到有趣的是，它是 `lock-free`  的实现，这意味着性能开销的大幅减少。

改用 mpmc 的代码如下

```rust
type Receiver = Receiver<Message>;
//...
loop {
    match receiver.recv().unwrap() {
        // 收到任务消息，执行任务
        Message::NewJob(job) => {
            println!("Worker {} got a job; executing.", id);
            job();
        }
        // 收到终止消息，结束loop
        Message::Terminate => {
            println!("Worker {} was told to terminate.", id);
            break;
        }
    }
}
```

### 基于CondVar的线程池

抛开 channel，我们还有一种更通用的做法，可以用在不同的语言，譬如 C 上面，也就是使用 condition variable。关于 condition variable 的使用，大家可以 Google，因为在使用 condition variable 的时候，都会配套有一个 Mutex，所以我们可以通过这个 Mutex 同时控制 condition variable 以及任务队列。

#### 类型定义

首先我们定义一个 Status和通知器，用来处理任务队列。

整个线程池结构体保存worker列表和通知器。

```rust
struct Status {
    queue: VecDeque<Job>,
    shutdown: bool,
}
type Notifier = Arc<(Mutex<Status>, Condvar)>;
pub struct CVarThreadPool {
    workers: Vec<Worker>,
    notifier: Notifier,
}
```

#### 线程池初始化

与上一节雷同，，不多做解释

```rust
pub fn new(size: usize) -> Self {
    assert!(size > 0);
    let status = Status {
        queue: VecDeque::new(),
        shutdown: false,
    };
    let notifier = Arc::new((Mutex::new(status), Condvar::new()));
    let mut workers = vec![];
    // 因为所有权的关系，不能使用map闭包
    for i in 0..size {
        let notifier = notifier.clone();
        workers.push(Worker::new(i, notifier));
    }
    Self { notifier, workers }
}
```

#### 任务获取

相对于 `channel`的方式，利用 `condVar` 稍显繁琐。

```rust
fn next_job(notifier: &Notifier) -> Option<Job> {
    // 两层解引用再上一个引用
    let (lock, cvar) = &**notifier;
    // 尝试拿到锁
    let mut status = lock.lock().unwrap();
    loop {
        // 查看队首的任务
        match status.queue.pop_front() {
            // 如果已关机，返回空任务
            None if status.shutdown => return None,
            // 无任务，阻塞当前线程，等待任务的到来
            // wait会自动解开互斥锁（防止死锁)
            None => status = cvar.wait(status).unwrap(),
            // 队列里有任务，返回任务
            some => return some
        }
    }
}
```

#### 任务添加

```rust
let (lock, cvar) = &*self.notifier;
let mut status = lock.lock().unwrap();
// 队列放入任务
status.queue.push_back(box f);
// 唤醒线程
cvar.notify_one();
```

#### 停机处理

我们让 `shutdown` 字段设为true，并唤醒线程即可完成停机。

**必须注意的是，我们使用了 `drop(status);` 来强制清除该资源，为的是退出互斥区（不然其他线程进不去互斥区，从而造成死锁）**

```rust
impl Drop for CVarThreadPool {
    fn drop(&mut self) {
        let (lock, cvar) = &*self.notifier;
        let mut status = lock.lock().unwrap();
        // 设置关闭状态
        status.shutdown = true;
        println!("Sending terminate message to all workers.");
        cvar.notify_one();
        drop(status); // 显式的清除MutexGuard，来退出互斥区
        for worker in &mut self.workers {
            println!("Shutting down worker {}", worker.id);
            // 利用take将线程从worker中取出
            if let Some(thread) = worker.thread.take() {
                thread.join().unwrap();
            }
        }
    }
}
```

## 坑点

在对于锁操作的时候，慎用以下语句：

- `while let xx = yy.lock() {}`
- `match yy.lock() {}`

如此会导致互斥锁在大括号结束后才会释放，这样实际就变成了单线程。（在下一节中有所展示）

将

```rust
while let Ok(task) = arx.lock().unwrap().recv() {
task.call_box(); //锁未释放
} //临时值MutexGuard<T>在此才被丢弃
```

 改为

```rust
loop {
    let task = arx.lock().unwrap().recv().unwrap(); //之后MutexGuard<T>将被丢弃
    task.call_box();
}
```

即可避免该问题

## 性能比较

### 测试环境

> CPU：**i7-7700HQ（2.8GHZ 四核8线程）**
>
> 模拟延时：10ms
>
> 操作系统：Windows 10
>
> 工具链：beta-x86_64-pc-windows-msvc
>
> 运行程序为debug版（release版本windows无法运行）

*注意：自制线程池犯了坑点中说的错误，使用了 `match yy.lock() {}`。*

### 测试结果

在同一局域网下通过 `wrk` 进行压力测试，8线程，持续10秒，结果如下

| 并发数 | 自制线程池 | 调库线程池 | 单线程异步 | 阻塞调用 |
| ------ | ---------- | ---------- | ---------- | -------- |
| 10     | 89         | 227        | 226        | 89       |
| 30     | 89         | 235        | 242        | 90       |
| 100    | 90         | 269        | 273        | 89       |
| 300    | 89         | 260        | 270        | 88       |
| 700    | 87         | 262        | 292        | 86       |
| 1000   | 85         | 240        | 290        | 80       |



- 线程池与异步在并发量不高时差不多性能，并发量上去之后，异步模式明显更占优势
- 自制线程池（官方教学文档版）效果较差，经过调试发现实际上只有一个线程被调用了，导致性能和单进程阻塞调用差不多

### 原因分析

1. **线程池在高并发下表现不佳**

   线程池的大小是固定的（2*CPU线程数也就是16线程），在面对上千级并发时，线程数依然会不够用，唯一的办法是加钱上服务器CPU（逃

2. **异步模式的突出表现**

   服务器是一个比较典型的考虑到异步是 `非阻塞IO` 调用，在执行每句语句后会立刻让出控制权给其他调用，避免盲等，也减少了IO损耗。



## 文章引用

1. Rust并发编程——https://www.jianshu.com/p/f4d853c0ef1e
2. The Rust Programming Language ——https://doc.rust-lang.org/book/ch20-00-final-project-a-web-server.html
