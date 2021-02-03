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

yum -y install unzip wget curl firewalld epel*
systemctl restart firewalld
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=4437/tcp
firewall-cmd --permanent --add-port=22122/tcp
firewall-cmd --permanent --add-port=44377/tcp
firewall-cmd --reload

##########获取最新版本号
latest_version="$(wget --no-check-certificate -qO- https://api.github.com/repos/p4gefau1t/trojan-go/tags | grep 'name' | cut -d\" -f4 | head -1)"
yellow "最新版本号为:${latest_version}"
##########设置下载连接地址
trojango_link="https://github.com/p4gefau1t/trojan-go/releases/download/${latest_version}/trojan-go-linux-amd64.zip"
######################
mkdir /root/trojan-go
wget "${trojango_link}" -O /root/trojan-go/trojan-go.zip
cd /root/trojan-go
unzip trojan-go.zip && rm -rf trojan-go.zip
yellow "trojan-go下载完成!"
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
###############服务端配置文件
cat > /root/trojan-go/server.yaml <<-EOF
run-type: server
local-addr: 0.0.0.0
local-port: 443
remote-addr: 127.0.0.1
remote-port: 80
password:
  - $vpn_password
ssl:
  cert: /root/trojan-go/server.cer
  key: /root/trojan-go/server.key
  fallback_port: 80
mux:
  enabled: true
  concurrency: 10
  idle_timeout: 60
EOF

# cat > /root/trojan-go/client.json <<-EOF
# {
    # "run_type": "client",
    # "local_addr": "127.0.0.1",
    # "local_port": 1080,
    # "remote_addr": "$your_domain",
    # "remote_port": 443,
    # "password": [
        # "$vpn_password"
    # ],
    # "ssl": {
        # "sni": "$your_domain"
    # },
    # "mux": {
        # "enabled": true
    # },
    # "router": {
        # "enabled": true,
        # "bypass": [
            # "geoip:cn",
            # "geoip:private",
            # "geosite:cn",
            # "geosite:geolocation-cn"
        # ],
        # "block": [
            # "geosite:category-ads"
        # ],
        # "proxy": [
            # "geosite:geolocation-!cn"
        # ],
        # "default_policy": "proxy",
        # "geoip": "/root/trojan-go/geoip.dat",
        # "geosite": "/root/trojan-go/geosite.dat"
    # }
# }
# EOF


if [ $real_addr == $local_addr ] ; then
	green "=========================================="
	green "域名解析正常，开启安装nginx并申请https证书"
	green "=========================================="
	sleep 1s
    yum install -y nginx
	rm -rf /usr/share/nginx/html/*
	cd /usr/share/nginx/html/
	wget www.yahoo.co.jp
	systemctl restart nginx.service
	#申请https证书
	curl https://get.acme.sh | sh
	~/.acme.sh/acme.sh  --issue  -d $your_domain  --webroot /usr/share/nginx/html/
    	~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /root/trojan-go/server.key \
        --fullchain-file /root/trojan-go/server.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
	#systemctl stop nginx.service
	yellow "nohup /root/trojan-go/trojan-go -config /root/trojan-go/server.yaml >trojan-go.log 2<&1 &"
else
	red "================================"
	red "域名解析地址与本VPS IP地址不一致"
	red "本次安装失败，请确保域名解析正常"
	red "================================"
fi

