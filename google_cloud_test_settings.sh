#!/bin/bash
#
#script for setup test server Ubuntu_16 on Google Cloud_version01
#
SCRIPTLOG="/tmp/startscriptlog"
#
timedatectl set-timezone Europe/Moscow
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, timezone don't set Europe/Moscow" >> ${SCRIPTLOG} && echo "look /tmp/startscriptlog" && exit 0; fi
apt-get update
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, system don't update" >> ${SCRIPTLOG} && echo "look /tmp/startscriptlog" && exit 0; fi
apt-get install git less nano nmap -y
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, applications don't install" >> ${SCRIPTLOG} && echo "look /tmp/startscriptlog" && exit 0; fi
sed -i -e 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' -e 's/PermitRootLogin no/PermitRootLogin yes/g'  -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
egrep 'PermitRootLogin yes' /etc/ssh/sshd_config && grep 'PasswordAuthentication yes' /etc/ssh/sshd_config
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, settings in /etc/ssh/sshd_config don't change" >> ${SCRIPTLOG} && echo "look /tmp/startscriptlog" && exit 0; fi
systemctl restart ssh
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, ssh.service don't restart" >> ${SCRIPTLOG} && echo "look /tmp/startscriptlog" && exit 0; fi
sed -i '/root/s/\:\*/\:$1$jYePn7UP$1Q6SYWeihp9IWcB3taOeq\//g' /etc/shadow
grep root /etc/shadow |grep ':$1$jYePn7UP$1Q6SYWeihp9IWcB3taOeq/:'
if [ $? -ne 0 ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR, root passwd don't change in /etc/shadow" >> ${SCRIPTLOG} && echo "look /tmp/startscriptlog" && exit 0; fi
echo "Well done!"
