---
title: material-ui与TS结合的实践
date: 2019-01-31 19:19:56
tags: React
---
> TypeScript yes!!!

<!-- more -->
# 介绍
## material-ui
[material-ui](https://material-ui.com/)是一款React下的组件库，它支持绝大部分Material Design所定义的组件。相比其他的React组件库【比如[antd](https://ant.design/),[semantic-ui](https://react.semantic-ui.com)】，它有如下优势：
* 样式酷炫， 符合年轻人审美
* 定制化程度强
* 支持多种CSS写法，如
  1. JSS
  2. Styled-Components
  3. CSS Modules
  4. LESS
  5. SASS/SCSS
* 完善的Typescript支持

## Typescript
[Typescript](http://www.typescriptlang.org/)是由微软开发的JavaScript的超集，同时借鉴了Java与C＃的优点。相比JavaScript，它的优势在于:
* 静态类型检查，减少运行时错误
* 增强IDE的智能提示
* 强大的社区支持
* 空安全机制

## Umi
[umi](https://umijs.org)，中文可发音为乌米，是一个由阿里开源的 react 应用框架。umi 以路由为基础的，支持类 next.js 的约定式路由，以及各种进阶的路由功能，并以此进行功能扩展，比如支持路由级的按需加载。然后配以完善的插件体系，覆盖从源码到构建产物的每个生命周期，支持各种功能扩展和业务需求，目前内外部加起来已有 50+ 的插件。它的主要特性在于：
* 📦 **开箱即用**，内置 react、react-router 等
* 🏈 **类 next.js 且[功能完备](https://umijs.org/guide/router.html)的路由约定**，同时支持配置的路由方式
* 🎉 **完善的插件体系**，覆盖从源码到构建产物的每个生命周期
* 🚀 **高性能**，通过插件支持 PWA、以路由为单元的 code splitting 等
* 💈 **支持静态页面导出**，适配各种环境，比如中台业务、无线业务、[egg](https://github.com/eggjs/egg)、支付宝钱包、云凤蝶等
* 🚄 **开发启动快**，支持一键开启 [dll](https://umijs.org/plugin/umi-plugin-react.html#dll) 和 [hard-source-webpack-plugin](https://umijs.org/plugin/umi-plugin-react.html#hardSource) 等
* 🐠 **一键兼容到 IE9**，基于 [umi-plugin-polyfills](https://umijs.org/plugin/umi-plugin-react.html#polyfills)
* 🍁 **完善的 TypeScript 支持**，包括 d.ts 定义和 umi test
* 🌴 **与 dva 数据流的深入融合**，支持 duck directory、model 的自动加载、code splitting 等等

# 最佳实践
## 前期准备
1. 安装umi脚手架
   自行查看[通过脚手架创建项目](https://umijs.org/zh/guide/create-umi-app.html)
2. 安装material-ui
   自行查看[安装 - Material-UI](https://material-ui.com/getting-started/installation/)
3. 暴露HTML模板
   UMI的HTML模板默认是隐藏的,需要在`pages`下新建`ejs`文件以暴露
   ```bash
   cd src/pages
   vim ./document.ejs
   ```
    
4. 加入字体库和移动端支持
   ```html
   <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My app</title>
      <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto:300,400,500">
      <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
    </head>
    <body>
      <div id="root"></div>
    </body>
    </html>
    ```
5. 修改tsconfig提升变成乐趣
   Umi已经把大体的配置好了，可以再加入一些检查
   ```js
    // tsconfig.json
    "noImplicitAny": true, //禁止隐式的any
    "noImplicitReturns": true, //禁止隐式的return
    "noImplicitThis": true, //禁止隐式的this
    "strictNullChecks": true //空安全检查
   ```
## 具体编码
### 改写styles的声明方式
1. 无theme
   ```ts
   const styles = createStyles({
       // JSS code
   })
   ```
2. 有theme
   ```ts
   const styles = (theme: Theme) => createStyls({
       // JSS code
   })
   ```
### 改写Props的声明方式
Props需要继承WithStyles这一泛型接口
```ts
interface Props extends WithStyles<typeof styles>{}
/* ....... */ 
class Example extends React.Component<Props,State>{}
```
### 自定义主题
一般在顶层组件(umi下是`src/layouts/index.tsx`)下自定义主题即可
```tsx
// .......没法高亮，抱歉
const customizedTheme = createMuiTheme({
    palette: {
      primary: blue,
      secondary: red,
    },
    typography: {
      useNextVariants: true
    },
})
function Layout(props: Props){
    return (
      <MuiThemeProvider theme={customizedTheme}>
        {props.children}    
      </MuiThemeProvider>
    )
}
export default withStyles(styles,{withTheme: true})(Layout)
```
### Attention！
**不要使用@material-ui/styles下的函数/组件，天坑警告**
**不要使用@material-ui/styles下的函数/组件，天坑警告**
**不要使用@material-ui/styles下的函数/组件，天坑警告**