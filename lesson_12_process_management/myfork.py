import os
import time
import sys
import signal  # импортируем модуль
# для выполнения использовал https://sky.pro/media/rabota-s-signalom-sigint-v-python/


# Функция для показа пользователю информации о номере сигнала и выход из программы
def exit_gracefully(signal, frame):
    print("SIGNAL: " + str(signal))
    sys.exit(0)


signal.signal(signal.SIGINT, exit_gracefully)  # Cttl + C, сигнал 2
# нормальное завершение программы, сигнал 15
signal.signal(signal.SIGTERM, exit_gracefully)
# выход пользователя ииз терминала, сигнал 1
signal.signal(signal.SIGHUP, exit_gracefully)

print('Hello! I am an example')
pid = os.fork()
print('pid of my child is %s' % pid)
if pid == 0:
    print('I am a child. Im going to sleep')
    for i in range(1, 40):
        print('mrrrrr')
        a = 2**i
        print(a)
        pid = os.fork()
        if pid == 0:
            print('my name is %s' % a)
            sys.exit(0)
        else:
            print("my child pid is %s" % pid)
        time.sleep(1)
    print('Bye')
    sys.exit(0)

else:
    for i in range(1, 200):
        print('HHHrrrrr')

        time.sleep(1)
        print(3**i)
    print('I am the parent')

# pid, status = os.waitpid(pid, 0)
# print "wait returned, pid = %d, status = %d" % (pid, status)
