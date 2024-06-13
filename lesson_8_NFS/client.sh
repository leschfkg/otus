#!/bin/bash
apt update -y && apt upgrade -y
apt install nfs-common -y
echo "172.22.23.105:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
systemctl daemon-reload && systemctl restart remote-fs.target
cp -r /vagrant/authorized_keys /root/.ssh/authorized_keys             # Добавьте вашу публичную часть ключа
cp -r /vagrant/.bashrc /home/vagrant && cp -r /vagrant/.bashrc /root/
timedatectl set-timezone Europe/Moscow                                # Укажите ваш часовой пояс