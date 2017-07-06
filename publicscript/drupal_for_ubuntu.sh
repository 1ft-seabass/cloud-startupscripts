#!/bin/bash

# @sacloud-once
#
# @sacloud-require-archive distro-ubuntu
#
# @sacloud-desc-begin
#   Drupal���C���X�g�[�����܂��B
#   �T�[�o�쐬��AWeb�u���E�U�ŃT�[�o��IP�A�h���X�ɃA�N�Z�X���Ă��������B
#   http://�T�[�o��IP�A�h���X/
#   �� �Z�b�g�A�b�v�ɂ�5�����x���Ԃ�������܂��B
#   �i���̃X�N���v�g�́AUbuntu 14.04 �܂��� 16.04 �ł̂ݓ��삵�܂��j
#   �Z�b�g�A�b�v������Ɋ�������ƁA �Ǘ����[�U�[�̃��[���A�h���X���Ɋ������[�������t����܂��i���g���̊��ɂ���Ă̓X�p���t�B���^�ɂ���M����Ȃ��ꍇ������܂��j
# @sacloud-desc-end
#
# Drupal �̊Ǘ����[�U�[�̓��̓t�H�[���̐ݒ�
# @sacloud-select-begin required default=7 drupal_version "Drupal �o�[�W����"
#   7 "Drupal 7.x"
#   8 "Drupal 8.x"
# @sacloud-select-end
# @sacloud-text required shellarg maxlen=128 site_name "Drupal �T�C�g��"
# @sacloud-text required shellarg maxlen=60 ex=Admin user_name "Drupal �Ǘ����[�U�[�̖��O"
# @sacloud-password required shellarg maxlen=60 password "Drupal �Ǘ����[�U�[�̃p�X���[�h"
# @sacloud-text required shellarg maxlen=254 ex=your.name@example.com mail "Drupal �Ǘ����[�U�[�̃��[���A�h���X"

# �t�@�C�����Œ�`����Ă��� `DISTRIB_RELEASE` �� Ubuntu �̃o�[�W�������L��
# ����Ă���̂ŁA����𗘗p���ĕ��������
source /etc/lsb-release

DRUPAL_VERSION=@@@drupal_version@@@

# MySQL �T�[�o�[�C���X�g�[���E�B�U�[�h�̐ݒ�l���Z�b�g
mysql_password=root
if [ $DISTRIB_RELEASE = "14.04" ]; then
  mysql_package="mysql-server-5.5"
elif [ $DISTRIB_RELEASE = "16.04" ]; then
  mysql_package="mysql-server-5.7"
fi
echo "$mysql_package mysql-server/root_password password $mysql_password" | debconf-set-selections
echo "$mysql_package mysql-server/root_password_again password $mysql_password" | debconf-set-selections

# Postfix �T�[�o�[�C���X�g�[���E�B�U�[�h�̐ݒ�l���Z�b�g
echo "postfix postfix/mailname string localdomain" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

# �K�v�ȃ~�h���E�F�A��S�ăC���X�g�[��
apt-get update || exit 1
if [ $DISTRIB_RELEASE = "14.04" ]; then
  required_packages="apache2 mysql-server php5 php5-apcu php5-mysql php5-gd mailutils"
elif [ $DISTRIB_RELEASE = "16.04" ]; then
  required_packages="apache2 libapache2-mod-php mysql-server php php-apcu php-mysql php-gd php-xml mailutils"
fi
apt-get -y install $required_packages

# Apache �� rewrite ���W���[����L����
a2enmod rewrite

# Drupal �� .htaccess ���g�p���邽�� /var/www/html �f�B���N�g���ɑ΂��ăI�[�o�[���C�h��S�ċ�����
patch -l /etc/apache2/sites-available/000-default.conf << EOS
13a14,16
>    <Directory /var/www/html>
>        AllowOverride All
>    </Directory>
>
EOS

# PHP �̊e��ݒ�
if [ $DISTRIB_RELEASE = "14.04" ]; then
  patch /etc/php5/apache2/php.ini << EOS
673c673
< post_max_size = 8M
---
> post_max_size = 16M
805c805
< upload_max_filesize = 2M
---
> upload_max_filesize = 16M
879c879
< ;date.timezone =
---
> date.timezone = Asia/Tokyo
EOS
elif [ $DISTRIB_RELEASE = "16.04" ]; then
  patch /etc/php/7.0/apache2/php.ini << EOS
656c656
< post_max_size = 8M
---
> post_max_size = 16M
798c798
< upload_max_filesize = 2M
---
> upload_max_filesize = 16M
912c912
< ;date.timezone =
---
> date.timezone = Asia/Tokyo
EOS
fi

# �t�@�C���A�b�v���[�h���̃v���O���X�o�[��\���ł���悤�ɂ���
if [ $DISTRIB_RELEASE = "14.04" ]; then
  echo "apc.rfc1867=1" >> /etc/php5/apache2/conf.d/20-apcu.ini
elif [ $DISTRIB_RELEASE = "16.04" ]; then
  echo "apc.rfc1867=1" >> /etc/php/7.0/apache2/conf.d/20-apcu.ini
fi

service apache2 restart

# �ŐV�ł� Drush ���_�E�����[�h����
php -r "readfile('http://files.drush.org/drush.phar');" > drush || exit 1

# drush �R�}���h�����s�\�ɂ��� /usr/local/bin �Ɉړ�
chmod +x drush || exit 1
mv drush /usr/local/bin || exit 1
drush=/usr/local/bin/drush

# Drupal ���_�E�����[�h
if [ $DRUPAL_VERSION -eq 7 ]; then
  project=drupal-7
elif [ $DRUPAL_VERSION -eq 8 ]; then
  project=drupal-8
fi
$drush -y dl $project --destination=/var/www --drupal-project-rename=html || exit 1

# �A�b�v���[�h���ꂽ�t�@�C����ۑ����邽�߂̃f�B���N�g����p��
mkdir /var/www/html/sites/default/files /var/www/html/sites/default/private || exit 1

# Drupal �T�C�g�̃��[�g�f�B���N�g���Ɉړ����� drush �R�}���h�ɔ�����
cd /var/www/html

# Drupal ���C���X�g�[��
$drush -y si\
  --db-url=mysql://root:root@localhost/drupal\
  --locale=ja\
  --account-name=@@@user_name@@@\
  --account-pass=@@@password@@@\
  --account-mail=@@@mail@@@\
  --site-name=@@@site_name@@@ || exit 1

if [ $DRUPAL_VERSION -eq 7 ]; then
  # Drupal �����[�J���C�Y���邽�߂̃��W���[����L����
  $drush -y en locale || exit 1

  # ���{�̃��P�[���ݒ�
  $drush -y vset site_default_country JP || exit 1

  # ���{����f�t�H���g�̌���Ƃ��Ēǉ�
  # drush_language ���W���[�����g���邪�A�X�^�[�g�A�b�v�X�N���v�g�ł͏�肭
  # �����Ȃ��̂� eval ���g��
  $drush eval "locale_add_language('ja', 'Japanese', '���{��');" || exit 1
  $drush eval '$langs = language_list(); variable_set("language_default", $langs["ja"])' || exit 1

  # �ŐV�̓��{��t�@�C������荞�ރ��W���[�����_�E�����[�h���ăC���X�g�[��
  $drush -y dl l10n_update || exit 1
  $drush -y en l10n_update || exit 1

  # �ŐV�̓��{������擾���ăC���|�[�g
  $drush l10n-update-refresh || exit 1
  $drush l10n-update || exit 1
elif [ $DRUPAL_VERSION -eq 8 ]; then
  # ���{��|��̃C���|�[�g
  $drush locale-check || exit 1
  $drush locale-update || exit 1

  # ���{��󂪃L���b�V���ɂ�蒆�r���[�ȏ�ԂɂȂ邱�Ƃ�����̂ŁA�L���b�V�������r���g����
  $drush cr || exit 1
fi

# Drupal �̃��[�g�f�B���N�g�� (/var/www/html) �ȉ��̏��L�҂� apache �ɕύX
chown -R www-data: /var/www/html || exit 1

# Drupal �̃N�����^�X�N���쐬���ꎞ�ԂɈ�x�̕p�x�ŉ�
cat << EOS > /etc/cron.hourly/drupal
#!/bin/bash
/usr/local/bin/drush -r /var/www/html cron
EOS
chmod 755 /etc/cron.hourly/drupal || exit 1

# ���|�[�g��ʂŗ��p�\�ȃA�b�v�f�[�g�ɖ�肪����ƌx������邽�߁A�A�b�v�f�[�g
# �������s���B
# - �����A�b�v�f�[�g�m�F���s���ƃX�e�[�^�X��ʂŐ���ƔF������Ȃ����߁Asleep
#   �R�}���h��1����Ɏ��s����B
# - `--update-backend=drupal` ���w�肵�Ȃ��ƁA���|�[�g��ʂɐ��������f����Ȃ��B
sleep 1m
$drush -y up --update-backend=drupal || exit 1

# ���������Ă��邩������Ȃ����߁A�Ǘ��҃��[���A�h���X�Ɋ������[���𑗐M

# �K�v�ȏ����W�߂�
IP=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`
SYSTEMINFO=`dmidecode -t system`

# �t�H�[���Őݒ肵���Ǘ��҂̃A�h���X�փ��[���𑗐M
/usr/sbin/sendmail -t -i -o -f @@@mail@@@ << EOF From: @@@mail@@@
Subject: finished drupal install on $IP
To: @@@mail@@@

Finished drupal install on $IP

Please access to http://$IP

System Info:
$SYSTEMINFO
EOF