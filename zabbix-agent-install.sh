#!/bin/bash

#  Copyright (C) 2021 Dmitriy Shweew
#  https://it-advisor.ru <shweew@it-advisor.ru>  

CONF=/etc/zabbix/zabbix_agentd.conf
KEY=/etc/zabbix/zabbix_agentd.psk

if [ -n "$1" ]
then

#Installing Package
rpm -ihv https://repo.zabbix.com/zabbix/5.2/rhel/7/x86_64/zabbix-agent-5.2.5-1.el7.x86_64.rpm

#Generate a key
openssl rand -hex 32 > $KEY
chown zabbix:zabbix $KEY
chmod 400 $KEY

#Set up a configuration file
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
echo "TLSPSKFile=/etc/zabbix/zabbix_agent.psk" >> $CONF
echo >> $CONF

#Create a firewall rule and enable zabbix-agent startup
firewall-cmd --permanent --new-service=zabbix
firewall-cmd --permanent --service=zabbix --add-port=10050/tcp
firewall-cmd --permanent --service=zabbix --set-short="Zabbix Agent"
firewall-cmd --permanent --add-service=zabbix
firewall-cmd --reload
systemctl enable zabbix-agent
systemctl restart zabbix-agent

echo ######################################################
echo -e "\033[7mHostname=$(hostname)\033[0m"
echo -e "\033[7mTLSPSKIdentity=PSK-$(hostname -s)\033[0m"
echo -e "\033[7mPSK=$(cat $KEY)\033[0m"
echo ######################################################
else
echo -en "\033[37;1;41mRun script with option: "./zabbix-agent-install.sh zabbix-server.example.com"\033[0m"
echo
fi
