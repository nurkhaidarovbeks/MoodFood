#!/bin/bash
# MoodFood — PostgreSQL daily backup script
# Add to cron: 0 2 * * * /app/moodfood/scripts/backup.sh >> /var/log/moodfood-backup.log 2>&1
set -e

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/moodfood-$DATE.sql"

mkdir -p "$BACKUP_DIR"

echo "[$DATE] Starting backup..."

# Create backup from running container
docker exec moodfood-postgres pg_dump -U moodfood moodfood > "$BACKUP_FILE"

# Verify backup is not empty
if [ ! -s "$BACKUP_FILE" ]; then
  echo "[$DATE] ERROR: Backup file is empty. Something went wrong."
  rm -f "$BACKUP_FILE"
  exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$DATE] Backup created: $BACKUP_FILE ($BACKUP_SIZE)"

# Delete backups older than 7 days
find "$BACKUP_DIR" -name "moodfood-*.sql" -mtime +7 -delete
echo "[$DATE] Old backups cleaned up (7-day retention)"

echo "[$DATE] Backup complete."

# ── Restore instructions ────────────────────────────────────────────────────
# To restore a backup:
#   docker exec -i moodfood-postgres psql -U moodfood moodfood < /backups/moodfood-YYYYMMDD-HHMMSS.sql
