#!/usr/bin/sh
ssh root@120.78.172.241 "cd ~/blog/source;git pull origin hexo;hexo g;hexo d"