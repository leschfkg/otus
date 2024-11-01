# Lesson №24 - DNS

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_24_DNS
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

Для быстрого запуска окружения и работы использован Vagrant-стенд из файла Vagrantfile с образом centos/7.
Стенд протестирован на VirtualBox 7.0.14, Vagrant 2.4, хостовая система: Windows 11 Pro.

# Домашнее задание

1. взять стенд https://github.com/erlong15/vagrant-bind 
* добавить еще один сервер client2
* завести в зоне dns.lab имена:
    * web1 - смотрит на клиент1
    * web2  смотрит на клиент2
* завести еще одну зону newdns.lab
* завести в ней запись
    * www - смотрит на обоих клиентов

2. настроить split-dns
* клиент1 - видит обе зоны, но в зоне dns.lab только web1
* клиент2 видит только dns.lab

### Взять стенд https://github.com/erlong15/vagrant-bind

1. Клонируем репозиторий
~~~
git clone https://github.com/erlong15/vagrant-bind
~~~
* убираем из файла Vagrantfile модуль ansible, так как хост под Windows, добавлем еще одну вм client2
* изменяем плэйбук ansible добавив файлы hosts, ansible.cfg, директорию group_vars, в которой размещаем доп конфиг и ключ ssh

* поднимаем стенд
~~~
vagrant up
~~~
* после того как стенд развернулся, переделываем плэйбук и выполняем плэйбук для настройки вм

из -за устаревшей версии ОС, требуется выполнить команды для изменения репозтториев
~~~
sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS* &&
sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS* &&
sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS*
~~~
после этого запускаем выполнение плэйбука еще раз
~~~
  01/11/2024   09:42.01   /home/mobaxterm/otus/otus/lesson_24_DNS/provisioning   dev  ansible-playbook playbook.yml

PLAY [all] ***************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************************************************************************************
ok: [client]
ok: [client2]
ok: [ns01]
ok: [ns02]

TASK [install packages] **************************************************************************************************************************************************************************************
changed: [ns02]
changed: [client2]
changed: [client]
changed: [ns01]

TASK [copy transferkey to all servers and the client] ********************************************************************************************************************************************************
changed: [client2]
changed: [ns02]
changed: [ns01]
changed: [client]
PLAY RECAP ***************************************************************************************************************************************************************************************************
client                     : ok=7    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
client2                    : ok=7    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
ns01                       : ok=9    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
ns02                       : ok=8    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
~~~
2. Для нормальной работы DNS-серверов, на них должно быть настроено одинаковое время, в CentOS по умолчанию уже есть NTP-клиент Chrony. Обычно он всегда включен и добавлен в автозагрузку. Проверить работу службы можно командой: systemctl status chronyd
~~~
root@ns01 ~ # systemctl status chronyd
● chronyd.service - NTP client/server
   Loaded: loaded (/usr/lib/systemd/system/chronyd.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2024-11-01 06:19:41 UTC; 37min ago
     Docs: man:chronyd(8)
           man:chrony.conf(5)
 Main PID: 543 (chronyd)
   CGroup: /system.slice/chronyd.service
           └─543 /usr/sbin/chronyd

Nov 01 06:19:40 ns01 systemd[1]: Starting NTP client/server...
Nov 01 06:19:40 ns01 chronyd[543]: chronyd version 3.2 starting (+CMDMON +NTP +REFCLOCK +RTC +PRIVDROP +SCFILTER +SECHASH +SIGND +ASYNCDNS +IPV6 +DEBUG)
Nov 01 06:19:40 ns01 chronyd[543]: Frequency 9.834 +/- 0.375 ppm read from /var/lib/chrony/drift
Nov 01 06:19:41 ns01 systemd[1]: Started NTP client/server.
Nov 01 06:19:49 ns01 chronyd[543]: Selected source 192.36.143.134
Nov 01 06:19:49 ns01 chronyd[543]: System clock wrong by 1.602131 seconds, adjustment started
Nov 01 06:19:50 ns01 chronyd[543]: System clock was stepped by 1.602131 seconds
Nov 01 06:27:28 ns01 chronyd[543]: Selected source 185.252.147.140
root@ns01 ~ #
~~~

3. Перед выполнением следующих заданий, нужно обратить внимание, на каком адресе и порту работают наши DNS-сервера. 
~~~
root@ns01 ~ # ss -tunlp | grep named
udp    UNCONN     0      0      192.168.50.10:53                    *:*                   users:(("named",pid=8991,fd=512))
udp    UNCONN     0      0       ::1:53                   :::*                   users:(("named",pid=8991,fd=513))
tcp    LISTEN     0      10     192.168.50.10:53                    *:*                   users:(("named",pid=8991,fd=21))
tcp    LISTEN     0      128    192.168.50.10:953                   *:*                   users:(("named",pid=8991,fd=23))
tcp    LISTEN     0      10      ::1:53                   :::*                   users:(("named",pid=8991,fd=22))
root@ns01 ~ #
~~~
Посмотреть информацию в настройках DNS-сервера (/etc/named.conf)
~~~
root@ns01 ~ # cat /etc/named.conf
options {

    // network
        listen-on port 53 { 192.168.50.10; };
        listen-on-v6 port 53 { ::1; };

    // data
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
~~~
~~~
root@ns02 ~ # cat /etc/named.conf
options {

    // network
        listen-on port 53 { 192.168.50.11; };
        listen-on-v6 port 53 { ::1; };

    // data
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
~~~
Исходя из данной информации, нам нужно подкорректировать файл /etc/resolv.conf для DNS-серверов: на хосте ns01 указать nameserver 192.168.50.10, а на хосте ns02 — 192.168.50.11  

В Ansible для этого можно воспользоваться шаблоном с Jinja. Изменим имя файла servers-resolv.conf на servers-resolv.conf.j2 и укажем там следующие условия:
~~~
domain dns.lab
search dns.lab
#Если имя сервера ns02, то указываем nameserver 192.168.50.11
{% if ansible_hostname == 'ns02' %}
nameserver 192.168.50.11
{% endif %}
#Если имя сервера ns01, то указываем nameserver 192.168.50.10
{% if ansible_hostname == 'ns01' %}
nameserver 192.168.50.10
{% endif %} 
~~~
После внесение изменений в файл, внесём измения в ansible-playbook:
Используем вместо модуля copy модуль template:
~~~
- name: copy resolv.conf to the servers
  template: src=servers-resolv.conf.j2 dest=/etc/resolv.conf owner=root group=root mode=0644
    
Или используя YAML-формат:

  - name: copy resolv.conf to the servers
    template: 
      src: servers-resolv.conf.j2 
      dest: /etc/resolv.conf 
      owner: root 
      group: root
      mode: 0644
~~~
Добавление имён в зону dns.lab

Проверим, что зона dns.lab уже существует на DNS-серверах:

Фрагмент файла /etc/named.conf на сервере ns01:
~~~
// lab's zone
zone "dns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.dns.lab";
};
~~~
Похожий фрагмент файла /etc/named.conf  находится на slave-сервере ns02:
~~~
// lab's zone
zone "dns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.dns.lab";
};
~~~
Также на хосте ns01 мы видим файл /etc/named/named.dns.lab с настройкой зоны:
~~~
root@ns01 ~ # cat /etc/named/named.dns.lab
$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11
root@ns01 ~ #
~~~
Именно в этот файл нам потребуется добавить имена. Допишем в конец файла следующие строки: 
~~~
;Web
web1            IN      A       192.168.50.15
web2            IN      A       192.168.50.16
~~~
Выполнем плэйбук еще раз для применения измений
~~~
  01/11/2024   09:52.45   /home/mobaxterm/otus/otus/lesson_24_DNS/provisioning   dev  ansible-playbook playbook.yml

PLAY [all] ***************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************************************************************************************
ok: [ns01]
ok: [client2]
ok: [client]
ok: [ns02]
~~~
После внесения изменений, выполним проверку с клиента:
~~~
root@client ~ # dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.16 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 52801
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.                  IN      A

;; ANSWER SECTION:
web1.dns.lab.           3600    IN      A       192.168.50.15

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns01.dns.lab.
dns.lab.                3600    IN      NS      ns02.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Fri Nov 01 07:31:02 UTC 2024
;; MSG SIZE  rcvd: 127

root@client ~ #
~~~
~~~
root@client ~ # dig @192.168.50.10 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.16 <<>> @192.168.50.10 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 2757
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.                  IN      A

;; ANSWER SECTION:
web2.dns.lab.           3600    IN      A       192.168.50.16

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns02.dns.lab.
dns.lab.                3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Fri Nov 01 07:32:47 UTC 2024
;; MSG SIZE  rcvd: 127

root@client ~ #
~~~
В примерах мы обратились к разным DNS-серверам с разными запросами

Создание новой зоны и добавление в неё записей

Для того, чтобы прописать на DNS-серверах новую зону нам потребуется: 

* На хосте ns01 добавить зону в файл /etc/named.conf:
~~~
// lab's newdns zone
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    allow-update { key "zonetransfer.key"; };
    file "/etc/named/named.newdns.lab";
};
~~~
* На хосте ns02 также добавить зону и указать с какого сервера запрашивать информацию об этой зоне (фрагмент файла /etc/named.conf):
~~~
// lab's newdns zone
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.newdns.lab";
};
~~~
* На хосте ns01 создадим файл /etc/named/named.newdns.lab

vi /etc/named/named.newdns.lab
~~~
$TTL 3600
$ORIGIN newdns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201007 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;WWW
www             IN      A       192.168.50.15
www             IN      A       192.168.50.16
~~~
В конце этого файла добавим записи www. У файла должны быть права 660, владелец — root, группа — named. 
~~~
root@ns01 ~ # ls -la /etc/named/
total 28
drw-rwx---.  2 root named   98 Nov  1 07:55 .
drwxr-xr-x. 78 root root  8192 Nov  1 07:53 ..
-rw-rw----.  1 root named  600 Nov  1 06:50 named.ddns.lab
-rw-rw----.  1 root named  698 Nov  1 07:32 named.dns.lab
-rw-rw----.  1 root named  625 Nov  1 06:51 named.dns.lab.rev
-rw-r--r--.  1 root root   701 Nov  1 07:55 named.newdns.lab
root@ns01 ~ # chown root:named /etc/named/named.newdns.lab
root@ns01 ~ # chmod 660 /etc/named/named.newdns.lab
root@ns01 ~ # ll /etc/named
total 28
drw-rwx---.  2 root named   98 Nov  1 07:55 .
drwxr-xr-x. 78 root root  8192 Nov  1 07:53 ..
-rw-rw----.  1 root named  600 Nov  1 06:50 named.ddns.lab
-rw-rw----.  1 root named  698 Nov  1 07:32 named.dns.lab
-rw-rw----.  1 root named  625 Nov  1 06:51 named.dns.lab.rev
-rw-rw----.  1 root named  701 Nov  1 07:55 named.newdns.lab
root@ns01 ~ #
~~~
После внесения данных изменений, изменяем значение serial (добавлем +1 к значению 2711201007) и перезапускаем named: systemctl restart named

Проверим с клиента
~~~
root@client ~ # dig @192.168.50.10 www.newdns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.16 <<>> @192.168.50.10 www.newdns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 60390
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.newdns.lab.                        IN      A

;; ANSWER SECTION:
www.newdns.lab.         3600    IN      A       192.168.50.15
www.newdns.lab.         3600    IN      A       192.168.50.16

;; AUTHORITY SECTION:
newdns.lab.             3600    IN      NS      ns01.dns.lab.
newdns.lab.             3600    IN      NS      ns02.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Fri Nov 01 08:03:36 UTC 2024
;; MSG SIZE  rcvd: 149

~~~
### Настройка Split-DNS 

У нас уже есть прописанные зоны dns.lab и newdns.lab. Однако по заданию client1  должен видеть запись web1.dns.lab и не видеть запись web2.dns.lab. Client2 может видеть обе записи из домена dns.lab, но не должен видеть записи домена newdns.lab Осуществить данные настройки нам поможет технология Split-DNS.

Для настройки Split-DNS нужно: 

1. Создать дополнительный файл зоны dns.lab, в котором будет прописана только одна запись: vim /etc/named/named.dns.lab.client
~~~
$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;Web
web1            IN      A       192.168.50.15
~~~
Имя файла может отличаться от указанной зоны. У файла должны быть права 660, владелец — root, группа — named.  
~~~
root@ns01 ~ # vi /etc/named/named.dns.lab.client
root@ns01 ~ # chown root:named  /etc/named/named.dns.lab.client
root@ns01 ~ # chmod 660  /etc/named/named.dns.lab.client
root@ns01 ~ # ll  /etc/named/named.dns.lab.client
-rw-rw----. 1 root named 652 Nov  1 08:07 /etc/named/named.dns.lab.client
root@ns01 ~ #
~~~

2. Внести изменения в файл /etc/named.conf на хостах ns01 и ns02

Прежде всего нужно сделать access листы для хостов client и client2. Сначала сгенерируем ключи для хостов client и client2, для этого на хосте ns01 запустим утилиту tsig-keygen (ключ может генериться 5 минут и более): 

~~~
root@ns01 ~ # tsig-keygen
key "tsig-key" {
        algorithm hmac-sha256;
        secret "l849ZhoSuBgA3xl7bsfE9qlEScwfeP6EJ3NJgIP+fn4=";
};
root@ns01 ~ #
~~~
~~~
root@ns01 ~ # tsig-keygen
key "tsig-key" {
        algorithm hmac-sha256;
        secret "c2CzUdiqhZ0F3/YmqM8PI2PU7iZ+1ZvbOhtTwPBKST0=";
};
~~~
Всего нам потребуется 2 таких ключа. После их генерации добавим блок с access листами в конец файла /etc/named.conf
~~~
key "client-key" {
        algorithm hmac-sha256;
        secret "l849ZhoSuBgA3xl7bsfE9qlEScwfeP6EJ3NJgIP+fn4=";
};

key "client2-key" {
        algorithm hmac-sha256;
        secret "c2CzUdiqhZ0F3/YmqM8PI2PU7iZ+1ZvbOhtTwPBKST0=";
};

acl client { !key client2-key; key client-key; 192.168.50.15; };
acl client2 { !key client-key; key client2-key; 192.168.50.16; };
~~~
В данном блоке access листов мы выделяем 2 блока: 
client имеет адрес 192.168.50.15, использует client-key и не использует client2-key
client2 имеет адрес 192ю168.50.16, использует clinet2-key и не использует client-key

Описание ключей и access листов будет одинаковое для master и slave сервера.
Повторяем на сервере NS02
~~~
key "client-key" {
        algorithm hmac-sha256;
        secret "l849ZhoSuBgA3xl7bsfE9qlEScwfeP6EJ3NJgIP+fn4=";
};

key "client2-key" {
        algorithm hmac-sha256;
        secret "c2CzUdiqhZ0F3/YmqM8PI2PU7iZ+1ZvbOhtTwPBKST0=";
};

acl client { !key client2-key; key client-key; 192.168.50.15; };
acl client2 { !key client-key; key client2-key; 192.168.50.16; };
~~~
Далее нужно создать файл с настройками зоны dns.lab для client, для этого на мастер сервере создаём файл /etc/named/named.dns.lab.client и добавляем в него следующее содержимое:
~~~
$TTL 3600
$ORIGIN dns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            2711201407 ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

; DNS Servers
ns01            IN      A       192.168.50.10
ns02            IN      A       192.168.50.11

;Web
web1            IN      A       192.168.50.15
~~~
Это почти скопированный файл зоны dns.lab, в конце которого удалена строка с записью web2. Имя зоны надо оставить такой же — dns.lab

Теперь можно внести правки в /etc/named.conf

Технология Split-DNS реализуется с помощью описания представлений (view), для каждого отдельного acl. В каждое представление (view) добавляются только те зоны, которые разрешено видеть хостам, адреса которых указаны в access листе.

Все ранее описанные зоны должны быть перенесены в модули view. Вне view зон быть недолжно, зона any должна всегда находиться в самом низу. 

После применения всех вышеуказанных правил на хосте ns01 мы получим следующее содержимое файла /etc/named.conf

~~~
options {

    // На каком порту и IP-адресе будет работать служба 
	listen-on port 53 { 192.168.50.10; };
	listen-on-v6 port 53 { ::1; };

    // Указание каталогов с конфигурационными файлами
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";

    // Указание настроек DNS-сервера
    // Разрешаем серверу быть рекурсивным
	recursion yes;
    // Указываем сети, которым разрешено отправлять запросы серверу
	allow-query     { any; };
    // Каким сетям можно передавать настройки о зоне
    allow-transfer { any; };
    
    // dnssec
	dnssec-enable yes;
	dnssec-validation yes;

    // others
	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// RNDC Control for client
key "rndc-key" {
    algorithm hmac-md5;
    secret "GrtiE9kz16GK+OKKU/qJvQ==";
};
controls {
        inet 192.168.50.10 allow { 192.168.50.15; 192.168.50.16; } keys { "rndc-key"; }; 
};

key "client-key" {
    algorithm hmac-sha256;
    secret "IQg171Ht4mdGYcjjYKhI9gSc1fhoxzHZB+h2NMtyZWY=";
};
key "client2-key" {
    algorithm hmac-sha256;
    secret "m7r7SpZ9KBcA4kOl1JHQQnUiIlpQA1IJ9xkBHwdRAHc=";
};

// ZONE TRANSFER WITH TSIG
include "/etc/named.zonetransfer.key"; 

server 192.168.50.11 {
    keys { "zonetransfer.key"; };
};
// Указание Access листов 
acl client { !key client2-key; key client-key; 192.168.50.15; };
acl client2 { !key client-key; key client2-key; 192.168.50.16; };
// Настройка первого view 
view "client" {
    // Кому из клиентов разрешено подключаться, нужно указать имя access-листа
    match-clients { client; };

    // Описание зоны dns.lab для client
    zone "dns.lab" {
        // Тип сервера — мастер
        type master;
        // Добавляем ссылку на файл зоны, который создали в прошлом пункте
        file "/etc/named/named.dns.lab.client";
        // Адрес хостов, которым будет отправлена информация об изменении зоны
        also-notify { 192.168.50.11 key client-key; };
    };

    // newdns.lab zone
    zone "newdns.lab" {
        type master;
        file "/etc/named/named.newdns.lab";
        also-notify { 192.168.50.11 key client-key; };
    };
};

// Описание view для client2
view "client2" {
    match-clients { client2; };

    // dns.lab zone
    zone "dns.lab" {
        type master;
        file "/etc/named/named.dns.lab";
        also-notify { 192.168.50.11 key client2-key; };
    };

    // dns.lab zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        file "/etc/named/named.dns.lab.rev";
        also-notify { 192.168.50.11 key client2-key; };
    };
};

// Зона any, указана в файле самой последней
view "default" {
    match-clients { any; };

    // root zone
    zone "." IN {
        type hint;
        file "named.ca";
    };

    // zones like localhost
    include "/etc/named.rfc1912.zones";
    // root DNSKEY
    include "/etc/named.root.key";

    // dns.lab zone
    zone "dns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab";
    };

    // dns.lab zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab.rev";
    };

    // ddns.lab zone
    zone "ddns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        allow-update { key "zonetransfer.key"; };
        file "/etc/named/named.ddns.lab";
    };

    // newdns.lab zone
    zone "newdns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.newdns.lab";
    };
};
~~~
Далее внесем изменения в файл /etc/named.conf на сервере ns02. Файл будет похож на файл, лежащий на ns01, только в настройках будет указание забирать информацию с сервера ns01:
~~~
options {

    // network 
	listen-on port 53 { 192.168.50.11; };
	listen-on-v6 port 53 { ::1; };

    // data
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";

    // server
	recursion yes;
	allow-query     { any; };
    allow-transfer { any; };
    
    // dnssec
	dnssec-enable yes;
	dnssec-validation yes;

    // others
	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// RNDC Control for client
key "rndc-key" {
    algorithm hmac-md5;
    secret "GrtiE9kz16GK+OKKU/qJvQ==";
};
controls {
        inet 192.168.50.11 allow { 192.168.50.15; 192.168.50.16; } keys { "rndc-key"; };
};

key "client-key" {
    algorithm hmac-sha256;
    secret "IQg171Ht4mdGYcjjYKhI9gSc1fhoxzHZB+h2NMtyZWY=";
};
key "client2-key" {
    algorithm hmac-sha256;
    secret "m7r7SpZ9KBcA4kOl1JHQQnUiIlpQA1IJ9xkBHwdRAHc=";
};
~~~

Так как файлы с конфигурациями получаются достаточно большими — возрастает вероятность сделать ошибку. При их правке можно воспользоваться утилитой named-checkconf. Она укажет в каких строчках есть ошибки. Использование данной утилиты рекомендуется после изменения настроек на DNS-сервере. 
~~~
root@ns01 ~ # named-checkconf
root@ns01 ~ #
~~~
~~~
root@ns02 ~ # named-checkconf
root@ns02 ~ #
~~~
После внесения данных изменений можно перезапустить (по очереди) службу named на серверах ns01 и ns02.
~~~
root@ns01 ~ # systemctl restart named
root@ns01 ~ #
~~~
~~~
root@ns02 ~ # systemctl restart named
root@ns02 ~ #
~~~
Далее, нужно будет проверить работу Split-DNS с хостов client и client2. Для проверки можно использовать утилиту ping:

Проверка на client:
~~~
root@client ~ # ping www.newdns.lab
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.011 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.022 ms
64 bytes from client (192.168.50.15): icmp_seq=3 ttl=64 time=0.020 ms
64 bytes from client (192.168.50.15): icmp_seq=4 ttl=64 time=0.020 ms
^C
--- www.newdns.lab ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 0.011/0.018/0.022/0.005 ms
root@client ~ # ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.009 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.019 ms
64 bytes from client (192.168.50.15): icmp_seq=3 ttl=64 time=0.021 ms
64 bytes from client (192.168.50.15): icmp_seq=4 ttl=64 time=0.020 ms
^C
--- web1.dns.lab ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3001ms
rtt min/avg/max/mdev = 0.009/0.017/0.021/0.005 ms
root@client ~ # ping web2.dns.lab
ping: web2.dns.lab: Name or service not known
root@client ~ #
~~~
На хосте мы видим, что client видит обе зоны (dns.lab и newdns.lab), однако информацию о хосте web2.dns.lab он получить не может. 

Проверка на client2:
~~~
root@client2 ~ #  ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=0.905 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=0.619 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=3 ttl=64 time=0.557 ms
^C
--- web1.dns.lab ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2001ms
rtt min/avg/max/mdev = 0.557/0.693/0.905/0.154 ms
root@client2 ~ # ping web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.010 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.021 ms
64 bytes from client2 (192.168.50.16): icmp_seq=3 ttl=64 time=0.020 ms
^C
--- web2.dns.lab ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.010/0.017/0.021/0.005 ms
root@client2 ~ #
~~~
Тут мы понимаем, что client2 видит всю зону dns.lab и не видит зону newdns.lab

Для того, чтобы проверить что master и slave сервера отдают одинаковую информацию, в файле /etc/resolv.conf можно удалить на время nameserver 192.168.50.10 и попробовать выполнить все те же проверки. Результат должен быть идентичный. 

### * настроить все без выключения selinux

selinux в процессе выполнения не выключал, все работает без дополнительных настроек
~~~
root@client2 ~ # getenforce
Enforcing
root@client2 ~ # sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31
root@client2 ~ #
~~~




