#!/bin/bash

# @sacloud-once
# @sacloud-desc-begin
# rbenv�ABundler�ARuby on Rails ���C���X�g�[������X�N���v�g�ł��B
# ���̃X�N���v�g�́ACentOS6.X �������� Scientific Linux6.X �ł̂ݓ��삵�܂��B
# ���̃X�N���v�g�͊����܂ł�10�����x���Ԃ�������܂��B
# �X�N���v�g�̐i���󋵂� /root/.sacloud-api/notes/�X�^�[�g�A�b�v�X�N���v�gID.log �����m�F���������B
# @sacloud-desc-end
# @sacloud-text required default="rbenv" shellarg user 'rbenv �𗘗p���郆�[�U�[��'
# @sacloud-text required default="2.3.0" shellarg ruby_version 'global �ŗ��p���� Ruby �̃o�[�W����'
# @sacloud-checkbox default="1" shellarg create_gemrc 'gem �� install �� update ���� --no-document �I�v�V������t�^���� .gemrc ���쐬����'

# �R���g���[���p�l���̓��͒l��ϐ��֑��
user=@@@user@@@
ruby_version=@@@ruby_version@@@
create_gemrc=@@@create_gemrc@@@

if [ $user != "root" ]; then
 home="/home/$user"
else
 home="/root"
fi

# ���[�U�[�̐ݒ�
if ! cat /etc/passwd | awk -F : '{ print $1 }' | egrep ^$user$; then
 adduser $user
fi

echo "[1/5] Ruby �̃C���X�g�[���ɕK�v�ȃ��C�u�������C���X�g�[����..."
yum install -y openssl-devel  >/dev/null 2>&1
yum install -y zlib-devel     >/dev/null 2>&1
yum install -y readline-devel >/dev/null 2>&1
yum install -y libyaml-devel  >/dev/null 2>&1
yum install -y libffi-devel   >/dev/null 2>&1
echo "[1/5] Ruby �̃C���X�g�[���ɕK�v�ȃ��C�u�������C���X�g�[�����܂���"

echo "[2/5] rbenv ���C���X�g�[����..."
git clone https://github.com/sstephenson/rbenv.git      $home/.rbenv                    >/dev/null 2>&1
git clone https://github.com/sstephenson/ruby-build.git $home/.rbenv/plugins/ruby-build >/dev/null 2>&1
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> $home/.bash_profile
echo 'eval "$(rbenv init -)"'               >> $home/.bash_profile
chown -R $user:$user $home/.rbenv
echo "[2/5] rbenv ���C���X�g�[�����܂���"


if [ "$create_gemrc" = "1" ]; then
cat << __EOS__ > $home/.gemrc
install: --no-document
update:  --no-document
__EOS__
 chown $user:$user $home/.gemrc
fi

echo "[3/5] Ruby �̃C���X�g�[����..."
su -l $user -c "rbenv install $ruby_version" >/dev/null 2>&1 
su -l $user -c "rbenv global  $ruby_version"
su -l $user -c "rbenv rehash"
echo "[3/5] Ruby ���C���X�g�[�����܂���"

echo "[4/5] Bundler �̃C���X�g�[����..."
su -l $user -c "rbenv exec gem i bundler" >/dev/null 2>&1
echo "[4/5] Bundler ���C���X�g�[�����܂���"

echo "[5/5] Rails �̃C���X�g�[����..."
su -l $user -c "rbenv exec gem i rails" >/dev/null 2>&1
echo "[5/5] Rails ���C���X�g�[�����܂���"

echo "�X�^�[�g�A�b�v�X�N���v�g�̏������������܂���"