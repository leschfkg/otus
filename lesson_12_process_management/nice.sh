#!/bin/bash
time nice -n -20 tar -czvf test0.tar.gz --absolute-names /tmp/test0.img & \
time nice -n 19 tar -czvf test7.tar.gz --absolute-names /tmp/test7.img  &  