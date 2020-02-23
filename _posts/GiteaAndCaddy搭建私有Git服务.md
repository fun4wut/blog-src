---
title: Gitea+Caddy搭建私有Git服务
date: 2019-07-06 17:38:11
tags: 
 - 服务器
 - Git
toc: true
index_img: https://gofun4-pic.oss-cn-hangzhou.aliyuncs.com/img/20200223141743.png
categories: 经验分享
---

花了不少时间把Github的垃圾代码搬迁到了Gitea上，用作自嗨。简单写写遇到的苦难，希望看到这篇文章的各位能少踩些坑

### 为什么使用Gitea+Caddy?

- Gitea相比其他Git服务【如gitlab，gogs等】，非常轻量级，适合学生服务器使用。
- Caddy使用非常简单，快速上手，自动部署HTTPS -> 这个我吹爆
- 两个都是用Go语言写的，<del>这是一种缘分，也是种巧合</del>

<!--more-->

## Gitea搭建

官网给出了几种安装方式，因为学生机内存吃紧，所以考虑直接二进制构建。

参照[英文文档](<https://docs.gitea.io/en-us/install-from-binary/>)的指示，一路continue，没啥问题。

默认在3000端口运行。

**记得打开防火墙**

### postgresql的安装

进入之后需要对数据库进行设置。

因为开源信仰，这里我们用postgresql作为数据库。

官网下载地址：https://www.postgresql.org/download/

参照该地址下载👆。

1. pgsql比较特殊，想进入命令行，先切换到`postgres`

   ```bash
   su postgres
   psql-U postgres
   ```

   

2. 进入psql后，先给这个用户设个密码

    ```
    alter user postgres with password '你要设置的密码';
    ```

3. 同时建一个新数据库供gitea使用

    ```
    CREATE DATABASE gitea;
    exit;
    ```



### gitea配置

进入`localhost:3000`，按照先前的数据库配置依次填入，并填好域名等，搭建即算完成。

对于gitea进一步配置请移步https://docs.gitea.io/en-us/customizing-gitea/



## Caddy搭建

前往<https://caddyserver.com/download>进行下载。

这里有几个插件要注意一下，可以考虑附上

- git： 用来拉取git内容
- dns.*： 如果你的域名用的别家DNS

安装脚本和直接下压缩包都行，视网速而定。

> 若直接下压缩包，需要把caddy手动copy到`/usr/local/bin`



**直接跑caddy是非常不合适的，因为Caddyfile分散在各地，不利于统一管理。**

**万幸的是我们可以使用守护进程。**



### 配置service

1. 将官方的配置文件copy

   ```bash
   sudo cp init/linux-systemd/caddy.service /etc/systemd/system/
   ```

2. 创建所需目录，我图方便没有修改脚本直接使用默认值了，如果有特殊需求，可以自己更改目录。

   ```bash
   sudo mkdir /etc/caddy
   sudo chown -R root:www-data /etc/caddy
   sudo touch /etc/caddy/Caddyfile
   
   sudo mkdir /etc/ssl/caddy
   sudo chown -R www-data:root /etc/ssl/caddy
   sudo chmod 0770 /etc/ssl/caddy
   
   sudo mkdir /var/www
   sudo chown www-data:www-data /var/www
   
   ```

   上面创建了三个目录，`/etc/caddy` 用了存放 Caddy 的配置文件，`/etc/ssl/caddy` 存放证书，`/var/www` 是默认的网站目录。

3. 这样的配置无法让caddy获得80和443端口的权限。需要修改`/etc/systemd/system/caddy.service`，取消注释

   ```
   ; Note that you may have to add capabilities required by any plugins in use.
   CapabilityBoundingSet=CAP_NET_BIND_SERVICE
   AmbientCapabilities=CAP_NET_BIND_SERVICE
   ```

4. 接着，重新加载 `systemd daemon`，让配置生效。

   ```bash
   sudo systemctl daemon-reload
   ```

5. 让 Caddy 开机自启。

   ```bash
   sudo systemctl enable caddy.service
   ```

6. 启动Caddy

   ```bash
   sudo systemctl start caddy.service
   ```


### 编写Caddyfile

非常简单，3行搞定

```
your.host.name {
	proxy / http://localhost:3000
}
```

> 配置文件在`/etc/caddy/Caddyfile`



## 预告

下一篇博客，将讲一讲Caddy+Hexo实现博客自动化构建与部属