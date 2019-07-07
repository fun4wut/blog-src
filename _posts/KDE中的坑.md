---
title: KDE踩坑实录 [3月22日更新]
date: 2019-03-13 15:15:30
tags: Linux
---

## 前言

> 只有写写踩坑文才能维持生活的样子
> 环境：Fedora 29,  KDE 5.55.0

<!-- more -->

## KDE CONNECT找不到设备

### 原因

**没有打开相关端口**

### 解决方法

- **防火墙是iptables**

  ```bash
  sudo iptables -I INPUT -p tcp --dport 1714:1764 -j ACCEPT
  sudo iptables -I INPUT -p udp --dport 1714:1764 -j ACCEPT
  ```

- **防火墙是firewall**

  ```bash
  sudo firewall-cmd --zone=public --add-port=1714-1764/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=1714-1764/udp --permanent
  sudo firewall-cmd --reload
  ```

## KMAIL无法加入微软系列邮箱

### 原因

**微软特殊的邮箱协议**

### 解决办法

1. 打开KMAIL
2. 进入设置->配置Kmail
3. 账户->接收->添加自定义账户->IMAP邮件服务器
4. IMAP服务器：imap-mail.outlook.com
5. 用户名：邮箱地址
6. 密码：你的邮箱密码
7. 高级->连接设置 ->自动探测

### 缺陷

***发邮件的咋整啊。。求教***

## 界面放大比例

若在"显示和监控"下进行界面放大的操作，会发现chrome，idea等软件依然没有被放大，且字体非常非常丑

## 解决方法
在"字体"界面调整字体DPI，注意不要直接在输入框手敲，而是使用提供的箭头来切换DPI

