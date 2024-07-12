# Lesson №13 - SELinux

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_13_SELinux
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

Для быстрого запуска окружения и работы использован Vagrant-стенд из файла Vagrantfile с образом almalinux/9.
Стенд протестирован на VirtualBox 7.0.14, Vagrant 2.4, хостовая система: Windows 11 Pro.

## Домашнее задание
Что нужно сделать?

1. Запустить nginx на нестандартном порту 3-мя разными способами:
переключатели setsebool;

добавление нестандартного порта в имеющийся тип;

формирование и установка модуля SELinux.


2. Обеспечить работоспособность приложения при включенном selinux.

развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;

выяснить причину неработоспособности механизма обновления зоны (см. README);

предложить решение (или решения) для данной проблемы;

выбрать одно из решений для реализации, предварительно обосновав выбор;

реализовать выбранное решение и продемонстрировать его работоспособность.

### Запустить nginx на нестандартном порту 3-мя разными способами:

Результатом выполнения команды vagrant up станет созданная виртуальная машина с установленным nginx, который работает на порту TCP 4881. Порт TCP 4881 уже проброшен до хоста. SELinux включен.

Во время развёртывания стенда попытка запустить nginx завершится с ошибкой:

~~~
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus\otus\lesson_13_SELinux> vagrant provision
==> otus-node-0: Running provisioner: shell...
    otus-node-0: Running: inline script
    otus-node-0: Extra Packages for Enterprise Linux 9 openh264  1.7 kB/s | 2.5 kB     00:01
    otus-node-0: Package epel-release-9-7.el9.noarch is already installed.
    otus-node-0: Package nginx-1:1.20.1-14.el9_2.1.alma.1.x86_64 is already installed.
    otus-node-0: Package vim-enhanced-2:8.2.2637-20.el9_1.x86_64 is already installed.
    otus-node-0: Dependencies resolved.
    otus-node-0: Nothing to do.
    otus-node-0: Complete!
    otus-node-0: Job for nginx.service failed because the control process exited with error code.
    otus-node-0: See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
The SSH command responded with a non-zero exit status. Vagrant
assumes that this means the command failed. The output for this command
should be in the log above. Please read the output to determine what
went wrong.
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus\otus\lesson_13_SELinux>
~~~
Данная ошибка появляется из-за того, что SELinux блокирует работу nginx на нестандартном порту.

Заходим на сервер по ssh

Дальнейшие действия выполняются от пользователя root.

1. Запуск nginx на нестандартном порту 3-мя разными способами 
Для начала проверим, что в ОС отключен файервол:
~~~
root@otus-node-0 ~ # systemctl status firewalld
○ firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; preset: enabled)
     Active: inactive (dead)
       Docs: man:firewalld(1)
root@otus-node-0 ~ #
~~~
Также можно проверить, что конфигурация nginx настроена без ошибок:
~~~
root@otus-node-0 ~ # nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
root@otus-node-0 ~ #
~~~
Далее проверим режим работы SELinux:
~~~
root@otus-node-0 ~ # getenforce
Enforcing
root@otus-node-0 ~ #
~~~
Должен отображаться режим Enforcing. Данный режим означает, что SELinux будет блокировать запрещенную активность.

Устанавливаем доп ПО для управления  SELinux
~~~
yum install -y setroubleshoot-server selinux-policy-mls setools-console policycoreutils-newrole
~~~

### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool

Находим в логах (/var/log/audit/audit.log) информацию о блокировании порта и, с помощью утилиты audit2why смотрим
~~~
root@otus-node-0 ~ # cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1720708975.947:617): avc:  denied  { open } for  pid=3147 comm="20-chrony-dhcp" path="/etc/sysconfig/network-scripts/ifcfg-eth1" dev="sda4" ino=16914497 scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=unconfined_u:object_r:user_tmp_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1720709815.570:1389): avc:  denied  { name_bind } for  pid=10772 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
root@otus-node-0 ~ #
~~~
Утилита audit2why покажет почему блокируется запуск NGINX. Исходя из вывода утилиты, мы видим, что нам нужно поменять параметр nis_enabled. 
Включим параметр nis_enabled и перезапустим nginx:
~~~
root@otus-node-0 ~ # setsebool -P nis_enabled 1
root@otus-node-0 ~ # systemctl restart nginx
root@otus-node-0 ~ # systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Fri 2024-07-12 09:39:52 MSK; 5s ago
    Process: 89859 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 89860 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 89861 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 89862 (nginx)
      Tasks: 7 (limit: 50168)
     Memory: 6.5M
        CPU: 52ms
     CGroup: /system.slice/nginx.service
             ├─89862 "nginx: master process /usr/sbin/nginx"
             ├─89863 "nginx: worker process"
             ├─89864 "nginx: worker process"
             ├─89865 "nginx: worker process"
             ├─89866 "nginx: worker process"
             ├─89867 "nginx: worker process"
             └─89868 "nginx: worker process"

Jul 12 09:39:52 otus-node-0.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 12 09:39:52 otus-node-0.local nginx[89860]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 12 09:39:52 otus-node-0.local nginx[89860]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jul 12 09:39:52 otus-node-0.local systemd[1]: Started The nginx HTTP and reverse proxy server.
root@otus-node-0 ~ #
~~~
Также можно проверить работу nginx из браузера, вводим IP виртуальной машины и порт 4881.
![alt text](image.png)

Проверить статус параметра можно с помощью команды:
~~~
root@otus-node-0 ~ # getsebool -a | grep nis_enabled
nis_enabled --> on
root@otus-node-0 ~ #
~~~
Вернём запрет работы nginx на порту 4881 обратно. Для этого отключим nis_enabled:
~~~
root@otus-node-0 ~ # setsebool -P nis_enabled 0
root@otus-node-0 ~ # getsebool -a | grep nis_enabled
nis_enabled --> off
root@otus-node-0 ~ #
~~~
После отключения nis_enabled служба nginx снова не запустится.
~~~
root@otus-node-0 ~ # systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
root@otus-node-0 ~ # systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Fri 2024-07-12 09:44:26 MSK; 2s ago
   Duration: 4min 34.521s
    Process: 91482 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 91483 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 25ms

Jul 12 09:44:26 otus-node-0.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 12 09:44:26 otus-node-0.local nginx[91483]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 12 09:44:26 otus-node-0.local nginx[91483]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Jul 12 09:44:26 otus-node-0.local nginx[91483]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jul 12 09:44:26 otus-node-0.local systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Jul 12 09:44:26 otus-node-0.local systemd[1]: nginx.service: Failed with result 'exit-code'.
Jul 12 09:44:26 otus-node-0.local systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
root@otus-node-0 ~ #
~~~
### Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:

Поиск имеющегося типа, для http трафика:
~~~
root@otus-node-0 ~ # semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
root@otus-node-0 ~ #
~~~
Добавим порт в тип http_port_t:
~~~
root@otus-node-0 ~ # semanage port -a -t http_port_t -p tcp 4881
root@otus-node-0 ~ # semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
root@otus-node-0 ~ #
~~~
Теперь перезапустим службу nginx и проверим её работу:
~~~
root@otus-node-0 ~ # systemctl restart nginx
root@otus-node-0 ~ # systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Fri 2024-07-12 09:49:07 MSK; 7s ago
    Process: 93140 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 93141 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 93142 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 93143 (nginx)
      Tasks: 7 (limit: 50168)
     Memory: 6.5M
        CPU: 41ms
     CGroup: /system.slice/nginx.service
             ├─93143 "nginx: master process /usr/sbin/nginx"
             ├─93144 "nginx: worker process"
             ├─93145 "nginx: worker process"
             ├─93146 "nginx: worker process"
             ├─93147 "nginx: worker process"
             ├─93148 "nginx: worker process"
             └─93149 "nginx: worker process"

Jul 12 09:49:06 otus-node-0.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 12 09:49:06 otus-node-0.local nginx[93141]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 12 09:49:06 otus-node-0.local nginx[93141]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jul 12 09:49:07 otus-node-0.local systemd[1]: Started The nginx HTTP and reverse proxy server.
root@otus-node-0 ~ #
~~~
Также можно проверить работу nginx из браузера
![alt text](image-1.png)
Удалить нестандартный порт из имеющегося типа можно с помощью команды:
~~~
root@otus-node-0 ~ # semanage port -d -t http_port_t -p tcp 4881
root@otus-node-0 ~ # semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
root@otus-node-0 ~ # systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
root@otus-node-0 ~ # systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Fri 2024-07-12 09:51:08 MSK; 6s ago
   Duration: 2min 1.591s
    Process: 93872 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 93873 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 19ms

Jul 12 09:51:08 otus-node-0.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 12 09:51:08 otus-node-0.local nginx[93873]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 12 09:51:08 otus-node-0.local nginx[93873]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Jul 12 09:51:08 otus-node-0.local nginx[93873]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jul 12 09:51:08 otus-node-0.local systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Jul 12 09:51:08 otus-node-0.local systemd[1]: nginx.service: Failed with result 'exit-code'.
Jul 12 09:51:08 otus-node-0.local systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
root@otus-node-0 ~ #
~~~
### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:

Посмотрим логи SELinux, которые относятся к nginx: 
~~~
root@otus-node-0 ~ # grep nginx /var/log/audit/audit.log
type=ADD_GROUP msg=audit(1720709533.664:1150): pid=6313 uid=0 auid=1000 ses=9 subj=unconfined_u:unconfined_r:groupadd_t:s0-s0:c0.c1023 msg='op=add-group id=989 exe="/usr/sbin/groupadd" hostname=? addr=? terminal=? res=success'UID="root" AUID="vagrant" ID="nginx"
type=GRP_MGMT msg=audit(1720709533.671:1151): pid=6313 uid=0 auid=1000 ses=9 subj=unconfined_u:unconfined_r:groupadd_t:s0-s0:c0.c1023 msg='op=add-shadow-group id=989 exe="/usr/sbin/groupadd" hostname=? addr=? terminal=? res=success'UID="root" AUID="vagrant" ID="nginx"
type=ADD_USER msg=audit(1720709533.779:1152): pid=6320 uid=0 auid=1000 ses=9 subj=unconfined_u:unconfined_r:useradd_t:s0-s0:c0.c1023 msg='op=add-user acct="nginx" exe="/usr/sbin/useradd" hostname=? addr=? terminal=? res=success'UID="root" AUID="vagrant"
type=SOFTWARE_UPDATE msg=audit(1720709534.248:1174): pid=6171 uid=0 auid=1000 ses=9 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='op=install sw="nginx-filesystem-1:1.20.1-14.el9_2.1.alma.1.noarch" sw_type=rpm key_enforce=0 gpg_res=1 root_dir="/" comm="yum" exe="/usr/bin/python3.9" hostname=? addr=? terminal=? res=success'UID="root" AUID="vagrant"
type=SOFTWARE_UPDATE msg=audit(1720709534.248:1175): pid=6171 uid=0 auid=1000 ses=9 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='op=install sw="nginx-core-1:1.20.1-14.el9_2.1.alma.1.x86_64" sw_type=rpm key_enforce=0 gpg_res=1 root_dir="/" comm="yum" exe="/usr/bin/python3.9" hostname=? addr=? terminal=? res=success'UID="root" AUID="vagrant"
type=SOFTWARE_UPDATE msg=audit(1720709534.248:1177): pid=6171 uid=0 auid=1000 ses=9 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 msg='op=install sw="nginx-1:1.20.1-14.el9_2.1.alma.1.x86_64" sw_type=rpm key_enforce=0 gpg_res=1 root_dir="/" comm="yum" exe="/usr/bin/python3.9" hostname=? addr=? terminal=? res=success'UID="root" AUID="vagrant"
type=AVC msg=audit(1720709815.570:1389): avc:  denied  { name_bind } for  pid=10772 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1720709815.570:1389): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55d00913e978 a2=10 a3=7ffc6de5fc30 items=0 ppid=1 pid=10772 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)ARCH=x86_64 SYSCALL=bind AUID="unset" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
type=SERVICE_START msg=audit(1720709815.573:1390): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'UID="root" AUID="unset"
type=SERVICE_START msg=audit(1720766392.371:1571): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'UID="root" AUID="unset"
type=SERVICE_STOP msg=audit(1720766666.931:1574): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'UID="root" AUID="unset"
type=AVC msg=audit(1720766666.962:1575): avc:  denied  { name_bind } for  pid=91483 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1720766666.962:1575): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55866eb1c978 a2=10 a3=7ffd2abc8620 items=0 ppid=1 pid=91483 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)ARCH=x86_64 SYSCALL=bind AUID="unset" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
type=SERVICE_START msg=audit(1720766666.963:1576): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'UID="root" AUID="unset"
type=SERVICE_START msg=audit(1720766947.003:1587): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'UID="root" AUID="unset"
type=SERVICE_STOP msg=audit(1720767068.641:1590): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'UID="root" AUID="unset"
type=AVC msg=audit(1720767068.675:1591): avc:  denied  { name_bind } for  pid=93873 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1720767068.675:1591): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=560c7a233978 a2=10 a3=7ffdf4e58940 items=0 ppid=1 pid=93873 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)ARCH=x86_64 SYSCALL=bind AUID="unset" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
type=SERVICE_START msg=audit(1720767068.683:1592): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'UID="root" AUID="unset"
root@otus-node-0 ~ #
~~~
Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном порту:
~~~
root@otus-node-0 ~ # grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

root@otus-node-0 ~ #
~~~
Audit2allow сформировал модуль, и сообщил нам команду, с помощью которой можно применить данный модуль:
~~~
root@otus-node-0 ~ # semodule -i nginx.pp
root@otus-node-0 ~ #
~~~
Попробуем снова запустить nginx:
~~~
root@otus-node-0 ~ # systemctl start nginx
root@otus-node-0 ~ # systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Fri 2024-07-12 09:55:42 MSK; 11s ago
    Process: 95495 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 95496 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 95497 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 95498 (nginx)
      Tasks: 7 (limit: 50168)
     Memory: 6.5M
        CPU: 45ms
     CGroup: /system.slice/nginx.service
             ├─95498 "nginx: master process /usr/sbin/nginx"
             ├─95499 "nginx: worker process"
             ├─95500 "nginx: worker process"
             ├─95501 "nginx: worker process"
             ├─95502 "nginx: worker process"
             ├─95503 "nginx: worker process"
             └─95504 "nginx: worker process"

Jul 12 09:55:42 otus-node-0.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 12 09:55:42 otus-node-0.local nginx[95496]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 12 09:55:42 otus-node-0.local nginx[95496]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jul 12 09:55:42 otus-node-0.local systemd[1]: Started The nginx HTTP and reverse proxy server.
root@otus-node-0 ~ #
~~~
После добавления модуля nginx запустился без ошибок. При использовании модуля изменения сохранятся после перезагрузки. 

Просмотр всех установленных модулей:
~~~
semodule -l
~~~
Для удаления модуля воспользуемся командой:
~~~
root@otus-node-0 ~ # semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
root@otus-node-0 ~ #
~~~
После удаления модуля NGINX снова не запускается:
~~~
root@otus-node-0 ~ # systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
root@otus-node-0 ~ # systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: failed (Result: exit-code) since Fri 2024-07-12 09:58:20 MSK; 3s ago
   Duration: 2min 37.950s
    Process: 96436 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 96437 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
        CPU: 16ms

Jul 12 09:58:20 otus-node-0.local systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 12 09:58:20 otus-node-0.local nginx[96437]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 12 09:58:20 otus-node-0.local nginx[96437]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Jul 12 09:58:20 otus-node-0.local nginx[96437]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jul 12 09:58:20 otus-node-0.local systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Jul 12 09:58:20 otus-node-0.local systemd[1]: nginx.service: Failed with result 'exit-code'.
Jul 12 09:58:20 otus-node-0.local systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
root@otus-node-0 ~ #
~~~

## Обеспечение работоспособности приложения при включенном SELinux

#### Для того, чтобы развернуть стенд потребуется хост, с установленным git и ansible.

## Для выполнения задания переделан исходный репозиторий для стенда, изменены образы вагрант боксов, сети, конфиги, плэйбук ансибл, все изменения добавлены в репозиторий домашнего задания, директория "selinux_dns_problems"

устанавливаем git и ansible:
~~~
yum install -y git ansible
~~~
Выполним клонирование репозитория:
~~~
  12/07/2024   10:06.38   /home/mobaxterm  git clone https://github.com/mbfx/otus-linux-adm.git
Клонирование в «otus-linux-adm»...
remote: Enumerating objects: 558, done.
remote: Counting objects: 100% (456/456), done.
remote: Compressing objects: 100% (303/303), done.
remote: Total 558 (delta 125), reused 396 (delta 74), pack-reused 102
Получение объектов: 100% (558/558), 1.38 МиБ | 2.68 МиБ/с, готово.
Определение изменений: 100% (140/140), готово.
                                                                                                                                                                                                        ✓

  12/07/2024   10:06.59   /home/mobaxterm  cd otus-linux-adm/
                                                                                                                                                                                                        ✓

  12/07/2024   10:07.07   /home/mobaxterm/otus-linux-adm   master 

~~~
 перейдем в директорию со стендом selinux_dns_problems
~~~
  12/07/2024   10:09.09   /home/mobaxterm/otus-linux-adm   master  cd selinux_dns_problems
                                                                                                                                                                                                        ✓

  12/07/2024   10:09.36   /home/mobaxterm/otus-linux-adm/selinux_dns_problems   master 
~~~
Развернём 2 ВМ с помощью vagrant: 
~~~
  12/07/2024   10:14.26   /home/mobaxterm/otus-linux-adm/selinux_dns_problems   master  vagrant up
Bringing machine 'ns01' up with 'virtualbox' provider...
Bringing machine 'client' up with 'virtualbox' provider...
==> ns01: Checking if box 'centos/7' version '1804.02' is up to date...
==> ns01: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> ns01: flag to force provisioning. Provisioners marked to run always will still run.
==> client: Importing base box 'centos/7'...
==> client: Matching MAC address for NAT networking...
==> client: Checking if box 'centos/7' version '1804.02' is up to date...
==> client: Setting the name of the VM: selinux_dns_problems_client_1720768590246_20425
==> client: Fixed port collision for 22 => 2222. Now on port 2201.
==> client: Clearing any previously set network interfaces...
==> client: Preparing network interfaces based on configuration...
    client: Adapter 1: nat
    client: Adapter 2: intnet
==> client: Forwarding ports...
    client: 22 (guest) => 2201 (host) (adapter 1)
==> client: Running 'pre-boot' VM customizations...
==> client: Booting VM...
==> client: Waiting for machine to boot. This may take a few minutes...
    client: SSH address: 127.0.0.1:2201
    client: SSH username: vagrant
    client: SSH auth method: private key
    client: Warning: Connection reset. Retrying...
    client: Warning: Connection aborted. Retrying...
    client: Warning: Connection aborted. Retrying...
    client: Warning: Connection aborted. Retrying...
    client:
    client: Vagrant insecure key detected. Vagrant will automatically replace
    client: this with a newly generated keypair for better security.
    client:
    client: Inserting generated public key within guest...
    client: Removing insecure key from the guest if it's present...
    client: Key inserted! Disconnecting and reconnecting using new SSH key...
==> client: Machine booted and ready!
==> client: Checking for guest additions in VM...
    client: No guest additions were detected on the base box for this VM! Guest
    client: additions are required for forwarded ports, shared folders, host only
    client: networking, and more. If SSH fails on this machine, please install
    client: the guest additions and repackage the box to continue.
    client:
    client: This is not an error message; everything may continue to work properly,
    client: in which case you may ignore this message.
==> client: Setting hostname...
==> client: Configuring and enabling network interfaces...
==> client: Rsyncing folder: /cygdrive/c/Users/levitskyav/Documents/MobaXterm/home/otus-linux-adm/selinux_dns_problems/ => /vagrant
==> client: Running provisioner: ansible...
Windows is not officially supported for the Ansible Control Machine.
Please check https://docs.ansible.com/intro_installation.html#control-machine-requirements

Vagrant gathered an unknown Ansible version:


and falls back on the compatibility mode '1.8'.

Alternatively, the compatibility mode can be specified in your Vagrantfile:
https://www.vagrantup.com/docs/provisioning/ansible_common.html#compatibility_mode

    client: Running ansible-playbook...
The Ansible software could not be found! Please verify
that Ansible is correctly installed on your host system.

If you haven't installed Ansible yet, please install Ansible
on your host system. Vagrant can't do this for you in a safe and
automated way.
Please check https://docs.ansible.com for more information.
                                                                                                                                                                                                        ✗

  12/07/2024   10:17.33   /home/mobaxterm/otus-linux-adm/selinux_dns_problems   master  vagrant status
Current machine states:

ns01                      running (virtualbox)
client                    running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
                                                                                                                                                                                                        ✓

  12/07/2024   10:18.49   /home/mobaxterm/otus-linux-adm/selinux_dns_problems   master 
~~~
Так как хост Windows 11 не отработали плэйбуки ansible, нужно выполнить их вручную. Удаляем стенд vagrant destroy -f.
Меняем в Vagrantfie сети ВМ на нужные нам, меняем образ с неподдерживаемой centos/7 на almalinux/9
~~~
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "almalinux/9"

  config.vm.provision "ansible" do |ansible|
    #ansible.verbose = "vvv"
    ansible.playbook = "provisioning/playbook.yml"
    ansible.become = "true"
  end

  config.vm.provider "virtualbox" do |v|
	  v.memory = 2048
  end

  config.vm.define "ns01" do |ns01|
    ns01.vm.network "public_network", ip: "172.22.23.106", netmask: "255.255.252.0"
    ns01.vm.hostname = "ns01"
  end

  config.vm.define "client" do |client|
    client.vm.network "public_network", ip: "172.22.23.107", netmask: "255.255.252.0"
    client.vm.hostname = "client"
  end

end
~~~
Создаем стенд заново
~~~
vagrant up
~~~
Заходим на вм стенда и добавляем ключ для авторизации:
~~~
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus-linux-adm\selinux_dns_problems>  vagrant ssh ns01
[vagrant@ns01 ~]$ sudo -i
[root@ns01 ~]# ll
total 16
-rw-------. 1 root root 5763 May 12  2018 anaconda-ks.cfg
-rw-------. 1 root root 5432 May 12  2018 original-ks.cfg
[root@ns01 ~]# ls -la
total 36
dr-xr-x---.  2 root root  137 May 12  2018 .
dr-xr-xr-x. 18 root root  239 Jul 12 07:29 ..
-rw-------.  1 root root 5763 May 12  2018 anaconda-ks.cfg
-rw-r--r--.  1 root root   18 Dec 29  2013 .bash_logout
-rw-r--r--.  1 root root  176 Dec 29  2013 .bash_profile
-rw-r--r--.  1 root root  176 Dec 29  2013 .bashrc
-rw-r--r--.  1 root root  100 Dec 29  2013 .cshrc
-rw-------.  1 root root 5432 May 12  2018 original-ks.cfg
-rw-r--r--.  1 root root  129 Dec 29  2013 .tcshrc
[root@ns01 ~]# mkdir .ssh
[root@ns01 ~]# vim .ssh/authorized_keys
-bash: vim: command not found
[root@ns01 ~]# vi .ssh/authorized_keys
[root@ns01 ~]# chmod 600 .ssh/authorized_keys
[root@ns01 ~]# logout
[vagrant@ns01 ~]$ logout
Connection to 127.0.0.1 closed.
~~~

Дорабытываем плэйбук для выполнения на двух хостах стенда, вносим исапрвления, в устанавливаемых пакетах ошибки, ПО уже не поддерживается. Меняем пакет ntp yf chrony, меняем пакет policycoreutils-python на policycoreutils-python-utils. Меняем IP адесаци в конфигурационных файлах для нашего стенда. Добавляем свою приватную часть ключа в ansible_root_key.

запускаем плейбук:
~~~
  12/07/2024   11:44.08   /home/mobaxterm/otus-linux-adm/selinux_dns_problems/provisioning   master  ansible-playbook playbook.yml

PLAY [all] **********************************************************************************************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************************************************************************
ok: [ns01]
ok: [client]

TASK [install packages] *********************************************************************************************************************************************************************************
changed: [client]
changed: [ns01]

PLAY [ns01] *********************************************************************************************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************************************************************************
ok: [ns01]

TASK [copy named.conf] **********************************************************************************************************************************************************************************
changed: [ns01]

TASK [copy master zone dns.lab] *************************************************************************************************************************************************************************
changed: [ns01] => (item=/drives/c/Users/levitskyav/Documents/MobaXterm/home/otus-linux-adm/selinux_dns_problems/provisioning/files/ns01/named.dns.lab)
changed: [ns01] => (item=/drives/c/Users/levitskyav/Documents/MobaXterm/home/otus-linux-adm/selinux_dns_problems/provisioning/files/ns01/named.dns.lab.view1)

TASK [copy dynamic zone ddns.lab] ***********************************************************************************************************************************************************************
changed: [ns01]

TASK [copy dynamic zone ddns.lab.view1] *****************************************************************************************************************************************************************
changed: [ns01]

TASK [copy master zone newdns.lab] **********************************************************************************************************************************************************************
changed: [ns01]

TASK [copy rev zones] ***********************************************************************************************************************************************************************************
changed: [ns01]

TASK [copy resolv.conf to server] ***********************************************************************************************************************************************************************
changed: [ns01]

TASK [copy transferkey to server] ***********************************************************************************************************************************************************************
changed: [ns01]

TASK [set /etc/named permissions] ***********************************************************************************************************************************************************************
changed: [ns01]

TASK [set /etc/named/dynamic permissions] ***************************************************************************************************************************************************************
changed: [ns01]

TASK [ensure named is running and enabled] **************************************************************************************************************************************************************
changed: [ns01]

PLAY [client] *******************************************************************************************************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************************************************************************************************
ok: [client]

TASK [copy resolv.conf to the client] *******************************************************************************************************************************************************************
changed: [client]

TASK [copy rndc conf file] ******************************************************************************************************************************************************************************
changed: [client]

TASK [copy motd to the client] **************************************************************************************************************************************************************************
changed: [client]

TASK [copy transferkey to client] ***********************************************************************************************************************************************************************
changed: [client]

PLAY RECAP **********************************************************************************************************************************************************************************************
client                     : ok=7    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
ns01                       : ok=14   changed=12   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

                                                                                                                                                                                                        ✓

  12/07/2024   11:54.25   /home/mobaxterm/otus-linux-adm/selinux_dns_problems/provisioning   master 
~~~

Подключимся к клиенту: vagrant ssh client
~~~
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus-linux-adm\selinux_dns_problems> vagrant ssh client
###############################
### Welcome to the DNS lab! ###
###############################

- Use this client to test the enviroment
- with dig or nslookup. Ex:
    dig @192.168.50.10 ns01.dns.lab

- nsupdate is available in the ddns.lab zone. Ex:
    nsupdate -k /etc/named.zonetransfer.key
    server 192.168.50.10
    zone ddns.lab
    update add www.ddns.lab. 60 A 192.168.50.15
    send

- rndc is also available to manage the servers
    rndc -c ~/rndc.conf reload

###############################
### Enjoy! ####################
###############################
Last login: Fri Jul 12 08:07:09 2024 from 10.0.2.2
~~~
Попробуем внести изменения в зону: nsupdate -k /etc/named.zonetransfer.key
~~~
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
>
>
> ^C[vagrant@client ~]$
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 172.22.23.106
> zone ddns.lab
> update add www.ddns.lab. 60 A 172.22.23.107
> send
update failed: SERVFAIL
> q
incorrect section name: q
> quit
[vagrant@client ~]$
~~~
Изменения внести не получилось. Давайте посмотрим логи SELinux, чтобы понять в чём может быть проблема.

Для этого воспользуемся утилитой audit2why:
~~~
[vagrant@client ~]$ sudo -i
[root@client ~]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1720771384.198:605): avc:  denied  { open } for  pid=2991 comm="20-chrony-dhcp" path="/etc/sysconfig/network-scripts/ifcfg-eth1" dev="sda4" ino=16914497 scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=unconfined_u:object_r:user_tmp_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1720771385.906:641): avc:  denied  { open } for  pid=3150 comm="20-chrony-dhcp" path="/etc/sysconfig/network-scripts/ifcfg-eth1" dev="sda4" ino=16914497 scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=unconfined_u:object_r:user_tmp_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

[root@client ~]#
~~~
тут мы видим, что интересующие нас ошибки отсутствуют

Не закрывая сессию на клиенте, подключимся к серверу ns01 и проверим логи SELinux:
~~~
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus-linux-adm\selinux_dns_problems> vagrant ssh ns01
Last login: Fri Jul 12 08:04:09 2024 from 10.0.2.2
[vagrant@ns01 ~]$ sudo -i
[root@ns01 ~]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1720771235.652:606): avc:  denied  { open } for  pid=2998 comm="20-chrony-dhcp" path="/etc/sysconfig/network-scripts/ifcfg-eth1" dev="sda4" ino=16914496 scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=unconfined_u:object_r:user_tmp_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1720771235.947:615): avc:  denied  { open } for  pid=3047 comm="20-chrony-dhcp" path="/etc/sysconfig/network-scripts/ifcfg-eth1" dev="sda4" ino=16914496 scontext=system_u:system_r:NetworkManager_dispatcher_chronyc_t:s0 tcontext=unconfined_u:object_r:user_tmp_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

type=AVC msg=audit(1720775870.277:10619): avc:  denied  { write } for  pid=33445 comm="isc-net-0000" name="dynamic" dev="sda4" ino=740118 scontext=system_u:system_r:named_t:s0 tcontext=unconfined_u:object_r:named_conf_t:s0 tclass=dir permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.

[root@ns01 ~]#
~~~
В логах мы видим, что ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t.

Проверим данную проблему в каталоге /etc/named:
~~~
[root@ns01 ~]# ls -laZ /etc/named
total 28
drw-rwx---.   3 root named system_u:object_r:named_conf_t:s0      120 Jul 12 09:13 .
drwxr-xr-x. 101 root root  system_u:object_r:etc_t:s0            8192 Jul 12 09:09 ..
drw-rwx---.   2 root named unconfined_u:object_r:named_conf_t:s0   56 Jul 12 09:10 dynamic
-rw-rw----.   1 root named system_u:object_r:named_conf_t:s0      782 Jul 12 09:13 named.20.22.172.rev
-rw-rw----.   1 root named system_u:object_r:named_conf_t:s0      610 Jul 12 09:09 named.dns.lab
-rw-rw----.   1 root named system_u:object_r:named_conf_t:s0      609 Jul 12 09:09 named.dns.lab.view1
-rw-rw----.   1 root named system_u:object_r:named_conf_t:s0      657 Jul 12 09:10 named.newdns.lab
[root@ns01 ~]#
~~~
Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге. Посмотреть в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux можно с помощью команды: semanage fcontext -l | grep named

~~~
[root@ns01 ~]# semanage fcontext -l | grep named
/dev/gpmdata                                       named pipe         system_u:object_r:gpmctl_t:s0
/dev/initctl                                       named pipe         system_u:object_r:initctl_t:s0
/dev/xconsole                                      named pipe         system_u:object_r:xconsole_device_t:s0
/dev/xen/tapctrl.*                                 named pipe         system_u:object_r:xenctl_t:s0
/etc/named(/.*)?                                   all files          system_u:object_r:named_conf_t:s0
/etc/named\.caching-nameserver\.conf               regular file       system_u:object_r:named_conf_t:s0
/etc/named\.conf                                   regular file       system_u:object_r:named_conf_t:s0
/etc/named\.rfc1912.zones                          regular file       system_u:object_r:named_conf_t:s0
/etc/named\.root\.hints                            regular file       system_u:object_r:named_conf_t:s0
/etc/rc\.d/init\.d/named                           regular file       system_u:object_r:named_initrc_exec_t:s0
/etc/rc\.d/init\.d/named-sdb                       regular file       system_u:object_r:named_initrc_exec_t:s0
/etc/rc\.d/init\.d/unbound                         regular file       system_u:object_r:named_initrc_exec_t:s0
/etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0
/etc/unbound(/.*)?                                 all files          system_u:object_r:named_conf_t:s0
/usr/lib/systemd/system/named-sdb.*                regular file       system_u:object_r:named_unit_file_t:s0
/usr/lib/systemd/system/named.*                    regular file       system_u:object_r:named_unit_file_t:s0
/usr/lib/systemd/system/unbound.*                  regular file       system_u:object_r:named_unit_file_t:s0
/usr/lib/systemd/systemd-hostnamed                 regular file       system_u:object_r:systemd_hostnamed_exec_t:s0
/usr/sbin/lwresd                                   regular file       system_u:object_r:named_exec_t:s0
/usr/sbin/named                                    regular file       system_u:object_r:named_exec_t:s0
/usr/sbin/named-checkconf                          regular file       system_u:object_r:named_checkconf_exec_t:s0
/usr/sbin/named-pkcs11                             regular file       system_u:object_r:named_exec_t:s0
/usr/sbin/named-sdb                                regular file       system_u:object_r:named_exec_t:s0
/usr/sbin/unbound                                  regular file       system_u:object_r:named_exec_t:s0
/usr/sbin/unbound-anchor                           regular file       system_u:object_r:named_exec_t:s0
/usr/sbin/unbound-checkconf                        regular file       system_u:object_r:named_exec_t:s0
/usr/sbin/unbound-control                          regular file       system_u:object_r:named_exec_t:s0
/usr/share/munin/plugins/named                     regular file       system_u:object_r:services_munin_plugin_exec_t:s0
/var/lib/softhsm(/.*)?                             all files          system_u:object_r:named_cache_t:s0
/var/lib/unbound(/.*)?                             all files          system_u:object_r:named_cache_t:s0
/var/log/named.*                                   regular file       system_u:object_r:named_log_t:s0
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0
/var/named/chroot(/.*)?                            all files          system_u:object_r:named_conf_t:s0
/var/named/chroot/dev                              directory          system_u:object_r:device_t:s0
/var/named/chroot/dev/log                          socket             system_u:object_r:devlog_t:s0
/var/named/chroot/dev/null                         character device   system_u:object_r:null_device_t:s0
/var/named/chroot/dev/random                       character device   system_u:object_r:random_device_t:s0
/var/named/chroot/dev/urandom                      character device   system_u:object_r:urandom_device_t:s0
/var/named/chroot/dev/zero                         character device   system_u:object_r:zero_device_t:s0
/var/named/chroot/etc(/.*)?                        all files          system_u:object_r:etc_t:s0
/var/named/chroot/etc/localtime                    regular file       system_u:object_r:locale_t:s0
/var/named/chroot/etc/named\.caching-nameserver\.conf regular file       system_u:object_r:named_conf_t:s0
/var/named/chroot/etc/named\.conf                  regular file       system_u:object_r:named_conf_t:s0
/var/named/chroot/etc/named\.rfc1912.zones         regular file       system_u:object_r:named_conf_t:s0
/var/named/chroot/etc/named\.root\.hints           regular file       system_u:object_r:named_conf_t:s0
/var/named/chroot/etc/pki(/.*)?                    all files          system_u:object_r:cert_t:s0
/var/named/chroot/etc/rndc\.key                    regular file       system_u:object_r:dnssec_t:s0
/var/named/chroot/lib(/.*)?                        all files          system_u:object_r:lib_t:s0
/var/named/chroot/proc(/.*)?                       all files          <<None>>
/var/named/chroot/run/named.*                      all files          system_u:object_r:named_var_run_t:s0
/var/named/chroot/usr/lib(/.*)?                    all files          system_u:object_r:lib_t:s0
/var/named/chroot/var/log                          directory          system_u:object_r:var_log_t:s0
/var/named/chroot/var/log/named.*                  regular file       system_u:object_r:named_log_t:s0
/var/named/chroot/var/named(/.*)?                  all files          system_u:object_r:named_zone_t:s0
/var/named/chroot/var/named/data(/.*)?             all files          system_u:object_r:named_cache_t:s0
/var/named/chroot/var/named/dynamic(/.*)?          all files          system_u:object_r:named_cache_t:s0
/var/named/chroot/var/named/named\.ca              regular file       system_u:object_r:named_conf_t:s0
/var/named/chroot/var/named/slaves(/.*)?           all files          system_u:object_r:named_cache_t:s0
/var/named/chroot/var/run/dbus(/.*)?               all files          system_u:object_r:system_dbusd_var_run_t:s0
/var/named/chroot/var/run/named.*                  all files          system_u:object_r:named_var_run_t:s0
/var/named/chroot/var/tmp(/.*)?                    all files          system_u:object_r:named_cache_t:s0
/var/named/chroot_sdb/dev                          directory          system_u:object_r:device_t:s0
/var/named/chroot_sdb/dev/null                     character device   system_u:object_r:null_device_t:s0
/var/named/chroot_sdb/dev/random                   character device   system_u:object_r:random_device_t:s0
/var/named/chroot_sdb/dev/urandom                  character device   system_u:object_r:urandom_device_t:s0
/var/named/chroot_sdb/dev/zero                     character device   system_u:object_r:zero_device_t:s0
/var/named/data(/.*)?                              all files          system_u:object_r:named_cache_t:s0
/var/named/dynamic(/.*)?                           all files          system_u:object_r:named_cache_t:s0
/var/named/named\.ca                               regular file       system_u:object_r:named_conf_t:s0
/var/named/slaves(/.*)?                            all files          system_u:object_r:named_cache_t:s0
/var/run/bind(/.*)?                                all files          system_u:object_r:named_var_run_t:s0
/var/run/ecblp0                                    named pipe         system_u:object_r:cupsd_var_run_t:s0
/var/run/initctl                                   named pipe         system_u:object_r:initctl_t:s0
/var/run/named(/.*)?                               all files          system_u:object_r:named_var_run_t:s0
/var/run/ndc                                       socket             system_u:object_r:named_var_run_t:s0
/var/run/systemd/initctl/fifo                      named pipe         system_u:object_r:initctl_t:s0
/var/run/unbound(/.*)?                             all files          system_u:object_r:named_var_run_t:s0
/var/named/chroot/usr/lib64 = /usr/lib
/var/named/chroot/lib64 = /usr/lib
/var/named/chroot/var = /var
[root@ns01 ~]#
~~~
Изменим тип контекста безопасности для каталога /etc/named: chcon -R -t named_zone_t /etc/named
~~~
[root@ns01 ~]# chcon -R -t named_zone_t /etc/named
[root@ns01 ~]#
[root@ns01 ~]#
[root@ns01 ~]# ls -laZ /etc/named
total 28
drw-rwx---.   3 root named system_u:object_r:named_zone_t:s0      120 Jul 12 09:13 .
drwxr-xr-x. 101 root root  system_u:object_r:etc_t:s0            8192 Jul 12 09:09 ..
drw-rwx---.   2 root named unconfined_u:object_r:named_zone_t:s0   56 Jul 12 09:10 dynamic
-rw-rw----.   1 root named system_u:object_r:named_zone_t:s0      782 Jul 12 09:13 named.20.22.172.rev
-rw-rw----.   1 root named system_u:object_r:named_zone_t:s0      610 Jul 12 09:09 named.dns.lab
-rw-rw----.   1 root named system_u:object_r:named_zone_t:s0      609 Jul 12 09:09 named.dns.lab.view1
-rw-rw----.   1 root named system_u:object_r:named_zone_t:s0      657 Jul 12 09:10 named.newdns.lab
[root@ns01 ~]#
~~~
Попробуем снова внести изменения с клиента: 
~~~
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 172.22.23.106
> zone ddns.lab
> update add www.ddns.lab. 60 A 172.22.23.107
> send
> quit
[vagrant@client ~]$
~~~
~~~
[vagrant@client ~]$ dig www.ddns.lab

; <<>> DiG 9.16.23-RH <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 9023
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 766aec4e12a0b163010000006690fb1d9589435c69e97dad (good)
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       172.22.23.107

;; Query time: 4 msec
;; SERVER: 172.22.23.106#53(172.22.23.106)
;; WHEN: Fri Jul 12 09:45:01 UTC 2024
;; MSG SIZE  rcvd: 85

[vagrant@client ~]$
~~~
Видим, что изменения применились. Попробуем перезагрузить хосты и ещё раз сделать запрос с помощью dig:
~~~
[vagrant@client ~]$ sudo reboot
[vagrant@client ~]$ Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus-linux-adm\selinux_dns_problems>
~~~
~~~
[vagrant@ns01 ~]$ sudo reboot
[vagrant@ns01 ~]$ Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
PS C:\Users\levitskyav\Documents\MobaXterm\home\otus-linux-adm\selinux_dns_problems>
~~~
~~~
[vagrant@client ~]$ dig @172.22.23.106 www.ddns.lab

; <<>> DiG 9.16.23-RH <<>> @172.22.23.106 www.ddns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 26721
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: b78bc472b1f2f206010000006690fc38b9f7058fea5b75e3 (good)
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       172.22.23.107

;; Query time: 2 msec
;; SERVER: 172.22.23.106#53(172.22.23.106)
;; WHEN: Fri Jul 12 09:49:44 UTC 2024
;; MSG SIZE  rcvd: 85

[vagrant@client ~]$
~~~
Всё правильно. После перезагрузки настройки сохранились. 

Всё правильно. После перезагрузки настройки сохранились. 
Для того, чтобы вернуть правила обратно, можно ввести команду: restorecon -v -R /etc/named


