#!/bin/bash
mdadm --create --verbose --force /dev/md0 --level=10 --raid-devices=4 /dev/sd{c,d,e,f}
cat /proc/mdstat
mdadm --detail --scan | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20% && parted /dev/md0 mkpart primary ext4 20% 40% && \
parted /dev/md0 mkpart primary ext4 40% 60% && parted /dev/md0 mkpart primary ext4 60% 80% && \
parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5)
    do 
        mkfs.ext4 /dev/md0p"$i"
    done
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5)
    do 
        echo $(blkid /dev/md0p"$i" | awk '{print $2}') /raid/part"$i" ext4 defaults 1 2 >> /etc/fstab
    done
mount -a