#!/usr/bin/env bash

## 脚本作用：清空docker容器的控制台日志

docker ps -a | awk '{if (NR>1){print $1}}' | xargs docker inspect --format='{{.LogPath}}' | xargs truncate -s 0