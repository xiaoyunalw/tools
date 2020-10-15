#!/bin/bash
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
bred(){
    echo -e "\033[31m\033[01m\033[05m$1\033[0m"
}
byellow(){
    echo -e "\033[33m\033[01m\033[05m$1\033[0m"
}

yum -y install unzip wget curl
systemctl stop firewalld
systemctl disable firewalld

green "======================="
yellow "请输入绑定到本VPS的域名"
green "======================="
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
green "======================="
yellow "请输入trojan的连接密码"
green "======================="
read vpn_password
cat > /root/server.json <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "www.yahoo.co.jp",
    "remote_port": 80,
    "password": [
        "$vpn_password"
    ],
    "ssl": {
        "cert": "/root/server.crt",
        "key": "/root/server.key"
    }
}
EOF
cat > /root/text.txt << EOF
y
$your_domain
123@123.com
y
EOF
if [ $real_addr == $local_addr ] ; then
green "=========================================="
green "域名解析正常，开启安装trojan-go并申请https证书"
green "=========================================="
wget -P /root https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.2/trojan-go-linux-amd64.zip
cd /root/
unzip trojan-go-linux-amd64.zip
./trojan-go -autocert request  < /root/text.txt
#sudo ./trojan-go -autocert renew
###############################################
fi
nohup ./trojan-go -config server.json >trojan-go.log 2<&1 &
