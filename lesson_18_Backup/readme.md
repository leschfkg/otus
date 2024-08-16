# Lesson №18 - Backup

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_18_Backup
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

1. Настроить стенд Vagrant с двумя виртуальными машинами: otus-node-0 и otus-node-1.

2.  Настроить удаленный бекап каталога /etc c сервера otus-node-1 при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:

* директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
* репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
* имя бекапа должно содержать информацию о времени снятия бекапа;
* глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех.
Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
* резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
* написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
* настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.

Запустите стенд на 30 минут.

Убедитесь что резервные копии снимаются.

Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа.


## Тестовый стенд:
* otus-node-0 172.22.23.105 Ubuntu 22.04
* otus-node-1 172.22.23.106 Ubuntu 22.04

Устанавливаем на машины borgbackup
~~~
root@otus-node-0 ~ # apt install borgbackup
~~~
~~~
root@otus-node-1 ~ # apt install borgbackup
~~~
На сервере otus-node-0 создаем пользователя и каталог /var/backup и назначаем на него права пользователя borg
~~~
root@otus-node-0 ~ # useradd -s /bin/bash -m -d /home/borg/ borg
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # mkdir /var/backup
root@otus-node-0 ~ # chown borg:borg /var/backup/
root@otus-node-0 ~ #
~~~
На сервер otus-node-0 создаем каталог ~/.ssh/authorized_keys в каталоге /home/borg
~~~
root@otus-node-0 ~ # su - borg
borg@otus-node-0:~$ mkdir .ssh
borg@otus-node-0:~$ touch .ssh/authorized_keys
borg@otus-node-0:~$ chmod 700 .ssh
borg@otus-node-0:~$ chmod 600 .ssh/authorized_keys
borg@otus-node-0:~$
~~~
На сервере otus-node-1:
~~~
root@otus-node-1 ~ # ssh-keygen -t ed25519
Generating public/private ed25519 key pair.
Enter file in which to save the key (/root/.ssh/id_ed25519):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:lBdBlaK8LI1FHZtFkIgNycMcDvGqlfdjtR072bnYhpY root@otus-node-1
The key's randomart image is:
+--[ED25519 256]--+
|    o=o* +*B+.   |
|     +B +.+=.    |
|      o+o.+.     |
|     o .+.       |
|    + .=S.. .    |
|   o .o.+. o = . |
|  .    .+ . =oo  |
|       . .  E+.. |
|           ...o  |
+----[SHA256]-----+
root@otus-node-1 ~ # ll .ssh/
total 20
drwx------ 2 root root 4096 Aug 16 14:28 .
drwx------ 5 root root 4096 Aug 16 14:15 ..
-rw------- 1 root root   93 Aug 16 13:21 authorized_keys
-rw------- 1 root root  411 Aug 16 14:28 id_ed25519
-rw-r--r-- 1 root root   98 Aug 16 14:28 id_ed25519.pub
root@otus-node-1 ~ #
~~~
Пробрасываем бобличную часть ключа id_ed25519.pub на сервер otus-node-0 в файл .ssh/authorized_keys пользователя borg

Все дальнейшие действия будут проходить на  сервере otus-node-1.
Инициализируем репозиторий borg на otus-node-0 сервере с otus-node-1 сервера:
~~~
root@otus-node-1 ~ # borg init --encryption=repokey borg@172.22.23.105:/var/backup/
The authenticity of host '172.22.23.105 (172.22.23.105)' can't be established.
ED25519 key fingerprint is SHA256:aY1Cjtv3k7J5rjHb2sFB4MNOfsFl4jIkf1swPyeSq+I.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Remote: Warning: Permanently added '172.22.23.105' (ED25519) to the list of known hosts.
Enter new passphrase:
Enter same passphrase again:
Do you want your passphrase to be displayed for verification? [yN]: n

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://borg@172.22.23.105/var/backup

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
If you used a repokey mode, the key is stored in the repo, but you should back it up separately.
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).

root@otus-node-1 ~ #
~~~
Запускаем для проверки создания бэкапа
~~~
root@otus-node-1 ~ # borg create --stats --list borg@172.22.23.105:/var/backup/::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc
Enter passphrase for key ssh://borg@172.22.23.105/var/backup:
~~~
видим, что бэкап выполнился
~~~
------------------------------------------------------------------------------
Repository: ssh://borg@172.22.23.105/var/backup
Archive name: etc-2024-08-16_14:36:37
Archive fingerprint: 3529fe634cb9b5feaa4a6706db812ea79ded6327abed99ed26602b17b2401fec
Time (start): Fri, 2024-08-16 14:36:47
Time (end):   Fri, 2024-08-16 14:36:48
Duration: 1.57 seconds
Number of files: 808
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:                2.27 MB              1.02 MB            992.65 kB
All archives:                2.27 MB              1.02 MB              1.07 MB

                       Unique chunks         Total chunks
Chunk index:                     769                  798
------------------------------------------------------------------------------
root@otus-node-1 ~ #
~~~
Смотрим, что у нас получилось
~~~
root@otus-node-1 ~ # borg list borg@172.22.23.105:/var/backup/
Enter passphrase for key ssh://borg@172.22.23.105/var/backup:
etc-2024-08-16_14:36:37              Fri, 2024-08-16 14:36:47 [3529fe634cb9b5feaa4a6706db812ea79ded6327abed99ed26602b17b2401fec]
root@otus-node-1 ~ #
~~~
 Смотрим список файлов
~~~
root@otus-node-1 ~ # borg list borg@172.22.23.105:/var/backup/::etc-2024-08-16_14:36:37
Enter passphrase for key ssh://borg@172.22.23.105/var/backup:
drwxr-xr-x root   root          0 Fri, 2024-08-16 14:16:40 etc
drwxr-xr-x root   root          0 Wed, 2022-10-05 10:21:13 etc/apt
-rw-r--r-- root   root       2403 Tue, 2022-08-09 14:57:11 etc/apt/sources.list.curtin.old
-rw-r--r-- root   root       2437 Wed, 2022-10-05 10:21:13 etc/apt/sources.list
drwxr-xr-x root   root          0 Fri, 2024-08-16 13:17:49 etc/apt/apt.conf.d
-rw-r--r-- root   root        129 Thu, 2020-11-26 13:34:42 etc/apt/apt.conf.d/10periodic
-rw-r--r-- root   root        108 Thu, 2020-11-26 13:34:42 etc/apt/apt.conf.d/15update-stamp
-rw-r--r-- root   root         85 Thu, 2020-11-26 13:34:42 etc/apt/apt.conf.d/20archive
-rw-r--r-- root   root        625 Wed, 2021-12-08 13:53:19 etc/apt/apt.conf.d/50command-not-found
-rw-r--r-- root   root        305 Thu, 2020-11-26 13:34:42 etc/apt/apt.conf.d/99update-notifier
-rw-r--r-- root   root         92 Fri, 2022-04-08 13:22:23 etc/apt/apt.conf.d/01-vendor-ubuntu
-rw-r--r-- root   root        630 Fri, 2022-04-08 13:22:23 etc/apt/apt.conf.d/01autoremove
-rw-r--r-- root   root         80 Wed, 2022-10-05 10:45:37 etc/apt/apt.conf.d/20auto-upgrades
.....
~~~
Достаем файл из бекапа
~~~
root@otus-node-1 ~ # borg extract borg@172.22.23.105:/var/backup/::etc-2024-08-16_14:36:37 /etc/hostname
Enter passphrase for key ssh://borg@172.22.23.105/var/backup:
root@otus-node-1 ~ #
~~~
Автоматизируем создание бэкапов с помощью systemd
Создаем сервис и таймер в каталоге /etc/systemd/system/
~~~
root@otus-node-1 ~ # vim /etc/systemd/system/borg-backup.service
~~~
~~~
[Unit]
Description=Borg Backup

[Service]
Type=oneshot

# Парольная фраза
Environment="BORG_PASSPHRASE=07041982"
# Репозиторий
Environment=REPO=borg@172.22.23.105:/var/backup/
# Что бэкапим
Environment=BACKUP_TARGET=/etc

# Создание бэкапа
ExecStart=/bin/borg create \
    --stats                \
    ${REPO}::etc-{now:%%Y-%%m-%%d_%%H:%%M:%%S} ${BACKUP_TARGET}

# Проверка бэкапа
ExecStart=/bin/borg check ${REPO}

# Очистка старых бэкапов
ExecStart=/bin/borg prune \
    --keep-daily  90      \
    --keep-monthly 12     \
    --keep-yearly  1       \
    ${REPO}
~~~
~~~
root@otus-node-1 ~ # vim /etc/systemd/system/borg-backup.timer
~~~
~~~
[Unit]
Description=Borg Backup

[Timer]
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
~~~
Включаем и запускаем службу таймера
~~~
root@otus-node-1 ~ # systemctl enable --now borg-backup.timer
Created symlink /etc/systemd/system/timers.target.wants/borg-backup.timer → /etc/systemd/system/borg-backup.timer.
root@otus-node-1 ~ #
~~~
Проверяем работу таймера
~~~
root@otus-node-1 ~ # systemctl list-timers --all
NEXT                        LEFT           LAST                        PASSED               UNIT                           ACTIVATES
Fri 2024-08-16 17:31:10 MSK 2h 42min left  Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago apt-daily.timer                apt-daily.service
Fri 2024-08-16 21:41:39 MSK 6h left        Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago motd-news.timer                motd-news.service
Sat 2024-08-17 00:00:00 MSK 9h left        n/a                         n/a                  dpkg-db-backup.timer           dpkg-db-backup.service
Sat 2024-08-17 00:00:00 MSK 9h left        Fri 2024-08-16 13:09:59 MSK 1h 38min ago         logrotate.timer                logrotate.service
Sat 2024-08-17 00:24:32 MSK 9h left        Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago fwupd-refresh.timer            fwupd-refresh.service
Sat 2024-08-17 06:06:16 MSK 15h left       Fri 2024-08-16 13:16:56 MSK 1h 31min ago         apt-daily-upgrade.timer        apt-daily-upgrade.service
Sat 2024-08-17 06:49:31 MSK 16h left       Fri 2024-08-16 13:17:00 MSK 1h 31min ago         man-db.timer                   man-db.service
Sat 2024-08-17 14:17:40 MSK 23h left       Fri 2024-08-16 14:17:40 MSK 31min ago            update-notifier-download.timer update-notifier-download.service
Sat 2024-08-17 14:27:40 MSK 23h left       Fri 2024-08-16 14:27:40 MSK 21min ago            systemd-tmpfiles-clean.timer   systemd-tmpfiles-clean.service
Sun 2024-08-18 03:10:57 MSK 1 day 12h left Fri 2024-08-16 13:11:01 MSK 1h 37min ago         e2scrub_all.timer              e2scrub_all.service
Mon 2024-08-19 00:05:29 MSK 2 days left    Fri 2024-08-16 13:15:34 MSK 1h 33min ago         fstrim.timer                   fstrim.service
Wed 2024-08-21 10:08:17 MSK 4 days left    Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago update-notifier-motd.timer     update-notifier-motd.service
n/a                         n/a            n/a                         n/a                  apport-autoreport.timer        apport-autoreport.service
n/a                         n/a            n/a                         n/a                  borg-backup.timer              borg-backup.service
n/a                         n/a            n/a                         n/a                  snapd.snap-repair.timer        snapd.snap-repair.service
n/a                         n/a            n/a                         n/a                  ua-timer.timer                 ua-timer.service

16 timers listed.
root@otus-node-1 ~ #
~~~
Оставляем стенд запущенным на 30 мин для проверки работы

При проверке обнаружилось, что задание не работало пока не запустил службу, а не только таймер
~~~
systemctl start borg-backup.service
root@otus-node-1 ~ # journalctl -u borg-backup.service
Aug 16 15:01:49 otus-node-1 systemd[1]: Starting Borg Backup...
Aug 16 15:01:51 otus-node-1 borg[15801]: ------------------------------------------------------------------------------
Aug 16 15:01:51 otus-node-1 borg[15801]: Repository: ssh://borg@172.22.23.105/var/backup
Aug 16 15:01:51 otus-node-1 borg[15801]: Archive name: etc-2024-08-16_15:01:50
Aug 16 15:01:51 otus-node-1 borg[15801]: Archive fingerprint: 14ecb0f61c7c902a069f1ecc6d94068c8d73f4a474730402a3896e88aabfec4f
Aug 16 15:01:51 otus-node-1 borg[15801]: Time (start): Fri, 2024-08-16 15:01:51
Aug 16 15:01:51 otus-node-1 borg[15801]: Time (end):   Fri, 2024-08-16 15:01:51
Aug 16 15:01:51 otus-node-1 borg[15801]: Duration: 0.13 seconds
Aug 16 15:01:51 otus-node-1 borg[15801]: Number of files: 810
Aug 16 15:01:51 otus-node-1 borg[15801]: Utilization of max. archive size: 0%
Aug 16 15:01:51 otus-node-1 borg[15801]: ------------------------------------------------------------------------------
Aug 16 15:01:51 otus-node-1 borg[15801]:                        Original size      Compressed size    Deduplicated size
Aug 16 15:01:51 otus-node-1 borg[15801]: This archive:                2.27 MB              1.02 MB              1.31 kB
Aug 16 15:01:51 otus-node-1 borg[15801]: All archives:                4.54 MB              2.04 MB              1.11 MB
Aug 16 15:01:51 otus-node-1 borg[15801]:                        Unique chunks         Total chunks
Aug 16 15:01:51 otus-node-1 borg[15801]: Chunk index:                     773                 1598
Aug 16 15:01:51 otus-node-1 borg[15801]: ------------------------------------------------------------------------------
Aug 16 15:01:52 otus-node-1 systemd[1]: borg-backup.service: Deactivated successfully.
Aug 16 15:01:52 otus-node-1 systemd[1]: Finished Borg Backup.
Aug 16 15:01:52 otus-node-1 systemd[1]: borg-backup.service: Consumed 1.009s CPU time.
root@otus-node-1 ~ # systemctl list-timers --all
NEXT                        LEFT           LAST                        PASSED               UNIT                           ACTIVATES
Fri 2024-08-16 15:06:49 MSK 4min 38s left  n/a                         n/a                  borg-backup.timer              borg-backup.service
Fri 2024-08-16 20:46:45 MSK 5h 44min left  Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago apt-daily.timer                apt-daily.service
Fri 2024-08-16 22:34:49 MSK 7h left        Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago motd-news.timer                motd-news.service
Sat 2024-08-17 00:00:00 MSK 8h left        n/a                         n/a                  dpkg-db-backup.timer           dpkg-db-backup.service
Sat 2024-08-17 00:00:00 MSK 8h left        Fri 2024-08-16 13:09:59 MSK 1h 52min ago         logrotate.timer                logrotate.service
Sat 2024-08-17 00:36:28 MSK 9h left        Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago fwupd-refresh.timer            fwupd-refresh.service
Sat 2024-08-17 05:44:50 MSK 14h left       Fri 2024-08-16 13:17:00 MSK 1h 45min ago         man-db.timer                   man-db.service
Sat 2024-08-17 06:08:06 MSK 15h left       Fri 2024-08-16 13:16:56 MSK 1h 45min ago         apt-daily-upgrade.timer        apt-daily-upgrade.service
Sat 2024-08-17 14:17:40 MSK 23h left       Fri 2024-08-16 14:17:40 MSK 44min ago            update-notifier-download.timer update-notifier-download.service
Sat 2024-08-17 14:27:40 MSK 23h left       Fri 2024-08-16 14:27:40 MSK 34min ago            systemd-tmpfiles-clean.timer   systemd-tmpfiles-clean.service
Sun 2024-08-18 03:10:00 MSK 1 day 12h left Fri 2024-08-16 13:11:01 MSK 1h 51min ago         e2scrub_all.timer              e2scrub_all.service
Mon 2024-08-19 01:17:55 MSK 2 days left    Fri 2024-08-16 13:15:34 MSK 1h 46min ago         fstrim.timer                   fstrim.service
Mon 2024-08-19 03:47:36 MSK 2 days left    Wed 2022-10-05 10:30:11 MSK 1 year 10 months ago update-notifier-motd.timer     update-notifier-motd.service
n/a                         n/a            n/a                         n/a                  apport-autoreport.timer        apport-autoreport.service
n/a                         n/a            n/a                         n/a                  snapd.snap-repair.timer        snapd.snap-repair.service
n/a                         n/a            n/a                         n/a                  ua-timer.timer                 ua-timer.service

16 timers listed.
root@otus-node-1 ~ #
~~~
Убедимся, что резервные копии снимаются по расписанию.
~~~
root@otus-node-1 ~ # borg list borg@172.22.23.105:/var/backup/
Enter passphrase for key ssh://borg@172.22.23.105/var/backup:
etc-2024-08-16_14:36:37              Fri, 2024-08-16 14:36:47 [3529fe634cb9b5feaa4a6706db812ea79ded6327abed99ed26602b17b2401fec]
etc-2024-08-16_15:28:12              Fri, 2024-08-16 15:28:13 [036be455112239a8bf6ce4670387db1e34ba90f7e60fb92f415cff6ff2674972]
root@otus-node-1 ~ #
~~~
Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа.
~~~
root@otus-node-1 ~ # systemctl stop borg-backup.timer
root@otus-node-1 ~ # systemctl stop borg-backup.service
root@otus-node-1 ~ # systemctl status borg-backup.timer
○ borg-backup.timer - Borg Backup
     Loaded: loaded (/etc/systemd/system/borg-backup.timer; enabled; vendor preset: enabled)
     Active: inactive (dead) since Fri 2024-08-16 15:31:21 MSK; 22s ago
    Trigger: n/a
   Triggers: ● borg-backup.service

Aug 16 14:48:25 otus-node-1 systemd[1]: Started Borg Backup.
Aug 16 15:31:21 otus-node-1 systemd[1]: borg-backup.timer: Deactivated successfully.
Aug 16 15:31:21 otus-node-1 systemd[1]: Stopped Borg Backup.
root@otus-node-1 ~ # systemctl status borg-backup.service
○ borg-backup.service - Borg Backup
     Loaded: loaded (/etc/systemd/system/borg-backup.service; static)
     Active: inactive (dead) since Fri 2024-08-16 15:28:15 MSK; 3min 34s ago
TriggeredBy: ○ borg-backup.timer
    Process: 25085 ExecStart=/bin/borg create --stats ${REPO}::etc-{now:%Y-%m-%d_%H:%M:%S} ${BACKUP_TARGET} (code=exited, status=0/SUCCESS)
    Process: 25093 ExecStart=/bin/borg check ${REPO} (code=exited, status=0/SUCCESS)
    Process: 25101 ExecStart=/bin/borg prune --keep-daily 90 --keep-monthly 12 --keep-yearly 1 ${REPO} (code=exited, status=0/SUCCESS)
   Main PID: 25101 (code=exited, status=0/SUCCESS)
        CPU: 1.040s

Aug 16 15:28:13 otus-node-1 borg[25085]: ------------------------------------------------------------------------------
Aug 16 15:28:13 otus-node-1 borg[25085]:                        Original size      Compressed size    Deduplicated size
Aug 16 15:28:13 otus-node-1 borg[25085]: This archive:                2.27 MB              1.02 MB                646 B
Aug 16 15:28:13 otus-node-1 borg[25085]: All archives:                6.81 MB              3.06 MB              1.11 MB
Aug 16 15:28:13 otus-node-1 borg[25085]:                        Unique chunks         Total chunks
Aug 16 15:28:13 otus-node-1 borg[25085]: Chunk index:                     774                 2398
Aug 16 15:28:13 otus-node-1 borg[25085]: ------------------------------------------------------------------------------
Aug 16 15:28:15 otus-node-1 systemd[1]: borg-backup.service: Deactivated successfully.
Aug 16 15:28:15 otus-node-1 systemd[1]: Finished Borg Backup.
Aug 16 15:28:15 otus-node-1 systemd[1]: borg-backup.service: Consumed 1.040s CPU time.
root@otus-node-1 ~ #
~~~
Удаляем директорию /etc
~~~
root@otus-node-1 ~ # rm -rf /etc/
root@otus-node-1 ~ # ll /
total 4019280
drwxr-xr-x  19    0    0       4096 Aug 16 12:32 .
drwxr-xr-x  19    0    0       4096 Aug 16 12:32 ..
lrwxrwxrwx   1    0    0          7 Aug  9  2022 bin -> usr/bin
drwxr-xr-x   4    0    0       4096 Aug 16 10:20 boot
drwxr-xr-x  19    0    0       4040 Aug 16 11:12 dev
drwxr-xr-x   3    0    0       4096 Oct  5  2022 home
lrwxrwxrwx   1    0    0          7 Aug  9  2022 lib -> usr/lib
lrwxrwxrwx   1    0    0          9 Aug  9  2022 lib32 -> usr/lib32
lrwxrwxrwx   1    0    0          9 Aug  9  2022 lib64 -> usr/lib64
lrwxrwxrwx   1    0    0         10 Aug  9  2022 libx32 -> usr/libx32
drwx------   2    0    0      16384 Oct  5  2022 lost+found
drwxr-xr-x   2    0    0       4096 Oct  5  2022 media
drwxr-xr-x   2    0    0       4096 Aug  9  2022 mnt
drwxr-xr-x   3    0    0       4096 Oct  5  2022 opt
dr-xr-xr-x 211    0    0          0 Aug 16 11:12 proc
drwx------   7    0    0       4096 Aug 16 12:31 root
drwxr-xr-x  30    0    0        880 Aug 16 11:16 run
lrwxrwxrwx   1    0    0          8 Aug  9  2022 sbin -> usr/sbin
drwxr-xr-x   6    0    0       4096 Aug  9  2022 snap
drwxr-xr-x   2    0    0       4096 Aug  9  2022 srv
-rw-------   1    0    0 4115660800 Oct  5  2022 swap.img
dr-xr-xr-x  13    0    0          0 Aug 16 11:12 sys
drwxrwxrwt  11    0    0       4096 Aug 16 12:30 tmp
drwxr-xr-x  14    0    0       4096 Aug  9  2022 usr
drwxrwxrwx   1 1000 1000       4096 Aug 16 09:00 vagrant
-rw-r--r--   1    0    0       3424 Oct  5  2022 VagrantBox.txt
drwxr-xr-x  13    0    0       4096 Aug  9  2022 var
root@otus-node-1 ~ #
~~~
Восстанавливаем данные из бэкапа
~~~
root@otus-node-1 ~ # borg extract borg@172.22.23.105:/var/backup/::etc-2024-08-16_15:28:12 /etc/
Enter passphrase for key ssh://borg@172.22.23.105/var/backup:
root@otus-node-1 ~ #
~~~
Задание выполнено!.






