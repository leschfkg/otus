#!/bin/bash

echo "COMMAND|PID|USER|NAME" | column -t -s "|"
(for pid in $(ls /proc | grep -E "^[0-9]+$"); do  # Получаем pid процессов
    if [ -d /proc/$pid ]; then
        uid=$(awk '/Uid/{print $2}' /proc/$pid/status) # Получаем uid пользователя
        cmd=$(cat /proc/$pid/comm)                     # Получаем имя процесса
		if [ $uid -eq 0 ]; then
            user_name='root'
        else
            user_name=$(grep $uid /etc/passwd | awk -F ":" '{print $1}')
        fi
		open_files=$(readlink /proc/$pid/map_files/*; readlink /proc/$pid/cwd) # Получаемоткрытые файлы и рабочую директорию
		if ! [ -z "$open_files" ]; then
			for num in $open_files; do
        echo "${cmd}|${pid}|${user_name}|${num}"
		done
		fi
    fi
done) | sort -n | column -t -s "|"