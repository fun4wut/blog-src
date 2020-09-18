---
title: Promise编程题：并发控制
date: 2018-05-26 09:39:27
tags: 
 - JS
 - 面试
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200223151629.png
categories: 学习笔记
---
笔者在面试字节的过程中碰到了道Promise的代码题，相比一般的让你写个 `Promise.all`, `Promise.race` 之流，增加了些难度。故在此记录一下解法

<!-- more -->

## 并发控制

大意是对并发进行限流，同一时间只能有n个并发，当超过n个时，后面的需要排队。主要用途，比如爬虫，如果不进行限流，大量的请求发上去，肯定会被server ban掉的。

和市面上大部分的并发控制题面不同，这里并发的请求是一个个add上去的，而不是一开始就定好的。

```js
// TODO: Complete the Scheduler Class
class Scheduler {
    constructor(n) {
        
    }

    add(promiseFunc) {
        
    }

}

const scheduler = new Scheduler(2)

const timeout = (time) => new Promise(r => setTimeout(r, time))

const addTask = (time, order) => {
    scheduler.add(async () => {
        await delay(time)
        console.log(order)
    })
}

addTask(1000, 1)

addTask(500, 2)

addTask(300, 3)

addTask(400, 4)

// log: 2 3 1 4
```

对于这种问题，首先我们肯定需要一个容器来存储PromiseFunc，同时满足FIFO的特性，很显然，可以使用队列来实现。
假设最大并发数是n，我们每次拿取队列的头n个元素来进行并发，每拿取一个，最大并发数n需要减1。每当一个任务完成后，让n再加1，同时再去拿队列的头n个元素去并发。显然这其实就是一种递归的思路。

那么，程序该如何知道这个递归该什么时候启动呢？这里就用到了 `EventLoop` ，利用**宏任务晚于同步任务执行**的特性，**通过setTimeout来保证所有的add（同步任务）执行完之后，再执行递归。**

代码如下：
```js
class Scheduler {
    constructor(n) {
        this.queue = []
        this.max = n
        setTimeout(() => this.run(), 0) // 使用箭头函数绑定this
    }

    add (promiseFunc) {
        this.queue.push(promiseFunc)
    }

    run() {
        // 如果任务数还不到最大并发量，那就全部并发
        const len = Math.min(this.max, this.queue.length)
        for (let i = 0; i < len; ++i) {
            this.max--
            const task = this.queue.shift() // 拿取头部元素
            task().then(() => { // 执行并递归
                this.max++
                this.run()
            })
        }
    }
}
```


### 变式

能做出上面那种已经很不错了，奈何笔者碰到的更加复杂，我们让难度升级，修改 `addTask` 如下

```js
const addTask = (time, order) => {
    scheduler.add(() => delay(time))
        .then(() => console.log(order))
}
```

发现问题了吗？这里 `add` 返回了一个Promise，同时 `log` 不再跟在 `delay` 后面，而是接在了 `add` 后面。这样依赖，`add` 也和 `log` 有了必要的先后关系：**必须要 `add` 的任务执行完了之后，才能执行 `log` 。**

来看如何解决，首先，由于 `add` 变成了微任务，但仍然先于宏任务 `setTimeout` 执行，所以递归的时机没有变化，依然是 `add` 全部完毕之后进行。

其次，因为有了先后关系，所以我们必须要让 `add` 在任务执行完之后 `resolve` ，这种特殊场景，我们就必须请出Promise构造器了，通过对 `PromiseFunc` 的二次封装，让他在完成后执行 `resolve` ，从而使 `add` 进入 `fulfilled` 状态，`console.log` 也就在这时得以执行了。

```js
    add (promiseFunc) {
        return new Promise(resolve => {
            const wrapperFunc = () => promiseFunc().then(resolve) // 注意resolve的时机
            this.queue.push(wrapperFunc)
        })
    }
```

## 总结

Promise题目的考察点，无非还是在事件循环上，搞懂事件循环，缕清任务发生的先后顺序，什么时候进行 `resolve` ，什么时候需要 `await` 。这些问题想清楚了，相关的代码题便能比较有头绪的解决。