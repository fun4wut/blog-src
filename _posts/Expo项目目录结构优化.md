---
title: Expo项目目录结构优化
date: 2020-02-23 17:57:32
tags: React
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/20200923215213.png
categories: 经验分享
---

Expo默认的目录结构比较奇快，没有src目录，entry point直接位于根目录上，非常的丑，而且其引入方式限制死了只能import相对路径，对代码的直观性也是有很大的伤害。针对这两个问题，笔者翻遍了Stack Overflow，终于拼凑出了一套解决办法，记录下来做分享和备忘。

<!--more-->

## Expo简介

**～了解这工具的可以跳过～**

Expo是一个快速搭建RN环境的工具链。不需要什么java环境搭建，xcode，Android Studio也不需要。只需要一个node即可。而且，其还提供了丰富的文档，和在线版的demo，在网页上就能体验效果。对一些端能力也做了封装，文档和教程也写的不错。

那么，代价是什么呢？比较大的问题就是打的包比较大了，不过对于快速迭代，没有什么更好的选择了。更多内容请看 [expo官网](https://expo.io/learn)

## 默认目录结构一览

```
.
├── app.json
├── App.tsx
├── assets
│  ├── icon.png
│  └── splash.png
├── babel.config.js
├── node_modules
├── package-lock.json
├── package.json
└── tsconfig.json
```

如上图所示，App.tsx是entry point。启动整个程序。

```react
import React from 'react';
import { Text, View } from 'react-native';

export default function App() {
  return (
    <View>
      <Text>Open up App.tsx to start working on your app!</Text>
    </View>
  );
}
```

最简的一个App根组件表示。

## 解决启动点位置问题

理想的目录结构当然是要有src目录的，App.tsx位于src目录的顶层。如下图

```
.
├── app.json
├── src
│  ├── App.tsx
├── assets
│  ├── icon.png
│  └── splash.png
├── babel.config.js
├── node_modules
├── package-lock.json
├── package.json
└── tsconfig.json
```

要达成这样的效果，需要对两个文件作修改。

1. App.tsx

   ```react
   import { registerRootComponent } from 'expo'; // import it explicitly
   import React from 'react';
   import { Text, View } from 'react-native';
   
   function App() {
     return (
       <View>
         <Text>Open up App.tsx to start working on your app!</Text>
       </View>
     );
   }
   export default registerRootComponent(App) // export it explicitly
   ```

   显式导入 `registerRootComponent`，然后在显式导出包装后的App组件即可

2. app.json

   ```json
   {
     "expo": {
       "entryPoint": "./src/App.tsx",
       //...
     }
   }
   ```

   加上这一即可，显示指定启动点。当然如果你不用ts，那启动点就是 `App.js/App.jsx`

**修改完之后，执行 `expo start -c`，清除缓存启动即可。**

## 解决路径导入问题

写相对路径导入在某些情况下是十分繁琐的，比如

```react
import Foo from '../../../components/foo'
```

实在不是很美观，而且也不利于看代码的人review。如果熟悉babel的话应该知道，babel是有模块别名设置的功能的，有了这个，便能使用绝对路径导入，上述代码将可以改写成

```react
import Foo from '@src/components/foo'
```

导入简单而清晰，便于维护。

----

下面来看如何实现

expo提供了babel的配置文件供我们修改，所以就很方便了，直接修改`babel.config.js`

```js
module.exports = function(api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      [
        'module-resolver',
        {
          alias: {
            '@src': './src',
          },
        },
      ],
    ],
  }
};
```

添加`module-resolver` 插件，添加别名即可。这里别名可以自由发挥。

---

看到这里用TS的同学一定很纳闷，众所周知，ts不依靠babel就能做到这些，直接在`tsconfig.json`上作修改不就行了？

起初我也有这样的迷惑，然后被就经历了ts编译没报错，expo报错的报错。后来我了解到，**这里的TS只负责类型检查，而不管文件的编译，那么文件的编译谁做？很简单，ts编译器把类型申明代码剔除，变成纯JS代码，然后就交给babel进行编译，所以模块import语句转成require是由babel负责的。** 自然，babel认不出`@src`是个什么鬼。所以TS的同学也要像前文一样，补充对babel的进行配置即可

这里再补充一下对于`tsconfig.json`的配置

```json
{
  "compilerOptions": {
		// ...
    "baseUrl": ".",
    "paths": {
      "@src/*": ["./src/*"]
    }
  }
}
```

`baseurl` 是指定的根目录地址，这里就是项目的根目录，下面的`paths`配置地址映射即可



## 题外话

快两个月没写博客了，这段时间去了字节跳动前端实习。说不上有趣，但是他们给的实在太多了.jpg。其实中途有几次想写一下用rust写compiler的心得。但是最近又被`borrow checker`按在地上摩擦了，而且也不知道该怎么写，以至于拖到现在。

这次不仅更新了博客，也更新了主题，不得不说，给博客配图是个非常痛苦的过程，哪些图适合放，哪些不适合，<del>哪些放出来会不会太死宅了，</del>都是很讲究的问题。所以光配图片我就花了3个小时。

之后对博客主题应该会还做修改，把之前的点击烟花特效加回来，和about页面（现在的about放的是linkedin未免有点严肃）。




