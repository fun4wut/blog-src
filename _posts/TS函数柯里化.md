---
title: TS函数柯里化
date: 2020-07-08 17:57:32
tags: TS
toc: true
categories: 经验分享
---

在公司疯狂摸鱼，忽然想念起前端来，所以写了点类型编程的玩具出来。今天先试着写写柯里化

## 何为柯里化

先简单介绍下什么是柯里化(currying)。意思是将多参数的函数，转化成单一参数的函数。举个例子：
```js
// 定义
const add = (a, b, c) => a + b + c

const curriedAdd = a => b => c => a + b + c

//调用
add(1, 2, 3) //6
curriedAdd(1)(2)(3) //6
```
可以看到，变为单一参数后，返回的是一个闭包，捕获了第一个参数的值，闭包的返回值也是一个单一参数的函数。

## 如何实现柯里化

我们先不关心类型，来看看JS下的柯里化如何实现
```js
function curry(fn) {
    return (fn.length === 1
        ? fn
        : (arg) => curry(fn.bind(null, arg)));
}
```
这里实现的很简单，使用 `bind` 创建一个已经预先接受第一个参数的函数，并进行递归即可，当函数参数个数为1时，即 `p => r`的形式，不需要再柯里化了，终止递归。

## 添加类型标注

我们来想想如何用TS给这个函数加上标注。

首先，对于函数的参数列表 `args: T`，我们需要知道 `args` 的第一个参数的类型，和剩下的参数列表的类型。在TS4.0下，可以比较方便的写出：

```ts
type Head<T extends any[]> = T[0]

type Tail<T> = T extends [any, ...infer R] ? R : never
```

`Head` 很简单，`Tail` 使用了 [Variadic Tuple Types](https://devblogs.microsoft.com/typescript/announcing-typescript-4-0-beta/#variadic-tuple-types)。使用infer获得R的类型，并使用`...`对R进行了展开，从而得到了剩余的的参数的类型。

有这两个 `Type Constructor`，便可以着手函数申明标注了，由于函数参数名字不能省去，写起来很丑，所以将函数用泛型表示。美观一些
```ts
type Fn<T extends any[], R> = (...args: T) => R

type Currify<F extends Fn<any, any>> = /* TODO */
```

接下来要获取F的具体参数类型和返回类型，这里可以使用 `infer` 和 `conditional` 来获取。
```ts
type Currify<F extends Fn<any, any>> = 
    F extends Fn<infer T, infer R>
    ? /* TODO */
    : never
```
TODO里面就是递归的核心了，首先想想递归的终止条件，是参数列表长度为1，但是类型是不允许计算的，所以换个方法，可以通过 `Tail<T>`是否为空列表来进行判断。
```ts
type Currify<F extends Fn<any, any>> = 
    F extends Fn<infer T, infer R>
        ? Tail<T> extends []
            ? F
            : /* TODO */
        : never
```
然后是递归转移，返回一个函数类型
```ts
type Currify<F extends Fn<any, any>> = 
    F extends Fn<infer T, infer R>
        ? Tail<T> extends []
            ? F
            : (arg: Head<T>) => Currify<(...args: Tail<T>) => R>
        : never
```
来看看效果
```ts
type Add = (a: number, b: number, c: number) => number

type CurAdd = Currify<Add>

// 鼠标停在CurAdd上方显示
type CurAdd = (arg: number) => (arg: number) => (c: number) => number
```
除了形参的名字被消除了之外，其他没有什么问题

## 对函数类型化

接下来我们着手对 `curry` 函数进行类型编写，主要是泛型部分，我们同样需要获取参数列表和返回值的类型，这里就不要infer了，直接写在泛型里即可。整个curry函数的返回值也就是 `Currify` 的类型，这里用 `typeof` 避免duplicate code。
```ts
declare function curry<T extends any[], R>(fn: Fn<T, R>): Currify<typeof fn>
```
这里只加了层declare而没有对函数体内部进行TS改写，是因为 `any` 用的比较多，没啥必要。

再来试试效果：
```ts
const curAdd = curry((a: number, b: number, c: number) => a + b + c)

console.log(curAdd(12)(2)(3)) // 17
```
