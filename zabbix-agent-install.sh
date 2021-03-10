#!/bin/bash

if [ -n "$1" ]
then
rpm -ihv https://repo.zabbix.com/zabbix/5.2/rhel/7/x86_64/zabbix-agent-5.2.5-1.el7.x86_64.rpm
cd /etc/zabbix
openssl rand -hex 32 > zabbix_agent.psk
chown zabbix:zabbix -R zabbix_agent.psk
chmod 400 zabbix_agent.psk
cp zabbix_agentd.conf zabbix_agentd.conf.old
echo "PidFile=/var/run/zabbix/zabbix_agentd.pid" > zabbix_agentd.conf
echo "LogFile=/var/log/zabbix/zabbix_agentd.log" >> zabbix_agentd.conf
echo "LogFileSize=0" >> zabbix_agentd.conf
echo "Server=$1" >> zabbix_agentd.conf
echo "ServerActive=$1" >> zabbix_agentd.conf
echo "Hostname=$(hostname)" >> zabbix_agentd.conf
echo "Include=/etc/zabbix/zabbix_agentd.d/*.conf" >> zabbix_agentd.conf
echo "TLSConnect=psk" >> zabbix_agentd.conf
echo "TLSAccept=psk" >> zabbix_agentd.conf
echo "TLSPSKIdentity=PSK-$(hostname -s)" >> zabbix_agentd.conf
echo "TLSPSKFile=/etc/zabbix/zabbix_agent.psk" >> zabbix_agentd.conf
echo >> zabbix_agentd.conf
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
echo -e "\033[7mPSK=$(cat /etc/zabbix/zabbix_agent.psk)\033[0m"
echo ######################################################
else
echo -en "\033[37;1;41mRun script with option: "./zabbix-agent-install.sh zabix-server.example.com"\033[0m"
echo
fi
