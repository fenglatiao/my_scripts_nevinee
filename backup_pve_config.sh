#!/usr/bin/env bash

dir_shell=$(cd $(dirname $0); pwd)

## 导入配置
. $dir_shell/my_config.sh

## 备份数量限制
backup_num=60
backup_date=$(date "+%Y-%m-%d")

## 压缩旧的文件夹
cd $dir_backup_pve
for element in $(ls -r); do
    if [[ -d $element ]] && [[ $element != $backup_date ]]; then
        tar -zcf $element.tar.gz $element
        rm -rf $element
    fi
done

## 删除超过备份数量的旧文件
count=$(ls | wc -l)
if [[ $count -gt $backup_num ]]; then
    rm -rf $(ls | head -n $(($count - $backup_num)))
fi

## 新建文件夹并备份
[ ! -d $backup_date ] && mkdir $backup_date
rsync -e "ssh -p $ssh_pve_port -i $ssh_pve_identity" -lprtv --exclude=".*" --delete $ssh_pve_user@$ssh_pve_host:/etc/ $dir_backup_pve/$backup_date
