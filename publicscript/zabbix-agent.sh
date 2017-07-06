#!/bin/bash

# @sacloud-once
# @sacloud-desc ���̃X�N���v�g��Zabbix Agent���Z�b�g�A�b�v���܂��B(���̃X�N���v�g�́ACentOS7.X�ł̂ݓ��삵�܂��B)
# @sacloud-desc Zabbix��URL�� http://IP Address/zabbix �ł��B
#
# @sacloud-select-begin required default=3.2 ZV "Zabbix Version"
#  3.2 "3.2"
#  3.0 "3.0"
#  2.4 "2.4"
#  2.2 "2.2"
# @sacloud-select-end
# @sacloud-textarea heredoc ADDR "�o�^����Zabbix�T�[�o��IP�A�h���X(ipv4)��1�s��1���͂��Ă��������B" ex="127.0.0.1"
# @sacloud-require-archive distro-centos distro-ver-7

#---------SET sacloud values---------#
ZABBIX_VERSION=@@@ZV@@@
IPLIST=/tmp/ip.list
cat > ${IPLIST} @@@ADDR@@@

#---------START OF zabbix-agent---------#
rpm -ivh http://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/rhel/7/x86_64/zabbix-release-${ZABBIX_VERSION}-1.el7.noarch.rpm
yum -y install zabbix-agent zabbix-sender

ZBX_SERVERS=127.0.0.1
for IPADDR in $(egrep "([0-9]+\.){3}[0-9]+$" ${IPLIST})
do
  ZBX_SERVERS="${ZBX_SERVERS},${IPADDR}"
  firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${IPADDR}/32' accept"
done

if [ $(egrep -c "([0-9]+\.){3}[0-9]+$" ${IPLIST}) -eq 0 ]
then
  firewall-cmd --permanent --add-port=10050/tcp
else
  sed -i "s/^Server=127.0.0.1$/Server=${ZBX_SERVERS}/" /etc/zabbix/zabbix_agentd.conf
fi

systemctl enable zabbix-agent
systemctl start zabbix-agent

rm -f ${IPLIST}

#---------END OF zabbix-agent---------#
#---------START OF firewalld---------#
firewall-cmd --reload
#---------END OF firewalld---------#

exit 0