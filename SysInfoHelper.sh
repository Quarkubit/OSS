#!/bin/bash

# -h, --help        Функция для вывода справки
show_help() {
    echo "Использование: $0 [OPTIONS]"
    echo "[OPTIONS]:"
    echo "  -h, --help          Выводит данную справку"
    echo "  -u, --users         Выводит перечень пользователей и их домашних директорий"
    echo "  -p, --processes     Выводит перечень запущенных процессов (номер и название)"
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

# Функция для проверки доступа к пути
check_path() {
    local path=$1
        if [ ! -w "$path" ]; then
            echo "Ошибка записи в файл $path" >&2
            exit 1
        fi
}

# Обработка аргументов командной строки
TEMP=$(getopt -o uphl:e: --long users,processes,help,log:,errors: -n 'SysInfoHelper.sh' -- "$@")
if [ $? != 0 ]; then
    echo "Ошибка в параметрах" >&2
    show_help
    exit 1
fi

eval set -- "$TEMP"

LOG_FILE=""
ERROR_FILE=""

while true; do
    case "$1" in
        -u|--users)
            list_users
            shift
            ;;
        -p|--processes)
            list_processes
            shift
            ;;
        -l|--log)
            LOG_FILE="$2"
            check_path "$LOG_FILE"
            exec > "$LOG_FILE"
            shift 2
            ;;
        -e|--errors)
            ERROR_FILE="$2"
            check_path "$ERROR_FILE"
            exec 2> "$ERROR_FILE"
            shift 2
            ;;
        -h|--help)
            show_help
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Ошибка в параметрах" >&2
            show_help
            exit 1
            ;;
    esac
done
