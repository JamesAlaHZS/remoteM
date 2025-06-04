#!/bin/bash
export LANG=en_US.UTF-8
export nix=${nix:-''}
[ -z "$nix" ] && sys='主流VPS-' || sys='容器NIX-'

# 脚本配置
export SCRIPT_URL="https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh"
export INSTALL_URL="https://raw.githubusercontent.com/JamesAlaHZS/remoteM/main/argosb.sh"

# ----------------- 核心功能函数 -----------------

# 处理卸载和升级命令
handle_commands() {
    if [[ "$1" == "del" ]]; then
        echo "正在卸载ArgoSB脚本..."
        if [ -n "$nix" ]; then
            # 容器NIX卸载
            pkill -f "sing-box" 2>/dev/null
            pkill -f "cloudflared" 2>/dev/null
            sed -i '/yonggekkk/d' ~/.bashrc 
            sed -i '/export first_deploy=y/d' ~/.bashrc
            rm -rf nixag
            echo "容器模式卸载完成" 
        else
            # VPS模式卸载
            pkill -f "sing-box" 2>/dev/null
            pkill -f "cloudflared" 2>/dev/null
            crontab -l > /tmp/crontab.tmp
            sed -i '/sbargopid/d' /tmp/crontab.tmp
            sed -i '/sbpid/d' /tmp/crontab.tmp
            crontab /tmp/crontab.tmp
            rm /极tmp/crontab.tmp
            rm -rf /etc/s-box-ag /usr/bin/agsb
            sed -i '/export first_deploy=y/d' ~/.bashrc
            echo "VPS模式卸载完成"
        fi
        exit
    fi
    
    if [[ "$1" == "up" ]]; then
        echo "正在升级脚本..."
        if [ -n "$nix" ]; then
            echo "容器NIX模式不支持脚本升级"
        else
            # 下载最新版本
            curl -L -o /usr/bin/agsb -# --retry 2 --insecure $SCRIPT_URL
            chmod +x /usr/bin/agsb
            echo "脚本升级完成"
        fi
        exit
    fi
}

# 检查是否首次部署
check_first_deployment() {
    ! grep -q "export first_deploy=y" ~/.bashrc
}

# 切换到root用户执行安装 - 修复: 传递正确的变量名
switch_to_root() {
    echo "正在切换到root用户执行安装..."
    sudo -i <<ROOT_INSTALL
        export INSTALL_URL="https://raw.githubusercontent.com/JamesAlaHZS/remoteM/main/argosb.sh"
        echo "已在root环境中"
        export nix=y uuid=${uuid} vmpt=${vmpt} agn=${agn} agk=${agk} 
        bash <(curl -Ls $INSTALL_URL)
ROOT_INSTALL

    # 标记已完成首次部署
    echo "export first_deploy=y" >> ~/.bashrc
    echo "首次部署完成"
    exit
}

# 非root用户处理流程
non_root_processing() {
    if [ -n "$nix" ]; then
        if check_first_deployment; then
            echo "准备执行首次部署..."
            switch_to_root
        else
            echo "已部署过，切换到root用户环境..."
            exec sudo -i
        fi
    fi
}

# 打印脚本标题
print_banner() {
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
    echo "甬哥Github项目  ：github.com/yonggekkk"
    echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
    echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
    echo "${sys}ArgoSB真一键无交互脚本"
    echo "当前版本：25.5.10 测试beta7版"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}

# 检测操作系统类型
detect_os_type() {
    if [[ -f /etc/redhat-release ]]; then
        echo "Centos"
    elif grep -q -E -i "alpine" /etc/issue; then
        echo "alpine"
    elif grep -q -E -i "debian" /etc/issue; then
        echo "Debian"
    elif grep -q -E -i "ubuntu" /etc/issue; then
        echo "Ubuntu"
    elif grep -q -E -i "centos|red hat|redhat" /etc/issue; then
        echo "Centos"
    elif grep -q -E -i "debian" /proc/version; then
        echo "Debian"
    elif grep -q -E -i "ubuntu" /proc/version; then
        echo "Ubuntu"
    elif grep -q -E -i "centos|red hat|redhat" /proc/version; then
        echo "Centos"
    else 
        echo "unsupported"
    fi
}

# 修复隧道连接问题
fix_connection() {
    echo "应用网络优化设置..."
    
    # 解决某些系统DNS问题
    if [ ! -f /etc/resolv.conf.backup ]; then
        cp /etc/resolv.conf /etc/resolv.conf.backup
    fi
    echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
    
    # 临时禁用防火墙
    if command -v ufw &> /dev/null; then
        ufw disable
    fi
    
    if command -v iptables &> /dev/null; then
        iptables -F
    fi
    
    if command -v firewall-cmd &> /dev/null; then
        systemctl stop firewalld
    fi
}

# VPS模式安装流程 - 修复: 使用正确的变量名
vps_installation() {
    # 依赖安装
    echo "正在安装依赖..."
    if command -v apt &> /dev/null; then
        apt update -y &> /dev/null
        apt install curl wget tar gzip cron jq procps coreutils util-linux -y &> /dev/null
    elif command -v yum &> /dev/null; then
        yum install -y curl wget jq tar procps-ng coreutils util-linux &> /dev/null
    elif command -v apk &> /dev/null; then
        apk update -y &> /dev/null
        apk add wget curl tar jq tzdata openssl git grep procps coreutils util-linux dcron &> /dev/null
    fi
    
    # 应用网络优化
    fix_connection
    
    # 创建安装目录
    mkdir -p /etc/s-box-ag
    
    # 下载sing-box
    sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
    sbname="sing-box-$sbcore-linux-$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')"
    echo "正在下载sing-box v$sbcore..."
    curl -L -o /etc/s-box-ag/sing-box.tar.gz -# --retry 2 "https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz"
    
    if [[ -f '/etc/s-box-ag/sing-box.tar.gz' ]]; then
        tar xzf /etc/s-box-ag/sing-box.tar.gz -C /etc/s-box-ag
        mv /etc/s-box-ag/$sbname/sing-box /etc/s-box-ag
        rm -rf /etc/s-box-ag/{sing-box.tar.gz,$sbname}
    else
        echo "下载失败，请检查网络连接" 
        exit
    fi

    # 配置端口和UUID - 修复: 使用一致的变量名
    if [ -z $vmpt ]; then
        vmpt=$(shuf -i 10000-65535 -n 1)
    fi
    
    if [ -z $uuid ]; then
        uuid=$(/etc/s-box-ag/sing-box generate uuid)
    fi
    
    hostname=$(hostname)
    echo
    echo "VMESS端口: $vmpt"
    echo "UUID: $uuid"
    echo

    # 创建配置文件
    cat > /etc/s-box-ag/sb.json <<CONFIG_EOF
{
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "vmess",
            "tag": "vmess-sb",
            "listen": "::",
            "listen_port": ${vmpt},
            "users": [
                {
                    "uuid": "${uuid}",
                    "alterId": 0
                }
            ],
            "transport": {
                "type": "ws",
                "path": "${uuid}-vm",
                "max_early_data": 2048,
                "early_data_header_name": "Sec-WebSocket-Protocol"    
            },
            "tls": {
                "enabled": false,
                "server_name": "www.bing.com"
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct",
            "tag": "direct"
        }
    ]
}
CONFIG_EOF
    
    # 启动服务
    echo "启动sing-box服务..."
    nohup setsid /etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json >/dev/null 2>&1 &
    echo $! > /etc/s-box-ag/sbpid.log
    
    # 设置定时任务
    echo "设置开机启动..."
    cron_entry='@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json >/dev/null 2>&1 & echo \$! > /etc/s-box-ag/sbpid.log"'
    (crontab -l | grep -v "/etc/s-box-ag/sb.json"; echo "$cron_entry") | crontab -
    
    # 下载cloudflared
    argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
    echo "正在下载cloudflared v$argocore..."
    curl -L -o /etc/s-box-ag/cloudflared -# --retry 2 "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')"
    chmod +x /etc/s-box-ag/cloudflared
    
    # 启动Argo隧道 - 修复: 使用一致的变量名
    if [[ -n "${agn}" && -n "${agk}" ]]; then
        argo_type='固定'
        echo "使用固定隧道: $agn"
        nohup setsid /etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token ${agk} >/dev/null 2>&1 &
        echo $! > /etc/s-box-ag/sbargopid.log
        argo_domain="${agn}"  # 直接使用提供的域名
    else
        argo_type='临时'
        nohup setsid /etc/s-box-ag/cloudflared tunnel --url "http://localhost:${vmpt}" --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 &
        echo $! > /etc/s-box-ag/sbargopid.log
    fi
    
    # 等待隧道准备就绪
    echo "正在创建Argo${argo_type}隧道，请稍候..."
    sleep 15
    
    # 获取隧道域名
    if [[ -n "${agn}" && -n "${agk}" ]]; then
        argo_domain="${agn}"  # 直接使用提供的域名
    else
        argo_domain=$(grep -a trycloudflare.com /etc/s-box-ag/argo.log 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
    fi
    
    if [[ -n "$argo_domain" ]]; then
        echo "隧道创建成功: $argo_domain"
    else
        echo "隧道创建失败，清理中..."
        rm -rf /etc/s-box-ag
        echo "请重试安装"
        exit
    fi
    
    # 创建隧道自启任务
    if [[ -n "${agn}" && -n "${agk}" ]]; then
        cron_entry='@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/cloudflared tunnel run --token ${agk} >/dev/null 2>&1 & echo \$! > /etc/s-box-ag/sbargopid.log"'
    else
        cron_entry='@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/cloudflared tunnel --url http://localhost:${vmpt} > /etc/s-box-ag/argo.log 2>&1 & echo \$! > /etc/s-box-ag/sbargopid.log"'
    fi
    (crontab -l | grep -v "sbargopid"; echo "$cron_entry") | crontab -
    
    # 生成订阅链接 - 修复：添加缺失的订阅生成部分
    vmport=$vmpt
    echo "生成订阅链接..."
    vmatls_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-443\", \"add\": \"104.16.0.0\", \"port\": \"443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argo_domain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
    echo "$vmatls_link1" > /etc/s-box-ag/jh.txt
    
    vmatls_link6="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-2096\", \"add\": \"[2606:4700::]\", \"port\": \"2096\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"t极ls\": \"tls\", \"sni\": \"$argo_domain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
    echo "$vmatls_link6" >> /etc/s-box-ag/jh.txt
    
    vma_link7="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-80\", \"add\": \"104.21.0.0\", \"port\": \"80\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
    echo "$vma_link7" >> /etc/s-box-ag/jh.txt
    
    vma_link13="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-2095\", \"add\": \"[2400:cb00:2049::]\", \"port\": \"2095\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
    echo "$vma_link13" >> /etc/s-box-ag/jh.txt
    
    baseurl=$(base64 -w0 /etc/s-box-ag/jh.txt)
    line1=$(sed -n '1p' /etc/s-box-ag/jh.txt)
    line6=$(sed -n '2p' /etc/s-box-ag/jh.txt)
    line7=$(sed -n '3p' /etc/s-box-ag/jh.txt)
    line13=$(sed -n '4p' /etc/s-box-ag/jh.txt)
    
    # 创建节点信息文件
    echo "创建节点信息..."
    cat > /etc/s-box-ag/list.txt <<INFO_EOF
---------------------------------------------------------
ArgoSB 脚本安装完成 (VPS模式)
---------------------------------------------------------

VMESS主协议端口: $vmport
UUID密码: $uuid
Argo隧道域名: $argo_domain

---------------------------------------------------------
节点配置：
1. 443端口: 
$line1

2. 2096端口(IPv6): 
$line6

3. 80端口: 
$line7

4. 2095端口(IPv6): 
$line13

---------------------------------------------------------
聚合订阅链接(13个端口全覆盖):
$baseurl

---------------------------------------------------------
使用以下命令管理脚本：
显示节点信息: agsb
升级脚本: agsb up
卸载脚本: agsb del
---------------------------------------------------------

INFO_EOF
    
    # 显示安装结果
    cat /etc/s-box-ag/list.txt
    echo "ArgoSB脚本安装完毕"
}

# 容器模式安装流程 - 修复: 使用一致的变量名
container_installation() {
    # 创建容器目录
    mkdir -p nixag
    
    # 下载sing-box
    sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
    sbname="sing-box-$sbcore-linux-$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')"
    echo "正在下载sing-box v$sbcore..."
    curl -L -o nixag/sing-box.tar.gz -# --retry 2 "https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz"
    
    if [[ -f 'nixag/sing-box.tar.gz' ]]; then
        tar xzf nixag/sing-box.tar.gz -C nixag
        mv nixag/$sbname/sing-box nixag
        rm -rf nixag/{sing-box.tar.gz,$sbname}
        chmod +x nixag/sing-box
    else
        echo "下载失败，请检查网络连接"
        exit
    fi
    
    # 配置端口和UUID - 修复: 使用一致的变量名
    if [ -z $vmpt ]; then
        vmpt=$(shuf -i 10000-65535 -n 1)
    fi
    
    if [ -z $uuid ]; then
        uuid=$(./nixag/sing-box generate uuid)
    fi
    
    hostname=$(uname -a | awk '{print $2}')
    echo
    echo "VMESS端口: $vmpt"
    echo "UUID: $uuid"
    echo
    
    # 创建配置文件
    cat > nixag/sb.json <<CONFIG_EOF
{
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true
    },
    "inbounds": [
        {
            "type": "vmess",
            "tag": "vmess-sb",
            "listen": "::",
            "listen_port": ${vmpt},
            "users": [
                {
                    "uuid": "${uuid}",
                    "alterId": 0
                }
            ],
            "transport": {
                "type": "ws",
                "path": "${uuid}-vm",
                "max_early_data": 2048,
                "early_data_header_name": "Sec-WebSocket-Protocol"    
            },
            "tls": {
                "enabled": false,
                "server_name": "www.bing.com"
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct",
            "tag": "direct"
        }
    ]
}
CONFIG_EOF
    
    # 启动服务
    echo "启动sing-box服务..."
    nohup ./nixag/sing-box run -c nixag/sb.json >/dev/null 2>&1 &
    echo $! > nixag/sbpid.log
    
    # 下载cloudflared
    argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
    echo "正在下载cloudflared v$argocore..."
    curl -L -o nixag/cloudflared -# --retry 2 "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')"
    chmod +x nixag/cloudflared
    
    # 启动Argo隧道 - 修复: 使用一致的变量名
    if [[ -n "${agn}" && -n "${agk}" ]]; then
        argo_type='固定'
        echo "使用固定隧道: $agn"
        nohup ./nixag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token ${agk} > nixag/argo-fixed.log 2>&1 &
        echo $! > nixag/sbargopid.log
        argo_domain="${agn}"  # 直接使用提供的域名
    else
        argo_type='临时'
        nohup ./nixag/cloudflared tunnel --url "http://localhost:${vmpt}" --edge-ip-version auto --no-autoupdate --protocol http2 > nixag/argo.log 2>&1 &
        echo $! > nixag/sbargopid.log
    fi
    
    # 等待隧道准备就绪
    echo "正在创建Argo${argo_type}隧道，请稍候..."
    sleep 15
    
    # 获取隧道域名
    if [[ -n "${agn}" && -n "${agk}" ]]; then
        argo_domain="${agn}"  # 直接使用提供的域名
    else
        argo_domain=$(grep -a trycloudflare.com nixag/argo.log 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
    fi
    
    if [[ -n "$argo_domain" ]]; then
        echo "隧道创建成功: $argo_domain"
    else
        echo "隧道创建失败，清理中..."
        rm -rf nixag
        echo "请重试安装"
        exit
    fi
    
    # 设置重启自动加载 - 修复: 使用一致的变量名
    if [[ "$hostname" == *firebase* || "$hostname" == *idx* ]]; then
        if ! grep -q "export nix=y uuid=" ~/.bashrc; then
            echo "export nix=y uuid='${uuid}' vmpt='${vmpt}' agn='${agn}' agk='${agk}' && bash <(curl -Ls $INSTALL_URL)" >> ~/.bashrc
        fi
    fi
    
    # 生成订阅链接 - 修复：添加缺失的订阅生成部分
    echo "生成订阅链接..."
    vmatls_link1="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-443\", \"add\": \"104.16.0.0\", \"port\": \"443\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argo_domain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
    echo "$vmatls_link1" > nixag/jh.txt
    
    vmatls_link6="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-tls-argo-$hostname-2096\", \"add\": \"[2606:4700::]\", \"port\": \"2096\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"tls\": \"tls\", \"sni\": \"$argo_domain\", \"alpn\": \"\", \"fp\": \"\"}" | base64 -w0)"
    echo "$vmatls_link6" >> nixag/jh.txt
    
    vma_link7="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-80\", \"add\": \"104.21.0.0\", \"port\": \"80\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
    echo "$vma_link7" >> nixag/jh.txt
    
    vma_link13="vmess://$(echo "{ \"v\": \"2\", \"ps\": \"vmess-ws-argo-$hostname-2095\", \"add\": \"[2400:cb00:2049::]\", \"port\": \"2095\", \"id\": \"$uuid\", \"aid\": \"0\", \"scy\": \"auto\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$argo_domain\", \"path\": \"/$uuid-vm?ed=2048\", \"tls\": \"\"}" | base64 -w0)"
    echo "$vma_link13" >> nixag/jh.txt
    
    baseurl=$(base64 -w0 nixag/jh.txt)
    line1=$(sed -n '1p' nixag/jh.txt)
    line6=$(sed -n '2p' nixag/jh.txt)
    line7=$(sed -n '3p' nixag/jh.txt)
    line13=$(sed -n '4p' nixag/jh.txt)
    
    # 创建信息文件
    cat > nixag/list.txt <<INFO_EOF
---------------------------------------------------------
ArgoSB 容器模式安装完成
---------------------------------------------------------

VMESS端口: $vmpt
UUID: $uuid
Argo隧道: $argo_domain
隧道类型: ${argo_type}隧道

---------------------------------------------------------
节点配置：
1. 443端口: 
$line1

2. 2096端口(IPv6): 
$line6

3. 80端口: 
$line7

4. 2095端口(IPv6): 
$line13

---------------------------------------------------------
聚合订阅链接(13个端口全覆盖):
$baseurl

重启容器后会自动启动服务
---------------------------------------------------------
INFO_EOF
    
    # 显示安装结果
    cat nixag/list.txt
    echo "安装完成，容器重启后会自动启动服务"
}

# ----------------- 主程序逻辑 -----------------

# 步骤1: 处理命令行参数
handle_commands "$1"

# 步骤2: 导出环境变量 (保持与传入参数一致)
export uuid=${uuid:-''}
export vmpt=${vmpt:-''}
export agn=${agn:-''}   
export agk=${agk:-''} 


# 步骤3: 处理非root用户
if [ "$(id -u)" -ne 0 ]; then
    non_root_processing
fi

# 步骤4: 显示脚本标题
print_banner


# 步骤5: 区分VPS和容器模式
if [ -z "$nix" ]; then 
    # VPS模式
    if [ "$(id -u)" -ne 0 ]; then
        echo "错误: VPS模式必须以root用户运行"
        echo "请在命令前加 sudo 或在命令前添加 nix=y 切换为容器模式"
        exit 1
    fi
    
    # 检测操作系统
    os_type=$(detect_os_type)
    if [ "$os_type" = "unsupported" ]; then
        echo "错误: 不支持的操作系统"
        exit 1
    fi
    
    # 检查是否已安装
    if pgrep "sing-box" >/dev/null && pgrep "cloudflared" >/dev/null && [ -f "/etc/s-box-ag/list.txt" ]; then
        echo "ArgoSB已在运行中"
        cat /etc/s-box-ag/list.txt
        exit
    fi
    
    # 执行VPS模式安装
    vps_installation
else
    # 容器模式
    # 检查是否已安装
    if pgrep "sing-box" >/dev/null && pgrep "cloudflared" >/dev/null && [ -f "nixag/list.txt" ]; then
        echo "ArgoSB已在运行中"
        cat nixag/list.txt
        exit
    fi
    
    # 执行容器模式安装
    container_installation
fi
