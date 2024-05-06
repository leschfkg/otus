1. клонируйте репозиторий git clone git@github.com:leschfkg/otus.git
2. перейдите в директорию cd otus/lesson_1_Where_does_Linux_begin
3. измените конфигурцию под себя в файле Vagrantfile
4. добавьте публичную часть ключа в файл authorized_keys
5. запустите создание ВМ - vagrant up


Версия VirtualBox 7.0.14
Если через shell устанвливать ПО, то отваливается VirtualBox Shared Folders, установку ПО через шелл пока убрал.

Обновление ядра:

1. Для того чтобы посмотреть текущую версию ядра, установленную в системе используйте такую команду: uname -a
2. Обновление ядра:
        2.1 Первый способ, будет установлена последняя версия linux ядра, официально поддерживаемого ОС Ubuntu. Минус этого способа в том, что официально поддерживаемое ядро обычно не самое новое:

           sudo apt update && sudo apt -y upgrade 

        2.2 Второй способ, перейти на сайт https://kernel.ubuntu.com/mainline/, выбрать директорию с версией ядра linux, на открывшейся странице будут ссылки на .deb файлы. Нужно скачать 4 из них:

linux-headers-{version}-generic_{version}.{date}_amd64.deb
linux-headers-{version}_{version}.{date}_all.deb
linux-image-unsigned-{version}-generic_{version}.{date}_amd64.deb
linux-modules-{version}-generic_{version}.{date}_amd64.deb

        2.3 После того, как вы скачали файлы, их нужно установить с помощью команды: sudo apt install -y ~/Downloads/linux-*.deb

Сборка ядра Linux из исходников:

1. Для того чтобы посмотреть текущую версию ядра, установленную в системе используйте такую команду: uname -a
2. Установка необходимых пакетов:
    apt install --yes make build-essential bc bison flex libssl-dev libelf-dev wget cpio fdisk extlinux dosfstools qemu-system-x86
3. Получение исходников ядра с kernel.org
4. Получить конфиг текущей конфигурации ядра:
    cd /boot && ls -la 
    cp /boot/config-5.15.0-56-generic .config

5. Первый вариант, сборка через oldconfig(при таком способе конфигурации ядра останутся включёнными многие ненужные модули, а значит сборка займет много времени, много места на диске (до 20 Гб) и само ядро получится большого размера.)
        5.1 make oldconfig
            После запуска скрипта вам придется просмотреть все вопросы и ответить на них. Обычно скрипт советует как отвечать и в большинстве случаев можно оставить значение по умолчанию, с версии ядер 6.3 выполнить отключение проверки сертификатов:
            scripts/config --disable SYSTEM_TRUSTED_KEYS
            scripts/config --disable SYSTEM_REVOCATION_KEYS
        5.2 Сборка ядра и установка вручную:
            make  -j8 (колличество ядер используемых пр сборке)
            make modules
            make modules_install
            make install
            reboot
6. Второй вариант, сборка через localmodulesconfig, она работает аналогично предыдущей, только в дополнение к этому проверяет какие модули ядра сейчас загружены и оставляет включёнными только их, сборку всех остальных отключает. Такое ядро соберется намного быстрее и это ответ на вопрос как собрать ядро Linux под свое железо  проще всего.
        6.1 make localmodulesconfig
            После запуска скрипта вам придется просмотреть все вопросы и ответить на них. Обычно скрипт советует как отвечать и в большинстве случаев можно оставить значение по умолчанию, с версии ядер 6.3 выполнить отключение проверки сертификатов:
            scripts/config --disable SYSTEM_TRUSTED_KEYS
            scripts/config --disable SYSTEM_REVOCATION_KEYS
        6.2 Сборка ядра и установка вручную:
            make  -j8 (колличество ядер используемых пр сборке)
            make modules
            make modules_install
            make install
            reboot
