#!/usr/bin/env bash

smartctl -a /dev/nvme0 | grep -Ei '^temperature' | awk '{print "lexar\t温度：" $2}'
smartctl -a /dev/nvme0 | awk '/Data Units Read/{print "lexar\t读取：" $4 " " $5 " " $6}'
smartctl -a /dev/nvme0 | awk '/Data Units Written/{print "lexar\t写入：" $4 " " $5 " " $6}'

smartctl -a /dev/nvme1 | grep -Ei '^temperature' | awk '{print "asgard\t温度：" $2}'
smartctl -a /dev/nvme1 | awk '/Data Units Read/{print "asgard\t读取：" $4 " " $5 " " $6}'
smartctl -a /dev/nvme1 | awk '/Data Units Written/{print "asgard\t写入：" $4 " " $5 " " $6}'
