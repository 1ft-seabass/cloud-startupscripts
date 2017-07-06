#!/bin/bash

# @sacloud-once

# @sacloud-desc-begin
#   Ruby�ARuby on Rails�AMongoDB�œ��삷�钆�E��K�̓T�C�g����CMS�ł���V���T�M���Z�b�g�A�b�v����X�N���v�g�ł��B
#   �I�v�V�����́u�h���C�����v��ݒ肷��ƁA
#   �u���E�U�� "http://example.jp/" �ɃA�N�Z�X����ƃV���T�M���\�������悤�ɃV���T�M���C���X�g�[������܂��B
#   example.jp�̕����́A�����p�̃h���C���ɉ����ēK���ύX���Ă��������B
#   
#   �T�[�o�쐬��AWeb�u���E�U�ŃV���T�M�̊Ǘ���ʂɃA�N�Z�X���Ă��������B
#   http://IP�A�h���X:3000/.mypage
#   ����ID/�p�X���[�h�͉��LURL���Q�Ƃ��Ă��������B
#   http://www.ss-proj.org/download/demo.html
#
#   �� ���̃X�N���v�g�� CentOS 7.X �ł̂ݓ��삵�܂��B
#   �� �������FCPU 2�R�A / ������ 3GB / �f�B�X�N 40GB
#   �� �Z�b�g�A�b�v�ɂ�10�����x���Ԃ�������܂��B
# @sacloud-desc-end
# @sacloud-require-archive distro-centos distro-ver-7.*
# @sacloud-text SSHOST "�h���C����"

#---------SET SS__HOST---------#
# ���[�U���h���C��������͂��Ă���΂�����A
# ���͂��Ă��Ȃ����IP�A�h���X��SS__HOST�ɐݒ肵�܂��B
SS_HOST=@@@SSHOST@@@
IPADDR=$(awk -F= '/^IPADDR=/{print $2}' /etc/sysconfig/network-scripts/ifcfg-eth0)

if [[ ${SS_HOST} != "" ]]
then
  SS__HOST=${SS_HOST}
else
  SS__HOST=${IPADDR}
fi

#---------START OF SHIRASAGI---------#
# �V���T�M�̃C���X�g�[�������s���܂��B
curl https://raw.githubusercontent.com/shirasagi/shirasagi/master/bin/install.sh | bash -s ${SS__HOST}
#---------END OF SHIRASAGI---------#

#---------START OF firewalld---------#
# �V���T�M�̊Ǘ���ʂ�3000�ԃ|�[�g���g�p���邽�߁A
# �T�[�o�ɑ΂���3000�ԃ|�[�g�ŃA�N�Z�X�ł���悤�ɂ��܂��B
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --reload
#---------END OF firewalld---------#

exit 0