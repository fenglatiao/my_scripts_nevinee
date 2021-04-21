#/usr/bin/env bash

## 文件夹
dir_shell=$(cd $(dirname $0); pwd)
dir_root=$(cd $dir_shell; cd ..; pwd)
dir_lede="$dir_root/lede"
dir_mine="$dir_root/mine"
dir_feed="$dir_root/feed"
dir_openwrt="$dir_root/openwrt"
dir_config_backup="$dir_root/backup"
dir_lede_files="$dir_lede/files"

## 导入配置
. $dir_shell/my_config.sh

## 文件
name_img=openwrt-x86-64-generic-squashfs-combined.img
file_img_gz=$dir_lede/bin/targets/x86/64/$name_img.gz

## rsync要同步/etc/下的文件清单
file_rsync_config=$dir_shell/compile_openwrt.list

## 要更新的repo网址、保存文件夹名
repo_feed_url=(
    https://github.com/kenzok8/openwrt-packages
    https://github.com/vernesong/OpenClash
    https://github.com/fw876/helloworld
)
repo_feed_dir=(
    kenzok8
    openclash
    helloworld
)

## 从上述三个文件夹分别要什么
list_kenzok8="AdGuardHome"
list_openclash="luci-app-openclash"
list_helloworld="luci-app-ssr-plus"

## mine repo
repo_mine_url=(
    https://github.com/rufengsuixing/luci-app-adguardhome
    https://github.com/sirpdboy/luci-app-advanced
    https://github.com/jerrykuku/luci-app-argon-config
    https://github.com/stamilo/luci-app-fullconenat
    https://github.com/kuoruan/luci-app-kcptun
    https://github.com/jefferymvp/luci-app-koolproxyR
    https://github.com/tty228/luci-app-serverchan
    https://github.com/pymumu/luci-app-smartdns
    https://github.com/jerrykuku/luci-theme-argon
)

## 备份并删除旧的
backup_config () {
    current_time=$(date "+%Y-%m-%d_%H-%M-%S")
    
    cd $dir_config_backup/config
    cp -fpv $dir_lede/.config $dir_config_backup/config/${current_time}.config
    count1=$(ls | wc -l)
    if [[ $count1 -gt 20 ]]; then
        rm -rf $(ls | head -n $(($count1 - 20)))
    fi
    
    cd $dir_config_backup
    cp -fpvr $dir_lede_files $dir_config_backup/files_${current_time}
    count2=$(ls -d files_* | wc -l)
    if [[ $count2 -gt 20 ]]; then
        rm -rf $(ls -d files_* | head -n $(($count2 - 20)))
    fi
}

## 同步openwrt的config
rsync_openwrt () {
    rsync -e "ssh -p $ssh_op_port -i $ssh_op_identity" -lprtv --include-from=$file_rsync_config --delete $ssh_op_user@$ssh_op_host:/etc/ $dir_lede_files/etc/
}

## git pull
git_fetch_and_pull () {
    git fetch
    git reset --hard
    git pull
}

## 更新feed并复制到mine下
update_feed_and_copy () {
    for ((i=0; i<${#repo_feed_url[*]}; i++)); do
        echo -e "\n-----------------------------------------------------\n\n开始更新：$dir_feed/${repo_feed_dir[i]}\n原始链接：${repo_feed_url[i]}"
        cd $dir_feed/${repo_feed_dir[i]}
        git_fetch_and_pull
        
        local tmp=list_${repo_feed_dir[i]}
        for dir in ${!tmp}; do
            rm -rf $dir_mine/$dir
            echo -e "\n复制 $dir_feed/${repo_feed_dir[i]}/$dir 到 $dir_mine 下..."
            cp -rplfu $dir_feed/${repo_feed_dir[i]}/$dir $dir_mine
        done
    done
}

## 更新其他mine
update_mine () {
    for ((i=0; i<${#repo_mine_url[*]}; i++)); do
        local dir=$(echo ${repo_mine_url[i]} | awk -F "/" '{print $NF}')
        echo -e "\n-----------------------------------------------------\n\n开始更新：$dir_mine/$dir\n原始链接：${repo_mine_url[i]}"
        cd $dir_mine/$dir
        git_fetch_and_pull
    done
}

## 更新lede
update_lede () {
    cd $dir_lede
    echo -e "\n-----------------------------------------------------\n\n开始更新$dir_lede"
    git_fetch_and_pull
    echo "rm -rf ./tmp"
    rm -rf ./tmp
    ./scripts/feeds update -a
    echo -e "删除旧版luci-theme-argon"
    rm -rf $dir_lede/package/lean/luci-theme-argon
    echo -e "复制新版luci-theme-argon"
    cp -rf $dir_mine/luci-theme-argon $dir_lede/package/lean/
    ./scripts/feeds update -i
    ./scripts/feeds install -a
}

## 编译
make_openwrt () {
    cd $dir_lede
    read -t 60 -p "请输入编译用的核心数：" choice2
    if [[ $choice2 -ge 1 && $choice2 -le 4 ]]; then
        make_time=$(date "+%Y-%m-%d_%H-%M-%S")
        start_time=$(date "+%Y-%m-%d %H:%M:%S")
        make -j$choice2 V=s 2>&1 | ts "[%Y-%m-%d %H:%M:%.S]" | tee log/${make_time}_make.log
    fi
}

## 准备编译
update_next () {
    cd $dir_lede
    [ ! -d log ] && mkdir log
    echo -e "\n-----------------------------------------------------\n"
    echo -e "还原config..."
    cp -fpv $dir_config_backup/config/${current_time}.config $dir_lede/.config
    echo -e "修改gcc版本为9.3.0..."
    perl -i -pe "s|default \"8\.4\.0\"|default \"9\.3\.0\"|" $dir_lede/toolchain/gcc/Config.version
    #echo -e "删除旧版luci-theme-argon"
    #rm -rf $dir_lede/package/lean/luci-theme-argon >/dev/null
    make defconfig
    
    read -t 60 -p "请确认是否运行 make menuconfig ？(y/n) " choice3
    [[ $choice3 == y ]] && make menuconfig
    
    read -t 60 -p "请确认是否立即运行 make download ？(y/n) " choice4
    download_time=$(date "+%Y-%m-%d_%H-%M-%S")
    [[ $choice4 == y ]] && make -j4 V=s download | ts "[%Y-%m-%d %H:%M:%.S]" | tee log/${download_time}_download.log
    
    read -t 60 -p "请确认是否立即开始编译？(y/n) " choice5
    [[ $choice5 == y ]] && make_openwrt
}

## 编译全过程
make_all_steps () {
    read -t 60 -p "请确认是否立即开始编译？(y/n) " choice1
    if [[ $choice1 == y ]]; then
        make_openwrt
    elif [[ $choice1 == n ]]; then
        backup_config
        rsync_openwrt
        update_feed_and_copy
        update_mine
        update_lede
        update_next
    fi
    make_status=$?
}

## 传输到pve，并发送通知
trans_and_notify () {
    rsync -e "ssh -p $ssh_pve_port -i $ssh_pve_identity" -lprtv $file_img_gz $ssh_pve_user@$ssh_pve_host:/root/img/
    read -t 60 -p "请确认是否解压$name_img ？(y/n) " choice6
    if [[ $choice6 != n ]]; then
        ssh pve "cd ~/img; if [ -f $name_img ]; then rm -f $name_img; fi; gzip -dk $name_img.gz"
        title="已成功编译OPENWRT固件"
        end_time=$(date '+%Y-%m-%d %H:%M:%S')
        desp="已成功编译OPENWRT固件\n\n\开始时间：$start_time\n\n结束时间：$end_time"
        wget -q --output-document=/dev/null --post-data="text=$title&desp=$(echo -e $desp)" $iyuu_url$iyuu_token.send
    fi

}

main () {
    make_all_steps
    [[ $make_status -eq 0 ]] && trans_and_notify
}

main "$@"