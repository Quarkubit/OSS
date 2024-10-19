#!/bin/bash

# -h, --help        Функция для вывода справки
show_help() {
    echo "Использование: $0 [OPTIONS]"
    echo "[OPTIONS]:"
    echo "  -u, --users         Выводит перечень пользователей и их домашних директорий"
    echo "  -p, --processes     Выводит перечень запущенных процессов"
    echo "  -h, --help          Выводит эту справку"
    echo "  -l, --log PATH      Замещает вывод на экран выводом в файл по заданному пути PATH"
    echo "  -e, --errors PATH   Замещает вывод ошибок из потока stderr в файл по заданному пути PATH"
}

# -u, --users        Функция для вывода пользователей и их домашних директорий
list_users() {
getent passwd | awk -F: '{print $1, $6}' | sort
}

# -p, --processes        Функция для вывода запущенных процессов
list_processes() {
ps -e -o pid,comm | sort -n
}

# -l, --log PATH        Функция для проверки доступа к пути
check_path() {

}

# -e, --errors PATH        Обработка аргументов командной строки
check_path() {

}

while true; do

done
