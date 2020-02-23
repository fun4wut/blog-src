---
title: 服务器部署nodejs的几种方法
date: 2018-05-26 09:39:27
tags: 
 - Linux
 - Node.js
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200223151629.png
categories: 经验分享
---

由于自身特性的原因。node程序必须保持开启才能访问网站，而当我们关闭SSH时这些进程都会被停止。有以下3种方法可以避免这个问题。

<!--more-->

# screen
Screen，虚拟终端管理器。可以在后台管理终端界面，防止SSH断开以后任务停止运行。
###### 安装方法：
 `sudo apt-get screen` (以ubuntu为例)
###### 使用方法:
1. 使用screen -S [任意id]命令进入一个名为id的终端，此时便可以随意执行操作
例如执行`sudo apt-get upgrade`，或者其它消耗时间比较长的工作，像编译内核等等。
2. 按ctrl+a后再按d保存虚拟终端，系统提示deatached即为保存成功
接下来可以断开SSH终端，虚拟终端仍会执行。
3. 访问已经创建好的终端
`screen -ls`   列出已经创建的正在后台运行的终端
`screen -r xxx` 进入终端
例如 screen -r terminal1
4. 彻底退出
`screen -r` 进入终端后执行exit即可完全退出

----

# PM2
pm2 是一个带有负载均衡功能的Node应用的进程管理器.当你要把你的独立代码利用全部的服务器上的所有CPU,并保证进程永远都活着

###### 安装方法
`​npm install -g pm2 `

###### 使用方法
启动应用 `pm2 start -watch app.js`

重启应用 `pm2 restart app.js `

显示进程列表 `pm2 list`

停止某应用 `pm2 stop app_name|app_id`

停止所有应用 `pm2 stop all`

----

# 小白方案

个人目前用的是宝塔Linux面板，可以说是把Linux的各种操作都已比较简单的形式展现出来了，不需要什么Linux知识就能掌握      [宝塔官网了解一下](https://www.bt.cn/)

![管理界面](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/11.png)

而这其中内置了PM2管理，装一下就OK了
![PM2界面](https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/22.png)

## 真·点点点操作

-----

参考：[使用Screen后台执行任务，防止SSH中断](https://blog.csdn.net/frank_good/article/details/51794030)

[pm2常用的命令用法介绍](https://blog.csdn.net/sunscheung/article/details/79171608)