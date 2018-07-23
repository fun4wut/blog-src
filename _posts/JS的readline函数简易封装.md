---
title: JS的readline函数简易封装
date: 2018-06-18 22:27:30
tags: JS
---
JS一直没有一个很好的处理标准输入的方法，在以前，我们需要这样做
```js
let readline = require('readline')
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
})
rl.on('line',  (line)=> {
    line.split('<br>').forEach((val) => console.log(val));
})
```
我们只能用监听换行符来回调去实现标准输入，但这是非常不自然的，结合ES6/8的Promise和async，我们可以对其进行一个简易封装
```js
let linemod= require ('readline')
const rl = linemod.createInterface({
    input: process.stdin,
    output: process.stdout
});

const readline = ()=>{
    return new Promise((resolve,reject)=>{
        rl.on('line',(line)=>{
            resolve(line)
        })
    })
}
const main = async ()=>{
    let a = await readline()
    //todo
}
```