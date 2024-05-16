# Lesson №3 - Ansible_1

## Getting started

1. клонируйте репозиторий 
~~~
git clone git@github.com:leschfkg/otus.git
~~~
2. перейдите в директорию:
~~~
 cd otus/lesson_3_Ansible_1
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



6. Подключитесь к первому серверу по ssh и установите ansible:
~~~
apt update -y && apt install ansible
~~~
7. Скопируйте директорию ./staging на сервер
8. скопируйте ваш приватный ключ на сервер(который использовали в шаге 4) и укажите в файле staging\group_vars\web путь к приватному ключу
9. Проверьте соединения с конфигурируемыми серверами 
~~~
ansible-playbook ping.yml
~~~
10. Выполните конфигурацию серверов, для установки nginx: 
~~~
ansible-playbook nginx.yml
~~~
проверьте работу nginx:
~~~
curl http://server_ip:8080
~~~