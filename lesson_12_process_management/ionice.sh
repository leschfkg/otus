#!/bin/bash
time ionice -c 1 -n 0 dd if=/dev/zero of=/tmp/test0.img bs=10M count=100 oflag=direct & \
time ionice -c 1 -n 7 dd if=/dev/zero of=/tmp/test7.img bs=10M count=100 oflag=direct &  
