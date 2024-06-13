#!/bin/bash
apt update -y && apt upgrade -y
apt install nfs-kernel-server -y
mkdir -p /srv/share/upload && chown -R nobody:nogroup /srv/share && chmod 0777 /srv/share/upload
cat << EOF >> /etc/exports 
/srv/share 172.22.23.106/32(rw,sync,root_squash)
EOF
exportfs -r
cp -r /vagrant/authorized_keys /root/.ssh/authorized_keys             # Добавьте вашу публичную часть ключа
cp -r /vagrant/.bashrc /home/vagrant && cp -r /vagrant/.bashrc /root/
timedatectl set-timezone Europe/Moscow                                # Укажите ваш часовой пояс