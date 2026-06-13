#!/bin/bash
# MoodFood — Резервная копия БД через Render External Database URL
# Запускай локально (нужен pg_dump установленный на машине)
#
# Использование:
#   export DATABASE_URL="postgresql://user:pass@dpg-xxx.oregon-postgres.render.com/moodfood"
#   ./scripts/backup.sh
#
# DATABASE_URL берёшь в Render Dashboard → PostgreSQL → Info → External Database URL
# Скопируй его в .env.backup (этот файл НЕ коммить в git)

set -e

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/moodfood-$DATE.sql"

DB_URL="${DATABASE_URL:?Переменная DATABASE_URL не задана. Скопируй External Database URL из Render Dashboard}"

mkdir -p "$BACKUP_DIR"
echo "[$(date)] Начинаем бэкап..."

pg_dump "$DB_URL" > "$BACKUP_FILE"

if [ ! -s "$BACKUP_FILE" ]; then
  echo "[$(date)] ОШИБКА: файл бэкапа пустой"
  rm -f "$BACKUP_FILE"
  exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] Бэкап сохранён: $BACKUP_FILE ($BACKUP_SIZE)"

# Удаляем бэкапы старше 7 дней
find "$BACKUP_DIR" -name "moodfood-*.sql" -mtime +7 -delete
echo "[$(date)] Старые бэкапы удалены (хранение: 7 дней)"
echo "[$(date)] Готово."

# Чтобы восстановить из бэкапа:
#   psql "$DATABASE_URL" < backups/moodfood-YYYYMMDD-HHMMSS.sql
