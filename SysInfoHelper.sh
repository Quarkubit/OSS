#!/bin/bash

# Инициализация переменных для путей
log_PATH=""
error_PATH=""

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
    if [ ! -e "$path" ]; then
        touch "$path"
    fi
    if [ ! -w "$path" ]; then
        echo "Ошибка записи в файл $path" >&2
        if [ -n "\$ERROR_FILE" ]; then
            echo "Ошибка записи в файл \$path" >> "\$ERROR_FILE"
        fi
        exit 1
    fi
}

# Функция перенаправления стандартного вывода
r_stdout() {
    local log_PATH="$1"
    check_path "$log_PATH"
    exec > "$log_PATH"
}

# Функция перенаправления стандартного потока ошибок
r_stderr() {
    local error_PATH="$1"
    check_path "$error_PATH"
    exec 2>"$error_PATH"
}

# Обработка аргументов командной строки
TEMP=$(getopt -o uphl:e: --long users,processes,help,log:,errors: -n 'SysInfoHelper.sh' -- "$@")
if [ $? != 0 ]; then
    echo "Ошибка в параметрах" >&2
    if [ -n "$ERROR_FILE" ]; then
        echo "Ошибка в параметрах" >> "$ERROR_FILE"
    fi
    show_help
    error_check
    exit 1
fi

eval set -- "$TEMP"

COMMAND=$(echo "$TEMP" | sed 's/ --$//')

# Запись использованной команды в лог-файл
if [ -n "$LOG_FILE" ]; then
    echo "$0 $COMMAND" >> "$LOG_FILE"
fi

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
            r_stdout "$log_PATH"
            shift 2
            ;;
        -e|--errors)
            ERROR_FILE="$2"
            r_stderr "$error_PATH"
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
            echo "Ошибка в параметрах111" >&2
            if [ -n "$ERROR_FILE" ]; then
                echo "Ошибка в параметрах" >> "$ERROR_FILE"
            fi
            show_help
            exit 1
            ;;
    esac
done



#Проверка ошибок и запись сообщения об отсутствии ошибок, если их нет
error_check() {

	# Проверка количества строк в файле ошибок
	LINE_COUNT=$(wc -l < "$ERROR_FILE")
	if [ "$LINE_COUNT" -gt 1 ]; then
	    # Удаление фразы "Ошибок нет", если она существует
	    sed -i "/Ошибок нет/d" "$ERROR_FILE"
	fi
}

# Проверка количества строк в файле ошибок
error_check
