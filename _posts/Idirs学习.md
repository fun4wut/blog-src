---
title: Idris学习
date: 2020-10-25 10:59:08
tags: 
 - Idris
top_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/18-8-29/post-bg.jpg
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/20201025103054.png
categories: 学习笔记
---

记录了下学习Idris过程，现在差不多咕了（逃
参考书目：《Type Driven Development with Idris》
练习答案：[https://github.com/fun4wut/TDD-Idris-Notes](https://github.com/fun4wut/TDD-Idris-Notes)
<!-- more -->

# Chapter 0

## REPL指令

![](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/Untitled.png)


# Chapter 1

1. 两大特性：
    - Holes：类型打洞，不声明直接调用函数，编译器可以识别并推导出该函数的类型
    - First-class types：类型可以当作value一样使用（可以用作函数的输入输出）
2. 几个使用场景：
    - 矩阵运算（编译期完成对矩阵的维数的验证和计算）
    - ATM机器（有限状态机）
    - 并发编程（确保同步问题的先后顺序）
    - 类型安全的 `printf`
3. 一般步骤：type、define、refine（先写类型，再写实现）

# Chapter 2

## 2.1 基本类型

### 2.1.1 数值类型

有4种数值类型：

1. Int：固定长度的整数，有上下限
2. Integer：大整数，没有上下限（整数字面量默认当作Integer处理）
3. Nat：自然数，没有上限（常用作下标，长度等属性的类型）
4. Double：双精度浮点数

### 2.1.2 类型转换

- 使用 `the` 函数（字面量可以表达为多种类型，使用the来显示指定）：`the Double (6+3*12)`
- 使用 `cast` 函数（基本类型都可以相互转换）：`putStrLn (cast 1+2)`

### 2.1.3 字符和字符串

1. Char：单个字符，单引号
2. String：字符串，双引号
3. 使用 `++` 拼接字符串

### 2.1.4 布尔类型

1. True和False，注意首字母大写
2. 不等号使用 `/=` 而不是 `!=`
3. If语句：`if <cond> then <exprs> else <exprs>`

## 2.2 函数

### 2.2.1 类型和声明

![](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/Untitled%201.png)

- 求值顺序：Idris使用严格求值，先对内层函数求值，再向外展开
- 参数的名字可以在 `type decl` 里写出来 `double : (value : Int) → Int`
- 函数的类型是**右结合**的

### 2.2.2 偏函数

Idris的函数是柯里化的，所以可以只填入部分参数，返回的值依然是个函数。

### 2.2.3 泛型函数

因为类型只是一个变量，所以直接在 `type decl` 里写类型变量就行了

```csharp
identity : ty -> ty
identity x = x

// The 函数的类型定义
the : (ty : Type) -> ty -> ty
// 易推出
// the Int : Int -> Int
// the String : String -> String
```

### 2.2.4 约束类型

泛型的类型必须满足某些约束（interface）

![](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/Untitled2.png)


### 2.2.5 运算符

运算符也是函数，中缀形式只是一个语法糖罢了。使用前缀形式，要用括号包裹

```csharp
(+) : Num ty => ty -> ty -> ty
(==): Eq  ty => ty -> ty -> ty
(<=): Ord ty => ty -> ty -> ty
```

运算符同样可以有偏函数

- `(< 3)` 表示 `\x => x < 3`
- `(3 <)` 表示 `\x => 3 < x`
- 缺了哪个操作数，就把那个操作数作为函数的参数

### 2.2.6 匿名函数

没有名字，可以不标注类型。

- 不标注类型：`\x, y ⇒ x+y`
- 标注类型：`\x : Int, y : Int ⇒ x+y`

### 2.2.7 局部定义

1. 局部变量：`let`

    ![](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/Untitled3.png)


2. 局部函数：`where`

    ![](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/Untitled4.png)


## 2.3 复合类型

### 2.3.1 元组

- `(ty, ty, ty, ...)` 的形式
- 二元组 `(ty, ty)` 称作 `Pair`
- 取第一个元素：`fst`，取第二个元素：`snd`
- 空元组 `()` 称为 `Unit`
- 在编译器内部，元组是当作嵌套的Pair来处理的

### 2.3.2 列表

- 底层是链表实现
- `Nil`，空列表
- `x :: xs` ，x为head，xs为tail
- List的拼接同样使用 `++`
- 可以用 `[a, b, c, d]` 的语法糖来书写列表
    - `[1,2,3]` 实则就是 `1::(2::(3::Nil))`
- Range
    - `[1..5]` 展开为 `[1,2,3,4,5]`
    - `[1,3..9]` 展开为 `[1,3,5,7,9]`
    - `[5,4..1]` 展开为 `[5,4,3,2,1]`

### 2.3.3 模块系统

- 文件顶端要声明模块名字，模块首字母大写，例如 `module Main`
- 文件名和模块名保持一致
- 使用 `export` 来暴露出声明，使用 `import` 来导入模块
- 模块的查找根据文件目录
- 一个Idris程序的入口是`main` ，main函数签名为 `IO ()`

## 2.4 其他

1. Idris是靠缩进控制作用域和声明的，所以对空格敏感
2. 如果idris可以推断出值来，那么可以用 `_` 代替
3. 单行注释，用 `--` 打头
4. 多行注释，用 `{-` 和 `-}` 包裹
5. 文档注释（注释会自动生成到文档上），用 `|||` 打头
    - 可以用 `@argName comment...`  对参数做额外的注释

# Chapter 3

## 3.1 编码Tips

### 3.1.1 常用的快捷键（Vim）

`<LocalLeader> r` 类型检查

`<LocalLeader> t` 展示类型

`<LocalLeader> a` 给定类型声明，生成函数体

`<LocalLeader> c` 对于模式匹配的case，分出更多的case（case split）

`<LocalLeader> mc` 对variable生成模式匹配

`<LocalLeader> w` add with clause

`<LocalLeader> e` 表达式求值

`<LocalLeader> l` 给定一个hole，生成这个hole的类型声明，并使得这个表达式正确（会用上所有的local变量作为参数）

`<LocalLeader> m` add missing clause

`<LocalLeader> f` 重构，refine

`<LocalLeader> o` 寻找符合这个hole的expression

`<LocalLeader> s` proof search

`<LocalLeader> i` open idris response window

`<LocalLeader> d` show documentation

### 3.1.2 一些命名规范

- 对于List类型的变量 `xs`，里面的元素一般叫作 `x`
- 对于自然数类型，一般起名叫做 `k`

### 3.1.3 mutual 块

**Idris的函数需要先声明再使用。**对于需要相互调用对方的函数，可以使用 `mutual` 块

```csharp
mutual
isEven : Nat -> Bool
isEven Z = True
isEven (S k) = isOdd k
isOdd : Nat -> Bool
isOdd Z = False
isOdd (S k) = isEven k
```

## 3.2 类型参数绑定

1. 如果在runtime需要用到类型参数，需要在decl时显式绑定

    ```haskell
    my_vec_length : {n: _} -> Vect n a -> Nat
    my_vec_length xs = n
    ```

2. 可以对函数进行特化（指定类型参数）

    ```haskell
    my_vec_length {a=Char} [1,2,3] -- error!
    my_vec_length {a=Char} ['1', '2'] -- OK
    ```

## 3.3 类型构造器

`idris` 不提供type alias，而是可以直接通过函数的方式来实现 `type constructor`

```haskell
Matrix : Nat -> Nat -> Type -> Type
Matrix n m a = Vect n (Vect m a)
```

# Chapter 4

## 4.1 ADT定义

1. 简单定义

    ```haskell
    data Shape = Triangle Double Double
     | Rectangle Double Double
     | Circle Double
    ```

2. 函数形式的完整定义，适用于需要类型约束的情况

    ```haskell
    data BSTree : Type -> Type where
    Empty : Ord elem => BSTree elem
    Node : Ord elem => (left : BSTree elem) -> (val : elem) ->
    (right : BSTree elem) -> BSTree elem
    ```

    Tips：可以使用 `%name` 指令来规范变量的命名规则。
    `%name Shape shape, shape1, shape2`

3. 在模式匹配时，可以使用 @ 来绑定表达式，避免重复书写

```haskell
insert : elem -> BSTree elem -> BSTree elem
insert x Empty = Node Empty x Empty
insert x orig@(Node left val right) = {- you can use orig here -}
```

## 4.2 Dependent data types

### 4.2.1 Definition

可以根据Constructor不同，返回不同的特化Data type

![](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/Untitled5.png)


如上图，Bicycle和Car，Bus的返回类型不同，虽然都是Vehicle。

由 `Vehicle` 定义的所有type被称为 `Vehicle` 的 `type family`

**Terminology: parameters and indices**
`Vect` defines a family of types, and we say that a `Vect` is indexed by its length and
parameterized by an element type. The distinction between parameters and indices
is as follows:

- A `parameter` is unchanged across the entire structure. In this case, every element of the vector has the same type.
- An `index` may change across a structure. In this case, every subvector has a
different length.

The distinction is most useful when looking at a function’s type: you can be certain
that the specific value of a parameter can play no part in a function’s definition. The
index, however, might, as you’ve already seen in chapter 3 when defining `length` for
vectors by looking at the length index, and when defining `createEmpties` for building a vector of empty vectors.

### 4.2.2 类型检查

可以显示的标明某个case不可能出现，但不影响编译器的行为

```haskell
refuel : Vehicle Petrol -> Vehicle Petrol
refuel (Car fuel) = Car 100
refuel (Bus fuel) = Bus 200
refuel Bicycle impossible
```

如果表明了一个会出现的case为impossible，编译器会报错

```haskell
refuel : Vehicle Petrol -> Vehicle Petrol
refuel (Car fuel) = Car 100
refuel (Bus fuel) impossible -- error!
```

### 4.2.3 Vect实例

`Vect` 就是使用依靠Dependent Type构建的。

```haskell
data Vect : Nat -> Type -> Type where
Nil : Vect Z a
(::) : (x : a) -> (xs : Vect k a) -> Vect (S k) a
```

同时还可以类型安全的下标取值运算。

```haskell
index : Fin n -> Vect n a -> a -- Fin n 是 [0, n) 的无符号整数
```