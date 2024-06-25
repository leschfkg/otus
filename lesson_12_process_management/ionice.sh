#!/bin/bash
time ionice -c 1 -n 0 su -c "$(dd if=/dev/zero of=/tmp/test0.img bs=10M count=100 oflag=direct)" & \
time ionice -c 1 -n 7 su -c "$(dd if=/dev/zero of=/tmp/test7.img bs=10M count=100 oflag=direct)" &  ### вопрос su -c, без этого ошибка ionice: failed to execute : No such file or directory, хотя все выполняется и файлы создаются
