---
title: ArchLinux安装攻略的补充
date: 2018-09-14 21:24:59
tags: Linux
---

闲来无事尝试安装了ArchLinux+WIn10的双系统,踩过不少坑,在**官方wiki**和**大神的博客**的帮助下,最终完成了安装.成果图如下.![效果图](/ArchLinux安装攻略的补充/a.jpg)

可以看到我又在那篇博客的基础上做了不少微调.故开贴将这些调整之处记录下来,也算是做一个备忘

<!-- more -->

### 传送门

- 官方wiki: https://wiki.archlinux.org/index.php/Installation_guide
- 以官方wiki的方式安装ArchLinux: https://www.viseator.com/2017/05/17/arch_install/

### TIPS

1. 官方wiki资料非常之全,几乎你需要的所有信息都能在其上找到,不过其缺点就是太大而全了,很容易迷失方向.
2. 善用Google && StackOverflow
3. **不会写太多文字,放上链接大家自己翻阅,比我自己瞎BB高到不知道哪里去了**
4. 只针对UEFI+GPT的电脑,BIOS+MBR可以稍作修改

## 分区篇

### LVM的使用

现在不少同学的硬盘都是SSD+HDD的模式,所以在分区的时候,对于根目录和家目录如何挂载会比较蛋疼.

幸好这里有一个LVM的分区方案,可用于管理磁盘驱动器或其他类似的大容量存储设备.详细信息参见[LVM的wiki](https://wiki.archlinux.org/index.php/LVM).

需要注意的是如果是双系统的话,boot分区不需要挂载在虚拟逻辑分区上,挂载到WIn10已经自带的EFI分区即可.

在分区中个人在配置grub引导的时候碰到了一个问题,`warning failed to connect to lvmetad，falling back to device scanning.`简单的方法是编辑`/etc/lvm/lvm.conf`这个文件，找到`use_lvmetad = 1`将`1`修改为`0`,保存，重新配置grub.

### ntfs-3g的使用

双系统中会无可避免的需要访问windows下的分区(ntfs),这里我们采用[ntfs-3g](https://wiki.archlinux.org/index.php/NTFS-3G)这一工具将指定分区挂载.

example: `sudo ntfs-3g /dev/sda4 /mnt/windows`.

需要注意的是这种方法是一次性的,下次重启的时候需要重新挂载.为了做到永久挂载,我们需要修改/etc/fstab

example: 

```
# <file system>   <dir> <type>    <options>             <dump>  <pass>
/dev/NTFS-part  /mnt/windows  ntfs-3g   defaults          0       0
```

### 传送门

+ LVM: https://wiki.archlinux.org/index.php/LVM
+ NTFS-3G: https://wiki.archlinux.org/index.php/NTFS-3G

## 美化篇

**这部分纯属个人喜好,自己斟酌,且绝大部分都可以通过AUR获取**

### 字体

1. noto fonts 
2. wqy
3. Consolas

### 终端:
1. oh-my-zsh   **zsh的主题工具,吹爆**
2. tilda  **下拉式的terminal**
3. powerline   **不少zsh主题的必备工具**
### 主题:
1. X-Arc-darker   **黑色主题**
2. Arc-White   **白色主题**
3. numix-circle    **圆形图标**

## 软件篇

### 科学上网

1. electron-shadowsocksr    **GUI界面,支持订阅,http代理和SSR特性,比SS高到不知道哪里去了**
2. google-chrome   **浏览器最强**
3. switchy omega(chrome插件)  **科学上网三件套**

### 写代码+办公

1. VScode   **轻量,好看**
2. IDEA    **写Java必备**
3. wps-office    **MS Office最好的替代品**

### 娱乐+即时通讯

1. telegram   <del>为什么linux没有qq呜呜呜呜</del>
2. netease-cloud-music **听歌必备,网易良心**
3. thunderbird  **火狐出品的邮件客户端**
4. screenfetch     **拍出像前言那样酷炫的图片**
