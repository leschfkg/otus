# Lesson №23 - VPN

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_23_VPN
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

# Домашнее задание

1. Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях

2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ

Задание со звездочкой

3. Самостоятельно изучить и настроить ocserv, подключиться с хоста к ВМ

### 1. Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях

 поднимаем две ВМ - vagrant up

### Настройка хоста otus-node-0:

 1. Cоздаем файл-ключ 

~~~
vagrant@otus-node-0:~$ sudo -i
root@otus-node-0:~# openvpn --genkey secret /etc/openvpn/static.key
root@otus-node-0:~#
~~~

2. Cоздаем конфигурационный файл OpenVPN со следующим содержимым:

~~~
dev tap 
ifconfig 10.10.10.1 255.255.255.0 
topology subnet 
secret /etc/openvpn/static.key 
comp-lzo 
status /var/log/openvpn-status.log 
log /var/log/openvpn.log  
verb 3 
~~~
~~~
root@otus-node-0:~# vim /etc/openvpn/server.conf
root@otus-node-0:~# cat /etc/openvpn/server.conf
dev tap
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3

root@otus-node-0:~#
~~~

3. Создаем service unit для запуска OpenVPN

~~~
root@otus-node-0:~# vim /etc/systemd/system/openvpn@.service
root@otus-node-0:~# cat /etc/systemd/system/openvpn@.service
[Unit]
Description=OpenVPN Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
WantedBy=multi-user.target

root@otus-node-0:~#
~~~
4. Запускаем сервис
~~~
root@otus-node-0:~# systemctl enable --now openvpn@server
Created symlink /etc/systemd/system/multi-user.target.wants/openvpn@server.service → /etc/systemd/system/openvpn@.service.
root@otus-node-0:~# systemctl status openvpn@server
● openvpn@server.service - OpenVPN Tunneling Application On server
     Loaded: loaded (/etc/systemd/system/openvpn@.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-10-28 10:55:04 MSK; 2s ago
   Main PID: 1893 (openvpn)
     Status: "Pre-connection initialization successful"
      Tasks: 1 (limit: 4562)
     Memory: 1.6M
        CPU: 8ms
     CGroup: /system.slice/system-openvpn.slice/openvpn@server.service
             └─1893 /usr/sbin/openvpn --cd /etc/openvpn/ --config server.conf

Oct 28 10:55:04 otus-node-0 systemd[1]: Starting OpenVPN Tunneling Application On server...
Oct 28 10:55:04 otus-node-0 openvpn[1893]: 2024-10-28 10:55:04 WARNING: Compression for receiving enabled. Compression >
Oct 28 10:55:04 otus-node-0 systemd[1]: Started OpenVPN Tunneling Application On server.
lines 1-14/14 (END)
~~~

### Настройка хоста otus-node-1: 

1. Cоздаем конфигурационный файл OpenVPN со следующим содержимым:

~~~
root@otus-node-1 ~ # vim /etc/openvpn/server.conf
root@otus-node-1 ~ # cat /etc/openvpn/server.conf
dev tap
remote 192.168.56.10
ifconfig 10.10.10.2 255.255.255.0
topology subnet
route 192.168.56.0 255.255.255.0
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3

root@otus-node-1 ~ #
~~~
2. На хост otus-node-1 в директорию /etc/openvpn необходимо скопировать файл-ключ static.key, который был создан на хосте otus-node-0.

~~~
root@otus-node-1 ~ # scp vagrant@192.168.56.10:/etc/openvpn/static.key .
The authenticity of host '192.168.56.10 (192.168.56.10)' can't be established.
ED25519 key fingerprint is SHA256:aY1Cjtv3k7J5rjHb2sFB4MNOfsFl4jIkf1swPyeSq+I.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.56.10' (ED25519) to the list of known hosts.
vagrant@192.168.56.10's password:
scp: /etc/openvpn/static.key: Permission denied
root@otus-node-1 ~ # scp vagrant@192.168.56.10:/etc/openvpn/static.key .
vagrant@192.168.56.10's password:
Permission denied, please try again.
vagrant@192.168.56.10's password:
static.key                                                                            100%  636   299.1KB/s   00:00
root@otus-node-1 ~ #
root@otus-node-1 ~ # ll
total 32
drwx------  4 root root 4096 Oct 28 11:05 .
drwxr-xr-x 20 root root 4096 Oct 28 10:18 ..
-rw-r--r--  1 root root 3588 Oct 28 10:31 .bashrc
-rw-r--r--  1 root root  161 Jul  9  2019 .profile
drwx------  3 root root 4096 Oct  5  2022 snap
drwx------  2 root root 4096 Oct 28 11:04 .ssh
-rwxr-xr-x  1 root root  636 Oct 28 11:05 static.key
-rw-------  1 root root 1114 Oct 28 11:01 .viminfo
root@otus-node-1 ~ # chmod 600 static.key
root@otus-node-1 ~ # mv static.key /etc/openvpn/
root@otus-node-1 ~ #
~~~

3. Создаем service unit для запуска OpenVPN

~~~
root@otus-node-1 ~ # vim /etc/systemd/system/openvpn@.service
root@otus-node-1 ~ # cat /etc/systemd/system/openvpn@.service
[Unit]
Description=OpenVPN Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
WantedBy=multi-user.target

root@otus-node-1 ~ #
~~~

4. Запускаем сервис 

~~~
root@otus-node-1 ~ # systemctl enable --now openvpn@server
Created symlink /etc/systemd/system/multi-user.target.wants/openvpn@server.service → /etc/systemd/system/openvpn@.service.
root@otus-node-1 ~ # systemctl status openvpn@server
● openvpn@server.service - OpenVPN Tunneling Application On server
     Loaded: loaded (/etc/systemd/system/openvpn@.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-10-28 11:08:19 MSK; 8s ago
   Main PID: 1774 (openvpn)
     Status: "Pre-connection initialization successful"
      Tasks: 1 (limit: 4562)
     Memory: 2.6M
        CPU: 13ms
     CGroup: /system.slice/system-openvpn.slice/openvpn@server.service
             └─1774 /usr/sbin/openvpn --cd /etc/openvpn/ --config server.conf

Oct 28 11:08:19 otus-node-1 systemd[1]: Starting OpenVPN Tunneling Application On server...
Oct 28 11:08:19 otus-node-1 openvpn[1774]: 2024-10-28 11:08:19 WARNING: Compression for receiving enabled. Compression >
Oct 28 11:08:19 otus-node-1 systemd[1]: Started OpenVPN Tunneling Application On server.
lines 1-14/14 (END)
~~~
Далее необходимо замерить скорость в туннеле:

1. На хосте 1 запускаем iperf3 в режиме сервера: iperf3 -s & 
~~~
root@otus-node-0:~# iperf3 -s &
[1] 2037
root@otus-node-0:~# -----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 10.10.10.2, port 35840
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 35844
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  7.36 MBytes  61.7 Mbits/sec
[  5]   1.00-2.00   sec  8.79 MBytes  73.8 Mbits/sec
[  5]   2.00-3.00   sec  9.18 MBytes  77.0 Mbits/sec
[  5]   3.00-4.00   sec  6.95 MBytes  58.2 Mbits/sec
[  5]   4.00-5.00   sec  17.8 MBytes   149 Mbits/sec
[  5]   5.00-6.00   sec  5.60 MBytes  47.0 Mbits/sec
[  5]   6.00-7.00   sec  4.84 MBytes  40.6 Mbits/sec
[  5]   7.00-8.00   sec  8.52 MBytes  71.4 Mbits/sec
[  5]   8.00-9.00   sec  10.0 MBytes  84.0 Mbits/sec
[  5]   9.00-10.00  sec  8.75 MBytes  73.4 Mbits/sec
[  5]  10.00-11.00  sec  4.99 MBytes  41.9 Mbits/sec
^C
root@otus-node-0:~# [  5]  11.00-12.00  sec  8.86 MBytes  74.4 Mbits/sec
[  5]  12.00-13.00  sec  10.5 MBytes  87.8 Mbits/sec
[  5]  13.00-14.00  sec  10.1 MBytes  85.1 Mbits/sec
[  5]  14.00-15.00  sec  4.93 MBytes  41.4 Mbits/sec
[  5]  14.00-15.00  sec  4.93 MBytes  41.4 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-15.00  sec   131 MBytes  73.5 Mbits/sec                  receiver
iperf3: the client has terminated
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
^C
root@otus-node-0:~#
~~~

2. На хосте 2 запускаем iperf3 в режиме клиента и замеряем  скорость в туннеле: iperf3 -c 10.10.10.1 -t 40 -i 5 

~~~
root@otus-node-1 ~ # iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 35844 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec  54.2 MBytes  91.0 Mbits/sec  150    431 KBytes
[  5]   5.00-10.02  sec  37.5 MBytes  62.7 Mbits/sec  363    311 KBytes
[  5]  10.02-15.18  sec  40.0 MBytes  65.1 Mbits/sec   70    325 KBytes
^C[  5]  15.18-15.75  sec  2.50 MBytes  36.3 Mbits/sec   87    169 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-15.75  sec   134 MBytes  71.5 Mbits/sec  670             sender
[  5]   0.00-15.75  sec  0.00 Bytes  0.00 bits/sec                  receiver
iperf3: interrupt - the client has terminated
root@otus-node-1 ~ #
~~~


Конфигурационные файлы сервера и клиента изменятся только в директиве dev. Меняем tap на tun

~~~
root@otus-node-0:~# vim /etc/openvpn/server.conf
root@otus-node-0:~# cat /etc/openvpn/server.conf
dev tun
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3

root@otus-node-0:~#
~~~
~~~
root@otus-node-1 ~ #  vim /etc/openvpn/server.conf
root@otus-node-1 ~ # cat /etc/openvpn/server.conf
dev tun
remote 192.168.56.10
ifconfig 10.10.10.2 255.255.255.0
topology subnet
route 192.168.56.0 255.255.255.0
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3

root@otus-node-1 ~ #
~~~
Перезапускаем службы на обоих серверах systemctl restart openvpn@server и повторяем пункты тест для режима работы tun. 

~~~
root@otus-node-0:~# iperf3 -s &
[2] 2059
root@otus-node-0:~# iperf3: error - unable to start listener for connections: Address already in use
iperf3: exiting
Accepted connection from 10.10.10.2, port 43540
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 43544
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  7.56 MBytes  63.4 Mbits/sec
[  5]   1.00-2.00   sec  6.46 MBytes  54.2 Mbits/sec
[  5]   2.00-3.00   sec  7.30 MBytes  61.3 Mbits/sec
[  5]   3.00-4.01   sec  4.50 MBytes  37.3 Mbits/sec
[  5]   4.01-5.00   sec  5.32 MBytes  45.1 Mbits/sec
[  5]   5.00-6.00   sec  9.70 MBytes  81.3 Mbits/sec
[  5]   6.00-7.00   sec  10.2 MBytes  85.4 Mbits/sec
[  5]   7.00-8.00   sec  5.36 MBytes  45.0 Mbits/sec
[  5]   8.00-9.00   sec  8.77 MBytes  73.6 Mbits/sec
[  5]   9.00-10.00  sec  7.31 MBytes  61.3 Mbits/sec
[  5]  10.00-11.00  sec  7.33 MBytes  61.5 Mbits/sec
[  5]  11.00-12.00  sec  10.2 MBytes  85.4 Mbits/sec
[  5]  12.00-13.00  sec  8.32 MBytes  69.8 Mbits/sec
[  5]  13.00-14.00  sec  7.94 MBytes  66.6 Mbits/sec
[  5]  14.00-15.00  sec  10.9 MBytes  91.3 Mbits/sec
[  5]  14.00-15.00  sec  10.9 MBytes  91.3 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-15.00  sec   121 MBytes  67.5 Mbits/sec                  receiver
iperf3: the client has terminated
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
^C
[2]+  Exit 1                  iperf3 -s
root@otus-node-0:~#
~~~
~~~
root@otus-node-1 ~ # iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 43544 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec  33.9 MBytes  56.9 Mbits/sec  497    679 KBytes
[  5]   5.00-10.01  sec  42.5 MBytes  71.2 Mbits/sec  215    181 KBytes
[  5]  10.01-15.01  sec  43.8 MBytes  73.3 Mbits/sec   45    225 KBytes
^C[  5]  15.01-15.64  sec  3.75 MBytes  50.1 Mbits/sec    0    235 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-15.64  sec   124 MBytes  66.5 Mbits/sec  757             sender
[  5]   0.00-15.64  sec  0.00 Bytes  0.00 bits/sec                  receiver
iperf3: interrupt - the client has terminated
root@otus-node-1 ~ #
~~~

В терминологии компьютерных сетей TUN и TAP — виртуальные сетевые драйверы ядра системы.

TAP эмулирует Ethernet-устройство и работает на канальном уровне модели OSI, оперируя кадрами Ethernet. TAP используется для создания сетевого моста,

TUN (сетевой туннель) работает на сетевом уровне модели OSI, оперируя IP-пакетами. TUN используется для маршрутизации.

Устройства TUN/TAP могут быть как временными, так и постоянными. Так же, как и физическим интерфейсам, им можно назначать адреса, применять правила сетевых экранов, анализировать трафик и т. д.

Подробнее можно посмотреть здесь https://www.hippolab.ru/virtualnyy-setevoy-interfeys-v-linux-tap-vs-tun

### 2. RAS на базе OpenVPN

Для выполнения данного задания можно воспользоваться Vagrantfile из  1 задания, только убрать одну ВМ или добавить третью машину, я добаляюю еще одну машину, чтобы не удалять первые две.

Настройка сервера:

1. Переходим в директорию /etc/openvpn и инициализируем PKI

~~~
vagrant@otus-node-0 /etc/openvpn $ sudo -i
root@otus-node-0 ~ # cd /etc/openvpn
root@otus-node-0 /etc/openvpn # /usr/share/easy-rsa/easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/pki


root@otus-node-0 /etc/openvpn #
~~~

2. Генерируем необходимые ключи и сертификаты для сервера

~~~
root@otus-node-0 /etc/openvpn # /usr/share/easy-rsa/easyrsa init-pki

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/pki


root@otus-node-0 /etc/openvpn #
~~~
~~~
root@otus-node-0 /etc/openvpn # /usr/share/easy-rsa/easyrsa build-ca
Using SSL: openssl OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)

Enter New CA Key Passphrase:
Re-Enter New CA Key Passphrase:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:test

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/etc/openvpn/pki/ca.crt
~~~
~~~
root@otus-node-0 /etc/openvpn # /usr/share/easy-rsa/easyrsa gen-dh
Using SSL: openssl OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)
Generating DH parameters, 2048 bit long safe prime
DH parameters of size 2048 created at /etc/openvpn/pki/dh.pem
~~~
~~~
root@otus-node-0 /etc/openvpn # echo 'rasvpn' | /usr/share/easy-rsa/easyrsa gen-req server nopass
Using SSL: openssl OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)
..+..+....+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+......+.+.........+..+...+.+...+...+.....+.......+..................+..+...+.........+...+.+.....+....+.....+.+......+.........+..............+...+.......+........+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+..+...............+....+........+.+.....+.......+.....+...+....+...+........+.........+.+..+..........+........+.+...+..+.........+......+...+..........+......+......+......+..+...+....+......+...+...............+..+....+...+...+............+...+.....+............+...+.......+.....+.+......+.........+.........+..+.+..............+....+......+...+...+.....+..........+...+..+.......+.....+...+...............+...+.+...+...+............+.......................+...+....+........+....+...+......+..+.......+..+....+..+.........+....+.....+.......+...+.....+.+.....+.+..+.+..............+...+...+......+.........+.+..............+.......+.........+........+.......+........+...+...+..........+.....+..........+.....+....+............+....................+......+.......+......+.....+.........+......+.+.....+.+.........+.....+.+..+...+....+...+...+..+.............+............+...+...+..+.......+.....+..........+.................+.+...+.....+.+.....+....+......+......+..................+.....+....+..+......+............+......+....+........+...+.+.....................+...+..+.........+...+...+.......+..+........................................+..................+.....+.............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
..+.....+.+...+..+.+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+.......+...+..+....+..+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*........+......+..+...+......+...+......+.+......+...+......+...+...............+......+..............+............+................+..+.+..+..........+..+.+.....+.+...........+.........+...................+..+.........+...+.......+.....+......+...+...............+.+...+...........+.+.....+.+..+...+.......+........+...+.+...........+.............+.........+..+...+.......+.........+......+........+......+.+.........+..+....+...+..+...+..........+...+........+.........+.+...........+...+.+......+...+...............+...+........................+...+.....+.......+.....+.+...+..+..........+.......................+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [server]:
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/server.req
key: /etc/openvpn/pki/private/server.key


root@otus-node-0 /etc/openvpn #
~~~
~~~
root@otus-node-0 /etc/openvpn # echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req server server
Using SSL: openssl OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a server certificate for 825 days:

subject=
    commonName                = rasvpn


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: Using configuration from /etc/openvpn/pki/easy-rsa-66068.y0EjZJ/tmp.SsvdC2
Enter pass phrase for /etc/openvpn/pki/private/ca.key:
4097B3B3477F0000:error:0700006C:configuration file routines:NCONF_get_string:no value:../crypto/conf/conf_lib.c:315:group=<NULL> name=unique_subject
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'rasvpn'
Certificate is to be certified until Jan 31 12:35:22 2027 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/pki/issued/server.crt


root@otus-node-0 /etc/openvpn #
~~~
~~~
root@otus-node-0 /etc/openvpn # openvpn --genkey secret ca.key
root@otus-node-0 /etc/openvpn #
~~~

3. Генерируем необходимые ключи и сертификаты для клиента

~~~
root@otus-node-0 /etc/openvpn # echo 'client' | /usr/share/easy-rsa/easyrsa gen-req client nopass
Using SSL: openssl OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)
..........+.....+...+......+......+..........+...+.....+...+...+.+...+..+....+.....+......+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*......+.........+.+........+.......+......+........+............+.......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*........+......+........+....+............+.........+..+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.+......+...+..+.......+..+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+..+...+.......+......+.........+............+......+..+.......+.....+.+........+.........+...+...+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+..+....+.....+...+..........+........+..........+............+..+.........+.......+...+..+....+...+...........+......+....+......+.....+.+....................+.............+..+....+..............+.......+...+.....+......+..................+.+.....+......+......+.........+.+...+...........+....+..+.......+.....+..........+......+.....+......+...+.+...............+......+...+........+....+...........+..........+.................+.+..+....+...+........+.........+....+............+..+...+...................+.....+....+..+..........+...+.........+...............+...............+.....+.+........................+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [client]:
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/client.req
key: /etc/openvpn/pki/private/client.key


root@otus-node-0 /etc/openvpn #
~~~
~~~
root@otus-node-0 /etc/openvpn # echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req client client
Using SSL: openssl OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a client certificate for 825 days:

subject=
    commonName                = client


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: Using configuration from /etc/openvpn/pki/easy-rsa-66156.KdLzmR/tmp.Px5w4M
Enter pass phrase for /etc/openvpn/pki/private/ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'client'
Certificate is to be certified until Jan 31 12:37:18 2027 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/pki/issued/client.crt


root@otus-node-0 /etc/openvpn #
~~~

4. Создаем конфигурационный файл сервера

~~~
root@otus-node-0 /etc/openvpn # vim /etc/openvpn/server.conf
root@otus-node-0 /etc/openvpn # cat /etc/openvpn/server.conf
port 1207
proto udp
dev tun
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/server.crt
key /etc/openvpn/pki/private/server.key
dh /etc/openvpn/pki/dh.pem
server 10.10.10.0 255.255.255.0
ifconfig-pool-persist ipp.txt
client-to-client
client-config-dir /etc/openvpn/client
keepalive 10 120
comp-lzo
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3

root@otus-node-0 /etc/openvpn #
~~~

5. Зададим параметр iroute для клиента

~~~
root@otus-node-0 /etc/openvpn # echo 'iroute 10.10.10.0 255.255.255.0' > /etc/openvpn/client/client
root@otus-node-0 /etc/openvpn # cat /etc/openvpn/client/client
iroute 10.10.10.0 255.255.255.0
root@otus-node-0 /etc/openvpn #
~~~

6. Запускаем сервис (при необходимости создать файл юнита как в задании 1) 

~~~
root@otus-node-0 /etc/openvpn # vim /etc/systemd/system/openvpn@.service
root@otus-node-0 /etc/openvpn # cat /etc/systemd/system/openvpn@.service
[Unit]
Description=OpenVPN Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
WantedBy=multi-user.target

root@otus-node-0 /etc/openvpn #
~~~
~~~
root@otus-node-0 /etc/openvpn # systemctl enable --now openvpn@server
Created symlink /etc/systemd/system/multi-user.target.wants/openvpn@server.service → /etc/systemd/system/openvpn@.service.
root@otus-node-0 /etc/openvpn #
~~~

7. На хост-машине настраиваем подключение:

~~~
  24-10-28   15:43:03   /home/mobaxterm/otus/otus/lesson_23_VPN   dev  vim client.conf
                                                                                                                                                                                              ✓

  24-10-28   15:43:26   /home/mobaxterm/otus/otus/lesson_23_VPN   dev  cat client.conf
dev tun
proto udp
remote 192.168.56.10 1207
client
resolv-retry infinite
remote-cert-tls server
ca ./ca.crt
cert ./client.crt
key ./client.key
route 192.168.56.0 255.255.255.0
persist-key
persist-tun
comp-lzo
verb 3

                                                                                                                                                                                              ✓

  24-10-28   15:43:30   /home/mobaxterm/otus/otus/lesson_23_VPN   dev 
~~~
Скопировать в одну директорию с client.conf файлы с сервера: 

Из каталога pki на компьютер клиента копируем файлы:

ca.crt

issued/client1.crt

private/client1.key

dh.pem

При использовании tls, также копируем ta.key.

~~~
  24-10-28   15:43:30   /home/mobaxterm/otus/otus/lesson_23_VPN   dev  ll
total 26
-rwxr-xr-x 1 LevitskyAV Enterprise Admins   1387 2024-10-28 15:21 Vagrantfile
-rwxr-xr-x 1 LevitskyAV Enterprise Admins     93 2024-10-28 10:16 authorized_keys
-rwxr-xr-x 1 LevitskyAV Enterprise Admins   1192 2024-10-28 15:53 ca.crt
-rw-r--r-- 1 LevitskyAV Enterprise Admins    231 2024-10-28 15:43 client.conf
-rwxr-xr-x 1 LevitskyAV Enterprise Admins   4503 2024-10-28 15:54 client.crt
-rwxr-xr-x 1 LevitskyAV Enterprise Admins   1704 2024-10-28 15:54 client.key
-rwxr-xr-x 1 LevitskyAV Enterprise Admins    424 2024-10-28 15:53 dh.pem
-rwxr-xr-x 1 LevitskyAV Enterprise Admins  29003 2024-10-28 15:46 readme.md
                                                                                                                                                                                              ✓

  24-10-28   15:54:45   /home/mobaxterm/otus/otus/lesson_23_VPN   dev 
~~~
на ОС windows переименовываем файл client.conf в client.conf.ovpn и добаялем конфиг в клиента openvpn, далее подключаемся к серверу

![alt text](image.png)

При успешном подключении проверяем пинг по внутреннему IP адресу  сервера в туннеле: ping -c 4 10.10.10.1 

~~~
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus\otus\lesson_23_VPN> ping 10.10.10.1

Обмен пакетами с 10.10.10.1 по с 32 байтами данных:
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=128
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=128
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=128
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=128

Статистика Ping для 10.10.10.1:
    Пакетов: отправлено = 4, получено = 4, потеряно = 0
    (0% потерь)
Приблизительное время приема-передачи в мс:
    Минимальное = 0мсек, Максимальное = 0 мсек, Среднее = 0 мсек
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus\otus\lesson_23_VPN>
~~~
Также проверяем командой ip r (netstat -rn) на хостовой машине что сеть туннеля импортирована в таблицу маршрутизации. 
~~~
root@otus-node-0 /etc/openvpn/pki # ip r
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100
10.0.2.3 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100
10.10.10.0/24 via 10.10.10.2 dev tun0
10.10.10.2 dev tun0 proto kernel scope link src 10.10.10.1
192.168.56.0/24 dev enp0s8 proto kernel scope link src 192.168.56.10
root@otus-node-0 /etc/openvpn/pki #
~~~

Для выполнения задания со * можно использовать эту статью:

https://interface31.ru/tech_it/2022/04/nastraivaem-openconnect-sovmestimyy-s-cisco-anyconnect-vpn-server-na-platforme-linux.html

Так же можно быстро поднять openconnect server в docker, делать не стал, не интересно и не хватает времени. 