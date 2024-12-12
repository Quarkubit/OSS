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
    echo "  -e, --error PATH   Замещает вывод ошибок из потока stderr в файл по заданному пути PATH"
}

# -u, --users        Функция для вывода пользователей и их домашних директорий
list_users() {
    awk -F: '$3>=1000 { print $1 " " $6 }' /etc/passwd | sort
}

# -p, --processes        Функция для вывода запущенных процессов
list_processes() {
    ps -e -o pid,comm | sort -n
}

# Функция для проверки доступа к пути
check_path() {
    local path=$1
    if [ -f "$path" ]; then
        rm "$path"
    fi
    if [ ! -e "$path" ]; then
        touch "$path"
    fi
    if [ ! -w "$path" ]; then
        echo "Ошибка записи в файл $path" >&2
        if [ -n "\$error_PATH" ]; then
            echo "Ошибка записи в файл \$path" >> "\$error_PATH"
        fi
        exit 1
    fi
}

#Проверка ошибок и запись сообщения об отсутствии ошибок, если их нет
error_check() {
	# Проверка количества строк в файле ошибок
	LINE_COUNT=$(wc -l < "$error_PATH")
	if [ "$LINE_COUNT" -gt 1 ]; then
	    # Удаление фразы "Ошибок нет", если она существует
	    sed -i "/Ошибок нет/d" "$error_PATH"
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

#Обработка аргументов командной строки
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            list_users

            ;;
        p)
            list_processes

            ;;
        h)
            show_help

            ;;
        l)
            log_PATH="$OPTARG"
            r_stdout "$log_PATH"
            ;;
        e)
            error_PATH="$OPTARG"
            r_stderr "$error_PATH"
            ;;
        -)
            case "${OPTARG}" in
                users)
                    list_users

                    ;;
                processes)
                    list_processes

                    ;;
                help)
                    show_help

                    ;;
                log)
                    log_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    r_stdout "$log_PATH"
                    ;;
                errors)
                    error_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    r_stderr "$error_PATH"
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [ -e "$error_PATH" ]; then
        echo "Ошибок нет" >> "$error_PATH"
        error_check
fi


