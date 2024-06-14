# Lesson №8 - Стенд Vagrant с NFS

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_8_NFS
~~~
3. измените конфигурцию под себя в файле Vagrantfile
4. добавьте публичную часть ключа в файл authorized_keys
5. запустите создание ВМ:

5.1 Linux bash
~~~
vagrant up && vagrant reload
~~~
5.2 Windows power shell
~~~
vagrant up; vagrant reload
~~~

Для быстрого запуска окружения и работы использован Vagrant-стенд из файла Vagrantfile с образом cdaf/UbuntuLVM.
Стенд протестирован на VirtualBox 7.0.14, Vagrant 2.4, хостовая система: Windows 11 Pro.

### Настраиваем сервер NFS

#### Первоначальный вариант Vagrantfile, для выполнения задания вручную
~~~
# -*- mode: ruby -*-
# vi: set ft=ruby :
$hosts = 2                              # укажите колличество вм
$disk = 0                              # укажите колличество дисков
Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vm|
    vm.memory = 4096
    vm.cpus = 2
    vm.check_guest_additions=false
  config.vm.box = "cdaf/UbuntuLVM"
  config.vm.box_version = "2022.10.05"
  config.vm.box_check_update = false
end

(0..$hosts-1).each do |i|
    config.vm.define "otus-node-#{i}" do |node|
        node.vm.network "public_network", ip: "172.22.23.#{105+i}", netmask: "255.255.252.0"
        node.vm.hostname = "otus-node-#{i}.local"
        node.vm.disk :disk, size: "50GB", primary: true
        (1..$disk).each do |d|
          node.vm.disk :disk, size: "20GB", name: "disk-#{d}"
        end
    end

end
  config.vm.provision "shell", inline: <<-SHELL
    apt update -y && apt upgrade -y
    cp -r /vagrant/authorized_keys /root/.ssh/authorized_keys             # Добавьте вашу публичную часть ключа
    cp -r /vagrant/.bashrc /home/vagrant && cp -r /vagrant/.bashrc /root/
    timedatectl set-timezone Europe/Moscow                                # Укажите ваш часовой пояс
  SHELL
end
~~~

Установим сервер NFS:
~~~
root@otus-node-0 ~ # apt install nfs-kernel-server
~~~
Настройки сервера находятся в файле /etc/nfs.conf 
~~~
root@otus-node-0 ~ # cat /etc/nfs.conf
#
# This is a general configuration for the
# NFS daemons and tools
#
[general]
pipefs-directory=/run/rpc_pipefs
#
[exports]
# rootdir=/export
#
[exportfs]
# debug=0
#
[gssd]
# verbosity=0
# rpc-verbosity=0
# use-memcache=0
# use-machine-creds=1
# use-gss-proxy=0
# avoid-dns=1
# limit-to-legacy-enctypes=0
# context-timeout=0
# rpc-timeout=5
# keytab-file=/etc/krb5.keytab
# cred-cache-directory=
# preferred-realm=
#
[lockd]
# port=0
# udp-port=0
#
[mountd]
# debug=0
manage-gids=y
# descriptors=0
# port=0
# threads=1
# reverse-lookup=n
# state-directory-path=/var/lib/nfs
# ha-callout=
#
[nfsdcld]
# debug=0
# storagedir=/var/lib/nfs/nfsdcld
#
[nfsdcltrack]
# debug=0
# storagedir=/var/lib/nfs/nfsdcltrack
#
[nfsd]
# debug=0
# threads=8
# host=
# port=0
# grace-time=90
# lease-time=90
# udp=n
# tcp=y
# vers2=n
# vers3=y
# vers4=y
# vers4.0=y
# vers4.1=y
# vers4.2=y
# rdma=n
# rdma-port=20049
#
[statd]
# debug=0
# port=0
# outgoing-port=0
# name=
# state-directory-path=/var/lib/nfs/statd
# ha-callout=
# no-notify=0
#
[sm-notify]
# debug=0
# force=0
# retry-time=900
# outgoing-port=
# outgoing-addr=
# lift-grace=y
#
[svcgssd]
# principal=
root@otus-node-0 ~ #
~~~
Проверяем наличие слушающих портов 2049/udp, 2049/tcp,111/udp, 111/tcp (не все они будут использоваться далее,  но их наличие сигнализирует о том, что необходимые сервисы готовы принимать внешние подключения):
~~~
root@otus-node-0 ~ # ss -tunlp
Netid      State       Recv-Q       Send-Q                Local Address:Port              Peer Address:Port      Process
udp        UNCONN      0            0                           0.0.0.0:34121                  0.0.0.0:*
udp        UNCONN      0            0                           0.0.0.0:57042                  0.0.0.0:*          users:(("rpc.mountd",pid=64811,fd=4))
udp        UNCONN      0            0                     127.0.0.53%lo:53                     0.0.0.0:*          users:(("systemd-resolve",pid=24549,fd=13))
udp        UNCONN      0            0                  10.0.2.15%enp0s3:68                     0.0.0.0:*          users:(("systemd-network",pid=24544,fd=21))
udp        UNCONN      0            0                           0.0.0.0:111                    0.0.0.0:*          users:(("rpcbind",pid=64182,fd=5),("systemd",pid=1,fd=57))
udp        UNCONN      0            0                           0.0.0.0:39107                  0.0.0.0:*          users:(("rpc.mountd",pid=64811,fd=12))
udp        UNCONN      0            0                           0.0.0.0:47469                  0.0.0.0:*          users:(("rpc.mountd",pid=64811,fd=8))
udp        UNCONN      0            0                         127.0.0.1:954                    0.0.0.0:*          users:(("rpc.statd",pid=64802,fd=5))
udp        UNCONN      0            0                           0.0.0.0:60555                  0.0.0.0:*          users:(("rpc.statd",pid=64802,fd=8))
udp        UNCONN      0            0                              [::]:48885                     [::]:*          users:(("rpc.mountd",pid=64811,fd=6))
udp        UNCONN      0            0                              [::]:32821                     [::]:*          users:(("rpc.mountd",pid=64811,fd=10))
udp        UNCONN      0            0                              [::]:111                       [::]:*          users:(("rpcbind",pid=64182,fd=7),("systemd",pid=1,fd=60))
udp        UNCONN      0            0                              [::]:53387                     [::]:*          users:(("rpc.mountd",pid=64811,fd=14))
udp        UNCONN      0            0                              [::]:47701                     [::]:*
udp        UNCONN      0            0                              [::]:39798                     [::]:*          users:(("rpc.statd",pid=64802,fd=10))
tcp        LISTEN      0            64                          0.0.0.0:46363                  0.0.0.0:*
tcp        LISTEN      0            64                          0.0.0.0:2049                   0.0.0.0:*
tcp        LISTEN      0            4096                        0.0.0.0:59617                  0.0.0.0:*          users:(("rpc.statd",pid=64802,fd=9))
tcp        LISTEN      0            4096                        0.0.0.0:44517                  0.0.0.0:*          users:(("rpc.mountd",pid=64811,fd=5))
tcp        LISTEN      0            4096                        0.0.0.0:49675                  0.0.0.0:*          users:(("rpc.mountd",pid=64811,fd=9))
tcp        LISTEN      0            4096                        0.0.0.0:35023                  0.0.0.0:*          users:(("rpc.mountd",pid=64811,fd=13))
tcp        LISTEN      0            4096                        0.0.0.0:111                    0.0.0.0:*          users:(("rpcbind",pid=64182,fd=4),("systemd",pid=1,fd=56))
tcp        LISTEN      0            4096                  127.0.0.53%lo:53                     0.0.0.0:*          users:(("systemd-resolve",pid=24549,fd=14))
tcp        LISTEN      0            128                         0.0.0.0:22                     0.0.0.0:*          users:(("sshd",pid=24370,fd=3))
tcp        LISTEN      0            4096                           [::]:50585                     [::]:*          users:(("rpc.mountd",pid=64811,fd=15))
tcp        LISTEN      0            4096                           [::]:45467                     [::]:*          users:(("rpc.mountd",pid=64811,fd=11))
tcp        LISTEN      0            64                             [::]:2049                      [::]:*
tcp        LISTEN      0            4096                           [::]:45419                     [::]:*          users:(("rpc.statd",pid=64802,fd=11))
tcp        LISTEN      0            4096                           [::]:47343                     [::]:*          users:(("rpc.mountd",pid=64811,fd=7))
tcp        LISTEN      0            4096                           [::]:111                       [::]:*          users:(("rpcbind",pid=64182,fd=6),("systemd",pid=1,fd=59))
tcp        LISTEN      0            64                             [::]:41427                     [::]:*
tcp        LISTEN      0            128                            [::]:22                        [::]:*          users:(("sshd",pid=24370,fd=4))
root@otus-node-0 ~ #
~~~
Создаём и настраиваем директорию, которая будет экспортирована в будущем 
~~~
root@otus-node-0 ~ # mkdir -p /srv/share/upload
root@otus-node-0 ~ # chown -R nobody:nogroup /srv/share
root@otus-node-0 ~ # chmod 0777 /srv/share/upload
root@otus-node-0 ~ #
~~~
Cоздаём в файле /etc/exports структуру, которая позволит экспортировать ранее созданную директорию:
~~~
root@otus-node-0 ~ # cat << EOF >> /etc/exports
/srv/share 172.22.23.106/32(rw,sync,root_squash)
EOF
root@otus-node-0 ~ # cat /etc/exports
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#

/srv/share 172.22.23.106/32(rw,sync,root_squash)
root@otus-node-0 ~ #

~~~
Экспортируем ранее созданную директорию:
~~~
root@otus-node-0 ~ # exportfs -r
exportfs: /etc/exports [2]: Neither 'subtree_check' or 'no_subtree_check' specified for export "172.22.23.106/32:/srv/share".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x

root@otus-node-0 ~ # echo $?
0
~~~
Проверяем экспортированную директорию следующей командой
~~~
root@otus-node-0 ~ # exportfs -s
/srv/share  172.22.23.106/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@otus-node-0 ~ #
~~~
### Настраиваем клиент NFS 

Установим пакет с NFS-клиентом, все действия выпоняются на второй виртуальной машине, которая выступает клиентом otus-node-1
~~~
root@otus-node-1 ~ # apt install nfs-common
~~~
Добавляем в /etc/fstab строку для монтирования NFS
~~~
root@otus-node-1 ~ # echo "172.22.23.105:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
root@otus-node-1 ~ # cat /etc/fstab
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/ubuntu-vg/ubuntu-lv during curtin installation
/dev/disk/by-id/dm-uuid-LVM-55UW81khcQD1tBqhtyPqo28oN1fqdcV8vETotTJ6c4sgB5duZdrCd9lcSZOpEkfW / ext4 defaults 0 1
# /boot was on /dev/sda2 during curtin installation
/dev/disk/by-uuid/52cbbd6d-889e-4a45-a150-eb0879e28527 /boot ext4 defaults 0 1
/swap.img       none    swap    sw      0       0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
vagrant /vagrant vboxsf uid=1000,gid=1000,_netdev 0 0
#VAGRANT-END
172.22.23.105:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0
root@otus-node-1 ~ #
~~~
и выполняем команды:
~~~
root@otus-node-1 ~ # systemctl daemon-reload
root@otus-node-1 ~ # systemctl restart remote-fs.target
root@otus-node-1 ~ #
~~~
Отметим, что в данном случае происходит автоматическая генерация systemd units в каталоге /run/systemd/generator/, которые производят монтирование при первом обращении к каталогу /mnt/.
~~~
root@otus-node-1 ~ # ls -la /run/systemd/generator/
total 32
drwxr-xr-x  8 root root 340 Jun 10 11:02 .
drwxr-xr-x 25 root root 600 Jun 10 11:02 ..
-rw-r--r--  1 root root 541 Jun 10 11:02 boot.mount
drwxr-xr-x  2 root root  80 Jun 10 11:02 local-fs.target.requires
drwxr-xr-x  2 root root  80 Jun 10 11:02 local-fs.target.wants
-rw-r--r--  1 root root 165 Jun 10 11:02 mnt.automount
-rw-r--r--  1 root root 243 Jun 10 11:02 mnt.mount
-rw-r--r--  1 root root 415 Jun 10 11:02 -.mount
drwxr-xr-x  2 root root  60 Jun 10 11:02 multi-user.target.wants
-rw-r--r--  1 root root   0 Jun 10 11:02 netplan.stamp
drwxr-xr-x  2 root root  60 Jun 10 11:02 network-online.target.wants
drwxr-xr-x  2 root root  80 Jun 10 11:02 remote-fs.target.requires
-rw-r--r--  1 root root 115 Jun 10 11:02 rpc_pipefs.target
-rw-r--r--  1 root root 234 Jun 10 11:02 run-rpc_pipefs.mount
-rw-r--r--  1 root root 175 Jun 10 11:02 swap.img.swap
drwxr-xr-x  2 root root  60 Jun 10 11:02 swap.target.requires
-rw-r--r--  1 root root 248 Jun 10 11:02 vagrant.mount
root@otus-node-1 ~ # ls -la /run/systemd/generator/remote-fs.target.requires/
total 0
drwxr-xr-x 2 root root  80 Jun 10 11:02 .
drwxr-xr-x 8 root root 340 Jun 10 11:02 ..
lrwxrwxrwx 1 root root  16 Jun 10 11:02 mnt.automount -> ../mnt.automount
lrwxrwxrwx 1 root root  16 Jun 10 11:02 vagrant.mount -> ../vagrant.mount
root@otus-node-1 ~ #
~~~
Заходим в директорию /mnt/ и проверяем успешность монтирования:
~~~
root@otus-node-1 ~ # cd /mnt/
root@otus-node-1 /mnt # mount | grep mnt
nsfs on /run/snapd/ns/lxd.mnt type nsfs (rw)
systemd-1 on /mnt type autofs (rw,relatime,fd=50,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=29899)
172.22.23.105:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=172.22.23.105,mountvers=3,mountport=48663,mountproto=udp,local_lock=none,addr=172.22.23.105)
root@otus-node-1 /mnt #
~~~
### Проверка работоспособности
Заходим на сервер.
~~~
Last login: Mon Jun 10 10:42:03 2024 from 172.22.21.223
root@otus-node-0 ~ #
~~~
Заходим в каталог /srv/share/upload.
~~~
root@otus-node-0 ~ # cd /srv/share/upload/
root@otus-node-0 /srv/share/upload # ls -la
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 10:46 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
root@otus-node-0 /srv/share/upload #
~~~
Создаём тестовый файл touch check_file
~~~
root@otus-node-0 /srv/share/upload # touch check_file
root@otus-node-0 /srv/share/upload # ls -la
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:10 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
root@otus-node-0 /srv/share/upload #
~~~
Заходим на клиент.
~~~
Last login: Mon Jun 10 10:56:59 2024 from 172.22.21.223
root@otus-node-1 ~ # 
~~~
Заходим в каталог /mnt/upload. 
Проверяем наличие ранее созданного файла.
~~~
root@otus-node-1 ~ # cd /mnt/upload/
root@otus-node-1 /mnt/upload # ls -la
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:10 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
root@otus-node-1 /mnt/upload #
~~~
Создаём тестовый файл touch client_file. 
Проверяем, что файл успешно создан.
~~~
root@otus-node-1 /mnt/upload # touch client_file
root@otus-node-1 /mnt/upload # ls -la
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:12 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 11:12 client_file
root@otus-node-1 /mnt/upload #
~~~
Предварительно проверяем клиент: 

перезагружаем клиент;
~~~
root@otus-node-1 /mnt/upload # reboot

Remote side unexpectedly closed network connection

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
заходим на клиент;
~~~
Last login: Mon Jun 10 10:59:10 2024 from 172.22.21.223
root@otus-node-1 ~ #
~~~
заходим в каталог /mnt/upload;
~~~
root@otus-node-1 ~ # cd /mnt/upload/
root@otus-node-1 /mnt/upload #
~~~
проверяем наличие ранее созданных файлов
~~~
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:12 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 11:12 client_file
root@otus-node-1 /mnt/upload #
~~~
Проверяем сервер: 

перезагружаем сервер;
~~~
root@otus-node-0 /srv/share/upload # reboot

Remote side unexpectedly closed network connection

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
заходим на сервер;
~~~
Last login: Mon Jun 10 10:59:12 2024 from 172.22.21.223
root@otus-node-0 ~ #
~~~
проверяем наличие файлов в каталоге /srv/share/upload/;
~~~
root@otus-node-0 ~ # ll /srv/share/upload/
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:12 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 11:12 client_file
root@otus-node-0 ~ #
~~~
проверяем экспорты exportfs -s;
~~~
root@otus-node-0 ~ # exportfs -s
/srv/share  172.22.23.106/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@otus-node-0 ~ #
~~~
проверяем работу RPC
~~~
root@otus-node-0 ~ # showmount -a 172.22.23.105
All mount points on 172.22.23.105:
172.22.23.106:/srv/share
root@otus-node-0 ~ #
~~~
Проверяем клиент повторно после перезагрузки сервера:

возвращаемся на клиент и перезагружаем клиент;
~~~
root@otus-node-1 /mnt/upload # reboot

Remote side unexpectedly closed network connection

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
заходим на клиент
~~~
Last login: Mon Jun 10 11:14:40 2024 from 172.22.21.223
root@otus-node-1 ~ #
~~~
проверяем работу RPC
~~~
root@otus-node-1 ~ # showmount -a 172.22.23.105
All mount points on 172.22.23.105:
172.22.23.106:/srv/share
root@otus-node-1 ~ #
~~~
заходим в каталог /mnt/upload
~~~
root@otus-node-1 ~ # cd /mnt/upload/
root@otus-node-1 /mnt/upload # ls -la
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:12 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 11:12 client_file
root@otus-node-1 /mnt/upload #
~~~
проверяем статус монтирования
~~~
root@otus-node-1 /mnt/upload # mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=60,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=15223)
172.22.23.105:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=172.22.23.105,mountvers=3,mountport=35201,mountproto=udp,local_lock=none,addr=172.22.23.105)
nsfs on /run/snapd/ns/lxd.mnt type nsfs (rw)
root@otus-node-1 /mnt/upload #
~~~
проверяем наличие ранее созданных файлов
~~~
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:12 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 11:12 client_file
root@otus-node-1 /mnt/upload #
~~~
создаём еще один тестовый файл и проверяем, что файл успешно создан
~~~
root@otus-node-1 /mnt/upload # touch final_check
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 11:24 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 10:46 ..
-rw-r--r-- 1 root   root       0 Jun 10 11:10 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 11:12 client_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 11:24 final_check
root@otus-node-1 /mnt/upload #
~~~
Вышеуказанные проверки прошли успешно, это значит, что демонстрационный стенд работоспособен и готов к работе.

### Создание автоматизированного Vagrantfile 
Для выполнения этой части задания удалим виртуальные машины этого урока
~~~
vagrant destroy -f
==> otus-node-1: Forcing shutdown of VM...
==> otus-node-1: Destroying VM and associated drives...
==> otus-node-0: Forcing shutdown of VM...
==> otus-node-0: Destroying VM and associated drives...
~~~
Переписываем Vagrantfile для автоматического конфигурирования сервера и клиента, пишем скрипты автоконфигурирования server.sh и client.sh

Vagrantfile
~~~
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vm|
    vm.memory = 4096
    vm.cpus = 2
    vm.check_guest_additions=false
  config.vm.box = "cdaf/UbuntuLVM"
  config.vm.box_version = "2022.10.05"
  config.vm.box_check_update = false
end

  config.vm.define "otus-node-0" do |server|
      server.vm.network "public_network", ip: "172.22.23.105", netmask: "255.255.252.0"
      server.vm.hostname = "otus-node-0.local"
      server.vm.disk :disk, size: "50GB", primary: true
      server.vm.provision "shell", path: "server.sh"
end

  config.vm.define "otus-node-1" do |client|
      client.vm.network "public_network", ip: "172.22.23.106", netmask: "255.255.252.0"
      client.vm.hostname = "otus-node-1.local"
      client.vm.disk :disk, size: "50GB", primary: true
      client.vm.provision "shell", path: "client.sh"
end
end
~~~
server.sh
~~~
#!/bin/bash
#apt update -y && 
apt update -y
apt install nfs-kernel-server -y
mkdir -p /srv/share/upload && chown -R nobody:nogroup /srv/share && chmod 0777 /srv/share/upload
cat << EOF >> /etc/exports 
/srv/share 172.22.23.106/32(rw,sync,root_squash)
EOF
exportfs -r
cp -r /vagrant/authorized_keys /root/.ssh/authorized_keys             # Добавьте вашу публичную часть ключа
cp -r /vagrant/.bashrc /home/vagrant && cp -r /vagrant/.bashrc /root/
timedatectl set-timezone Europe/Moscow                                # Укажите ваш часовой пояс
~~~
client.sh
~~~
#!/bin/bash
#apt update -y && 
apt update -y
apt install nfs-common -y
echo "172.22.23.105:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
systemctl daemon-reload && systemctl restart remote-fs.target
cp -r /vagrant/authorized_keys /root/.ssh/authorized_keys             # Добавьте вашу публичную часть ключа
cp -r /vagrant/.bashrc /home/vagrant && cp -r /vagrant/.bashrc /root/
timedatectl set-timezone Europe/Moscow                                # Укажите ваш часовой пояс
~~~
Поднимаем виртуальные машины  и проверяем работу 
~~~
vagrant up
~~~
### Проверка работоспособности
Заходим на сервер
~~~
Last login: Mon Jun 10 12:30:36 2024 from 172.22.21.223
root@otus-node-0 ~ #
~~~
Заходим в каталог /srv/share/upload, Создаём тестовый файл touch check_file
~~~
root@otus-node-0 ~ # cd /srv/share/upload/
root@otus-node-0 /srv/share/upload # touch check_file
root@otus-node-0 /srv/share/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 12:40 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 12:15 ..
-rw-r--r-- 1 root   root       0 Jun 10 12:40 check_file
root@otus-node-0 /srv/share/upload #
~~~
Заходим на клиент.
~~~
Last login: Mon Jun 10 12:30:38 2024 from 172.22.21.223
root@otus-node-1 ~ #
~~~
Заходим в каталог /mnt/upload, проверяем наличие ранее созданного файла, создаём тестовый файл touch client_file, проверяем, что файл успешно создан.
~~~
root@otus-node-1 ~ # cd /mnt/upload/
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 12:40 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 12:15 ..
-rw-r--r-- 1 root   root       0 Jun 10 12:40 check_file
root@otus-node-1 /mnt/upload # touch client_file
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 12:42 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 12:15 ..
-rw-r--r-- 1 root   root       0 Jun 10 12:40 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 12:42 client_file
root@otus-node-1 /mnt/upload #
~~~
Вышеуказанные проверки прошли успешно!

Проверяем работу после перезагрузки клиента и сервера:

перезагружаем клиент
~~~
root@otus-node-1 /mnt/upload # reboot

Remote side unexpectedly closed network connection

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
заходим на клиент, заходим в каталог /mnt/upload, проверяем наличие ранее созданных файлов.
~~~
Last login: Mon Jun 10 12:41:22 2024 from 172.22.21.223
root@otus-node-1 ~ # cd /mnt/upload/
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 12:42 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 12:15 ..
-rw-r--r-- 1 root   root       0 Jun 10 12:40 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 12:42 client_file
root@otus-node-1 /mnt/upload #
~~~
перезагружаем сервер, заходим на сервер, проверяем наличие файлов в каталоге /srv/share/upload/, проверяем экспорты exportfs -s; проверяем работу RPC showmount -a 172.22.23.105.
~~~
root@otus-node-0 /srv/share/upload # reboot

Remote side unexpectedly closed network connection

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
~~~
Last login: Mon Jun 10 12:39:31 2024 from 172.22.21.223
root@otus-node-0 ~ # ll /srv/share/upload/
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 12:42 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 12:15 ..
-rw-r--r-- 1 root   root       0 Jun 10 12:40 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 12:42 client_file
root@otus-node-0 ~ # exportfs -s
/srv/share  172.22.23.106/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@otus-node-0 ~ # showmount -a
All mount points on otus-node-0:
172.22.23.106:/srv/share
root@otus-node-0 ~ #
~~~
Проверяем клиент: 

возвращаемся на клиент, перезагружаем клиент, заходим на клиент, проверяем работу RPC showmount -a, заходим в каталог /mnt/upload, проверяем статус монтирования mount | grep mnt, проверяем наличие ранее созданных файлов, создаём тестовый файл touch final_check, проверяем, что файл успешно создан.
~~~
root@otus-node-1 ~ # showmount -a 172.22.23.105
All mount points on 172.22.23.105:
172.22.23.106:/srv/share
root@otus-node-1 ~ # cd /mnt/upload/
root@otus-node-1 /mnt/upload # mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=60,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=19489)
172.22.23.105:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=172.22.23.105,mountvers=3,mountport=53149,mountproto=udp,local_lock=none,addr=172.22.23.105)
nsfs on /run/snapd/ns/lxd.mnt type nsfs (rw)
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 12:42 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 12:15 ..
-rw-r--r-- 1 root   root       0 Jun 10 12:40 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 12:42 client_file
root@otus-node-1 /mnt/upload # touch final_check
root@otus-node-1 /mnt/upload # ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Jun 10 12:51 .
drwxr-xr-x 3 nobody nogroup 4096 Jun 10 12:15 ..
-rw-r--r-- 1 root   root       0 Jun 10 12:40 check_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 12:42 client_file
-rw-r--r-- 1 nobody nogroup    0 Jun 10 12:51 final_check
root@otus-node-1 /mnt/upload #
~~~
Все вышеуказанные проверки прошли успешно, это значит, что демонстрационный стенд развернутый автоматически работоспособен и готов к работе! 

# Задание со звездочкой*
## Настроить аутентификацию через KERBEROS (NFSv4)

### Сервер Kerberos

Установите необходимые пакеты:
~~~
root@otus-node-0 ~ # apt update && apt install nfs-kernel-server nfs-common krb5-user libpam-krb5 krb5-admin-server krb5-kdc

~~~
Вы можете отвечать на вопросы STD.LOCAL и nfs.std.local

Добавляем группу nfs :
~~~
root@otus-node-0 ~ # groupadd nfs
~~~
Добавьте пользователя nobody в группу nfs :
~~~
root@otus-node-0 ~ # usermod -a -G nfs nobody
~~~
Создайте папку , которая будет общей :
~~~
root@otus-node-0 ~ # mkdir /nfs
~~~
Установите разрешения:
~~~
root@otus-node-0 ~ # chmod 770 /nfs && chgrp nfs /nfs
~~~
Отредактируйте /etc/hosts и добавьте эти записи:
~~~
172.22.23.105 nfs.std.local nfs
172.22.23.106 cln1.std.local cln1
172.22.23.107 cln2.std.local cln2
~~~
Настройка службы NFS

Отредактируйте файл /etc/exports, указав следующие параметры:

rw : доступ для чтения/записи.

sync : сервер посещает que les données soient sur le disque avant de répondre

anongid : явно установите gid 1001 (группа nfs, созданная ранее). Значения uid и gid по умолчанию: 65534, что означает «никто пользователь/группа».

root_squash : запрещает удаленным пользователям root иметь права суперпользователя (root) на удаленных томах, смонтированных по NFS.

no_subtree_check : эта опция отключает проверку поддерева, что имеет небольшие последствия для безопасности, но в некоторых случаях может повысить надежность.

Примечание:

krb5 Используйте Kerberos только для аутентификации.

krb5i Используйте Kerberos для аутентификации и добавляйте хэш в каждую транзакцию для обеспечения целостности. Трафик по-прежнему можно перехватывать и проверять, но изменения в нем будут очевидны.

krb5p Используйте Kerberos для аутентификации, проверки целостности и шифрования всего трафика между клиентом и сервером. Это наиболее безопасно, но и требует наибольшей нагрузки.

~~~
/nfs    *(rw,sync,anongid=1001,root_squash,no_subtree_check,sec=krb5p)
~~~
Отредактируйте файл /etc/default/nfs-kernel-server, чтобы включить демон svcgssd , необходимый для Kerberos:
~~~
NEED_SVCGSSD=yes
~~~
Перезапустите и перезагрузите/экспортируйте общий ресурс NFS :
~~~
root@otus-node-0 ~ # systemctl restart nfs-kernel-server.service && exportfs -arv
exporting *:/nfs
root@otus-node-0 ~ #
~~~
Затем создайте новую область с помощью kdb5_newrealm утилиты:
~~~
root@otus-node-0 ~ # krb5_newrealm
This script should be run on the master KDC/admin server to initialize
a Kerberos realm.  It will ask you to type in a master key password.
This password will be used to generate a key that is stored in
/etc/krb5kdc/stash.  You should try to remember this password, but it
is much more important that it be a strong password than that it be
remembered.  However, if you lose the password and /etc/krb5kdc/stash,
you cannot decrypt your Kerberos database.
Loading random data
Initializing database '/var/lib/krb5kdc/principal' for realm 'STD.LOCAL',
master key name 'K/M@STD.LOCAL'
You will be prompted for the database Master Password.
It is important that you NOT FORGET this password.
Enter KDC database master key:
Re-enter KDC database master key to verify:


Now that your realm is set up you may wish to create an administrative
principal using the addprinc subcommand of the kadmin.local program.
Then, this principal can be added to /etc/krb5kdc/kadm5.acl so that
you can use the kadmin program on other computers.  Kerberos admin
principals usually belong to a single user and end in /admin.  For
example, if jruser is a Kerberos administrator, then in addition to
the normal jruser principal, a jruser/admin principal should be
created.

Don't forget to set up DNS information so your clients can find your
KDC and admin servers.  Doing so is documented in the administration
guide.
root@otus-node-0 ~ #
~~~
Отредактируйте /etc/krb5kdc/kadm5.acl 
~~~
#*/admin@STD.LOCAL *
kdcadmin/admin@STD.LOCAL *
~~~
Запускаем службы :
~~~
root@otus-node-0 ~ # vim /etc/krb5kdc/kadm5.acl
root@otus-node-0 ~ # systemctl start krb5-kdc.service
root@otus-node-0 ~ # systemctl start krb5-admin-server.service
root@otus-node-0 ~ #
~~~
Создайте основного пользователя-администратора для администрирования:
~~~
root@otus-node-0 ~ # kadmin.local
Authenticating as principal root/admin@STD.LOCAL with password.
kadmin.local:  add_principal kdcadmin/admin@STD.LOCAL
No policy specified for kdcadmin/admin@STD.LOCAL; defaulting to no policy
Enter password for principal "kdcadmin/admin@STD.LOCAL":
Re-enter password for principal "kdcadmin/admin@STD.LOCAL":
Principal "kdcadmin/admin@STD.LOCAL" created.
kadmin.local:  exit
root@otus-node-0 ~ #
~~~
Создайте пользователя nfs :
~~~
root@otus-node-0 ~ # kadmin.local
Authenticating as principal root/admin@STD.LOCAL with password.
kadmin.local:  add_principal nfsuser@STD.LOCAL
No policy specified for nfsuser@STD.LOCAL; defaulting to no policy
Enter password for principal "nfsuser@STD.LOCAL":
Re-enter password for principal "nfsuser@STD.LOCAL":
Principal "nfsuser@STD.LOCAL" created.
kadmin.local:  exit
root@otus-node-0 ~ #
~~~
Создайте записи службы nfs для сервера и клиентов:
~~~
root@otus-node-0 ~ # kadmin.local
Authenticating as principal root/admin@STD.LOCAL with password.
kadmin.local:  addprinc -randkey nfs/nfs.std.local@STD.LOCAL
No policy specified for nfs/nfs.std.local@STD.LOCAL; defaulting to no policy
Principal "nfs/nfs.std.local@STD.LOCAL" created.
kadmin.local:  addprinc -randkey nfs/cln1.std.local@STD.LOCAL
No policy specified for nfs/cln1.std.local@STD.LOCAL; defaulting to no policy
Principal "nfs/cln1.std.local@STD.LOCAL" created.
kadmin.local:  addprinc -randkey nfs/cln2.std.local@STD.LOCAL
No policy specified for nfs/cln2.std.local@STD.LOCAL; defaulting to no policy
Principal "nfs/cln2.std.local@STD.LOCAL" created.
kadmin.local:  exit
root@otus-node-0 ~ #
~~~
Добавьте записи nfs в файл /etc/krb5.keytab :
~~~
root@otus-node-0 ~ # kadmin.local
Authenticating as principal root/admin@STD.LOCAL with password.
kadmin.local:  ktadd nfs/nfs.std.local
Entry for principal nfs/nfs.std.local with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal nfs/nfs.std.local with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
kadmin.local:  ktadd nfs/cln1.std.local
Entry for principal nfs/cln1.std.local with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal nfs/cln1.std.local with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
kadmin.local:  ktadd nfs/cln2.std.local
Entry for principal nfs/cln2.std.local with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal nfs/cln2.std.local with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
kadmin.local:  exit
root@otus-node-0 ~ #
~~~
Перезагрузите сервер
~~~
root@otus-node-0 ~ # reboot

Remote side unexpectedly closed network connection

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
Клиент (Debian/Ubuntu)

Установить пакеты:

Вы можете отвечать на вопросы STD.LOCAL и nfs.std.local
~~~
root@otus-node-1 ~ # apt update && apt install nfs-common krb5-user
~~~
Включите запустите службу nfs , чтобы она запускалась при загрузке:
~~~
root@otus-node-1 ~ # systemctl enable nfs-client.target
root@otus-node-1 ~ # systemctl start nfs-client.target
root@otus-node-1 ~ #
~~~
Добавьте эти записи в /etc/hosts :
~~~
172.22.23.105 nfs.std.local nfs
172.22.23.106 cln1.std.local cln1
172.22.23.107 cln2.std.local cln2
~~~
Добавьте запись nfs/cln1.std.local в /etc/krb5.keytab.

Мы можем скопировать файл /etc/krb5.keytab с сервера или сгенерировать его с клиента через Kerberos .

Добавить из клиента с Kerberos :
~~~
root@otus-node-1 ~ # kadmin -p kdcadmin/admin@STD.LOCAL
Authenticating as principal kdcadmin/admin@STD.LOCAL with password.
Password for kdcadmin/admin@STD.LOCAL:
kadmin:  ktadd nfs/cln1.std.local
Entry for principal nfs/cln1.std.local with kvno 3, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal nfs/cln1.std.local with kvno 3, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
kadmin:  exit
root@otus-node-1 ~ #
~~~
Перезагрузите хост:
~~~
root@otus-node-1 ~ # reboot

Remote side unexpectedly closed network connection

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
Подключите общий ресурс nfs к /mnt :
~~~
root@otus-node-1 ~ # mkdir /mnt/nfs
root@otus-node-1 ~ # mount -t nfs -o sec=krb5p nfs.std.local:/nfs /mnt/nfs/
root@otus-node-1 ~ #
~~~
Примечание.

 Теперь у нас должен быть доступ к общему ресурсу nfs с правами root, но невозможно открыть каталог «/mnt/nfs/»: устаревший дескриптор файла от пользователя. Вам нужен билет Kerberos .

 Запросите билет Kerberos :
 ~~~
root@otus-node-1 /mnt/nfs # kinit nfsuser@STD.LOCAL
Password for nfsuser@STD.LOCAL:
root@otus-node-1 /mnt/nfs #
~~~
Проверьте статус билета Kerberos :
~~~
root@otus-node-1 /mnt/nfs # klist
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: nfsuser@STD.LOCAL

Valid starting       Expires              Service principal
06/13/2024 17:40:18  06/14/2024 03:40:18  krbtgt/STD.LOCAL@STD.LOCAL
        renew until 06/14/2024 17:40:15
root@otus-node-1 /mnt/nfs #
~~~
Чтобы позволить пользователю монтировать /mnt/nfs после аутентификации, добавьте эту строку в /etc/fstab :
~~~
nfs.std.local:/nfs       /mnt/nfs        nfs     defaults,timeo=900,retrans=5,_netdev,sec=krb5p,user,noauto     0 0
~~~
создадим файлы для проверки работы на первом клиенте
~~~
root@otus-node-1 ~ # cd /mnt/nfs/
root@otus-node-1 /mnt/nfs # touch client1
root@otus-node-1 /mnt/nfs # ll
total 8
drwxrwx--- 2 root   nogroup 4096 Jun 13 17:42 .
drwxr-xr-x 3 root   root    4096 Jun 13 17:39 ..
-rw-r--r-- 1 nobody nogroup    0 Jun 13 17:42 client1
root@otus-node-1 /mnt/nfs #
~~~
ПРоверим появился ли файл на сервере
~~~
root@otus-node-0 ~ # cd /nfs/
root@otus-node-0 /nfs # ll
total 8
drwxrwx---  2 root   nfs  4096 Jun 13 17:42 .
drwxr-xr-x 21 root   root 4096 Jun 13 17:17 ..
-rw-r--r--  1 nobody nfs     0 Jun 13 17:42 client1
root@otus-node-0 /nfs #
~~~
Файл есть, все работает, повторим шаги на втором клиенте, изменив только FQDN на 
cln2.std.local
~~~
root@otus-node-2 ~ # apt update && apt install nfs-common krb5-user
root@otus-node-2 ~ # systemctl enable nfs-client.target
root@otus-node-2 ~ # systemctl start nfs-client.target
root@otus-node-2 ~ # vim /etc/hosts
root@otus-node-2 ~ # kadmin -p kdcadmin/admin@STD.LOCAL
Authenticating as principal kdcadmin/admin@STD.LOCAL with password.
Password for kdcadmin/admin@STD.LOCAL:
kadmin:  ktadd nfs/cln2.std.local
Entry for principal nfs/cln2.std.local with kvno 3, encryption type aes256-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
Entry for principal nfs/cln2.std.local with kvno 3, encryption type aes128-cts-hmac-sha1-96 added to keytab FILE:/etc/krb5.keytab.
kadmin:  exit
root@otus-node-2 ~ # reboot
root@otus-node-2 ~ #
Remote side unexpectedly closed network connection
~~~
Подключите общий ресурс nfs к /mnt :
~~~
root@otus-node-2 ~ # mkdir /mnt/nfs
root@otus-node-2 ~ # mount -t nfs -o sec=krb5p nfs.std.local:/nfs /mnt/nfs/
root@otus-node-2 ~ # kinit nfsuser@STD.LOCAL
Password for nfsuser@STD.LOCAL:
root@otus-node-2 ~ # klist
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: nfsuser@STD.LOCAL

Valid starting       Expires              Service principal
06/13/2024 17:49:46  06/14/2024 03:49:46  krbtgt/STD.LOCAL@STD.LOCAL
        renew until 06/14/2024 17:49:43
root@otus-node-2 ~ #
~~~
Чтобы позволить пользователю монтировать /mnt/nfs после аутентификации, добавьте эту строку в /etc/fstab :
~~~
nfs.std.local:/nfs       /mnt/nfs        nfs     defaults,timeo=900,retrans=5,_netdev,sec=krb5p,user,noauto     0 0
~~~
создадим файлы для проверки работы на втором клиенте
~~~
root@otus-node-2 ~ # cd /mnt/nfs/
root@otus-node-2 /mnt/nfs # ll
total 8
drwxrwx--- 2 root   nogroup 4096 Jun 13 17:42 .
drwxr-xr-x 3 root   root    4096 Jun 13 17:45 ..
-rw-r--r-- 1 nobody nogroup    0 Jun 13 17:42 client1
root@otus-node-2 /mnt/nfs # touch client2
root@otus-node-2 /mnt/nfs # ll
total 8
drwxrwx--- 2 root   nogroup 4096 Jun 13  2024 .
drwxr-xr-x 3 root   root    4096 Jun 13 17:45 ..
-rw-r--r-- 1 nobody nogroup    0 Jun 13 17:42 client1
-rw-r--r-- 1 nobody nogroup    0 Jun 13  2024 client2
root@otus-node-2 /mnt/nfs #
~~~
ПРоверим появился ли файл на сервере
~~~
root@otus-node-0 /nfs # ll
total 8
drwxrwx---  2 root   nfs  4096 Jun 13 17:51 .
drwxr-xr-x 21 root   root 4096 Jun 13 17:17 ..
-rw-r--r--  1 nobody nfs     0 Jun 13 17:42 client1
-rw-r--r--  1 nobody nfs     0 Jun 13 17:51 client2
root@otus-node-0 /nfs #
~~~
Создадим файл на сервере, и проверим виден лион на клиентах
~~~
root@otus-node-0 /nfs # touch server
root@otus-node-0 /nfs # ll
total 8
drwxrwx---  2 root   nfs  4096 Jun 13 17:53 .
drwxr-xr-x 21 root   root 4096 Jun 13 17:17 ..
-rw-r--r--  1 nobody nfs     0 Jun 13 17:42 client1
-rw-r--r--  1 nobody nfs     0 Jun 13 17:51 client2
-rw-r--r--  1 root   root    0 Jun 13 17:53 server
root@otus-node-0 /nfs #
~~~
~~~
root@otus-node-1 /mnt/nfs # ll
total 8
drwxrwx--- 2 root   nogroup 4096 Jun 13 17:53 .
drwxr-xr-x 3 root   root    4096 Jun 13 17:39 ..
-rw-r--r-- 1 nobody nogroup    0 Jun 13 17:42 client1
-rw-r--r-- 1 nobody nogroup    0 Jun 13 17:51 client2
-rw-r--r-- 1 root   root       0 Jun 13 17:53 server
root@otus-node-1 /mnt/nfs #
~~~
~~~
root@otus-node-2 /mnt/nfs # ll
total 8
drwxrwx--- 2 root   nogroup 4096 Jun 13  2024 .
drwxr-xr-x 3 root   root    4096 Jun 13 17:45 ..
-rw-r--r-- 1 nobody nogroup    0 Jun 13 17:42 client1
-rw-r--r-- 1 nobody nogroup    0 Jun 13  2024 client2
-rw-r--r-- 1 root   root       0 Jun 13  2024 server
root@otus-node-2 /mnt/nfs #
~~~
Перейдем в другого пользователя и проверим есть ли у него права на чтение и запись файлов в примонтированную директорию
~~~
root@otus-node-1 /mnt/nfs # su vagrant
vagrant@otus-node-1 /mnt/nfs $ ll
ls: cannot open directory '.': Permission denied
vagrant@otus-node-1 /mnt/nfs $ touch vagrant
touch: cannot touch 'vagrant': Permission denied
vagrant@otus-node-1 /mnt/nfs $
~~~
Все работает, прав на директорию у не авторизованного пользователя нет. Задание выполнено!
