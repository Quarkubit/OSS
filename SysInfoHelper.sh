#!/bin/bash

# Файл для хранения путей
CONFIG_FILE="config.txt"

# Функция для чтения значений из файла
read_cfg() {
    if [ -f "$CONFIG_FILE" ] && [ -n "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        LOG_FILE="logs.txt"
        ERROR_FILE="errors.txt"
    fi
}

read_cfg

# -h, --help        Функция для вывода справки
show_help() {
    echo "Использование: $0 [OPTIONS]"
    echo "[OPTIONS]:"
    echo "  -h, --help          Выводит данную справку"
    echo "  -u, --users         Выводит перечень пользователей и их домашних директорий"
    echo "  -p, --processes     Выводит перечень запущенных процессов (номер и название)"
    echo "  -l, --log PATH      Замещает вывод на экран выводом в файл по заданному пути PATH"
    echo "  -e, --errors PATH   Замещает вывод ошибок из потока stderr в файл по заданному пути PATH"
    echo "  -c, --check		Проверить расположение файлов вывода -l и -e"
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

# Обработка аргументов командной строки
TEMP=$(getopt -o uphl:e:c --long users,processes,help,log:,errors:,check -n 'SysInfoHelper.sh' -- "$@")
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
            check_path "$LOG_FILE"
            exec > "$LOG_FILE"
            shift 2
            ;;
        -e|--errors)
            ERROR_FILE="$2"
            check_path "$ERROR_FILE"
            exec 2> >(tee -a "$ERROR_FILE" >&2)
            #echo "$ERROR_FILE"
	    shift 2
            ;;
        -h|--help)
            show_help
            shift
            ;;
	-c|--check)
	    echo "$ERROR_FILE"
	    echo "$LOG_FILE"
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
if [ ! -s "$ERROR_FILE" ]; then
    echo "Ошибок нет" >> "$ERROR_FILE"
fi

# Функция для записи значений в файл
write_cfg() {
    echo "LOG_FILE=\"$LOG_FILE\"" > "$CONFIG_FILE"
    echo "ERROR_FILE=\"$ERROR_FILE\"" >> "$CONFIG_FILE"
}

write_cfg
