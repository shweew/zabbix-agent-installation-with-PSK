#!/bin/bash

#  Copyright (C) 2021 Dmitriy Shweew
#  https://it-advisor.ru <shweew@it-advisor.ru>  

CONF=/etc/zabbix/zabbix_agentd.conf
KEY=/etc/zabbix/zabbix_agentd.psk
FILE=/etc/lsb-release

if [ -n "$1" ]; then

# Check Ubuntu or CentOS, install package and configure firewall
if [ -f "$FILE" ]; then
  wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+bionic_all.deb
  dpkg -i zabbix-release_5.0-1+bionic_all.deb
  sudo apt install zabbix-agent
  sudo iptables -A INPUT -p tcp --dport 10050 -j ACCEPT
  sudo netfilter-persistent save
  sudo netfilter-persistent reload
else 
  rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
  yum install zabbix-agent -y
  firewall-cmd --permanent --new-service=zabbix
  firewall-cmd --permanent --service=zabbix --add-port=10050/tcp
  firewall-cmd --permanent --service=zabbix --set-short="Zabbix Agent"
  firewall-cmd --permanent --add-service=zabbix
  firewall-cmd --reload
fi

# Generate key
openssl rand -hex 32 > $KEY
chown zabbix:zabbix $KEY
chmod 400 $KEY

# Create configuration file
cp $CONF $CONF.old
echo "PidFile=/var/run/zabbix/zabbix_agentd.pid" > $CONF
echo "LogFile=/var/log/zabbix/zabbix_agentd.log" >> $CONF
echo "LogFileSize=0" >> $CONF
echo "Server=$1" >> $CONF
echo "ServerActive=$1" >> $CONF
echo "Hostname=$(hostname)" >> $CONF
echo "Include=/etc/zabbix/zabbix_agentd.d/*.conf" >> $CONF
echo "TLSConnect=psk" >> $CONF
echo "TLSAccept=psk" >> $CONF
echo "TLSPSKIdentity=PSK-$(hostname -s)" >> $CONF
echo "TLSPSKFile=$KEY" >> $CONF
echo >> $CONF

# Enable zabbix-agent startup
sudo systemctl enable zabbix-agent
sudo systemctl restart zabbix-agent

echo ######################################################
echo -e "\033[7mHostname=$(hostname)\033[0m"
echo -e "\033[7mTLSPSKIdentity=PSK-$(hostname -s)\033[0m"
echo -e "\033[7mPSK=$(cat $KEY)\033[0m"
echo ######################################################
else
echo -en "\033[37;1;41mRun script with option: "./zabbix-agent-install.sh zabbix-server.example.com"\033[0m"
echo
fi
exit 0
