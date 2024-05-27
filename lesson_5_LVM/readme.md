# Lesson №4 - LVM

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_5_LVM
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

### LVM - начало работы
~~~
lsblk
~~~
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0 79.9M  1 loop /snap/lxd/22923
loop1                       7:1    0   47M  1 loop /snap/snapd/16292
loop2                       7:2    0   62M  1 loop /snap/core20/1587
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0  125G  0 lvm  /
sdb                         8:16   0   20G  0 disk
sdc                         8:32   0   20G  0 disk
sdd                         8:48   0   20G  0 disk
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
На выделенных дисках будем экспериментировать. Диски sdb, sdc будем использовать для базовых вещей и снапшотов. На дисках sdd,sde создадим lvm mirror.

Для начала разметим диск для будущего использования LVM - создадим PV:
~~~
root@otus-node-0 ~ # pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
root@otus-node-0 ~ #
~~~
Затем можно создавать первый уровень абстракции - VG:
~~~
root@otus-node-0 ~ # vgcreate otus /dev/sdb
  Volume group "otus" successfully created
root@otus-node-0 ~ #
~~~
И в итоге создать Logical Volume (далее - LV):
~~~
root@otus-node-0 ~ #  lvcreate -l+80%FREE -n test otus
  Logical volume "test" created.
root@otus-node-0 ~ #
~~~
Посмотреть информацию о только что созданном Volume Group:
~~~
root@otus-node-0 ~ # vgdisplay otus
  --- Volume group ---
  VG Name               otus
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <20.00 GiB
  PE Size               4.00 MiB
  Total PE              5119
  Alloc PE / Size       4095 / <16.00 GiB
  Free  PE / Size       1024 / 4.00 GiB
  VG UUID               NmIq1m-llwi-GzBG-s1jr-YRZ1-y4ZV-yZcHyg

root@otus-node-0 ~ #
~~~
Детальную информацию о LV получим командой:
~~~
root@otus-node-0 ~ # lvdisplay /dev/otus/test
  --- Logical volume ---
  LV Path                /dev/otus/test
  LV Name                test
  VG Name                otus
  LV UUID                m8Pb1w-ckab-6po8-X1Ko-CklQ-hSft-dl4oIT
  LV Write Access        read/write
  LV Creation host, time otus-node-0, 2024-05-24 13:03:09 +0300
  LV Status              available
  # open                 0
  LV Size                <16.00 GiB
  Current LE             4095
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:1

root@otus-node-0 ~ #
~~~
В сжатом виде информацию можно получить командами vgs и lvs:
~~~
root@otus-node-0 ~ # vgs
  VG        #PV #LV #SN Attr   VSize    VFree
  otus        1   1   0 wz--n-  <20.00g 4.00g
  ubuntu-vg   1   1   0 wz--n- <125.00g    0
root@otus-node-0 ~ # lvs
  LV        VG        Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test      otus      -wi-a-----  <16.00g
  ubuntu-lv ubuntu-vg -wi-ao---- <125.00g
root@otus-node-0 ~ #
~~~
Создадим на LV файловую систему и смонтируем его
~~~
root@otus-node-0 ~ # mkfs.ext4 /dev/otus/test
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 4193280 4k blocks and 1048576 inodes
Filesystem UUID: 445fa07d-585f-498a-8e53-7549311dee97
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # mkdir /data
root@otus-node-0 ~ # mount /dev/otus/test /data/
root@otus-node-0 ~ # mount | grep /data
/dev/mapper/otus-test on /data type ext4 (rw,relatime)
root@otus-node-0 ~ #
~~~
### Расширение LVM

Для начала так же необходимо создать PV:
~~~
root@otus-node-0 ~ # pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
root@otus-node-0 ~ #
~~~
Далее необходимо расширить VG добавив в него этот диск.
~~~
root@otus-node-0 ~ #  vgextend otus /dev/sdc
  Volume group "otus" successfully extended
root@otus-node-0 ~ #
~~~
Убедимся что новый диск присутствует в новой VG:
~~~
root@otus-node-0 ~ # vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb
  PV Name               /dev/sdc
root@otus-node-0 ~ #
~~~
И что места в VG прибавилось:
~~~
root@otus-node-0 ~ # vgs
  VG        #PV #LV #SN Attr   VSize    VFree
  otus        2   1   0 wz--n-   39.99g <24.00g
  ubuntu-vg   1   1   0 wz--n- <125.00g      0
root@otus-node-0 ~ #
~~~
Сымитируем занятое место с помощью команды dd для большей наглядности:
~~~
root@otus-node-0 ~ #  dd if=/dev/zero of=/data/test.log bs=1M count=17000 status=progress
16550723584 bytes (17 GB, 15 GiB) copied, 20 s, 828 MB/s
dd: error writing '/data/test.log': No space left on device
15999+0 records in
15998+0 records out
16775692288 bytes (17 GB, 16 GiB) copied, 20.3993 s, 822 MB/s
~~~
Теперь у нас занято 100% дискового пространства:
~~~
root@otus-node-0 ~ # df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              198M  6.0M  192M   4% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  123G  6.9G  110G   6% /
tmpfs                              988M     0  988M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  128M  1.7G   7% /boot
vagrant                            223G  198G   25G  89% /vagrant
tmpfs                              198M  4.0K  198M   1% /run/user/0
/dev/mapper/otus-test               16G   16G     0 100% /data
~~~
Увеличиваем LV за счет появившегося свободного места. 
~~~
root@otus-node-0 ~ # lvextend -l+80%FREE /dev/otus/test
  Size of logical volume otus/test changed from <16.00 GiB (4095 extents) to <35.20 GiB (9010 extents).
  Logical volume otus/test successfully resized.
root@otus-node-0 ~ #
~~~
Проверяем, что LV расширен
~~~
root@otus-node-0 ~ # lvs /dev/otus/test
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- <35.20g
root@otus-node-0 ~ #
~~~
Но файловая система при этом осталась прежнего размера
~~~
root@otus-node-0 ~ # df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              198M  6.0M  192M   4% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  123G  6.9G  110G   6% /
tmpfs                              988M     0  988M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  128M  1.7G   7% /boot
vagrant                            223G  198G   25G  89% /vagrant
tmpfs                              198M  4.0K  198M   1% /run/user/0
/dev/mapper/otus-test               16G   16G     0 100% /data
root@otus-node-0 ~ #
~~~
Произведем расширение файловой системы:
~~~
root@otus-node-0 ~ # resize2fs /dev/otus/test
resize2fs 1.46.5 (30-Dec-2021)
Filesystem at /dev/otus/test is mounted on /data; on-line resizing required
old_desc_blocks = 2, new_desc_blocks = 5
The filesystem on /dev/otus/test is now 9226240 (4k) blocks long.

root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              198M  6.0M  192M   4% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  123G  6.9G  110G   6% /
tmpfs                              988M     0  988M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  128M  1.7G   7% /boot
vagrant                            223G  198G   25G  89% /vagrant
tmpfs                              198M  4.0K  198M   1% /run/user/0
/dev/mapper/otus-test               35G   16G   18G  48% /data
root@otus-node-0 ~ #
~~~
Допустим нам нужно уменьшить логический том. Можно уменьшить существующий LV с помощью команды lvreduce, но перед этим необходимо отмонтировать файловую систему, проверить её на ошибки и уменьшить ее размер:
~~~
 umount /data/
~~~
~~~
root@otus-node-0 ~ # e2fsck -fy /dev/otus/test
e2fsck 1.46.5 (30-Dec-2021)
Pass 1: Checking inodes, blocks, and sizes
Inode 12 extent tree (at level 2) could be narrower.  Optimize? yes

Pass 1E: Optimizing extent trees
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information

/dev/otus/test: ***** FILE SYSTEM WAS MODIFIED *****
/dev/otus/test: 12/2310144 files (0.0% non-contiguous), 4269291/9226240 blocks
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # resize2fs /dev/otus/test 20G
resize2fs 1.46.5 (30-Dec-2021)
Resizing the filesystem on /dev/otus/test to 5242880 (4k) blocks.
The filesystem on /dev/otus/test is now 5242880 (4k) blocks long.

root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # lvreduce /dev/otus/test -L 20G
  WARNING: Reducing active logical volume to 20.00 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/test? [y/n]: y
  Size of logical volume otus/test changed from <35.20 GiB (9010 extents) to 20.00 GiB (5120 extents).
  Logical volume otus/test successfully resized.
root@otus-node-0 ~ #
~~~
~~~
mount /dev/otus/test /data/
~~~
Убедимся, что ФС и lvm необходимого размера:
~~~
root@otus-node-0 ~ # df -h /data/
Filesystem             Size  Used Avail Use% Mounted on
/dev/mapper/otus-test   20G   16G  3.1G  84% /data
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ #  lvs /dev/otus/test
  LV   VG   Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- 20.00g
root@otus-node-0 ~ #
~~~

### Работа со снапшотами

Снапшот создается командой lvcreate, только с флагом -s, который указывает на то, что это снимок:
~~~
root@otus-node-0 ~ # lvcreate -L 10G -s -n test-snap /dev/otus/test
  Logical volume "test-snap" created.
root@otus-node-0 ~ #
~~~
Проверим с помощью vgs:
~~~
root@otus-node-0 ~ # vgs -o +lv_size,lv_name | grep test
  otus        2   2   1 wz--n-   39.99g 9.99g   20.00g test
  otus        2   2   1 wz--n-   39.99g 9.99g   10.00g test-snap
root@otus-node-0 ~ #
~~~
Команда lsblk, например, нам наглядно покажет, что произошло:
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0 79.9M  1 loop /snap/lxd/22923
loop1                       7:1    0   47M  1 loop /snap/snapd/16292
loop2                       7:2    0   62M  1 loop /snap/core20/1587
loop3                       7:3    0 63.9M  1 loop /snap/core20/2318
loop4                       7:4    0   87M  1 loop /snap/lxd/28373
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0  125G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─otus-test-real          253:2    0   20G  0 lvm
  ├─otus-test             253:1    0   20G  0 lvm  /data
  └─otus-test--snap       253:4    0   20G  0 lvm
sdc                         8:32   0   20G  0 disk
├─otus-test-real          253:2    0   20G  0 lvm
│ ├─otus-test             253:1    0   20G  0 lvm  /data
│ └─otus-test--snap       253:4    0   20G  0 lvm
└─otus-test--snap-cow     253:3    0   10G  0 lvm
  └─otus-test--snap       253:4    0   20G  0 lvm
sdd                         8:48   0   20G  0 disk
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Здесь otus-test-real — оригинальный LV, otus-test--snap — снапшот, а otus-test--snap-cow — copy-on-write, сюда пишутся изменения.

Снапшот можно смонтировать как и любой другой LV:
~~~
root@otus-node-0 ~ # mkdir /data-snap
root@otus-node-0 ~ # mount /dev/otus/test-snap /data-snap/
root@otus-node-0 ~ # ll /data-snap/
total 16382540
drwxr-xr-x  3 root root        4096 May 24 13:53 .
drwxr-xr-x 22 root root        4096 May 24 14:10 ..
drwx------  2 root root       16384 May 24 13:07 lost+found
-rw-r--r--  1 root root 16775692288 May 24 13:53 test.log
root@otus-node-0 ~ # umount /data-snap
root@otus-node-0 ~ #
~~~
Можно также восстановить предыдущее состояние. “Откатиться” на снапшот. Для этого сначала для большей наглядности удалим наш log файл:
~~~
root@otus-node-0 ~ # rm /data/test.log
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # ll /data
total 24
drwxr-xr-x  3 root root  4096 May 24 14:14 .
drwxr-xr-x 22 root root  4096 May 24 14:10 ..
drwx------  2 root root 16384 May 24 13:07 lost+found
root@otus-node-0 ~ #
~~~
Размонтируем том для восстановления данных:
~~~
root@otus-node-0 ~ # umount /data
root@otus-node-0 ~ #
~~~
Проверим, что в статусе LV стройка # open c 1 изменилась на 0 и том не используеся:
~~~
root@otus-node-0 ~ # lvdisplay /dev/otus/test
  --- Logical volume ---
  LV Path                /dev/otus/test
  LV Name                test
  VG Name                otus
  LV UUID                m8Pb1w-ckab-6po8-X1Ko-CklQ-hSft-dl4oIT
  LV Write Access        read/write
  LV Creation host, time otus-node-0, 2024-05-24 13:03:09 +0300
  LV snapshot status     source of
                         test-snap [active]
  LV Status              available
  # open                 0
  LV Size                20.00 GiB
  Current LE             5120
  Segments               2
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:1

root@otus-node-0 ~ #
~~~
Запустим восстановление из снапшота:
~~~
root@otus-node-0 ~ #  lvconvert --merge /dev/otus/test-snap
  Merging of volume otus/test-snap started.
  otus/test: Merged: 100.00%
root@otus-node-0 ~ # mount /dev/otus/test /data
root@otus-node-0 ~ # ll /data
total 16382540
drwxr-xr-x  3 root root        4096 May 24 13:53 .
drwxr-xr-x 22 root root        4096 May 24 14:10 ..
drwx------  2 root root       16384 May 24 13:07 lost+found
-rw-r--r--  1 root root 16775692288 May 24 13:53 test.log
root@otus-node-0 ~ #
~~~

### Работа с LVM-RAID

Для начала так же необходимо создать PV:
~~~
root@otus-node-0 ~ # pvcreate /dev/sd{d,e}
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
root@otus-node-0 ~ #
~~~
Cоздаваем первый уровень абстракции - VG:
~~~
root@otus-node-0 ~ # vgcreate vg0 /dev/sd{d,e}
  Volume group "vg0" successfully created
root@otus-node-0 ~ #
~~~
Создаем Logical Volume c RAID:
~~~
root@otus-node-0 ~ # lvcreate -l+80%FREE -m1 -n mirror vg0
  Logical volume "mirror" created.
root@otus-node-0 ~ #
~~~
Проверяем работу:
~~~
root@otus-node-0 ~ # lvs
  LV        VG        Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test      otus      -wi-ao----   20.00g
  ubuntu-lv ubuntu-vg -wi-ao---- <125.00g
  mirror    vg0       rwi-a-r---  <16.00g                                    62.17
root@otus-node-0 ~ #
~~~

Постройение массива окончено:
~~~
root@otus-node-0 ~ # lvs
  LV        VG        Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test      otus      -wi-ao----   20.00g
  ubuntu-lv ubuntu-vg -wi-ao---- <125.00g
  mirror    vg0       rwi-a-r---  <16.00g                                    100.00
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0 79.9M  1 loop /snap/lxd/22923
loop1                       7:1    0   47M  1 loop /snap/snapd/16292
loop2                       7:2    0   62M  1 loop /snap/core20/1587
loop3                       7:3    0 63.9M  1 loop /snap/core20/2318
loop4                       7:4    0   87M  1 loop /snap/lxd/28373
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0  125G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─otus-test               253:1    0   20G  0 lvm  /data
sdc                         8:32   0   20G  0 disk
└─otus-test               253:1    0   20G  0 lvm  /data
sdd                         8:48   0   20G  0 disk
├─vg0-mirror_rmeta_0      253:2    0    4M  0 lvm
│ └─vg0-mirror            253:6    0   16G  0 lvm
└─vg0-mirror_rimage_0     253:3    0   16G  0 lvm
  └─vg0-mirror            253:6    0   16G  0 lvm
sde                         8:64   0   20G  0 disk
├─vg0-mirror_rmeta_1      253:4    0    4M  0 lvm
│ └─vg0-mirror            253:6    0   16G  0 lvm
└─vg0-mirror_rimage_1     253:5    0   16G  0 lvm
  └─vg0-mirror            253:6    0   16G  0 lvm
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~

## Домашнее задание

### Уменьшить том под / до 10G

Перед началом работы поставьте пакет xfsdump - он будет необходим для снятия копии / тома.
~~~
apt update && apt install xfsdump -y
~~~
Подготовим временный том для / раздела:
~~~
root@otus-node-0 ~ # pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
root@otus-node-0 ~ #
~~~
Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:
~~~
root@otus-node-0 ~ # mkfs.xfs /dev/vg_root/lv_root
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=1310464 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=5241856, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
root@otus-node-0 ~ # mount /dev/vg_root/lv_root /mnt
root@otus-node-0 ~ #
~~~
Этой командой копируем все данные с / раздела в /mnt:

rsync -axu / /mnt/

-a, --archive архивный режим

-x, --one-file-system не выходить за пределы файловой системы

-u, --update только обновление (не переписывает более новые файлы)
~~~
root@otus-node-0 ~ # rsync -axu / /mnt/
root@otus-node-0 ~ # ll /mnt
total 4019224
drwxr-xr-x 20 root    root           334 May 24 15:56 .
drwxr-xr-x 20 root    root          4096 May 24 15:56 ..
lrwxrwxrwx  1 root    root             7 Aug  9  2022 bin -> usr/bin
drwxr-xr-x  2 root    root             6 Oct  5  2022 boot
drwxr-xr-x  2 root    root             6 May 24 16:01 dev
drwxr-xr-x 99 root    root          8192 May 24 15:56 etc
drwxr-xr-x  3 root    root            21 Oct  5  2022 home
lrwxrwxrwx  1 root    root             7 Aug  9  2022 lib -> usr/lib
lrwxrwxrwx  1 root    root             9 Aug  9  2022 lib32 -> usr/lib32
lrwxrwxrwx  1 root    root             9 Aug  9  2022 lib64 -> usr/lib64
lrwxrwxrwx  1 root    root            10 Aug  9  2022 libx32 -> usr/libx32
drwx------  2 root    root             6 Oct  5  2022 lost+found
drwxr-xr-x  2 root    root             6 Oct  5  2022 media
drwxr-xr-x  2 root    root             6 May 24 16:02 mnt
drwxr-xr-x  3 root    root            39 Oct  5  2022 opt
dr-xr-xr-x  2 root    root             6 May 24 15:56 proc
drwx------  5 root    root            75 May 24 15:57 root
drwxr-xr-x  2 root    root             6 May 24 15:59 run
lrwxrwxrwx  1 root    root             8 Aug  9  2022 sbin -> usr/sbin
drwxr-xr-x  6 root    root            69 Aug  9  2022 snap
drwxr-xr-x  2 root    root             6 Aug  9  2022 srv
-rw-------  1 root    root    4115660800 Oct  5  2022 swap.img
dr-xr-xr-x  2 root    root             6 May 24 15:56 sys
drwxrwxrwt 11 root    root          4096 May 24 16:01 tmp
drwxr-xr-x 14 root    root           160 Aug  9  2022 usr
drwxrwxrwx  2 vagrant vagrant          6 May 24 12:46 vagrant
-rw-r--r--  1 root    root          3424 Oct  5  2022 VagrantBox.txt
drwxr-xr-x 13 root    root           164 Aug  9  2022 var
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop1                       7:1    0   62M  1 loop /snap/core20/1587
loop2                       7:2    0 79.9M  1 loop /snap/lxd/22923
loop3                       7:3    0 38.8M  1 loop /snap/snapd/21759
loop4                       7:4    0 63.9M  1 loop /snap/core20/2318
loop5                       7:5    0   87M  1 loop /snap/lxd/28373
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0  125G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─vg_root-lv_root         253:1    0   20G  0 lvm  /mnt
sdc                         8:32   0   20G  0 disk
sdd                         8:48   0   20G  0 disk
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Затем сконфигурируем grub для того, чтобы при старте перейти в новый /.
Сымитируем текущий root, сделаем в него chroot и обновим grub:
~~~
root@otus-node-0 ~ # for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

root@otus-node-0 ~ # chroot /mnt/

root@otus-node-0 / # grub-mkconfig -o /boot/grub/grub.cfg

Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.15.0-48-generic
Found initrd image: /boot/initrd.img-5.15.0-48-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done

root@otus-node-0 / # update-grub

Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.15.0-48-generic
Found initrd image: /boot/initrd.img-5.15.0-48-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done
root@otus-node-0 / #
~~~
Проверяем /boot/grub/grub.cfg, должна быть загрузка с нового / раздела

Проверяем размер старого /, он равен 125 Гб
~~~
root@otus-node-0 / # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop1                       7:1    0   62M  1 loop
loop2                       7:2    0 79.9M  1 loop
loop3                       7:3    0 38.8M  1 loop
loop4                       7:4    0 63.9M  1 loop
loop5                       7:5    0   87M  1 loop
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0  125G  0 lvm
sdb                         8:16   0   20G  0 disk
└─vg_root-lv_root         253:1    0   20G  0 lvm  /
sdc                         8:32   0   20G  0 disk
sdd                         8:48   0   20G  0 disk
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 / #
~~~
Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем старый LV размером в 40G и создаём новый на 8G. Без перезагрузки на моем тестовом стенде не работает, поэтому перезагружаем ВМ
~~~
root@otus-node-0 / # lvremove /dev/ubuntu-vg/ubuntu-lv
  Logical volume ubuntu-vg/ubuntu-lv contains a filesystem in use.

root@otus-node-0 / # reboot
Running in chroot, ignoring request.

root@otus-node-0 / # exit
exit
root@otus-node-0 ~ # reboot

Remote side unexpectedly closed network connection



Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~

После перезагрузки проверяем что и откуда примонтировано, как видим система нпосле перезашрущки на новом LV
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0   47M  1 loop /snap/snapd/16292
loop1                       7:1    0   62M  1 loop /snap/core20/1587
loop2                       7:2    0 79.9M  1 loop /snap/lxd/22923
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:1    0  125G  0 lvm
sdb                         8:16   0   20G  0 disk
└─vg_root-lv_root         253:0    0   20G  0 lvm  /
sdc                         8:32   0   20G  0 disk
sdd                         8:48   0   20G  0 disk
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем старый LV размером в 40G и создаём новый на 10G.
~~~
root@otus-node-0 ~ # lvremove /dev/ubuntu-vg/ubuntu-lv
Do you really want to remove and DISCARD active logical volume ubuntu-vg/ubuntu-lv? [y/n]: yes
  Logical volume "ubuntu-lv" successfully removed
~~~
~~~
root@otus-node-0 ~ # lsblk
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0               7:0    0   47M  1 loop /snap/snapd/16292
loop1               7:1    0   62M  1 loop /snap/core20/1587
loop2               7:2    0 79.9M  1 loop /snap/lxd/22923
sda                 8:0    0  127G  0 disk
├─sda1              8:1    0    1M  0 part
├─sda2              8:2    0    2G  0 part /boot
└─sda3              8:3    0  125G  0 part
sdb                 8:16   0   20G  0 disk
└─vg_root-lv_root 253:0    0   20G  0 lvm  /
sdc                 8:32   0   20G  0 disk
sdd                 8:48   0   20G  0 disk
sde                 8:64   0   20G  0 disk
sr0                11:0    1 1024M  0 rom
~~~
~~~
root@otus-node-0 ~ # lvcreate -n ubuntu-vg/ubuntu-lv -L 10G /dev/ubuntu-vg
WARNING: ext4 signature detected on /dev/ubuntu-vg/ubuntu-lv at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/ubuntu-vg/ubuntu-lv.
  Logical volume "ubuntu-lv" created.
root@otus-node-0 ~ #
~~~
Проделываем на нем те же операции, что и в первый раз, только для переноса системы уже используем xfsdump:
~~~
root@otus-node-0 ~ # mkfs.xfs /dev/ubuntu-vg/ubuntu-lv
meta-data=/dev/ubuntu-vg/ubuntu-lv isize=512    agcount=4, agsize=655360 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=2621440, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
root@otus-node-0 ~ # mount /dev/ubuntu-vg/ubuntu-lv /mnt
root@otus-node-0 ~ # xfsdump -J - /dev/vg_root/lv_root |  xfsrestore -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.9 (dump format 3.0)
xfsdump: level 0 dump of otus-node-0:/
xfsdump: dump date: Fri May 24 16:34:40 2024
xfsdump: session id: 26a6c6ce-3223-428f-bc66-0c1857370ac5
xfsdump: session label: ""
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.9 (dump format 3.0)
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 7588223616 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description:
xfsrestore: hostname: otus-node-0
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/vg_root-lv_root
xfsrestore: session time: Fri May 24 16:34:40 2024
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: 16a53a46-973e-4f80-b435-a16aad83f98f
xfsrestore: session id: 26a6c6ce-3223-428f-bc66-0c1857370ac5
xfsrestore: media id: efc6a0b1-a930-4010-a493-ee8e7aafd5ef
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 9124 directories and 87649 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 7465618880 bytes
xfsdump: dump size (non-dir files) : 7437050288 bytes
xfsdump: dump complete: 111 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 111 seconds elapsed
xfsrestore: Restore Status: SUCCESS
root@otus-node-0 ~ #
~~~
Так же как в первый раз cконфигурируем grub
~~~
root@otus-node-0 ~ # for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
root@otus-node-0 ~ # chroot /mnt/
root@otus-node-0 / # grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.15.0-48-generic
Found initrd image: /boot/initrd.img-5.15.0-48-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done
root@otus-node-0 / # update-grub
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.15.0-48-generic
Found initrd image: /boot/initrd.img-5.15.0-48-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done
root@otus-node-0 / #
~~~
Пока не перезагружаемся и не выходим из под chroot - мы можем заодно перенести /var.

### Выделить том под /var в зеркало
На свободных дисках создаем зеркало:
~~~
root@otus-node-0 / # pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
root@otus-node-0 / # vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
root@otus-node-0 / # lvcreate -L 10G -m1 -n lv_var vg_var
  Logical volume "lv_var" created.
root@otus-node-0 / #
~~~
Создаем на нем ФС и перемещаем туда /var:
~~~
root@otus-node-0 / # mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 2621440 4k blocks and 655360 inodes
Filesystem UUID: 8aa3815e-46df-4b3b-a184-3dd582b8af1b
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

root@otus-node-0 / # mount /dev/vg_var/lv_var /mnt
root@otus-node-0 / # cp -aR /var/* /mnt/
root@otus-node-0 / #
~~~
На всякий случай сохраняем содержимое старого var (или же можно его просто удалить):
~~~
root@otus-node-0 / # mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
root@otus-node-0 / # ll /tmp/oldvar/
total 8
drwxr-xr-x 13 root root    164 May 24 16:47 .
drwxrwxrwt 12 root root   4096 May 24 16:47 ..
drwxr-xr-x  2 root root      6 Apr 18  2022 backups
drwxr-xr-x 13 root root    189 May 24 16:32 cache
drwxrwxrwt  2 root root      6 Aug  9  2022 crash
drwxr-xr-x 40 root root   4096 May 24 16:34 lib
drwxrwsr-x  2 root staff     6 Apr 18  2022 local
lrwxrwxrwx  1 root root      9 May 24 16:35 lock -> /run/lock
drwxrwxr-x  5 root syslog  281 May 24 16:22 log
drwxrwsr-x  2 root mail      6 Aug  9  2022 mail
drwxr-xr-x  2 root root      6 Aug  9  2022 opt
lrwxrwxrwx  1 root root      4 May 24 16:35 run -> /run
drwxr-xr-x  5 root root     44 Aug  9  2022 snap
drwxr-xr-x  4 root root     45 Aug  9  2022 spool
drwxrwxrwt  5 root root    264 May 24 16:28 tmp
root@otus-node-0 / #
~~~
Ну и монтируем новый var в каталог /var:
~~~
root@otus-node-0 / # echo "`blkid | grep var: | awk '{print $2}'` \
 /var ext4 defaults 0 0" >> /etc/fstab
root@otus-node-0 / # cat /etc/fstab
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
UUID="8aa3815e-46df-4b3b-a184-3dd582b8af1b"  /var ext4 defaults 0 0
root@otus-node-0 / #
~~~
После чего можно успешно перезагружаться в новый (уменьшенный root) и удалять
временную Volume Group:
~~~
root@otus-node-0 / # exit
exit
root@otus-node-0 ~ # reboot

Remote side unexpectedly closed network connection

Session stopped
    - Press <Return> to exit tab
    - Press R to restart session
    - Press S to save terminal output to file
~~~
Проверяем что система на правильном LV и что размер LV 10 Гб
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0   47M  1 loop /snap/snapd/16292
loop1                       7:1    0 79.9M  1 loop /snap/lxd/22923
loop2                       7:2    0 63.9M  1 loop /snap/core20/2318
loop3                       7:3    0   87M  1 loop /snap/lxd/28373
loop4                       7:4    0   62M  1 loop /snap/core20/1587
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:1    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─vg_root-lv_root         253:0    0   20G  0 lvm
sdc                         8:32   0   20G  0 disk
├─vg_var-lv_var_rmeta_0   253:2    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_0  253:3    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sdd                         8:48   0   20G  0 disk
├─vg_var-lv_var_rmeta_1   253:4    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_1  253:5    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # lvremove /dev/vg_root/lv_root
Do you really want to remove and DISCARD active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed
root@otus-node-0 ~ #  vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
root@otus-node-0 ~ # pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
root@otus-node-0 ~ #
~~~

### Выделить том под /home
Выделяем том под /home по тому же принципу что делали для /var:
~~~
root@otus-node-0 ~ # pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
root@otus-node-0 ~ # vgcreate vg_home /dev/sdb
  Volume group "vg_home" successfully created
root@otus-node-0 ~ # lvcreate -n lv_home -L 10G /dev/vg_home
WARNING: xfs signature detected on /dev/vg_home/lv_home at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/vg_home/lv_home.
  Logical volume "lv_home" created.
~~~
Проверяем сездание тома
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop1                       7:1    0 79.9M  1 loop /snap/lxd/22923
loop2                       7:2    0 63.9M  1 loop /snap/core20/2318
loop3                       7:3    0   87M  1 loop /snap/lxd/28373
loop4                       7:4    0   62M  1 loop /snap/core20/1587
loop5                       7:5    0 38.8M  1 loop /snap/snapd/21759
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:1    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─vg_home-lv_home         253:0    0   10G  0 lvm
sdc                         8:32   0   20G  0 disk
├─vg_var-lv_var_rmeta_0   253:2    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_0  253:3    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sdd                         8:48   0   20G  0 disk
├─vg_var-lv_var_rmeta_1   253:4    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_1  253:5    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Создаем файловую систему, монтируем том и копируем данные
~~~
root@otus-node-0 ~ # mkfs.xfs /dev/vg_home/lv_home
meta-data=/dev/vg_home/lv_home   isize=512    agcount=4, agsize=655360 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=2621440, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
root@otus-node-0 ~ # mount /dev/vg_home/lv_home /mnt
root@otus-node-0 ~ # cp -aR /home/* /mnt/
root@otus-node-0 ~ # rm -rf /home/*
root@otus-node-0 ~ # umount /mnt
root@otus-node-0 ~ # mount /dev/vg_home/lv_home /home/
root@otus-node-0 ~ #
~~~
Правим fstab для автоматического монтирования /home:
~~~
root@otus-node-0 ~ # echo "`blkid | grep home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
root@otus-node-0 ~ # cat /etc/fstab
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
UUID="8aa3815e-46df-4b3b-a184-3dd582b8af1b"  /var ext4 defaults 0 0
UUID="9e1c48cc-0dd3-45d9-80ae-746bdea40e06" /home xfs defaults 0 0
root@otus-node-0 ~ #
~~~

### Работа со снапшотами

~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop1                       7:1    0 79.9M  1 loop /snap/lxd/22923
loop2                       7:2    0 63.9M  1 loop /snap/core20/2318
loop3                       7:3    0   87M  1 loop /snap/lxd/28373
loop4                       7:4    0   62M  1 loop /snap/core20/1587
loop5                       7:5    0 38.8M  1 loop /snap/snapd/21759
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:1    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─vg_home-lv_home         253:0    0   10G  0 lvm  /home
sdc                         8:32   0   20G  0 disk
├─vg_var-lv_var_rmeta_0   253:2    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_0  253:3    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sdd                         8:48   0   20G  0 disk
├─vg_var-lv_var_rmeta_1   253:4    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_1  253:5    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Генерируем файлы в /home/:
~~~
root@otus-node-0 ~ # touch /home/file{1..20}
~~~
Снять снапшот:
~~~
root@otus-node-0 ~ # lvcreate -L 5G -s -n home_snap /dev/vg_home/lv_home
  Logical volume "home_snap" created.
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop1                       7:1    0 79.9M  1 loop /snap/lxd/22923
loop2                       7:2    0 63.9M  1 loop /snap/core20/2318
loop3                       7:3    0   87M  1 loop /snap/lxd/28373
loop4                       7:4    0   62M  1 loop /snap/core20/1587
loop5                       7:5    0 38.8M  1 loop /snap/snapd/21759
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:1    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk
├─vg_home-lv_home-real    253:7    0   10G  0 lvm
│ ├─vg_home-lv_home       253:0    0   10G  0 lvm  /home
│ └─vg_home-home_snap     253:9    0   10G  0 lvm
└─vg_home-home_snap-cow   253:8    0    5G  0 lvm
  └─vg_home-home_snap     253:9    0   10G  0 lvm
sdc                         8:32   0   20G  0 disk
├─vg_var-lv_var_rmeta_0   253:2    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_0  253:3    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sdd                         8:48   0   20G  0 disk
├─vg_var-lv_var_rmeta_1   253:4    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_1  253:5    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sde                         8:64   0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Удалить часть файлов:
~~~
root@otus-node-0 ~ # rm -f /home/file{11..20}
~~~
Процесс восстановления из снапшота:
~~~
root@otus-node-0 ~ # umount /home
root@otus-node-0 ~ # lvconvert --merge /dev/vg_home/home_snap
  Merging of volume vg_home/home_snap started.
  vg_home/lv_home: Merged: 100.00%
root@otus-node-0 ~ # mount /home
root@otus-node-0 ~ # ls -la /home/
total 0
drwxr-xr-x  3 root    root    292 May 27 10:12 .
drwxr-xr-x 20 root    root    334 May 24 16:36 ..
-rw-r--r--  1 root    root      0 May 27 10:12 file1
-rw-r--r--  1 root    root      0 May 27 10:12 file10
-rw-r--r--  1 root    root      0 May 27 10:12 file11
-rw-r--r--  1 root    root      0 May 27 10:12 file12
-rw-r--r--  1 root    root      0 May 27 10:12 file13
-rw-r--r--  1 root    root      0 May 27 10:12 file14
-rw-r--r--  1 root    root      0 May 27 10:12 file15
-rw-r--r--  1 root    root      0 May 27 10:12 file16
-rw-r--r--  1 root    root      0 May 27 10:12 file17
-rw-r--r--  1 root    root      0 May 27 10:12 file18
-rw-r--r--  1 root    root      0 May 27 10:12 file19
-rw-r--r--  1 root    root      0 May 27 10:12 file2
-rw-r--r--  1 root    root      0 May 27 10:12 file20
-rw-r--r--  1 root    root      0 May 27 10:12 file3
-rw-r--r--  1 root    root      0 May 27 10:12 file4
-rw-r--r--  1 root    root      0 May 27 10:12 file5
-rw-r--r--  1 root    root      0 May 27 10:12 file6
-rw-r--r--  1 root    root      0 May 27 10:12 file7
-rw-r--r--  1 root    root      0 May 27 10:12 file8
-rw-r--r--  1 root    root      0 May 27 10:12 file9
drwxr-x---  5 vagrant vagrant 157 Oct  5  2022 vagrant
root@otus-node-0 ~ #
~~~

## Задание со звездочкой*
на нашей куче дисков попробовать поставить btrfs/zfs:

с кешем и снэпшотами

разметить здесь каталог /opt

Используем разделs /dev/sde, /dev/sdf для создания устройства кэша. Флагом -C указывается устройство-кэш. Флагом -B указываются кэшируемые устройства. Если все сделать одной командой, то сразу получится то, что нам нужно: один раздела на HDD и один кэш для них на SSD. В моем случае для кэша используется /dev/sde и диск /dev/sdf будет кэшироваться.
~~~
root@otus-node-0 ~ # make-bcache -C /dev/sde -B /dev/sdf
UUID:                   1cdb2a8b-0a62-4d66-8440-045b86d8c30c
Set UUID:               78747fd3-ac4f-4bb2-a902-de225acdac4f
version:                0
nbuckets:               40960
block_size:             1
bucket_size:            1024
nr_in_set:              1
nr_this_dev:            0
first_bucket:           1
UUID:                   2d86071d-53e6-4fa6-80e2-d432fa599d33
Set UUID:               78747fd3-ac4f-4bb2-a902-de225acdac4f
version:                1
block_size:             1
data_offset:            16
root@otus-node-0 ~ #
~~~
Проверяем командой Lsblk, bcache-super-show
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0   87M  1 loop /snap/lxd/28373
loop1                       7:1    0   62M  1 loop /snap/core20/1587
loop2                       7:2    0 79.9M  1 loop /snap/lxd/22923
loop3                       7:3    0 38.8M  1 loop /snap/snapd/21759
loop4                       7:4    0 63.9M  1 loop /snap/core20/2318
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:1    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─vg_home-lv_home         253:0    0   10G  0 lvm  /home
sdc                         8:32   0   20G  0 disk
├─vg_var-lv_var_rmeta_0   253:2    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_0  253:3    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sdd                         8:48   0   20G  0 disk
├─vg_var-lv_var_rmeta_1   253:4    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_1  253:5    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sde                         8:64   0   20G  0 disk
└─bcache0                 252:0    0   20G  0 disk
sdf                         8:80   0   20G  0 disk
└─bcache0                 252:0    0   20G  0 disk
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # bcache-super-show /dev/sde
sb.magic                ok
sb.first_sector         8 [match]
sb.csum                 7B6BF2516213DD62 [match]
sb.version              3 [cache device]

dev.label               (empty)
dev.uuid                1cdb2a8b-0a62-4d66-8440-045b86d8c30c
dev.sectors_per_block   1
dev.sectors_per_bucket  1024
dev.cache.first_sector  1024
dev.cache.cache_sectors 41942016
dev.cache.total_sectors 41943040
dev.cache.ordered       yes
dev.cache.discard       no
dev.cache.pos           0
dev.cache.replacement   0 [lru]

cset.uuid               78747fd3-ac4f-4bb2-a902-de225acdac4f
root@otus-node-0 ~ # bcache-super-show /dev/sdf
sb.magic                ok
sb.first_sector         8 [match]
sb.csum                 A0B46ED43EF5B976 [match]
sb.version              1 [backing device]

dev.label               (empty)
dev.uuid                2d86071d-53e6-4fa6-80e2-d432fa599d33
dev.sectors_per_block   1
dev.sectors_per_bucket  1024
dev.data.first_sector   16
dev.data.cache_mode     0 [writethrough]
dev.data.cache_state    1 [clean]

cset.uuid               78747fd3-ac4f-4bb2-a902-de225acdac4f
root@otus-node-0 ~ #
~~~
Теперь самое время вспомнить про файловую систему BTRFS и развернуть ее на нашем кэширующем устройстве.
~~~
root@otus-node-0 ~ # mkfs.btrfs /dev/bcache0
btrfs-progs v5.16.2
See http://btrfs.wiki.kernel.org for more information.

Performing full device TRIM /dev/bcache0 (20.00GiB) ...
NOTE: several default settings have changed in version 5.15, please make sure
      this does not affect your deployments:
      - DUP for metadata (-m dup)
      - enabled no-holes (-O no-holes)
      - enabled free-space-tree (-R free-space-tree)

Label:              (null)
UUID:               4bc18c2a-396b-4956-b117-8ee2c80d9dbf
Node size:          16384
Sector size:        4096
Filesystem size:    20.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP             256.00MiB
  System:           DUP               8.00MiB
SSD detected:       yes
Zoned device:       no
Incompat features:  extref, skinny-metadata, no-holes
Runtime features:   free-space-tree
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1    20.00GiB  /dev/bcache0

root@otus-node-0 ~ #
~~~
Монтируем раздел BTRFS, и переносим данные из /opt
~~~
root@otus-node-0 ~ # mount /dev/bcache0 /mnt/
root@otus-node-0 ~ # cp -aR /opt/* /mnt/
root@otus-node-0 ~ # rm -rf /opt/*
root@otus-node-0 ~ # umount /mnt
root@otus-node-0 ~ # mount /dev/bcache0 /opt/
root@otus-node-0 ~ #
~~~
Правим fstab для автоматического монтирования /opt:
~~~
root@otus-node-0 ~ # echo "`blkid | grep bcache0 | awk '{print $2}'` /opt btrfs defaults 0 0" >> /etc/fstab
root@otus-node-0 ~ # cat /etc/fstab
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
UUID="8aa3815e-46df-4b3b-a184-3dd582b8af1b"  /var ext4 defaults 0 0
UUID="9e1c48cc-0dd3-45d9-80ae-746bdea40e06" /home xfs defaults 0 0
UUID="4bc18c2a-396b-4956-b117-8ee2c80d9dbf" /opt btrfs defaults 0 0
root@otus-node-0 ~ #
~~~
Результат выполненой работы:
~~~
root@otus-node-0 ~ # lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0   87M  1 loop /snap/lxd/28373
loop1                       7:1    0   62M  1 loop /snap/core20/1587
loop2                       7:2    0 79.9M  1 loop /snap/lxd/22923
loop3                       7:3    0 38.8M  1 loop /snap/snapd/21759
loop4                       7:4    0 63.9M  1 loop /snap/core20/2318
sda                         8:0    0  127G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    2G  0 part /boot
└─sda3                      8:3    0  125G  0 part
  └─ubuntu--vg-ubuntu--lv 253:1    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk
└─vg_home-lv_home         253:0    0   10G  0 lvm  /home
sdc                         8:32   0   20G  0 disk
├─vg_var-lv_var_rmeta_0   253:2    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_0  253:3    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sdd                         8:48   0   20G  0 disk
├─vg_var-lv_var_rmeta_1   253:4    0    4M  0 lvm
│ └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
└─vg_var-lv_var_rimage_1  253:5    0   10G  0 lvm
  └─vg_var-lv_var         253:6    0   10G  0 lvm  /var
sde                         8:64   0   20G  0 disk
└─bcache0                 252:0    0   20G  0 disk /opt
sdf                         8:80   0   20G  0 disk
└─bcache0                 252:0    0   20G  0 disk /opt
sr0                        11:0    1 1024M  0 rom
root@otus-node-0 ~ #
~~~
Снапшоты в BTRFS

Основная информация о сабволумах:
~~~
root@otus-node-0 ~ # btrfs subvolume show /opt/
/
        Name:                   <FS_TREE>
        UUID:                   443ca814-717e-4b30-957a-f13e52815eb2
        Parent UUID:            -
        Received UUID:          -
        Creation time:          2024-05-27 12:32:11 +0300
        Subvolume ID:           5
        Generation:             14
        Gen at creation:        0
        Parent ID:              0
        Top level ID:           0
        Flags:                  -
        Send transid:           0
        Send time:              2024-05-27 12:32:11 +0300
        Receive transid:        0
        Receive time:           -
        Snapshot(s):
~~~
~~~
Основные свойства:
Name - имя сабволума
UUID - уникальный идентификатор
Parent UUID - идентификатор предка сабволума от снапшота
Received UUID - идентификатор предка сабволума от btrfs send
Subvolume ID - уникальный идентификатор размещения в Btree
Generation - номер последней транзакций при последнем обновлении
Gen at creation - номер транзакции на момент создания сабволума
Parent ID - идентификатор сабволума, в который вложен текущий
Top level ID - идентично Parent ID
Flags - возможен флаг readonly
Snapshot(s) - список снапшотов, произвденных от этого сабволума
~~~
Снапшот посути - сабволум с расширенными свойствами

Основное отличие снапшота - наличие Parent UUID и Received UUID

У сабволума эти поля всегда пустые

Создаем снапшот:
~~~
root@otus-node-0 ~ # mkdir /opt/backup
root@otus-node-0 ~ # btrfs subvolume snapshot -r /opt/ /opt/backup/opt-$(date +%Y%m%d)
Create a readonly snapshot of '/opt/' in '/opt/backup/opt-20240527'
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # ll /opt/
total 16
drwxr-xr-x  1 root root 284 May 27 13:07 .
drwxr-xr-x 20 root root 334 May 27 12:34 ..
drwxr-xr-x  1 root root  24 May 27 13:07 backup
-rw-r--r--  1 root root   0 May 27 12:55 file1
-rw-r--r--  1 root root   0 May 27 12:55 file10
-rw-r--r--  1 root root   0 May 27 12:55 file11
-rw-r--r--  1 root root   0 May 27 12:55 file12
-rw-r--r--  1 root root   0 May 27 12:55 file13
-rw-r--r--  1 root root   0 May 27 12:55 file14
-rw-r--r--  1 root root   0 May 27 12:55 file15
-rw-r--r--  1 root root   0 May 27 12:55 file16
-rw-r--r--  1 root root   0 May 27 12:55 file17
-rw-r--r--  1 root root   0 May 27 12:55 file18
-rw-r--r--  1 root root   0 May 27 12:55 file19
-rw-r--r--  1 root root   0 May 27 12:55 file2
-rw-r--r--  1 root root   0 May 27 12:55 file20
-rw-r--r--  1 root root   0 May 27 12:55 file3
-rw-r--r--  1 root root   0 May 27 12:55 file4
-rw-r--r--  1 root root   0 May 27 12:55 file5
-rw-r--r--  1 root root   0 May 27 12:55 file6
-rw-r--r--  1 root root   0 May 27 12:55 file7
-rw-r--r--  1 root root   0 May 27 12:55 file8
-rw-r--r--  1 root root   0 May 27 12:55 file9
drwxr-xr-x  1 root root 116 Oct  5  2022 VBoxGuestAdditions-6.1.38
root@otus-node-0 ~ #
~~~
Параметр только чтения -r управляем:
~~~
root@otus-node-0 ~ # btrfs property get /opt/backup/opt-20240527/
ro=true
root@otus-node-0 ~ # sudo btrfs property set /opt/backup/opt-20240527/ ro false
root@otus-node-0 ~ # btrfs property get /opt/backup/opt-20240527/
ro=false
root@otus-node-0 ~ #
~~~
Проверим изменения каталога, с которого сделан снапшот:
~~~
root@otus-node-0 ~ # btrfs subvolume show /opt/
/
        Name:                   <FS_TREE>
        UUID:                   443ca814-717e-4b30-957a-f13e52815eb2
        Parent UUID:            -
        Received UUID:          -
        Creation time:          2024-05-27 12:32:11 +0300
        Subvolume ID:           5
        Generation:             17
        Gen at creation:        0
        Parent ID:              0
        Top level ID:           0
        Flags:                  -
        Send transid:           0
        Send time:              2024-05-27 12:32:11 +0300
        Receive transid:        0
        Receive time:           -
        Snapshot(s):
                                backup/opt-20240527
root@otus-node-0 ~ #
~~~
Удалим данные перед восстановлением:
~~~
root@otus-node-0 ~ # rm -rf /opt/file*
root@otus-node-0 ~ # ll /opt/
total 16
drwxr-xr-x  1 root root  62 May 27 13:13 .
drwxr-xr-x 20 root root 334 May 27 12:34 ..
drwxr-xr-x  1 root root  24 May 27 13:07 backup
drwxr-xr-x  1 root root 116 Oct  5  2022 VBoxGuestAdditions-6.1.38
root@otus-node-0 ~ #
~~~
проверим, что в снапшоте данные на месте:
~~~
root@otus-node-0 ~ # ll /opt/backup/opt-20240527/
total 16
drwxr-xr-x 1 root root 284 May 27 13:07 .
drwxr-xr-x 1 root root  24 May 27 13:07 ..
drwxr-xr-x 1 root root   0 May 27 13:07 backup
-rw-r--r-- 1 root root   0 May 27 12:55 file1
-rw-r--r-- 1 root root   0 May 27 12:55 file10
-rw-r--r-- 1 root root   0 May 27 12:55 file11
-rw-r--r-- 1 root root   0 May 27 12:55 file12
-rw-r--r-- 1 root root   0 May 27 12:55 file13
-rw-r--r-- 1 root root   0 May 27 12:55 file14
-rw-r--r-- 1 root root   0 May 27 12:55 file15
-rw-r--r-- 1 root root   0 May 27 12:55 file16
-rw-r--r-- 1 root root   0 May 27 12:55 file17
-rw-r--r-- 1 root root   0 May 27 12:55 file18
-rw-r--r-- 1 root root   0 May 27 12:55 file19
-rw-r--r-- 1 root root   0 May 27 12:55 file2
-rw-r--r-- 1 root root   0 May 27 12:55 file20
-rw-r--r-- 1 root root   0 May 27 12:55 file3
-rw-r--r-- 1 root root   0 May 27 12:55 file4
-rw-r--r-- 1 root root   0 May 27 12:55 file5
-rw-r--r-- 1 root root   0 May 27 12:55 file6
-rw-r--r-- 1 root root   0 May 27 12:55 file7
-rw-r--r-- 1 root root   0 May 27 12:55 file8
-rw-r--r-- 1 root root   0 May 27 12:55 file9
drwxr-xr-x 1 root root 116 Oct  5  2022 VBoxGuestAdditions-6.1.38
root@otus-node-0 ~ #
~~~

В BTRFS восстановление происходит путем замены сабволума на снапшот

Представим себе такой сценарий: на btrfs расположен сабвольюм, в котором располагаются файлы какой-либо базы данных (ну или другие важные данные). С этого сабвольюма периодически снимаются снапшоты, и в определенный момент возникает необходимость откатить данные. В этом случае мы просто избавляемся от сабвольюма и вместо него начинаем использовать снятый с него снапшот, либо — если не хотим испортить еще и эти данные — снимаем со снапшота еще один снапшот. Если оригинальный сабвольюм не был замонтирован и использовался как обычная директория, то его необходимо либо удалить либо переместить/переименовать, а на его место поместить снапшот.

В консоли это может выглядеть примерно так:

переименовываем сабвольюм
~~~
mv the_subvolume the_subvol.old
~~~
помещаем на место сабвольюма его снапшот
~~~
btrfs subvolume snapshot the_snapshot the_subvolume
~~~

Если же сабвольюм был замонтирован и использовался через точку монтирования, то достаточно отмонтировать сабвольюм и подмонтировать на его место снапшот.


Отмонтируем сабвольюм
~~~
root@otus-node-0 ~ # umount /opt/
umount: /opt/: target is busy.
root@otus-node-0 ~ # lsof /opt/
COMMAND    PID USER  FD   TYPE DEVICE SIZE/OFF NODE NAME
VBoxServi 1293 root txt    REG   0,36  1737912  259 /opt/VBoxGuestAdditions-6.1.38/sbin/VBoxService
root@otus-node-0 ~ # kill -9 1293
root@otus-node-0 ~ # umount /opt
root@otus-node-0 ~ #
~~~
Можно создать снапшот снапшота, чтобы не испортить последние уцелевшие данные:
~~~
root@otus-node-0 ~ # btrfs subvolume snapshot -r /opt/backup/opt-20240527/ /opt/backup/backup_snap
root@otus-node-0 ~ # btrfs subvolume list /opt
ID 256 gen 24 top level 5 path backup/opt-20240527
ID 257 gen 21 top level 5 path backup/backup_snap
root@otus-node-0 ~ #
~~~
монтируем снапшот:
~~~
root@otus-node-0 ~ # mount -o subvolid=256 /dev/bcache0 /opt/
~~~
проверяем что данные на месте
~~~
root@otus-node-0 ~ # ll /opt/
total 16
drwxr-xr-x  1 root root 284 May 27 13:07 .
drwxr-xr-x 20 root root 334 May 27 12:34 ..
drwxr-xr-x  1 root root   0 May 27 13:07 backup
-rw-r--r--  1 root root   0 May 27 12:55 file1
-rw-r--r--  1 root root   0 May 27 12:55 file10
-rw-r--r--  1 root root   0 May 27 12:55 file11
-rw-r--r--  1 root root   0 May 27 12:55 file12
-rw-r--r--  1 root root   0 May 27 12:55 file13
-rw-r--r--  1 root root   0 May 27 12:55 file14
-rw-r--r--  1 root root   0 May 27 12:55 file15
-rw-r--r--  1 root root   0 May 27 12:55 file16
-rw-r--r--  1 root root   0 May 27 12:55 file17
-rw-r--r--  1 root root   0 May 27 12:55 file18
-rw-r--r--  1 root root   0 May 27 12:55 file19
-rw-r--r--  1 root root   0 May 27 12:55 file2
-rw-r--r--  1 root root   0 May 27 12:55 file20
-rw-r--r--  1 root root   0 May 27 12:55 file3
-rw-r--r--  1 root root   0 May 27 12:55 file4
-rw-r--r--  1 root root   0 May 27 12:55 file5
-rw-r--r--  1 root root   0 May 27 12:55 file6
-rw-r--r--  1 root root   0 May 27 12:55 file7
-rw-r--r--  1 root root   0 May 27 12:55 file8
-rw-r--r--  1 root root   0 May 27 12:55 file9
drwxr-xr-x  1 root root 116 Oct  5  2022 VBoxGuestAdditions-6.1.38
root@otus-node-0 ~ # 
~~~
проверим какой сабволум примонтирован в /opt
~~~
root@otus-node-0 ~ # btrfs subvolume show /opt/
backup/opt-20240527
        Name:                   opt-20240527
        UUID:                   4f17bd59-92d0-9044-8025-55ead77bcd05
        Parent UUID:            443ca814-717e-4b30-957a-f13e52815eb2
        Received UUID:          -
        Creation time:          2024-05-27 13:07:19 +0300
        Subvolume ID:           256
        Generation:             37
        Gen at creation:        15
        Parent ID:              5
        Top level ID:           5
        Flags:                  -
        Send transid:           0
        Send time:              2024-05-27 13:07:19 +0300
        Receive transid:        0
        Receive time:           -
        Snapshot(s):
                                backup/backup_snap
~~~
