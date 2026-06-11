#!/bin/bash
# MoodFood — Production deploy script
# Run on the server after git pull, or via GitHub Actions SSH step.
set -e

DEPLOY_DIR="/app/moodfood"
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M%S)

echo "=== MoodFood Deploy — $DATE ==="

# 1. Pull latest code
cd "$DEPLOY_DIR"
git pull origin main
echo "[1/5] Code updated"

# 2. Backup database before any migration
mkdir -p "$BACKUP_DIR"
docker exec moodfood-postgres pg_dump -U moodfood moodfood > "$BACKUP_DIR/pre-deploy-$DATE.sql"
if [ ! -s "$BACKUP_DIR/pre-deploy-$DATE.sql" ]; then
  echo "ERROR: Backup is empty. Aborting deploy."
  exit 1
fi
echo "[2/5] Database backup saved: $BACKUP_DIR/pre-deploy-$DATE.sql"

# 3. Run migrations (against running postgres container)
cd "$DEPLOY_DIR/Backend"
DATABASE_URL="postgresql://moodfood:${DB_PASSWORD:-moodfood_dev}@localhost:5434/moodfood?schema=public" \
  npx prisma migrate deploy
echo "[3/5] Migrations applied"

# 4. Rebuild and restart containers
cd "$DEPLOY_DIR"
docker-compose up --build -d
echo "[4/5] Containers restarted"

# 5. Wait for health check
echo "[5/5] Waiting for health check..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:3000/health > /dev/null; then
    echo "=== Deploy successful! App is healthy. ==="
    exit 0
  fi
  echo "  Attempt $i/30..."
  sleep 2
done

echo "=== DEPLOY FAILED: health check timed out after 60s ==="
exit 1
