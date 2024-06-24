#!/bin/bash
LOG_FILE=access.log
TEMP_FILE=/root/temp.log
CURRENT_HOUR=$(date +"%d/%b/%Y:%H")
LAST_HOUR=$(date +"%d/%b/%Y:%H" --date '-1 hour')
if [[ ! -f "$TEMP_FILE" ]]; then
  echo "Лог файл не существует, обрабатываем все данные что есть в логе и создаем темп файл для обработки по часам"
  touch $TEMP_FILE
  # Список IP адресов (с наибольшим кол-вом запросов)
  echo "Список IP адресов (с наибольшим кол-вом запросов)"
  echo "кол-во  IP адрес"
  awk '{print $1}' $LOG_FILE | sort | uniq -c | sort -rn | head -10
  echo "--------------------------------------------"
  # Список запрашиваемых URL
  echo "Список запрашиваемых URL (с наибольшим кол-вом запросов)"
  echo "кол-во  URL адрес"
  awk '{print $7}' $LOG_FILE | sort | uniq -c | sort -rn | head -10
  echo "--------------------------------------------"
  # Все ошибки c момента последнего запуска
  echo "Все ошибки"
  echo "колл-во код ошибки"
  cat $LOG_FILE | cut -d '"' -f3 | cut -d ' ' -f2 | grep -v '200\|30*' | sort | uniq -c | sort -rn
  echo "--------------------------------------------"
  # Список всех кодов HTTP
  echo "Список всех кодов HTTP"
  echo "колл-во код ответа"
  cat $LOG_FILE | cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn
  echo "--------------------------------------------"
else
  grep "$CURRENT_HOUR" $LOG_FILE > $TEMP_FILE
  echo -e "Oбрабатываемый временной диапазон c $(date +"%d/%b/%Y:%H:%M" --date '-1 hour') по $(date +"%d/%b/%Y:%H:%M")"
  # Список IP адресов (с наибольшим кол-вом запросов)
  echo "Список IP адресов (с наибольшим кол-вом запросов)"
  echo "кол-во  IP адрес"
  awk '{print $1}' $TEMP_FILE | sort | uniq -c | sort -rn | head -10
  echo "--------------------------------------------"
  # Список запрашиваемых URL
  echo "Список запрашиваемых URL (с наибольшим кол-вом запросов)"
  echo "кол-во  URL адрес"
  awk '{print $7}' $TEMP_FILE | sort | uniq -c | sort -rn | head -10
  echo "--------------------------------------------"
  # Все ошибки c момента последнего запуска
  echo "Все ошибки"
  echo "колл-во код ошибки"
  cat $TEMP_FILE | cut -d '"' -f3 | cut -d ' ' -f2 | grep -v '200\|30*' | sort | uniq -c | sort -rn
  echo "--------------------------------------------"
  # Список всех кодов HTTP
  echo "Список всех кодов HTTP"
  echo "колл-во код ответа"
  cat $TEMP_FILE | cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn
  echo "--------------------------------------------"
fi



