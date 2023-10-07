#!/bin/bash
###############################################
# Это скрипт для создания резервных копий     #
# любой выбранной вами директории.            #
# При запуске скрипта передать два параметра: #
# 1 - путь до сохраняемой директории,         #
# 2 - путь до места хранения бэкапов.         #
###############################################

PATH_TO_LOG=$(pwd)/max-directory-backup.log
YEARLY_FILE_LIMIT=1
MONTHLY_FILE_LIMIT=3
WEEKLY_FILE_LIMIT=4
DAILY_FILE_LIMIT=6

create_backup() {
    if [ "-e ${1}" -a "-n ${2}" ]; then # проверяем что оба аргумента были введены
        if [ -d "${2}" ]; then # проверяем существует ли папка назначения, если нет - создаём
            WHERE="${2}" # в этой переменной КУДА сохраняем
        else
            echo "Нет директории, указанной как место хранения - ${2}, создаю её" >> $PATH_TO_LOG
            mkdir "${2}"
            WHERE="${2}" # в этой переменной КУДА сохраняем
        fi

        if [ -d "${1}" ]; then # проверяем существует ли архивируемый объект
            WHAT="${1}"  # в этой переменной хранится ЧТО сохраняем
            echo "Начинаю резервное копирование директории ${WHAT} в хранилище бэкапов ${WHERE}" >> $PATH_TO_LOG
            if [ "$(dpkg -s tar 2>/dev/null | grep "Status: install ok installed")" == "" ]; then # проверка установлен ли пакет tar
                echo "Не смог выполнить резервное копирование, т.к. не установлен архиватор tar" >> $PATH_TO_LOG
            else
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
                tar -czf "${WHERE}/${ARCHIVE_NAME}.tar.gz" "${WHAT}" # нужно ли использовать -P, чтобы убрать вывод "tar: Removing leading `/' from member names"?
                
                echo "Резервное копирование завершено. Архив ${ARCHIVE_NAME}.tar.gz помещен в директорию ${WHERE}" >> $PATH_TO_LOG
                return 0
            fi
        else
            echo "Error: ${1} не существует" >> $PATH_TO_LOG
        fi

    else
        echo "Error: введите два параметра при запуске скрипта - путь до сохраняемой директории, путь до места хранения бэкапов." >> $PATH_TO_LOG
    fi
}

clear_backup_folder() {
    # советовали избавиться от этих условий, но я не знаю как от них избавиться,
    # мне нужно проверить 4 разных условия, поэтому case тут не подойдет
    if [ "$(ls -A ${1}/yearly | wc -l)" -gt "${YEARLY_FILE_LIMIT}" ]; then
        echo "Переполнение директории ${1}/yearly выше указанного лимита. Удаляю самый старый бэкап" >> $PATH_TO_LOG
        rm -rf "${1}/yearly/$(ls -rt ${1}/yearly | head -1)"
    fi
    if [ "$(ls -A ${1}/monthly | wc -l)" -gt "${MONTHLY_FILE_LIMIT}" ]; then
        echo "Переполнение директории ${1}/monthly выше указанного лимита. Удаляю самый старый бэкап" >> $PATH_TO_LOG
        rm -rf "${1}/monthly/$(ls -rt ${1}/monthly | head -1)"
    fi
    if [ "$(ls -A ${1}/weekly | wc -l)" -gt "${WEEKLY_FILE_LIMIT}" ]; then
        echo "Переполнение директории ${1}/weekly выше указанного лимита. Удаляю самый старый бэкап" >> $PATH_TO_LOG
        rm -rf "${1}/weekly/$(ls -rt ${1}/weekly | head -1)"
    fi
    if [ "$(ls -A ${1}/daily | wc -l)" -gt "${DAILY_FILE_LIMIT}" ]; then
        echo "Переполнение директории ${1}/daily выше указанного лимита. Удаляю самый старый бэкап" >> $PATH_TO_LOG
        rm -rf "${1}/daily/$(ls -rt ${1}/daily | head -1)"
    fi
}

echo "" >> "${PATH_TO_LOG}"
date >> "${PATH_TO_LOG}"
create_backup "${1}" "${2}"
if [ $? == 0 ]; then # если создание бекапа выполнилось успешно
    clear_backup_folder "${2}"
fi