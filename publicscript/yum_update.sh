#!/bin/bash

# @sacloud-once
# @sacloud-desc yum update�����s���܂��B�����㎩���ċN�����܂��B
# @sacloud-desc �i���̃X�N���v�g�́ACentOS6.X, 7.X�ł̂ݓ��삵�܂��j
# @sacloud-require-archive distro-centos distro-ver-6.*
# @sacloud-require-archive distro-centos distro-ver-7.*
# @sacloud-checkbox default= noreboot "yum update������ɍċN�����Ȃ�"

yum -y update || exit 1
WILL_NOT_REBOOT=@@@noreboot@@@

if [ -z ${WILL_NOT_REBOOT} ]; then
    WILL_NOT_REBOOT="0"
fi

if [ ${WILL_NOT_REBOOT} != "1" ];then
  echo "rebooting..."
  sh -c 'sleep 10; reboot' &
fi
exit 0