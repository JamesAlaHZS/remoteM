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
            rm /tmp/crontab.tmp
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

# 切换到root用户执行安装
switch_to_root() {
    echo "正在切换到root用户执行安装..."
    sudo -i <<ROOT_INSTALL
        export INSTALL_URL="https://raw.githubusercontent.com/JamesAlaHZS/remoteM/main/argosb.sh"
        echo "已在root环境中"
        export nix=y uuid=${uuid} vmpt=${port_vm_ws} agn=${ARGO_DOMAIN} agk=${ARGO_AUTH}
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

# VPS模式安装流程
vps_installation() {
    # 依赖安装
    echo "正在安装依赖..."
    if command -v apt &> /dev/null; then
        apt update -y &> /dev/null
        apt install curl w极tar gzip cron jq procps coreutils util-linux -y &> /dev/null
    elif command -v yum &> /dev/null; then
        yum install -y curl wget jq tar procps-ng coreutils util-linux &> /dev/null
    elif command -v apk &> /dev/null; then
        apk update -y &> /dev/null
        apk add wget curl tar jq tzdata openssl git grep procps coreutils util-linux dcron &> /dev/null
    fi
    
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

    # 配置端口和UUID
    if [ -z $port_vm_ws ]; then
        port_vm_ws=$(shuf -i 10000-65535 -n 1)
    fi
    
    if [ -z $UUID ]; then
        UUID=$(/etc/s-box-ag/sing-box generate uuid)
    fi
    
    echo
    echo "VMESS端口: $port_vm_ws"
    echo "UUID: $UUID"
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
            "listen_port": ${port_vm_ws},
            "users": [
                {
                    "uuid": "${UUID}",
                    "alterId": 0
                }
            ],
            "transport": {
                "type": "ws",
                "path": "${UUID}-vm",
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
    nohup setsid /etc/s-box-ag/sing-box run -c /etc/s-box-ag/sb.json >/dev/null 2>&1
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
    
    # 启动Argo隧道
    if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
        argo_type='固定'
        nohup setsid /etc/s-box-ag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH} >/dev/null 2>&1 &
        echo $! > /etc/s-box-ag/sbargopid.log
        echo ${ARGO_DOMAIN} > /etc/s-box-ag/sbargoym.log
        echo ${ARGO_AUTH} > /etc/s-box-ag/sbargotoken.log
    else
        argo_type='临时'
        nohup setsid /etc/s-box-ag/cloudflared tunnel --url "http://localhost:${port_vm_ws}" --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box-ag/argo.log 2>&1 &
        echo $! > /etc/s-box-ag/sbargopid.log
    fi
    
    # 等待隧道准备就绪
    echo "正在创建Argo${argo_type}隧道，请稍候..."
    sleep 10
    
    # 获取隧道域名
    if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
        argo_domain=$(cat /etc/s-box-ag/sbargoym.log 2>/dev/null)
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
    if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
        cron_entry='@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/cloudflared tunnel run --token ${ARGO_AUTH} >/dev/null 2>&1 & echo \$! > /etc/s-box-ag/sbargopid.log"'
    else
        cron_entry='@reboot /bin/bash -c "nohup setsid /etc/s-box-ag/cloudflared tunnel --url http://localhost:${port_vm_ws} > /etc/s-box-ag/argo.log 2>&1 & echo \$! > /etc/s-box-ag/sbargopid.log"'
    fi
    (crontab -l | grep -v "sbargopid"; echo "$cron_entry") | crontab -
    
    # 创建节点信息文件
    hostname=$(hostname)
    cat > /etc/s-box-ag/list.txt <<INFO_EOF
---------------------------------------------------------
ArgoSB 脚本安装完成 (VPS模式)
---------------------------------------------------------

VMESS主协议端口: $port_vm_ws
UUID密码: $UUID
Argo隧道域名: $argo_domain

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

# 容器模式安装流程
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
    
    # 配置端口和UUID
    if [ -z $port_vm_ws ]; then
        port_vm_ws=$(shuf -i 10000-65535 -n 1)
    fi
    
    if [ -z $UUID ]; then
        UUID=$(./nixag/sing-box generate uuid)
    fi
    
    echo
    echo "VMESS端口: $port_vm_ws"
    echo "UUID: $UUID"
    echo
    
    # 创建配置文件
    hostname=$(uname -a | awk '{print $2}')
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
            "listen_port": ${port_vm_ws},
            "users": [
                {
                    "uuid": "${UUID}",
                    "alterId": 0
                }
            ],
            "transport": {
                "type": "ws",
                "path": "${UUID}-vm",
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
    nohup ./nixag/sing-box run -c nixag/sb.json >/dev/null 2>&1
    echo $! > nixag/sbpid.log
    
    # 下载cloudflared
    argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
    echo "正在下载cloudflared v$argocore..."
    curl -L -o n极ag/cloudflared -# --retry 2 "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')"
    chmod +x nixag/cloudflared
    
    # 启动Argo隧道
    if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
        argo_type='固定'
        nohup ./nixag/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH} >/dev/null 2>&1 &
        echo $! > nixag/sbargopid.log
        echo ${ARGO_DOMAIN} > nixag/sbargoym.log
        echo ${ARGO_AUTH} > nixag/sbargotoken.log
    else
        argo_type='临时'
        nohup ./nixag/cloudflared tunnel --url "http://localhost:${port_vm_ws}" --edge-ip-version auto --no-autoupdate --protocol http2 > nixag/argo.log 2>&1 &
        echo $! > nixag/sbargopid.log
    fi
    
    # 等待隧道准备就绪
    echo "正在创建Argo${argo_type}隧道，请稍候..."
    sleep 10
    
    # 获取隧道域名
    if [[ -n "${ARGO_DOMAIN}" && -n "${ARGO_AUTH}" ]]; then
        argo_domain=$(cat nixag/sbargoym.log 2>/dev/null)
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
    
    # 设置重启自动加载
    if [[ "$hostname" == *firebase* || "$hostname" == *idx* ]]; then
        if ! grep -q "export nix=y uuid=" ~/.bashrc; then
            echo "export nix=y uuid=${uuid} vmpt=${port_vm_ws} agn=${ARGO_DOMAIN} agk=${ARGO_AUTH} && bash <(curl -Ls $INSTALL_URL)" >> ~/.bashrc
        fi
    fi
    
    # 创建信息文件
    cat > nixag/list.txt <<INFO_EOF
---------------------------------------------------------
ArgoSB 容器模式安装完成
---------------------------------------------------------

VMESS端口: $port_vm_ws
UUID: $UUID
Argo隧道: $argo_domain

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

# 步骤2: 处理非root用户
if [ "$(id -u)" -ne 0 ]; then
    non_root_processing
fi

# 步骤3: 显示脚本标题
print_banner

# 步骤4: 导出环境变量
export UUID=${uuid:-''}
export port_vm_ws=${vmpt:-''}
export ARGO_DOMAIN=${agn:-''}   
export ARGO_AUTH=${agk:-''} 

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
