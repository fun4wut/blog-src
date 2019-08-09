---
title: WSL改造实录
date: 2018-11-17 22:24:42
tags: Linux
toc: true
categories: 经验分享
---


换了新显示器后，原来的arch怎么也识别不出来，很蛋疼，加之之前双系统来回切也有些厌烦了。

最终，想起了被遗弃在角落的WSL。决定加以改造，作为日常使用。


**WSL安装过程不再赘述。**

<!-- more -->

## WSL-terminal

为什么要使用WSL-terminal呢，因为<del>他比PS，cmder之流高到不知道那里去了。</del> 他是基于mintty魔改的终端，低调奢华。附带添加至右键菜单，添加之环境变量等脚本全家桶，安装省心方便

方法：浏览器打开 [wsl-terminal地址](https://github.com/goreliu/wsl-terminal)阅读完Readme下载即可。

## 设置镜像源

ubuntu国外源非常慢，这里建议采用清华大学TUNA的源。

清华大学镜像站网址: [https://mirrors.tuna.tsinghua.edu.cn/](https://mirrors.tuna.tsinghua.edu.cn/)具体怎么设置就不说了，TUNA上有写，记得根据版本进行选择。

之后运行
```shell
sudo apt-get update
sudo apt-get upgrade
```
更新Ubuntu软件源即可

## 安装ZSH&OH-MY-ZSH

ZSH有多强大就不赘述了，用过都说好。

```shell
sudo apt-get install zsh
chsh -s /bin/zsh
```

如此即可将默认shell切换为zsh，**TIPS：之后再运行wsl-termial/tools下的 6-set-default-shell.bat** 方可生效

---

### OH-MY-ZSH 安装

```shell
$ sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

预定义的几个主题就很不错，但是agnoster主题需要powerline加持，一会再说

---

### OH-MY-ZSH 插件安装

```shell
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone https://github.com/zsh-users/zsh-autosuggestions${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

安装高亮和历史补全插件。同时在 `~/.zshrc`中修改

```shell
plugins = (... zsh-autosuggestions zsh-syntax-highlighting)
```

之后运行`source ~/.zshrc`使其生效



---

### 安装powerline主题

agnoster主题所必须。通过pip安装

`pip install powerline-status`

但是，powerline还需要特定主题。由于我们的terminal是运行在win上的，所以我们需要在win上下载安装这些字体

```powershell
git clone https://github.com/powerline/fonts
cd fonts
./install.ps1
cd ..
rm -rf fonts
```

之后在wsl-terminal选项中设置powerline专属字体即可

---

### 安装颜色插件

改造完的WSL依然有点丑

![](https://cdn-images-1.medium.com/max/1200/1*nQF2vf2K9iPpBhuzBWxS1w.png)



由于windows默认文件权限是777，导致背景色是深绿色，很丑。下一步就是把它去掉

```shell
git clone  https://github.com/seebi/dircolors-solarized
```

下载该插件。

vim打开 `~/.zshrc`，加入新行

```shell
eval `dircolors ~/你刚刚下载插件的目录/dircolors.256dark`
```

`source ~/.zshrc`生效

---

### 修改文件权限

TODO:



## 其他常用软件备忘

### 环境管理

1. nvm【管理node】
2. anaconda 【管理python】
3. SDKMAN 【管理Java，kotlin，maven。。。】

### 包管理

1. yarn 【全局模块目录通过`yarn global bin`查询，加入到path中】
2. maven

### 代理

1. proxychains【去GitHub下载最新版】
2. 利用alias更新hosts
    `alias = "alias hosts='sudo wget https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/hosts -O /etc/hosts'"`
3.  