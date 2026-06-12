#!/bin/bash
# MoodFood — Ручной триггер деплоя на Render
# Используй когда нужно передеплоить без пуша кода
#
# Использование:
#   export RENDER_DEPLOY_HOOK_URL="https://api.render.com/deploy/srv-xxx?key=yyy"
#   ./scripts/deploy.sh

set -e

DEPLOY_HOOK_URL="${RENDER_DEPLOY_HOOK_URL:?Переменная RENDER_DEPLOY_HOOK_URL не задана}"

echo "=== MoodFood — Триггер Render деплоя ==="
echo "Отправляем запрос..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$DEPLOY_HOOK_URL")

if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
  echo "✓ Деплой запущен (HTTP $STATUS)"
  echo "Следи за прогрессом: https://dashboard.render.com"
else
  echo "✗ Ошибка: не удалось запустить деплой (HTTP $STATUS)"
  exit 1
fi
