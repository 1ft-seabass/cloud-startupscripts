#!/bin/bash

# @sacloud-once
#
# @sacloud-require-archive pkg-kusanagi
#
# @sacloud-desc-begin
#   KUSANAGI8 ���� WordPress ���Z�b�g�A�b�v����X�N���v�g�ł��B
#   ���̃X�N���v�g���g���� kusanagi ���[�U�� ssh ���O�C���\�ɂȂ�܂��B
#   �T�[�o�쐬��AWeb�u���E�U�ŃT�[�o��IP�A�h���X�ɃA�N�Z�X���Ă��������B
#   https://�T�[�o��IP�A�h���X/
#   �� �Z�b�g�A�b�v�ɂ�5?10�����x���Ԃ�������܂��B
#   �Z�b�g�A�b�v������Ɋ�������ƁA �Ǘ����[�U�[�̃��[���A�h���X���Ɋ������[�������t����܂��i���g���̊��ɂ���Ă̓X�p���t�B���^�ɂ���M����Ȃ��ꍇ������܂��j
#   ���[�����M��A�T�[�o���ċN�������܂��̃��[������M������1���قǑ҂��ăA�N�Z�X���������B
#   �i���̃X�N���v�g�́AKUSANAGI8.x�ł̂ݓ��삵�܂��j
#   
#   �Z�b�g�A�b�v��́Akusanagi��SSL(Let's Encrypt)�ݒ��AWordPress ��URL�ݒ��IP�A�h���X����h���C�����ɕύX����ݒ�̎��{���������߂��܂��B
#   �ڍׂ͏ڍׂ͈ȉ��̃y�[�W���ڍׂ͈ȉ��̃y�[�W��������������
#    http://cloud-news.sakura.ad.jp/wordpress-for-kusanagi8/
# @sacloud-desc-end
#
# �Ǘ����[�U�[�̓��̓t�H�[���̐ݒ�
# @sacloud-password required shellarg maxlen=60 minlen=6 KUSANAGI_PASSWD  "���[�U�[ kusanagi �̃p�X���[�h" ex="6?60����"
# @sacloud-password required shellarg maxlen=60 minlen=6 DBROOT_PASSWD    "MariaDB root ���[�U�[�̃p�X���[�h" ex="6?60����"
# @sacloud-text     required shellarg maxlen=60 WP_ADMIN_USER    "WordPress �Ǘ��҃��[�U�� (���p�p�����A�����A�n�C�t���A�s���I�h�A�A�b�g�}�[�N (@) �݂̂��g�p�\)" ex="1?60����"
# @sacloud-password required shellarg maxlen=60 minlen=6 WP_ADMIN_PASSWD  "WordPress �Ǘ��҃p�X���[�h" ex="6?60����"
# @sacloud-text     required shellarg maxlen=256 WP_TITLE        "WordPress �T�C�g�̃^�C�g�� (256�����ȉ�)"
# @sacloud-text     required  maxlen=128 WP_ADMIN_MAIL   "WordPress �Ǘ��҃��[���A�h���X (�C���X�g�[���������Ƀ��[�������M����܂�)" ex="user@example.com"

echo "## set default variables";
TERM=xterm

IPADDRESS0=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`
WPDB_USERNAME="wp_`mkpasswd -l 10 -C 0 -s 0`"
WPDB_PASSWORD=`mkpasswd -l 32 -d 9 -c 9 -C 9 -s 0 -2`

echo "## yum update";
yum --enablerepo=remi,remi-php56 update -y || exit 1
sleep 10

#---------START OF kusanagi---------#
echo "## Kusanagi init";
kusanagi init --tz Asia/Tokyo --lang ja --keyboard ja \
  --passwd @@@KUSANAGI_PASSWD@@@ --no-phrase \
  --dbrootpass @@@DBROOT_PASSWD@@@ \
  --nginx --hhvm || exit 1

echo "## Kusanagi provision";
kusanagi provision \
  --WordPress  --wplang ja \
  --fqdn $IPADDRESS0 \
  --no-email  \
  --dbname $WPDB_USERNAME --dbuser $WPDB_USERNAME --dbpass $WPDB_PASSWORD \
  default_profile  || exit 1

#---------END OF kusanagi---------#

#---------START OF WordPrss---------#

# �o�b�N�G���h�� sudo �������悤�ɐݒ�ύX
sed 's/^Defaults    requiretty/#Defaults    requiretty/' -i.bk  /etc/sudoers  || exit 1

# ��������WordPress �̐ݒ�t�@�C���쐬
echo "## Kusanagi wordpress config";
sudo -u kusanagi -i /usr/local/bin/wp core config \
  --dbname=$WPDB_USERNAME \
  --dbuser=$WPDB_USERNAME \
  --dbpass=$WPDB_PASSWORD \
  --dbhost=localhost --dbcharset=utf8mb4 --extra-php \
  --path=/home/kusanagi/default_profile/DocumentRoot/ \
  < /usr/lib/kusanagi/resource/wp-config-sample/ja/wp-config-extra.php  || exit 1

echo "## Kusanagi wordpress core install";
sudo -u kusanagi  -i /usr/local/bin/wp core install \
  --url=$IPADDRESS0 \
  --title=@@@WP_TITLE@@@ \
  --admin_user=@@@WP_ADMIN_USER@@@  \
  --admin_password=@@@WP_ADMIN_PASSWD@@@ \
  --admin_email="@@@WP_ADMIN_MAIL@@@" \
  --path=/home/kusanagi/default_profile/DocumentRoot/  || exit 1

# sudo �̕ύX�����ɖ߂�
/bin/cp /etc/sudoers.bk /etc/sudoers  || exit 1

#---------END OF WordPrss---------#

# ���������Ă��邩������Ȃ����߁AWP�Ǘ��҃��[���A�h���X�Ɋ������[���𑗐M

# �K�v�ȏ����W�߂�
SYSTEMINFO=`dmidecode -t system`

# �t�H�[���Őݒ肵���Ǘ��҂̃A�h���X�փ��[���𑗐M
echo "## send email.";
/usr/sbin/sendmail -t -i -o -f @@@WP_ADMIN_MAIL@@@ << EOF From: @@@WP_ADMIN_MAIL@@@
Subject: finished Wordpress install on $IPADDRESS0
To: @@@WP_ADMIN_MAIL@@@

Finish WordPress install on $IPADDRESS0

Please access to https://$IPADDRESS0 after 1 min.

Autogenerate DBname, DBUsername, DBpassword etc...
You can find Wordpress DB Infomation in /home/kusanagi/default_profile/DocumentRoot/wp-config.php

System Info:
$SYSTEMINFO
EOF

echo "## finished!";
echo "please access to https://$IPADDRESS0/";

echo "## reboot after 10 seconds.";
sh -c 'sleep 10; reboot' &
 
exit 0