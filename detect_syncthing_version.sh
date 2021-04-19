#!/usr/bin/env bash

dir_shell=$(cd $(dirname $0); pwd)

## 导入配置
. $dir_shell/my_config.sh

## 相关目录
dir_syncthing=$dir_dockerfile/syncthing
dir_workflows=$dir_dockerfile/.github/workflows

## 相关要修改的文件
file_dockerfile=$dir_syncthing/Dockerfile
file_build_yaml=$dir_workflows/syncthing.yml
file_version=$dir_syncthing/version

## 取得最新版本
version_remote=$(curl -s https://github.com/syncthing/syncthing/releases/latest | awk -F "tag/v|\">" '{print $2}')
version_current=$(cat $file_version)
if [[ $version_remote != $version_current ]]; then
    perl -i -pe "s|SYNCTHING_VERSION=$version_current|SYNCTHING_VERSION=$version_remote|" $file_dockerfile
    perl -i -pe "s|tag: latest,v$version_current|tag: latest,v$version_remote|" $file_build_yaml
    title="检测到syncthing有更新"
    desp="检测到syncthing有更新\n\n当前版本：$version_current\n\n远程版本：$version_remote"
    wget -q --output-document=/dev/null --post-data="text=$title&desp=$(echo -e $desp)" $iyuu_url$iyuu_token.send
    if [[ $? -eq 0 ]]; then
        echo $version_remote > $file_version
    fi
    cd $dir_syncthing
    git add .
    git commit -a -m "Auto update syncthing"
    if [[ $? -eq 0 ]]; then
        git push
    fi
else
    echo "syncthing没有更新"
fi

