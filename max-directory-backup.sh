#!/bin/bash
############################################################################
# Это скрипт для создания резервных копий любой директории.                #
# При запуске скрипта передать путь до конфиг файла с помощью ключа -c     #
# ПРИМЕР: ./max-directory-backup.sh -c ./max-directory-backup.conf         #
#                                                                          #
# Конфиг файл должен содержать шесть пар "ключ":"значение" в формате json: #
# ПРИМЕР:                                                                  #
# {                                                                        #
#     "what": "/PATH/TO/BACKUP_DIR", "where": "/PATH/TO/STORAGE_DIR",      #
#     "YEARLY_FILE_LIMIT": "1", "MONTHLY_FILE_LIMIT": "3",                 #
#     "WEEKLY_FILE_LIMIT": "4", "DAILY_FILE_LIMIT": "6"                    #
# }                                                                        #
############################################################################

# перешел на вывод логов в STDOUT/STDERR, но при необходимости можно опять вернуть >> $PATH_TO_LOG в логировании
#PATH_TO_LOG=$(pwd)/max-directory-backup.log

# чтобы скрипт не мог запуститься в 2 экземпляра
LOCK_FILE=/tmp/max-directory-backup.lock
LOCK_FD=9
get_lock() {
    eval "exec $LOCK_FD>$LOCK_FILE"
    flock -n $LOCK_FD
}
get_lock || exit

create_backup() {
    if [ -d "${1}" ]; then # проверяем существует ли архивируемый объект
        WHAT="${1}"  # ЧТО сохраняем
        if [ "$(dpkg -s tar 2>/dev/null | grep "Status: install ok installed")" == "" ]; then # проверка установлен ли пакет tar
            echo "$(date) | Error | Не смог выполнить резервное копирование, т.к. не установлен архиватор tar" >&2
        else
            if [ -d "${2}" ]; then # проверяем существует ли папка назначения, если нет - создаём
                WHERE="${2}" # КУДА сохраняем
            else
                echo "$(date) | Info | Нет директории, указанной как место хранения - ${2}, создаю её"
                mkdir "${2}"
                WHERE="${2}" # КУДА сохраняем
            fi

            if [ "$(date +%m.%d)" == "12.31" ]; then # сегодня 31 декабря
                WHERE="${WHERE}/yearly"
            elif [ "$(date +%d)" == "01" ]; then # сегодня 1 день месяца
                WHERE="${WHERE}/monthly"
            elif [ "$(date +%A)" == "Sunday" -o "$(date +%A)" == "Воскресение" ]; then # сегодня воскресение
                WHERE="${WHERE}/weekly"
            else # сегодня любой другой день
                WHERE="${WHERE}/daily"
            fi
            mkdir -p "${WHERE}"
            WHAT=$(echo "${WHAT}" | sed 's/\/$//') # если в конце пути стоит /, то уберём его
            ARCHIVE_NAME=$(echo "${WHAT}" | sed 's|.*/||')_$(date "+%Y.%m.%d-%Hh%Mm") # возьмём всё что после / - это и будет имя папки, и добавим к нему дату
            
            tar -P -czf "${WHERE}/${ARCHIVE_NAME}.tar.gz" "${WHAT}" # нужно ли использовать -P, чтобы убрать вывод "tar: Removing leading `/' from member names"?
            echo "$(date) | Info | Резервное копирование завершено. Архив ${ARCHIVE_NAME}.tar.gz помещен в директорию ${WHERE}"
            return 0
        fi
    else
        echo "$(date) | Error | Архивируемый объект ${1} не существует" >&2
    fi
}

# удаление бэкапов старше заданного количества дней/недель/месяцев/лет
clear_backup_folder() {
    BACKUP_DIR="${1}"
    if [ "$(date +%m.%d)" == "12.31" ]; then # сегодня 31 декабря
        LIMIT="$(cat ${CONFIG} | jq -r '.YEARLY_FILE_LIMIT')"
        echo "$(date) | Info | Очистка бэкапов старше ${LIMIT} лет из директории ${BACKUP_DIR}/yearly"
        find "${BACKUP_DIR}/yearly" -type f -mtime +$( expr 365 \* "${LIMIT}" ) -delete
    elif [ "$(date +%d)" == "01" ]; then # сегодня 1 день месяца
        LIMIT="$(cat ${CONFIG} | jq -r '.MONTHLY_FILE_LIMIT')"
        echo "$(date) | Info | Очистка бэкапов старше ${LIMIT} месяцев из директории ${BACKUP_DIR}/monthly"
        find "${BACKUP_DIR}/monthly" -type f -mtime +$( expr 30 \* "${LIMIT}" ) -delete
    elif [ "$(date +%A)" == "Sunday" -o "$(date +%A)" == "Воскресение" ]; then # сегодня воскресение
        LIMIT="$(cat ${CONFIG} | jq -r '.WEEKLY_FILE_LIMIT')"
        echo "$(date) | Info | Очистка бэкапов старше ${LIMIT} недель из директории ${BACKUP_DIR}/weekly"
        find "${BACKUP_DIR}/weekly" -type f -mtime +$( expr 7 \* "${LIMIT}" ) -delete
    else # сегодня любой другой день
        LIMIT="$(cat ${CONFIG} | jq -r '.DAILY_FILE_LIMIT')"
        echo "$(date) | Info | Очистка бэкапов старше ${LIMIT} дней из директории ${BACKUP_DIR}/daily"
        find "${BACKUP_DIR}/daily" -type f -mtime +$( expr 1 \* "${LIMIT}" ) -delete
    fi
}


# MAIN

while [ -n "$1" ]
do
    case "$1" in
    -c)
        CONFIG="${2}"
        echo "$(date) | Info | Используется конфиг файл ${CONFIG}"
        WHAT="$(cat ${CONFIG} | jq -r '.what')" # в этой переменной хранится ЧТО сохраняем
        WHERE="$(cat ${CONFIG} | jq -r '.where')" # в этой переменной КУДА сохраняем
        if [ -e "${WHAT}" -a -n "${WHERE}" ]; then # проверяем что оба аргумента были введены
            echo "$(date) | Info | Начинаю резервное копирование директории "${WHAT}" в хранилище бэкапов "${WHERE}""
            create_backup "${WHAT}" "${WHERE}"
            if [ $? == 0 ]; then # если создание бекапа выполнилось успешно
                clear_backup_folder "$(cat ${CONFIG} | jq -r '.where')"
            fi
        else
            echo "$(date) | Error | Проверьте в конфиг файле пути к директориям для бекапа" >&2
        fi
        shift
        ;;
    *) echo "$(date) | Error | $1 - неопознанный аргумент" >&2 ;;
    esac
    shift
done
