---
title: Hexo+Caddy+Git自动化博客部署
date: 2019-07-07 09:48
tag:
 - Hexo
 - Caddy
---

在使用GithubPage+Hexo来部署博客时，我们时常会遇到这样的问题: 网页源代码push上去了，但是大量的markdown文件保留在了本地，这对于多机用户的影响是很大的。为此你不得不再新建一个branch/repo来存放你的文章，但依然难以避免忘记同步文章的情况发生。且多机环境意味着每台机器都要装nodejs环境来进行网页的生成。十分不友好。所以更好的解决方案呼之欲出：使用*webhhook*等方式，把生成网页的步骤交给服务器，PC要做的仅仅是写markdown+同步至Git

<!--more-->

# 前置工作

- 准备好Caddy环境，具体可查看我的上一篇博客：[Gitea+Caddy搭建私有Git服务]([https://blog.fun4go.top/2019/07/06/Gitea+Caddy%E6%90%AD%E5%BB%BA%E7%A7%81%E6%9C%89Git%E6%9C%8D%E5%8A%A1/](https://blog.fun4go.top/2019/07/06/Gitea+Caddy搭建私有Git服务/))
- 任意Git服务（如Github/GitLab/Gitea）
- Hexo的基础知识，不了解的请先去查阅官网：[文档|Hexo](https://hexo.io/zh-cn/docs/index.html)



# 配置Repo

## 建议一个存放文章源代码的Repo

将source文件夹下的所有文件上传

## 设置Webhook (Optional)

Caddy的Git插件只对以下有效

- Github
- Gitlab

**不使用上述Git服务的请跳过**

Webhook位于Settings/Webhooks。

- Payload URL: 你的博客地址
- Content type：选择Json
- Secret：自己设置密钥
- 点击Add Webhook即算完成



# 配置Hexo

## 使用官方源的Nodejs

由于Caddy的用户组为`www-data`，它的PATH变的路径很少。使用`nvm`或`n`来使用node环境的话会出很多问题。

这里建议直接`sudo apt install nodejs`

## 建立hexo主目录

1. 在`/var/www/`下建立你的博客主目录

2. 主题什么的也照例配好

3. 删除source文件夹

4. 假设你的博客目录名为blog，则执行

   `chown www-data -R /var/www/blog`让caddy获得整个文件夹的完整权限

5. 为方便调试，给`www-data`用户加上shell，以便进行登录

   `usermod -s /bin/bash www-data`



# 配置Caddy

对`/etc/caddy/Caddyfile`进行修改，增加新的网站

```
blog.your.host {
    tls your@email
    gzip
    root /var/www/blog/public
    git {
        repo https://your.git.repo
        path ../source
        hook /webhook secret-key
        hook_type gogs
        interval 300
        clone_args --recursive
        pull_args --recurse-submodules
        then hexo g
    }
}
```

下面对各个配置进行解释

1. **tls**: 你的邮箱，用来设置Https
2. **gzip**：对网页进行压缩，加快传输速度
3. **root**：你的网页代码目录（即为public目录）
4. **repo**：你的repo的git地址，ssh和https地址均可
5. 如果你设置了Webhook：
   1. **hook**：hook类型（即为`/webhook`）和密钥
   2. **hook_type**: 显示指定你的hook类型（github/gitlab）
6. 如果你没设置webhook：
   1. **interval**：拉取时间，定期拉取repo【时间单位为秒】
7. **clone_args**：递归
8. **pull_args**：递归
9. **then**：可以自定义命令，这里我们执行`hexo g`来生成静态网页



最后执行`systemctl reload caddy.service`载入配置，大功告成！