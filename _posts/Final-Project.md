---
title: Web应用开发大作业分享，感悟，吐槽
date: 2018-05-25 17:38:11
tags: 
 - 小程序
 - Node.js
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200223151753.png
categories: 经验分享
---

Web大作业终于在1个星期内搞定了。说是说一星期，但还是花了不少时间在体育预约程序的设计上。在这上面花的时间要将近3个星期。期间也搞了一下功能阉割版的微信小程序。
名字叫做**ECNU查询通** ![小程序二维码](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/a.jpg)<br/>
但是微信小程序还是太过简单，它缺少一个用户界面。而这次的Web大作业是一个完整的带注册，登录，改密等基本操作的网站。

<!--more-->

---
## Repo
[小程序前端](https://github.com/fun4wut/gelEle_frontend)

[小程序后端](https://github.com/fun4wut/queryEle_backend)

[终极网页版](https://github.com/fun4wut/WebFinalProject)

---

## 核心体系
1. 后端采用express+mysql，优点是开发快，代码量少，相比Java更清亮，相比PHP逼格更高（npm社区还是相当活跃的）
2. 后端开发语言用的是TypeScript，编译器的静态类型检查还是挺不错的，有写Java的感觉，遗憾的是冒出来很多类型错误，不得不把类型改为any，这样一来TS的优势实际上就没了，希望下次把TS的文档好好读一读再来重构一下
3. 前端采用了bootstrap+jquery,最对新手友好的方式了。之前也曾经尝试过用React，但你又不得不和Webpack，gulp等打包工具打上交道，留给自己的时间完全不够，而且最让人头疼的CSS还是得自己写，故放弃。而bootstrap实则是一款UI框架，他已经将大量的CSS样式写好了，你需要的只是去套用class就行了，简单粗暴，对着文档找你要的类就行了。jQuery则是老牌框架了。DOM操作着实要比JSX，模板要简单不少。

---
### 踩过的坑
1. express框架的蜜汁静态文件管理，很多时候你根本不知道你托管的静态文件路径到底对不对，只能一个个去猜
2. async/await的用法之前一直都不会，原来必须返回Promise的函数才能调用await，可是这样每个函数都要 ```return new Promise((resolve,reject)=>{})```，让代码量膨胀了不少
3. 发post请求时json和表单的区别，很容易一下子掉进去，半天还找不到结果
4. 在全部课程列表页面中需要在页面加载时去向服务器发请求，拿到课程信息并渲染表格，但是我安装的表格检索插件在我渲染之前就启动了，导致表格信息无法被录入，最终采用`window.onload = function(){}`的方法，效果是在全部dom和js加载玩之后才会执行，就解决了问题
5. 同样还是在课程列表页面中，需要对每个`<tr>`元素加一个点击事件监听。但如果单独写出`$('tr).click(()=>{})`的话，只会对表格第一页的`<tr>`元素加入点击事件，对第二第三页的无效。所以我们得把函数写在`<tr>`的onclick属性中去，值得注意是监听函数必须带有一个参数obj用来传入该元素的`this`，从而让函数能调用this找到该行的DOM位置。
6. 处理页面跳转请在ajax的地方使用`window.location.href = '/target'`，而不是在服务器端用`res.redirect('/target')`
7. ajax返回的数据res必须使用`res.json()`方法，不可以使用`JSON.parse(res)`
8. 表单形式提交，`<button>`的type是'submit'，利用ajax提交时，type必须显示地写出为'button'

---
## TODO-LIST
1. 完善cookie管理，最好能加入session机制，使得会话更安全。
2. 更多新的feature
3. <del>小程序端/网页端/移动端上线</del>
