#!/usr/bin/env bash

dir_shell=$(cd $(dirname $0); pwd)

## 导入配置
. $dir_shell/my_config.sh

## 同步ssl证书并重启服务
rsync -e "ssh -p $ssh_op_port -i $ssh_op_identity" -prtv --delete $dir_certs/ $ssh_op_user@$ssh_op_host:/etc/certs/
ssh $ssh_op_alias "/etc/init.d/uhttpd restart"
