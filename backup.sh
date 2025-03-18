#!/bin/bash

# Налаштування
LOCAL_DIR="$HOME/data"
REMOTE_USER="vagrant"
REMOTE_HOST="192.168.56.11"
REMOTE_DIR="/home/vagrant/backup"
SSH_KEY="/home/vagrant/private_key"  # Шлях до приватного ключа
LOCAL_BACKUP_DIR="$HOME/backup_copy"  # Локальна копія резервних файлів

# Лог-файл
LOG_FILE="$HOME/backup.log"

# Виправлення прав доступу до приватного ключа
chmod 600 "$SSH_KEY"

# Перевірка наявності локального каталогу
if [ ! -d "$LOCAL_DIR" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ❌ Локальний каталог $LOCAL_DIR не існує!" | tee -a "$LOG_FILE"
    mkdir -p "$LOCAL_DIR"
fi

# Перевірка наявності локальної папки для копій
mkdir -p "$LOCAL_BACKUP_DIR"

# Перевірка доступності сервера
ping -c 2 $REMOTE_HOST > /dev/null
if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ❌ Сервер $REMOTE_HOST недоступний!" | tee -a "$LOG_FILE"
    exit 1
fi

# Перевірка та створення каталогу backup на віддаленому сервері
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

# Створення архіву з міткою часу
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"
tar -czf "/tmp/$ARCHIVE_NAME" -C "$LOCAL_DIR" .

# Передача архіву на сервер через SCP
scp -i "$SSH_KEY" "/tmp/$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ✅ Резервне копіювання успішне: $ARCHIVE_NAME" | tee -a "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') ❌ Помилка резервного копіювання!" | tee -a "$LOG_FILE"
    exit 1
fi

# Завантаження архіву назад на локальну машину
scp -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$ARCHIVE_NAME" "$LOCAL_BACKUP_DIR"

if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ✅ Копія збережена локально у $LOCAL_BACKUP_DIR" | tee -a "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') ❌ Помилка при копіюванні архіву назад!" | tee -a "$LOG_FILE"
fi

# Видалення старих резервних копій на сервері (залишаємо лише 3 останніх)
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_DIR && ls -tp | grep -v '/$' | sed -n '4,\$p' | xargs -r rm --"

# Видалення старих локальних копій (залишаємо лише 3 останніх)
ls -tp "$LOCAL_BACKUP_DIR" | grep -v '/$' | sed -n '4,$p' | xargs -I {} rm -f "$LOCAL_BACKUP_DIR/{}"

# Видалення тимчасового файлу
rm "/tmp/$ARCHIVE_NAME"

exit 0
