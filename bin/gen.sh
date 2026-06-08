#!/bin/bash

# Настройки
NUM_KEYS=1000000
PREFIX="user:"
OUTPUT_FILE="data.txt"

echo "Генерация $NUM_KEYS команд в файл $OUTPUT_FILE..."

# Создаем временный файл со случайными строками
# Генерируем в 10 раз больше случайных байт, чем нужно
# (6 байт на строку + 6 букв + разделители)
> "$OUTPUT_FILE"

for i in $(seq 1 $NUM_KEYS); do
    # Генерируем 6 случайных байт и преобразуем в буквы
    RAND_STR=$(head -c 6 /dev/urandom | od -An -tu1 | \
               awk '{
                   letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                   result=""
                   for(i=1;i<=6;i++) {
                       idx = ($i % 52) + 1
                       result = result substr(letters, idx, 1)
                   }
                   print result
               }')

    echo "SET ${PREFIX}${i} ${RAND_STR}" >> "$OUTPUT_FILE"

    if [ $((i % 100000)) -eq 0 ]; then
        echo "Сгенерировано $i ключей..."
    fi
done

echo "Готово! Файл $OUTPUT_FILE создан."
