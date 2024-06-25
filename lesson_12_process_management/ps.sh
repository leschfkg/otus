#!/bin/bash
# https://www.baeldung.com/linux/total-process-cpu-usage
# https://stackoverflow.com/questions/16726779/how-do-i-get-the-total-cpu-usage-of-an-application-from-proc-pid-stat

clk_tck=$(getconf CLK_TCK) #получить количество тактов в секунду, прочитав конфигурацию системы

(echo "PID|TTY|STAT|TIME|COMMAND";
for pid in $(ls /proc | grep -E "^[0-9]+$"); do
    if [ -d /proc/$pid ]; then
        stat=($(sed -e 's/(//' -e 's/)//' "/proc/$pid/stat")) #создаем массив удаляя скобки из названии процесса
		cmd=${stat[1]}                                        #получаем pid из массива
		state=${stat[2]}                                      #получаем статус из массива
		tty=${stat[6]}                                        #получаем tty из массива
		utime=${stat[13]}                                     #получаем время в пространсве пользователя в тактах
		stime=${stat[14]}                                     #получаем время в пространсве ядра в тактах
        let total_time="($utime + $stime) / clk_tck"          #суммируем и делим на такты для перевода в секунды
        echo "${pid}|${tty}|${state}|${total_time}|${cmd}"
    fi
done) | sort -n | column -t -s "|"
