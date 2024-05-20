# Lesson №4 - RAID

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_4_RAID
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

### Версия VirtualBox 7.0.14

### На проверку отправьте

1. Измененный Vagrantfile - выполнено, файл Vagrantfile
2. Скрипт для создания рейда - выполнено, файл build_raid.sh
3. Конф для автосборки рейда при загрузке - выполнено, файл mdadm.conf

### Доп. задание*

Vagrantfile, который сразу собирает систему с подключенным рейдом и смонтированными разделами. После перезагрузки стенда разделы должны автоматически примонтироваться - выполнено, описано в Vagrantfile

### Задание повышенной сложности**
#### Перенести работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается.
вывод команды lsblk до решения
~~~
root@otus-node-0 ~ # lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0  103M  1 loop /snap/lxd/23541
loop1    7:1    0 63.2M  1 loop /snap/core20/1738
loop2    7:2    0 49.6M  1 loop /snap/snapd/17883
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0   10M  0 disk
root@otus-node-0 ~ #
~~~

1. Подключаем второй диск к компьютеру эквивалентного(или большего) объема.
~~~
root@otus-node-0 ~ # lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0 63.2M  1 loop /snap/core20/1738
loop1    7:1    0 49.6M  1 loop /snap/snapd/17883
loop2    7:2    0  103M  1 loop /snap/lxd/23541
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0   10M  0 disk
sdc      8:32   0   40G  0 disk
root@otus-node-0 ~ #
~~~
2. Форматируем новый диск
~~~
fdisk /dev/sdc
~~~
~~~
root@otus-node-0 ~ # lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0 63.2M  1 loop /snap/core20/1738
loop1    7:1    0 49.6M  1 loop /snap/snapd/17883
loop2    7:2    0  103M  1 loop /snap/lxd/23541
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0   10M  0 disk
sdc      8:32   0   40G  0 disk
└─sdc1   8:33   0   40G  0 part
root@otus-node-0 ~ #
~~~
 3. Создаем на нем массив:
~~~
mdadm --create /dev/md0 --level=1 --raid-devices=2 missing /dev/sdc1
~~~ 
Массив создается с пропущенным диском и поэтому работает в degrade режиме.
~~~
root@otus-node-0 ~ # lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
loop0     7:0    0 63.2M  1 loop  /snap/core20/1738
loop1     7:1    0 49.6M  1 loop  /snap/snapd/17883
loop2     7:2    0  103M  1 loop  /snap/lxd/23541
sda       8:0    0   40G  0 disk
└─sda1    8:1    0   40G  0 part  /
sdb       8:16   0   10M  0 disk
sdc       8:32   0   40G  0 disk
└─sdc1    8:33   0   40G  0 part
  └─md0   9:0    0   40G  0 raid1
root@otus-node-0 ~ #
~~~
~~~
root@otus-node-0 ~ # cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
md0 : active raid1 sdc1[1]
      41908224 blocks super 1.2 [2/1] [_U]

unused devices: <none>
~~~
4.  Далее создаем на массиве разделы под будущую систему. Создаем такие же разделы под корень и своп как на оригинальном диске, в моем примере - не используется.
~~~
fdisk /dev/md0
~~~
5. Создаем файловые системы на разделах зеркала
~~~
mkfs.ext4 /dev/md0
~~~
~~~
root@otus-node-0 ~ # mkfs.ext4 /dev/md0
mke2fs 1.46.5 (30-Dec-2021)
Found a dos partition table in /dev/md0
Proceed anyway? (y,N) yes
Creating filesystem with 10477056 4k blocks and 2621440 inodes
Filesystem UUID: 11271a96-1881-470d-b821-099f429f5d50
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624

Allocating group tables: done
Writing inode tables: done
Creating journal (65536 blocks): done
Writing superblocks and filesystem accounting information: done

root@otus-node-0 ~ #
~~~
6. Монтируем будущий корень и копируем в него текущий корень
~~~
# mount /dev/md0 /mnt
# rsync -axu / /mnt/
~~~
7. После этого прицепляем системные каталоги к новому корню, что бы потом сделать chroot в новый корень. chroot в новый корень на этапе настройки позволяет сделать все настройки в новом корне(который на RAID) и не трогать текущий (который на простом диске), что позволит организовать загрузку как с корнем в RAID-е, так и с корнем на диске. Это может потребоваться, если мы что-то намудрим в настройке нового раидного корня и не сможем загрузится в раидную версию нашей системы. Тогда остается шанс откатится полностью назад еще одной перезагрузкой. И собственно делаем chroot в новый корень.
~~~
# mount --bind /proc /mnt/proc
# mount --bind /dev /mnt/dev
# mount --bind /sys /mnt/sys
# mount --bind /run /mnt/run
# chroot /mnt
~~~
8. Для начала смотрим UUID-ы разделов на раиде и прописываем их в fstab.
изначальный файл fstab:
~~~
LABEL=cloudimg-rootfs   /        ext4   discard,errors=remount-ro       0 1
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
vagrant /vagrant vboxsf uid=1000,gid=1000,_netdev 0 0
#VAGRANT-END
~~~
~~~
# blkid | grep md >> /etc/fstab
# vim /etc/fstab
~~~
там комментируем старые корень и своп и используя скопированные туда uuid-ы прописываем новый корень и своп по образу и подобию старых, но с uuid-ами раидных разделов
~~~
#LABEL=cloudimg-rootfs  /        ext4   discard,errors=remount-ro       0 1
UUID=11271a96-1881-470d-b821-099f429f5d50    /    ext4  discard,errors=remount-ro 0 1
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
vagrant /vagrant vboxsf uid=1000,gid=1000,_netdev 0 0
#VAGRANT-END
~~~
9. Создаем новую конфигурацию GRUB и проверяем, что в его конфиг прописан раидный uuid для корня.
~~~
# update-grub
# cat /boot/grub/grub.cfg
~~~
10. Ставим первую стадию GRUB на второй диск (который несет на себе часть зеркала).
~~~
# grub-install /dev/sdc
~~~
11. Очень важный шаг! Нужно прописать (хотя бы на время) конфигурацию mdadm, которая позволит загрузится с деградированного массива (а у нас пока он именно такой)
~~~
dpkg-reconfigure mdadm
~~~
Там со всем соглашаемся, включаяя последний шаг, где спрашивают - позволять ли грузится системе на деградированном массиве,
dpkg-reconfigure вызовет перестройку initrd, но так как мы в chroot, то он его перезапишет только в раидном корне (на реальном корне initrd сохранится таким как он был) - система на раиде готова.
12. Можно перегружаться и выбрать в BIOS или VirtualBox загрузочным второй диск, или можно вернутся в реальную систему и обновить GRUB - он найдет вторую систему установленную на раиде и включит ее свое меню.
~~~
# exit                              #---выходим из chroot
# poweroff
~~~
Тут важная точка в процессе.
Если при перезагрузке что-то пошло не так и новая система на раиде не поднимается, то откат назад делается перегрузкой с первого диска - там у нас сохранилось все как было до начала процедуры.

13. Перегрузившись в новую систему остается только навесить в RAID первый диск и обновить на нем первую стадию GRUB.

Проверяем, что загрузились именно с RAID
~~~
root@otus-node-0 ~ # lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
loop0     7:0    0 49.6M  1 loop  /snap/snapd/17883
loop1     7:1    0  103M  1 loop  /snap/lxd/23541
loop2     7:2    0 63.2M  1 loop  /snap/core20/1738
sda       8:0    0   40G  0 disk
└─sda1    8:1    0   40G  0 part
  └─md0   9:0    0   40G  0 raid1 /
sdb       8:16   0   10M  0 disk
sdc       8:32   0   40G  0 disk
└─sdc1    8:33   0   40G  0 part
root@otus-node-0 ~ #
~~~
Убиваем старые разделы и создаем один новый - на весь объем
~~~
fdisk /dev/sdc
~~~
добавляем бывший системный диск в массив
~~~
mdadm --manage /dev/md0 --add /dev/sdc1
~~~
Обновляем GRUB
~~~
grub-install /dev/sda
~~~
После чего сморим как перестраивается наш деградированный массив в полноценно рабочий.
~~~
root@otus-node-0 ~ # cat /proc/mdstat
Personalities : [raid1] [linear] [multipath] [raid0] [raid6] [raid5] [raid4] [raid10]
md0 : active raid1 sdc1[2] sda1[1]
      41908224 blocks super 1.2 [2/1] [_U]
      [==>..................]  recovery = 14.3% (6001152/41908224) finish=2.8min speed=206936K/sec

unused devices: <none>
~~~
После перестроения массива, система готова к работе на RAID 1
~~~
root@otus-node-0 ~ # cat /proc/mdstat
Personalities : [raid1] [linear] [multipath] [raid0] [raid6] [raid5] [raid4] [raid10]
md0 : active raid1 sdc1[2] sda1[1]
      41908224 blocks super 1.2 [2/2] [UU]

unused devices: <none>
~~~
~~~
root@otus-node-0 ~ # lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
loop0     7:0    0 49.6M  1 loop  /snap/snapd/17883
loop1     7:1    0  103M  1 loop  /snap/lxd/23541
loop2     7:2    0 63.2M  1 loop  /snap/core20/1738
sda       8:0    0   40G  0 disk
└─sda1    8:1    0   40G  0 part
  └─md0   9:0    0   40G  0 raid1 /
sdb       8:16   0   10M  0 disk
sdc       8:32   0   40G  0 disk
└─sdc1    8:33   0   40G  0 part
  └─md0   9:0    0   40G  0 raid1 /

~~~
