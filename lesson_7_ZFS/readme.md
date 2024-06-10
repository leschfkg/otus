# Lesson №7 - ZFS

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_7_ZFS
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

### ZFS - Определение алгоритма с наилучшим сжатием
Смотрим список всех дисков, которые есть в виртуальной машине:
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0   62M  1 loop /snap/core20/1587
loop1                       7:1    0 63.9M  1 loop /snap/core20/2318
loop2                       7:2    0 79.9M  1 loop /snap/lxd/22923
loop3                       7:3    0   87M  1 loop /snap/lxd/28373
loop4                       7:4    0 38.8M  1 loop /snap/snapd/21759
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0  125G  0 lvm  /
sdb                         8:16   0   20G  0 disk
sdc                         8:32   0   20G  0 disk
sdd                         8:48   0   20G  0 disk
sde                         8:64   0   20G  0 disk
sdf                         8:80   0   20G  0 disk
sdg                         8:96   0   20G  0 disk
sdh                         8:112  0   20G  0 disk
sdi                         8:128  0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Создаём пул из двух дисков в режиме RAID 1:
~~~
root@otus-node-0 ~ # zpool create otus1 mirror sdb sdc
root@otus-node-0 ~ # zpool status
  pool: otus1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors
root@otus-node-0 ~ #
~~~
Создадим ещё 3 пула:
~~~
root@otus-node-0 ~ # zpool create otus2 mirror sdd sde
root@otus-node-0 ~ # zpool create otus3 mirror sdf sdg
root@otus-node-0 ~ # zpool create otus4 mirror sdh sdi
~~~
Смотрим информацию о пулах:
~~~
root@otus-node-0 ~ # zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1  19.5G   111K  19.5G        -         -     0%     0%  1.00x    ONLINE  -
otus2  19.5G   105K  19.5G        -         -     0%     0%  1.00x    ONLINE  -
otus3  19.5G   106K  19.5G        -         -     0%     0%  1.00x    ONLINE  -
otus4  19.5G   106K  19.5G        -         -     0%     0%  1.00x    ONLINE  -
root@otus-node-0 ~ #
~~~
Добавим разные алгоритмы сжатия в каждую файловую систему:

Алгоритм lzjb
~~~
root@otus-node-0 ~ # zfs set compression=lzjb otus1
root@otus-node-0 ~ #
~~~
Алгоритм lz4
~~~
root@otus-node-0 ~ # zfs set compression=lz4 otus2
root@otus-node-0 ~ #
~~~
Алгоритм gzip
~~~
root@otus-node-0 ~ # zfs set compression=gzip-9 otus3
root@otus-node-0 ~ #
~~~
Алгоритм zle
~~~
root@otus-node-0 ~ # zfs set compression=zle otus4
root@otus-node-0 ~ #
~~~
Проверим, что все файловые системы имеют разные методы сжатия:
~~~
root@otus-node-0 ~ # zfs get compression
NAME   PROPERTY     VALUE           SOURCE
otus1  compression  lzjb            local
otus2  compression  lz4             local
otus3  compression  gzip-9          local
otus4  compression  zle             local
root@otus-node-0 ~ #
~~~
Сжатие файлов будет работать только с файлами, которые были добавлены после включение настройки сжатия. 

Скачаем один и тот же текстовый файл во все пулы: 
~~~
root@otus-node-0 ~ # for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2024-06-07 16:34:15--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41052631 (39M) [text/plain]
Saving to: ‘/otus1/pg2600.converter.log’

pg2600.converter.log                                100%[==================================================================================================================>]  39.15M   902KB/s    in 18s

2024-06-07 16:34:34 (2.22 MB/s) - ‘/otus1/pg2600.converter.log’ saved [41052631/41052631]

--2024-06-07 16:34:34--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41052631 (39M) [text/plain]
Saving to: ‘/otus2/pg2600.converter.log’

pg2600.converter.log                                100%[==================================================================================================================>]  39.15M  2.91MB/s    in 13s

2024-06-07 16:34:47 (3.03 MB/s) - ‘/otus2/pg2600.converter.log’ saved [41052631/41052631]

--2024-06-07 16:34:47--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41052631 (39M) [text/plain]
Saving to: ‘/otus3/pg2600.converter.log’

pg2600.converter.log                                100%[==================================================================================================================>]  39.15M  3.43MB/s    in 13s

2024-06-07 16:35:01 (2.94 MB/s) - ‘/otus3/pg2600.converter.log’ saved [41052631/41052631]

--2024-06-07 16:35:01--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 41052631 (39M) [text/plain]
Saving to: ‘/otus4/pg2600.converter.log’

pg2600.converter.log                                100%[==================================================================================================================>]  39.15M  3.20MB/s    in 15s

2024-06-07 16:35:17 (2.68 MB/s) - ‘/otus4/pg2600.converter.log’ saved [41052631/41052631]

root@otus-node-0 ~ #
~~~
Проверим, что файл был скачан во все пулы:
~~~
root@otus-node-0 ~ # ls -lah /otus*
/otus1:
total 22M
drwxr-xr-x  2 root root    3 Jun  7 16:34 .
drwxr-xr-x 24 root root 4.0K Jun  7 16:28 ..
-rw-r--r--  1 root root  40M Jun  2 11:03 pg2600.converter.log

/otus2:
total 18M
drwxr-xr-x  2 root root    3 Jun  7 16:34 .
drwxr-xr-x 24 root root 4.0K Jun  7 16:28 ..
-rw-r--r--  1 root root  40M Jun  2 11:03 pg2600.converter.log

/otus3:
total 11M
drwxr-xr-x  2 root root    3 Jun  7 16:34 .
drwxr-xr-x 24 root root 4.0K Jun  7 16:28 ..
-rw-r--r--  1 root root  40M Jun  2 11:03 pg2600.converter.log

/otus4:
total 40M
drwxr-xr-x  2 root root    3 Jun  7 16:35 .
drwxr-xr-x 24 root root 4.0K Jun  7 16:28 ..
-rw-r--r--  1 root root  40M Jun  2 11:03 pg2600.converter.log
root@otus-node-0 ~ #
~~~
Уже на этом этапе видно, что самый оптимальный метод сжатия у нас используется в пуле otus3.
Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:
~~~
root@otus-node-0 ~ # zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.7M  18.9G     21.6M  /otus1
otus2  17.7M  18.9G     17.6M  /otus2
otus3  10.9M  18.9G     10.7M  /otus3
otus4  39.3M  18.9G     39.2M  /otus4
root@otus-node-0 ~ #

root@otus-node-0 ~ # zfs get compressratio
NAME   PROPERTY       VALUE  SOURCE
otus1  compressratio  1.82x  -
otus2  compressratio  2.23x  -
otus3  compressratio  3.65x  -
otus4  compressratio  1.00x  -
root@otus-node-0 ~ #
~~~
Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.

### Определение настроек пула
Скачиваем архив в домашний каталог:
~~~
root@otus-node-0 ~ # wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
--2024-06-10 09:18:24--  https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download
Resolving drive.usercontent.google.com (drive.usercontent.google.com)... 74.125.205.132, 2a00:1450:4026:805::2001
Connecting to drive.usercontent.google.com (drive.usercontent.google.com)|74.125.205.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/octet-stream]
Saving to: ‘archive.tar.gz’

archive.tar.gz                                      100%[==================================================================================================================>]   6.94M  6.41MB/s    in 1.1s

2024-06-10 09:18:34 (6.41 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]

root@otus-node-0 ~ #
~~~
Разархивируем его:
~~~
root@otus-node-0 ~ # tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
root@otus-node-0 ~ #
~~~
Проверим, возможно ли импортировать данный каталог в пул:
~~~
root@otus-node-0 ~ # zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE
root@otus-node-0 ~ #
~~~
Данный вывод показывает нам имя пула, тип raid и его состав. 

Сделаем импорт данного пула к нам в ОС:
~~~
root@otus-node-0 ~ # zpool import -d zpoolexport/ otus
root@otus-node-0 ~ # zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
~~~
Далее нам нужно определить настройки: zpool get all otus
~~~
root@otus-node-0 ~ # zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      15250001514331317249           -
otus  autotrim                       off                            default
otus  compatibility                  off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local
otus  feature@redaction_bookmarks    disabled                       local
otus  feature@redacted_datasets      disabled                       local
otus  feature@bookmark_written       disabled                       local
otus  feature@log_spacemap           disabled                       local
otus  feature@livelist               disabled                       local
otus  feature@device_rebuild         disabled                       local
otus  feature@zstd_compress          disabled                       local
otus  feature@draid                  disabled                       local
root@otus-node-0 ~ #
~~~
C помощью параметра get можно уточнить конкретный параметр, например:
~~~
root@otus-node-0 ~ # zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
root@otus-node-0 ~ # zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
root@otus-node-0 ~ # zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
root@otus-node-0 ~ # zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
root@otus-node-0 ~ # zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
root@otus-node-0 ~ #
~~~
### Работа со снапшотом, поиск сообщения от преподавателя
Скачаем файл, указанный в задании:
~~~
root@otus-node-0 ~ # wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
root@otus-node-0 ~ #
~~~
Восстановим файловую систему из снапшота:
~~~
root@otus-node-0 ~ # zfs receive otus/test@today < otus_task2.file
root@otus-node-0 ~ #
~~~
Далее, ищем в каталоге /otus/test файл с именем “secret_message”:
~~~
root@otus-node-0 ~ # find /otus/test -name "secret_message" /otus/test/task1/file_mess/secret_message
find: paths must precede expression: `/otus/test/task1/file_mess/secret_message'
find: possible unquoted pattern after predicate `-name'?
root@otus-node-0 ~ #
~~~
Смотрим содержимое найденного файла:
~~~
root@otus-node-0 ~ # cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/

root@otus-node-0 ~ #
~~~
Тут мы видим ссылку на курс OTUS, задание выполнено.




