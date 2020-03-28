---
title: 增强RN的Stylesheet
date: 2020-03-28 13:34:37
tags: 
 - RN
 - TS
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200328133408.png
categories: 经验分享
---

## 一句话概括

 让StyleSheet.create支持字段方法同时能保持类型检查，代码实现直接看 造轮子部分

## 情景重现

在编写RN代码中，我们常常会遇到这样的case：

```react
<Button
	// ...
  viewStyle={[styles.submitBtn, isValid?null:{ backgroundColor: '#8A223C' }]}
  textStyle={[styles.submitBtnText, isValid ? null : { color: '#8A8B9C' }]}
/>
```

可以看到，我们经常会需对style进行extend，根据某个变量来对样式进行修改。

这种做法看似方便，却打破了样式与逻辑分离的约定。不利于后期的维护。

## 问题引入

我们仔细想一下，有什么办法可以做到让样式也可以根据传入的数据来进行变化呢？

比较容易想到的就是用方法(method)，我在style对象里加方法，根据入参来决定出参不就行了？

然而由于StyleSheet的声明文件限制，我们的style对象必须只能是字面量

```typescript
type NamedStyles = { [P in keyof T]: ViewStyle | TextStyle | ImageStyle };
export function create | NamedStyles>(styles: T | NamedStyles): T;
```

其实这里的声明写复杂了，我们对此做一些简化

```typescript
type NamedStyles = Record
declare function create(styles: T): T
```

两段代码（应该）是等价的。

但实际上create函数做了什么？让我们来看看create的语法

```js
 /**
  * Creates a StyleSheet style reference from the given object.
  */
 create<+S: ____Styles_Internal>(
  obj: S,
 ): $ObjMap StyleSheetInternalStyleIdentifier> {
  const result = {};
  for (const key in obj) {
   StyleSheetValidation.validateStyle(key, obj);
   result[key] = obj[key] && ReactNativePropRegistry.register(obj[key]);
  }
  return result;
 }
```

RN使用Flow写的，不过大致还是能懂得，主要逻辑从第7行开始。

对每个字段做了两个步骤，一是检验style是否合法，而是拷贝到新的obj里，并且在PropRegistry里进行注册。【我对这个注册的步骤不大懂，有什么用，似乎不影响运行？】

```js
var objects = {}; 
var uniqueID = 1;
var emptyObject = {};
class ReactNativePropRegistry {  
  static register(object: Object): number {
    var id = ++uniqueID;   
    if (__DEV__) {    
      Object.freeze(object);  
    }   
    objects[id] = object;   
    return id;  
  }
  // ...
}
```

分析完代码，不难看出，create做的主要不过是把输入再返回给你罢了，用个函数包装是为了 type check 和 type hint。

## 解决办法

由于原先的StyleSheet的create函数会对字段做check，所以function是会被拦住的，但其实，这个check用处不大，改成直接返回是可以接受的。所以我们需要重写一下create方法的实现，改成最原始的直接返回。再来想想，让create支持字段有方法的对象，还需要修改类型定义。

```typescript
type AllStyle = TextStyle | ViewStyle | ImageStyle
type StyleFn = (...args: any[]) => AllStyle
type NamedStyles = Record
declare function create(styles: T): T
```

代码比较显然，StyleFn 就是一个返回AllStyle的函数类型。

## 开始造轮子

只需要导出一个函数就够了，为了兼容JS，采用源文件用js + d.ts声明的方式。

### index.js

函数很简单，就一行

```js
export const createStyleSheet = _ => _
```

### index.d.ts

把上述提到的类型定义修改加入

```typescript
import { TextStyle, ViewStyle, ImageStyle } from 'react-native'
type AllStyle = TextStyle | ViewStyle | ImageStyle
type StyleFn = (...args: any[]) => AllStyle
type NamedStyles = Record
export function createStyleSheet(styles: T): T
```

## 实战效果

理论上，my-style-sheet 应该和 StyleSheet 应该是无缝兼容了，让我们修改一个style.js文件，把StyleSheet.create改为createStyleSheet，看看效果

![img](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200328132822.png)

没有报错，说明没有问题。

### 小试牛刀

接下来让我们试试在style对象里添加方法

```js
createStyleSheet({
 root: {
  margin: 4,
 },
 testMethod(foo = true) {
  return {
   ...this.root,
   color: foo ? '#fff' : '#000',
  }
 },
})
```

使用了方法之后，我们获得了另外一个好处，就是可以利用this来使用别的字段了，这也提升了代码的复用性。

### 回到原点

现在我们来解决开头的问题 

```react
<Button
  // ...
  viewStyle={[styles.submitBtn, isValid?null:{ backgroundColor: '#8A223C' }]}
  textStyle={[styles.submitBtnText, isValid ? null : { color: '#8A8B9C' }]}
 />
```

对应的styles如下

```js
 submitBtn: {
  flex: 1,
  height: 44,
  backgroundColor: '#FE2C55',
  marginTop: 16,
 },
 submitBtnText: {
  fontSize: 15,
  lineHeight: 18,
  color: '#ffffff',
 },
```

现在，我们的styles支持了方法，那之前的逻辑就可以不这写了

```js
 submitBtn(isValid: boolean) {
  return {
   flex: 1,
   height: 44,
   backgroundColor: isValid ? '#FE2C55' : '#8A223C',
   marginTop: 16,
  }
 },
 submitBtnText(isValid: boolean) {
  return {
   fontSize: 15,
   lineHeight: 18,
   color: isValid ? '#ffffff' : '#8A8B9C',
  }
 },
```

其实，如果不用到this的话，可以再简化成箭头函数

```typescript
 submitBtn: (isValid: boolean) => ({
  flex: 1,
  height: 44,
  backgroundColor: isValid ? '#FE2C55' : '#8A223C',
  marginTop: 16,
 }),
```

调用测的代码便可以简化成这样

```react
<Button
  // ...
  viewStyle={styles.submitBtn(isValid)}
  textStyle={styles.submitBtnText(isValid)}
/>
```