# Lesson №10 - SYSTEMD

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_10_Systemd
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

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).

2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).

3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.

### Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова

Для начала создаём файл с конфигурацией для сервиса в директории /etc/default - из неё сервис будет брать необходимые переменные.
~~~
root@otus-node-0 ~ # vim /etc/default/watchlog
root@otus-node-0 ~ # cat /etc/default/watchlog
# Configuration file for my watchlog service
# Place it to /etc/default

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log

root@otus-node-0 ~ #
~~~
Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение,
плюс ключевое слово ‘ALERT’
~~~
root@otus-node-0 ~ # vim /var/log/watchlog.log
root@otus-node-0 ~ # cat /var/log/watchlog.log
Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение, плюс ключевое слово ALERT
Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение, плюс ключевое слово ALERT
Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение, плюс ключевое слово ALERT

root@otus-node-0 ~ #
~~~
Создадим скрипт:
~~~
root@otus-node-0 ~ # vim /opt/watchlog.sh
root@otus-node-0 ~ # cat /opt/watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi

root@otus-node-0 ~ #
~~~
Команда logger отправляет лог в системный журнал.
Добавим права на запуск файла:
~~~
root@otus-node-0 ~ # chmod +x /opt/watchlog.sh
root@otus-node-0 ~ # ll /opt/
total 16
drwxr-xr-x  3 root root 4096 Jun 18 11:50 .
drwxr-xr-x 20 root root 4096 Jun 18 09:44 ..
drwxr-xr-x  8 root root 4096 Oct  5  2022 VBoxGuestAdditions-6.1.38
-rwxr-xr-x  1 root root  132 Jun 18 11:50 watchlog.sh
root@otus-node-0 ~ #
~~~
Создадим юнит для сервиса:
~~~
root@otus-node-0 ~ # vim /etc/systemd/system/watchlog.service
root@otus-node-0 ~ # cat /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/default/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG

root@otus-node-0 ~ #
~~~
Создадим юнит для таймера:
~~~
root@otus-node-0 ~ # vim /etc/systemd/system/watchlog.timer
root@otus-node-0 ~ # cat /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target

root@otus-node-0 ~ #
~~~
Затем достаточно только запустить timer:
~~~
root@otus-node-0 ~ # systemctl start watchlog.timer
root@otus-node-0 ~ # systemctl status watchlog.timer
● watchlog.timer - Run watchlog script every 30 second
     Loaded: loaded (/etc/systemd/system/watchlog.timer; disabled; vendor preset: enabled)
     Active: active (elapsed) since Tue 2024-06-18 11:54:07 MSK; 5s ago
    Trigger: n/a
   Triggers: ● watchlog.service

Jun 18 11:54:07 otus-node-0 systemd[1]: Started Run watchlog script every 30 second.
root@otus-node-0 ~ #
~~~
И убедиться в результате:
~~~
root@otus-node-0 ~ # tail -n 1000 /var/log/syslog  | grep word
Jun 18 11:24:06 otus-node-0 systemd[1]: Started Dispatch Password Requests to Console Directory Watch.
Jun 18 11:24:06 otus-node-0 systemd[1]: Condition check resulted in Forward Password Requests to Plymouth Directory Watch being skipped.
Jun 18 11:24:06 otus-node-0 kernel: [    4.892645] systemd[1]: Started Forward Password Requests to Wall Directory Watch.
Jun 18 12:02:46 otus-node-0 root: Tue Jun 18 12:02:46 PM MSK 2024: I found word, Master!
Jun 18 12:07:45 otus-node-0 root: Tue Jun 18 12:07:45 PM MSK 2024: I found word, Master!
Jun 18 12:08:21 otus-node-0 root: Tue Jun 18 12:08:21 PM MSK 2024: I found word, Master!
Jun 18 12:08:57 otus-node-0 root: Tue Jun 18 12:08:57 PM MSK 2024: I found word, Master!
Jun 18 12:09:37 otus-node-0 root: Tue Jun 18 12:09:37 PM MSK 2024: I found word, Master!
root@otus-node-0 ~ #
~~~

### Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта

Устанавливаем spawn-fcgi и необходимые для него пакеты:
~~~
root@otus-node-0 ~ # apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y
~~~
Сам Init скрипт, который будем переписывать, можно найти здесь: https://gist.github.com/cea2k/1318020 
~~~
root@otus-node-0 ~ # git clone https://gist.github.com/cea2k/1318020
Cloning into '1318020'...
remote: Enumerating objects: 4, done.
remote: Total 4 (delta 0), reused 0 (delta 0), pack-reused 4
Receiving objects: 100% (4/4), done.
Resolving deltas: 100% (1/1), done.
root@otus-node-0 ~ # ll
total 52
drwx------  6 root root 4096 Jun 18 12:13 .
drwxr-xr-x 20 root root 4096 Jun 18 09:44 ..
drwxr-xr-x  3 root root 4096 Jun 18 12:13 1318020
-rw-------  1 root root    7 Jun 18 11:23 .bash_history
-rw-r--r--  1 root root 3588 Jun 18 10:09 .bashrc
drwx------  2 root root 4096 Jun 18 11:23 .cache
-rw-------  1 root root   20 Jun 18 12:09 .lesshst
-rw-r--r--  1 root root  161 Jul  9  2019 .profile
drwx------  3 root root 4096 Oct  5  2022 snap
drwx------  2 root root 4096 Oct  5  2022 .ssh
-rw-------  1 root root 9577 Jun 18 11:57 .viminfo
root@otus-node-0 ~ # cd 1318020/
root@otus-node-0 ~/1318020 # ll
total 16
drwxr-xr-x 3 root root 4096 Jun 18 12:13 .
drwx------ 6 root root 4096 Jun 18 12:13 ..
drwxr-xr-x 8 root root 4096 Jun 18 12:13 .git
-rw-r--r-- 1 root root 1629 Jun 18 12:13 php_cgi
root@otus-node-0 ~/1318020 #
~~~
Но перед этим необходимо создать файл с настройками для будущего сервиса в файле /etc/spawn-fcgi/fcgi.conf.
Он должен получится следующего вида:
~~~
root@otus-node-0 ~/1318020 # mkdir /etc/spawn-fcgi
root@otus-node-0 ~/1318020 # vim /etc/spawn-fcgi/fcgi.conf
root@otus-node-0 ~/1318020 # cat /etc/spawn-fcgi/fcgi.conf
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"

root@otus-node-0 ~/1318020 #
~~~
А сам юнит-файл будет примерно следующего вида:
~~~
root@otus-node-0 ~/1318020 # vim /etc/systemd/system/spawn-fcgi.service
root@otus-node-0 ~/1318020 # cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target

root@otus-node-0 ~/1318020 #
~~~
в соответствии с файлом конфигурации fcgi.conf, копируем скрипт в /usr/bin/
~~~
root@otus-node-0 ~/1318020 # cp php_cgi /usr/bin/
root@otus-node-0 ~/1318020 # chmod +x /usr/bin/php_cgi
~~~
Убеждаемся, что все успешно работает:
~~~
root@otus-node-0 ~/1318020 # systemctl daemon-reload
root@otus-node-0 ~/1318020 # systemctl start spawn-fcgi
root@otus-node-0 ~/1318020 # systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-06-18 12:24:01 MSK; 4s ago
   Main PID: 23956 (php-cgi)
      Tasks: 33 (limit: 9386)
     Memory: 14.2M
        CPU: 29ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─23956 /usr/bin/php-cgi
             ├─23957 /usr/bin/php-cgi
             ├─23958 /usr/bin/php-cgi
             ├─23959 /usr/bin/php-cgi
             ├─23960 /usr/bin/php-cgi
             ├─23961 /usr/bin/php-cgi
             ├─23962 /usr/bin/php-cgi
             ├─23963 /usr/bin/php-cgi
             ├─23964 /usr/bin/php-cgi
             ├─23965 /usr/bin/php-cgi
             ├─23966 /usr/bin/php-cgi
             ├─23967 /usr/bin/php-cgi
             ├─23968 /usr/bin/php-cgi
             ├─23969 /usr/bin/php-cgi
             ├─23970 /usr/bin/php-cgi
             ├─23971 /usr/bin/php-cgi
             ├─23972 /usr/bin/php-cgi
             ├─23973 /usr/bin/php-cgi
             ├─23974 /usr/bin/php-cgi
             ├─23975 /usr/bin/php-cgi
             ├─23976 /usr/bin/php-cgi
             ├─23977 /usr/bin/php-cgi
             ├─23978 /usr/bin/php-cgi
             ├─23979 /usr/bin/php-cgi
             ├─23980 /usr/bin/php-cgi
             ├─23981 /usr/bin/php-cgi
             ├─23982 /usr/bin/php-cgi
             ├─23983 /usr/bin/php-cgi
             ├─23984 /usr/bin/php-cgi
             ├─23985 /usr/bin/php-cgi
             ├─23986 /usr/bin/php-cgi
             ├─23987 /usr/bin/php-cgi
             └─23988 /usr/bin/php-cgi

Jun 18 12:24:01 otus-node-0 systemd[1]: Started Spawn-fcgi startup service by Otus.
root@otus-node-0 ~/1318020 #
~~~
### Установим Nginx из стандартного репозитория:
~~~
root@otus-node-0 ~/1318020 # apt install nginx -y
~~~
Для запуска нескольких экземпляров сервиса модифицируем исходный service для использования различной конфигурации, а также PID-файлов. Для этого создадим новый Unit для работы с шаблонами (/etc/systemd/system/nginx@.service):
~~~
root@otus-node-0 ~ # vim /etc/systemd/system/nginx@.service
root@otus-node-0 ~ # cat /etc/systemd/system/nginx@.service
# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target

root@otus-node-0 ~ #
~~~
Далее необходимо создать два файла конфигурации (/etc/nginx/nginx-first.conf, /etc/nginx/nginx-second.conf). Их можно сформировать из стандартного конфига /etc/nginx/nginx.conf, с модификацией путей до PID-файлов и разделением по портам:
~~~
user www-data;
worker_processes auto;
pid /run/nginx-first.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

http {
        server {
            listen 9001;
        }
#include /etc/nginx/sites-enabled/*;
~~~
~~~
user www-data;
worker_processes auto;
pid /run/nginx-second.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

http {
        server {
             listen 9002;
        }
#include /etc/nginx/sites-enabled/*;
~~~
~~~
root@otus-node-0 ~ # cp /etc/nginx/nginx.conf /etc/nginx/nginx-first.conf
root@otus-node-0 ~ # cp /etc/nginx/nginx.conf /etc/nginx/nginx-second.conf
root@otus-node-0 ~ # vim /etc/nginx/nginx-first.conf
root@otus-node-0 ~ # vim /etc/nginx/nginx-second.conf
~~~
Этого достаточно для успешного запуска сервисов.
~~~
root@otus-node-0 ~ # systemctl daemon-reload
root@otus-node-0 ~ # systemctl start nginx@first
root@otus-node-0 ~ # systemctl start nginx@second
root@otus-node-0 ~ # systemctl status nginx@second
● nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-06-18 12:47:22 MSK; 8s ago
       Docs: man:nginx(8)
    Process: 33158 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-second.conf -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 33159 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 33160 (nginx)
      Tasks: 7 (limit: 9386)
     Memory: 4.7M
        CPU: 14ms
     CGroup: /system.slice/system-nginx.slice/nginx@second.service
             ├─33160 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;"
             ├─33161 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33162 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33163 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33164 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33165 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             └─33166 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >

Jun 18 12:47:22 otus-node-0 systemd[1]: Starting A high performance web server and a reverse proxy server...
Jun 18 12:47:22 otus-node-0 systemd[1]: Started A high performance web server and a reverse proxy server.
...skipping...
● nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-06-18 12:47:22 MSK; 8s ago
       Docs: man:nginx(8)
    Process: 33158 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-second.conf -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 33159 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 33160 (nginx)
      Tasks: 7 (limit: 9386)
     Memory: 4.7M
        CPU: 14ms
     CGroup: /system.slice/system-nginx.slice/nginx@second.service
             ├─33160 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;"
             ├─33161 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33162 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33163 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33164 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             ├─33165 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >
             └─33166 "nginx: worker process" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" >

Jun 18 12:47:22 otus-node-0 systemd[1]: Starting A high performance web server and a reverse proxy server...
Jun 18 12:47:22 otus-node-0 systemd[1]: Started A high performance web server and a reverse proxy server.
~~~
Проверить можно несколькими способами, например, посмотреть, какие порты слушаются:
~~~
root@otus-node-0 ~ # ss -tnulp | grep nginx
tcp   LISTEN 0      511             0.0.0.0:9002      0.0.0.0:*    users:(("nginx",pid=33166,fd=6),("nginx",pid=33165,fd=6),("nginx",pid=33164,fd=6),("nginx",pid=33163,fd=6),("nginx",pid=33162,fd=6),("nginx",pid=33161,fd=6),("nginx",pid=33160,fd=6))
tcp   LISTEN 0      511             0.0.0.0:9001      0.0.0.0:*    users:(("nginx",pid=33113,fd=6),("nginx",pid=33112,fd=6),("nginx",pid=33111,fd=6),("nginx",pid=33110,fd=6),("nginx",pid=33109,fd=6),("nginx",pid=33108,fd=6),("nginx",pid=33107,fd=6))
root@otus-node-0 ~ #
~~~
Или просмотреть список процессов:
~~~
root@otus-node-0 ~ # ps aux | grep nginx
root       33107  0.0  0.0  55096  1664 ?        Ss   12:47   0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on;
www-data   33108  0.0  0.0  55848  5752 ?        S    12:47   0:00 nginx: worker process
www-data   33109  0.0  0.0  55848  5752 ?        S    12:47   0:00 nginx: worker process
www-data   33110  0.0  0.0  55848  5752 ?        S    12:47   0:00 nginx: worker process
www-data   33111  0.0  0.0  55848  5752 ?        S    12:47   0:00 nginx: worker process
www-data   33112  0.0  0.0  55848  5752 ?        S    12:47   0:00 nginx: worker process
www-data   33113  0.0  0.0  55848  5752 ?        S    12:47   0:00 nginx: worker process
root       33160  0.0  0.0  10088   936 ?        Ss   12:47   0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;
www-data   33161  0.0  0.0  10832  3880 ?        S    12:47   0:00 nginx: worker process
www-data   33162  0.0  0.0  10832  3880 ?        S    12:47   0:00 nginx: worker process
www-data   33163  0.0  0.0  10832  3876 ?        S    12:47   0:00 nginx: worker process
www-data   33164  0.0  0.0  10832  3880 ?        S    12:47   0:00 nginx: worker process
www-data   33165  0.0  0.0  10832  3880 ?        S    12:47   0:00 nginx: worker process
www-data   33166  0.0  0.0  10832  3880 ?        S    12:47   0:00 nginx: worker process
root       33843  0.0  0.0   6480  2240 pts/0    S+   12:49   0:00 grep --color=auto nginx
~~~

Задание выполнено!





