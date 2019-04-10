#!/usr/bin/sh
ssh  Ali "source ~/.zshrc;cd ~/blog/source;git pull origin hexo;hexo g;hexo d"