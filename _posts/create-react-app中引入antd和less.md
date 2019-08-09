---
title: create-react-app中引入antd和less
date: 2018-08-14 17:57:32
tags: React
toc: true
categories: 经验分享
---

create-react-app作为React框架的官方脚手架，以其安装方便，无需配置，开箱即用，而被人所喜爱。但在使用过程中也暴露出不少问题，比如不能按需加载UI框架，以及不支持SASS，LESS等CSS预处理器。下文就将解决这两个问题。
<!-- more -->

## 预备步骤
### 安装yarn（可选）
`npm i -g yarn`
### 安装antd
`yarn add antd`
### 解锁自定义配置
`yarn eject`

## 加入LESS的支持
在解锁自定义配置之后，会发现根目录下多了好多文件夹，这些就是暴露出来的配置文件。
### 安装less
`yarn add less less-loader` 

### 配置webpack
打开config文件夹下的webpack.config.dev.js文件，利用编辑器/IDE找到这一部分，并在use数组下加入这一less-loader对象,webpack.config.prod.js同理
```js
         -  test: /\.css$/,
         +  test: /\.(less|css)$/,
            use: [
              require.resolve('style-loader'),
              {
                loader: require.resolve('css-loader'),
                options: {
                  importLoaders: 1,
                },
              },
         +      {
         +        loader: require.resolve('less-loader')
         +      },
              {
                loader: require.resolve('postcss-loader'),
```

## 按需加载antd
### 安装所需插件
`yarn add babel-plugin-import` 

### 在webpack或package.json中写入配置
```js
          // webpack.config.dev.js
          {
            test: /\.(js|jsx|mjs)$/,
            include: paths.appSrc,
            loader: require.resolve('babel-loader'),
            options: {
      +      plugins: [
      +        ["import",{libraryName: "antd",style: "css"}]
      +      ],
              cacheDirectory: true,
            },
          },
```

```json
//package.json
  "babel": {
    "presets": [
      "react-app"
    ],
  +  "plugins": [
  +    ["import",{"libraryName":"antd","style":"css"}]
  +  ]
  },
```

## 总结
完成上述两处即可，愉快地coding吧 
![](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/alice.jpg)