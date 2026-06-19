# MoodFood Backend — Лог сессий разработки

> Репозиторий: https://github.com/nurkhaidarovbeks/MoodFood  
> Рабочая директория: `c:\Users\0penf\Corporate project\Backend`  
> Модель: Claude Sonnet 4.6

---

## Как использовать этот файл

Этот файл — быстрый контекст для Claude. Если начинаешь новую сессию, дай Claude этот файл и скажи: *«Прочитай SESSION_LOG.md и продолжим работу»*. Он поймёт всё что было сделано и сможет продолжить без повторных объяснений.

---

## Проект

MoodFood — AI-приложение для рекомендаций еды на основе настроения, бюджета, аллергий и диетических ограничений пользователя. Бэкенд написан с нуля.

**Стек:** Node.js + TypeScript + Express + Prisma + PostgreSQL + JWT + bcrypt + Zod + Jest

---

## Архитектурные решения (принятые раз и навсегда)

| Решение | Обоснование |
|---------|------------|
| **JWT stateless, без refresh** | MVP — упрощает старт |
| **bcrypt cost=12** | Стандарт для паролей |
| **DI для сервисов** | `AuthService(prisma)` — легко мокается в тестах |
| **jest-mock-extended** | Тесты без реальной БД, `*/config/database` → мок автоматически |
| **SHA-256 для токенов** | Сырой токен только в письме, в БД только хэш |
| **DietaryRestrictionService централизован** | Все будущие эндпоинты с рецептами ОБЯЗАНЫ проходить через него |
| **Email stub в dev** | Если SMTP пустой — письма в консоль |
| **Порт PostgreSQL: 5434** | На машине разработчика уже заняты 5432 (pg17) и 5433 (pg18) нативными Windows сервисами |

---

## Текущее состояние: что реализовано

### Сессия 1 — 30 мая 2026 (Epic 1)
- Email/password регистрация и вход
- Google OAuth (ID token, серверная верификация)
- Email верификация (MVP-режим: `REQUIRE_EMAIL_VERIFICATION=false`)
- Профиль питания: PUT (upsert), PATCH (частичное), GET
- DietaryRestrictionService — 10 типов ограничений + кастомные
- 36 тестов

### Сессия 3 — 6 июня 2026
- Epic 2: модуль рецептов — полный CRUD (`POST/GET/PUT/PATCH/DELETE /api/v1/recipes`)
- Эндпоинт рекомендаций (`GET /api/v1/recipes/recommendations`) — фильтрует через `DietaryRestrictionService`
- Фильтрация по настроению (`?mood=calm`), пагинация (`?limit=20&offset=0`)
- Ингредиенты хранятся через upsert — shared ingredients переиспользуются
- `validate` middleware расширен для поддержки query-параметров (`source: 'body' | 'query'`)
- Seed: `prisma/seed.ts` — 10 разнообразных рецептов (мясо, вегетарианские, веганские, разные настроения)
- **77 тестов — все зелёные** (+22 новых)

### Сессия 2 — 2 июня 2026
- Apple Sign In (ID token, серверная верификация через `apple-signin-auth`)
- OTP аутентификация (6 цифр, 5 минут, SHA-256 хэш, 3 попытки)
- Rate limiting на OTP: 3 отправки/15 мин, 10 попыток/5 мин
- SQL injection аудит — защита подтверждена (Prisma + Zod, нет raw queries)
- Исправлена проблема с портом PostgreSQL (переехали на 5434)
- Инициализирован git репозиторий, создан monorepo
- Создан корневой GUIDE.md для всей команды
- **55 тестов — все зелёные**

---

## Все файлы проекта

### Конфигурация
| Файл | Описание |
|------|---------|
| `package.json` | Зависимости и npm скрипты |
| `tsconfig.json` | TypeScript компилятор |
| `jest.config.ts` | Jest с moduleNameMapper для мока БД |
| `.env.example` | Шаблон переменных окружения |
| `.env` | Локальные переменные (не в git!) |
| `docker-compose.yml` | PostgreSQL + Backend — полный стек на портах 5434/3000 |
| `Dockerfile` | Multi-stage build для продакшн контейнера |
| `.dockerignore` | Исключает node_modules, dist, .env из образа |

### База данных
| Файл | Описание |
|------|---------|
| `prisma/schema.prisma` | Все модели и enum'ы (см. ниже) |
| `prisma/migrations/` | История миграций (коммитятся в git) |
| `prisma/seed.ts` | Seed: 2 subscription plans + 10 рецептов |

**Модели и поля:**

| Модель | Ключевые поля |
|--------|--------------|
| `User` | id, email, name, passwordHash, authProvider, googleId, appleId, isEmailVerified, otpHash/Expires/Attempts, isActive |
| `UserProfile` | userId, age, goal, lifestyle, budgetLevel, dietaryRestrictions (JSON), allergies (JSON), customRestrictions (JSON), onboardingCompleted |
| `Recipe` | title, cookingTimeMin, difficulty, estimatedCost, calories, proteinG, steps, moodTags (JSON) |
| `Ingredient` | name (unique), category |
| `RecipeIngredient` | recipeId, ingredientId, amount, unit |
| `UserIngredient` | userId, ingredientId *(кладовка)* |
| `Order` | userId, amount, currency, status, **orderType** (purchase/topup/subscription), gateway (bereke/paypal), gatewayOrderId, paymentUrl, transactionId |
| `Wallet` | userId (unique), balance |
| `WalletTransaction` | walletId, orderId, amount, currency, type (topup/payment/refund), description |
| `SubscriptionPlan` | type (monthly/annual unique), name, priceKzt, priceUsd, durationDays, isActive |
| `UserSubscription` | userId, planId, orderId (unique), status (pending/active/cancelled/expired), startedAt, expiresAt |

### Core
| Файл | Описание |
|------|---------|
| `src/config/env.ts` | Парсинг env (Bereke, PayPal, SMTP, JWT, ...) |
| `src/config/database.ts` | Singleton Prisma клиент |
| `src/utils/jwt.ts` | `signToken()`, `verifyToken()` |
| `src/utils/hash.ts` | `sha256()`, `generateToken()` |
| `src/utils/profile-completion.ts` | `isProfileComplete()` |

### Сервисы
| Файл | Описание |
|------|---------|
| `src/services/email.service.ts` | `sendEmail()`, `sendVerificationEmail()`, `sendOtpEmail()` |
| `src/services/google-oauth.service.ts` | `verifyGoogleIdToken()` |
| `src/services/apple-auth.service.ts` | `verifyAppleIdToken()` |
| `src/services/dietary-restriction.service.ts` | `canUserSeeRecipe()`, `filterRecipesForUser()` — **через него все рецепты** |
| `src/services/bereke.service.ts` | `bereRegisterOrder()`, `bereGetStatus()`, `bereRefund()` |
| `src/services/paypal.service.ts` | `createPayPalOrder()`, `capturePayPalOrder()` |

### Middleware
| Файл | Описание |
|------|---------|
| `src/middleware/auth.ts` | `requireAuth` — проверяет JWT из `Authorization: Bearer` |
| `src/middleware/validate.ts` | `validate(schema, source?)` — Zod валидация body / query |
| `src/middleware/errorHandler.ts` | `AppError` + глобальный обработчик |

### Модуль Auth
| Файл | Описание |
|------|---------|
| `src/modules/auth/auth.schema.ts` | Zod: Register, Login, GoogleAuth, AppleAuth, OtpSend, OtpVerify |
| `src/modules/auth/auth.service.ts` | register, login, googleAuth, appleAuth, verifyEmail, resendVerification, sendOtp, verifyOtp |
| `src/modules/auth/auth.controller.ts` | HTTP handlers |
| `src/modules/auth/auth.routes.ts` | Роуты + rate limiting на OTP |

### Модуль Profile
| Файл | Описание |
|------|---------|
| `src/modules/profile/profile.schema.ts` | Zod: ProfileUpsert, ProfilePatch |
| `src/modules/profile/profile.service.ts` | getProfile, upsertProfile, patchProfile |
| `src/modules/profile/profile.controller.ts` | HTTP handlers |
| `src/modules/profile/profile.routes.ts` | `requireAuth` на всех маршрутах |

### Модуль Recipes
| Файл | Описание |
|------|---------|
| `src/modules/recipes/recipe.schema.ts` | Zod: CreateRecipe, PatchRecipe, RecommendationsQuery |
| `src/modules/recipes/recipe.service.ts` | CRUD + recommendations (DietaryRestrictionService + matchScore) |
| `src/modules/recipes/recipe.controller.ts` | HTTP handlers |
| `src/modules/recipes/recipe.routes.ts` | Публичные GET + приватные CUD |

### Модуль Pantry
| Файл | Описание |
|------|---------|
| `src/modules/pantry/pantry.schema.ts` | Zod: AddIngredientsSchema |
| `src/modules/pantry/pantry.service.ts` | getIngredients, addIngredients, removeIngredient, clearPantry |
| `src/modules/pantry/pantry.controller.ts` | HTTP handlers |
| `src/modules/pantry/pantry.routes.ts` | Все под `requireAuth` |

### Модуль Payment
| Файл | Описание |
|------|---------|
| `src/modules/payment/payment.schema.ts` | Zod: CheckoutSchema (amount, gateway, **orderType**), RefundSchema |
| `src/modules/payment/payment.service.ts` | State machine, idempotency, `creditWallet`, `activateSubscriptionForOrder` |
| `src/modules/payment/payment.controller.ts` | HTTP handlers |
| `src/modules/payment/payment.routes.ts` | Bereke + PayPal роуты, orders CRUD |

### Модуль Wallet
| Файл | Описание |
|------|---------|
| `src/modules/wallet/wallet.schema.ts` | Zod: TopupSchema, WalletTransactionsQuerySchema |
| `src/modules/wallet/wallet.service.ts` | getWallet, getTransactions, getBalance, debitWallet |
| `src/modules/wallet/wallet.controller.ts` | HTTP handlers |
| `src/modules/wallet/wallet.routes.ts` | GET /, GET /transactions, POST /topup |

### Модуль Subscription
| Файл | Описание |
|------|---------|
| `src/modules/subscription/subscription.schema.ts` | Zod: SubscribeSchema (planType, gateway) |
| `src/modules/subscription/subscription.service.ts` | getPlans, subscribe, getMySubscription, hasActiveSubscription, cancelSubscription |
| `src/modules/subscription/subscription.controller.ts` | HTTP handlers |
| `src/modules/subscription/subscription.routes.ts` | 4 роута |

### Точка входа
| Файл | Описание |
|------|---------|
| `src/app.ts` | Express: helmet, cors, все 7 групп роутов, 404, errorHandler |
| `src/server.ts` | Запуск, подключение к БД, graceful shutdown |

### Тесты
| Файл | Кол-во | Что тестирует |
|------|--------|-------------|
| `tests/env.setup.ts` | — | Устанавливает process.env до импорта |
| `tests/__mocks__/database.ts` | — | Мок Prisma через jest-mock-extended |
| `tests/auth.test.ts` | 27 | Регистрация, вход, Google, Apple, OTP |
| `tests/profile.test.ts` | 8 | Профиль: create, patch, get, ошибки |
| `tests/dietary-restriction.test.ts` | 24 | Все 10 ограничений + кастомные + edge cases |
| `tests/recipe.test.ts` | 22 | CRUD рецептов, рекомендации, фильтрация |
| `tests/pantry.test.ts` | 7 | Кладовка: CRUD, 404, очистка |
| `tests/payment.test.ts` | 29 | State machine, Bereke/PayPal checkout, success/fail/callback, idempotency, refund |
| `tests/wallet.test.ts` | 14 | getWallet, debitWallet, topup checkout, wallet credit on payment |
| `tests/subscription.test.ts` | 14 | getPlans, subscribe, activate, cancel, auto-expiry, idempotency |
| **Итого** | **145** | |

> Запуск: `npx --no-install jest --no-coverage` (нужен только `DATABASE_URL` и `JWT_SECRET` в env)

---

## Все API эндпоинты

База: `http://localhost:3000/api/v1`

### Auth
| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `POST` | `/auth/register` | — | Email + password регистрация |
| `POST` | `/auth/login` | — | Email + password вход |
| `POST` | `/auth/google` | — | Google ID token → JWT |
| `POST` | `/auth/apple` | — | Apple ID token → JWT |
| `POST` | `/auth/otp/send` | — | Отправить 6-значный OTP на email |
| `POST` | `/auth/otp/verify` | — | Проверить OTP → JWT |
| `GET` | `/auth/verify-email?token=` | — | Верифицировать email по ссылке |
| `POST` | `/auth/resend-verification` | — | Переслать письмо верификации |

### Profile
| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/profile` | JWT | Получить профиль |
| `PUT` | `/profile` | JWT | Создать/заменить профиль |
| `PATCH` | `/profile` | JWT | Частично обновить профиль |

### Recipes & Pantry
| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/recipes` | — | Список рецептов (пагинация, `?mood=`) |
| `GET` | `/recipes/:id` | — | Один рецепт |
| `POST` | `/recipes` | JWT | Создать рецепт |
| `PUT` | `/recipes/:id` | JWT | Полная замена рецепта |
| `PATCH` | `/recipes/:id` | JWT | Частичное обновление |
| `DELETE` | `/recipes/:id` | JWT | Удалить рецепт |
| `GET` | `/recipes/recommendations` | JWT | Рекомендации (`?useMyIngredients=true&minMatchScore=0.8`) |
| `GET` | `/pantry` | JWT | Список ингредиентов в кладовке |
| `POST` | `/pantry` | JWT | Добавить ингредиенты |
| `DELETE` | `/pantry/:id` | JWT | Удалить один ингредиент |
| `DELETE` | `/pantry/clear` | JWT | Очистить всю кладовку |

### Payment
| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `POST` | `/payment/checkout` | JWT | Создать ордер (purchase/topup/subscription) → `{ paymentUrl }` |
| `GET` | `/payment/success?orderId=` | — | Bereke редирект после успешной оплаты |
| `GET` | `/payment/fail?orderId=` | — | Bereke редирект после ошибки |
| `POST` | `/payment/callback` | — | Bereke server-to-server webhook |
| `GET` | `/payment/paypal/success?token=` | — | PayPal capture после аппрува |
| `GET` | `/payment/paypal/cancel` | — | PayPal отмена |
| `GET` | `/payment/orders` | JWT | Список своих ордеров |
| `GET` | `/payment/orders/:id` | JWT | Один ордер (только свой) |
| `POST` | `/payment/orders/:id/refund` | JWT | Возврат через Bereke refund.do |

### Wallet
| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/wallet` | JWT | Баланс + последние 20 транзакций |
| `GET` | `/wallet/transactions?limit=&offset=` | JWT | Полная история с пагинацией |
| `POST` | `/wallet/topup` | JWT | `{ amount, gateway }` → `{ paymentUrl }` |

### Subscriptions
| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/subscriptions/plans` | — | Тарифы с ценами (публичный) |
| `GET` | `/subscriptions/me` | JWT | Текущая подписка пользователя |
| `POST` | `/subscriptions/subscribe` | JWT | `{ planType, gateway }` → `{ paymentUrl }` |
| `DELETE` | `/subscriptions/me` | JWT | Soft cancel (доступ сохраняется до expiresAt) |

### System
| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/health` | — | `{ status, db, version }` — 503 если БД недоступна |

---

## OTP — как работает

1. `POST /auth/otp/send` с `{ email }` → сервер генерирует 6 цифр, хранит SHA-256 хэш, отправляет код на email
2. `POST /auth/otp/verify` с `{ email, code }` → проверяет хэш, срок (5 мин), счётчик попыток (макс 3) → возвращает JWT
3. Один и тот же ответ для несуществующего email (защита от user enumeration)
4. Rate limit: 3 отправки/15 мин по email, 10 попыток/5 мин по IP

---

## Apple Sign In — нюансы

- Apple присылает `email` и `name` только при **первом** входе
- При повторных входах — только `sub` (appleId). Поэтому `name` принимается как опциональный параметр
- Если пользователь уже есть с таким email — привязывает `appleId` к существующему аккаунту
- Требует `APPLE_CLIENT_ID` в `.env` (Bundle ID приложения, например `com.moodfood.app`)

---

## Коды ошибок

| Код | HTTP | Когда |
|-----|------|-------|
| `EMAIL_EXISTS` | 409 | Дублирующий email при регистрации |
| `INVALID_CREDENTIALS` | 401 | Неверный пароль или email |
| `ACCOUNT_INACTIVE` | 403 | Аккаунт заблокирован |
| `EMAIL_NOT_VERIFIED` | 403 | Требуется верификация email |
| `INVALID_TOKEN` | 400 | Токен верификации недействителен |
| `INVALID_APPLE_TOKEN` | 401 | Apple ID token не прошёл проверку |
| `APPLE_NO_EMAIL` | 400 | Apple не вернул email |
| `APPLE_EMAIL_UNVERIFIED` | 400 | email_verified = false в Apple токене |
| `INVALID_OTP` | 401 | OTP неверный, истёк или не существует |
| `OTP_MAX_ATTEMPTS` | 429 | Превышено 3 попытки — нужен новый код |
| `OTP_RATE_LIMITED` | 429 | Слишком частые запросы OTP |
| `UNAUTHORIZED` | 401 | JWT отсутствует или недействителен |
| `NOT_FOUND` | 404 | Маршрут не найден |

---

## Запуск проекта

```powershell
# Предусловие: запустить Docker Desktop

cd "c:\Users\0penf\Corporate project\Backend"

docker-compose up -d                              # PostgreSQL на порту 5434
npx prisma migrate dev --name <описание           # применить миграции
npm run dev                                       # сервер на localhost:3000
npm test                                          # 84 тестов

# Просмотр БД визуально
npx prisma studio                                 # открывает localhost:5555
```

**pgAdmin подключение:**
- Host: `localhost`, Port: `5434`
- Database: `moodfood`, User: `moodfood`, Password: `moodfood_dev`

---

## Git воркфлоу

```
main ← только через Pull Request, никогда напрямую

# Начало новой задачи
git checkout main && git pull origin main
git checkout -b feature/название

# Работа
git add . && git commit -m "feat: описание"
git push origin feature/название

# Потом Pull Request на GitHub: feature/название → main
```

**Формат коммитов:** `feat:` / `fix:` / `refactor:` / `docs:` / `test:`

---

## Сессия 5 — 11 июня 2026 (Infra + Epic 3 Backend)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6

### Инфраструктура

**Docker — полный стек:**
- `Backend/Dockerfile` — multi-stage build: builder (Alpine + OpenSSL + npm ci + prisma generate + tsc) → runner (только production deps)
- `docker-compose.yml` обновлён — добавлен сервис `backend` + healthcheck для postgres
- `Backend/.dockerignore`
- Фикс: `binaryTargets = ["native", "linux-musl-openssl-3.0.x"]` в schema.prisma — Alpine 3.18+ использует OpenSSL 3.x
- Фикс: rate limiter IPv6 — заменён `req.ip` на `req.socket.remoteAddress` (express-rate-limit v8 бросал ValidationError)

**Запуск:**
```powershell
# Разработка (hot reload)
docker-compose up -d postgres && npm run dev

# Продакшн-режим (всё в Docker)
docker-compose up --build -d
```

**GitHub Actions CI** (`.github/workflows/ci.yml`):
- Запускается на любой пуш (`branches: ['**']`) и на PR в main
- Шаги: checkout → Node 20 → npm ci → prisma generate → 84 тестов → tsc build → upload artifact
- После пуша: `https://github.com/nurkhaidarovbeks/MoodFood/actions`

**Прочая инфраструктура:**
- `.github/PULL_REQUEST_TEMPLATE.md` — шаблон появляется автоматически при создании PR
- `scripts/deploy.sh` — деплой на сервере: backup → migrate → restart → healthcheck
- `scripts/backup.sh` — pg_dump, 7-дневное хранение, cron в 2:00
- `nginx/moodfood.conf` — reverse proxy конфиг (применить когда будет VPS)

**`/health` endpoint улучшен:**
```json
{ "status": "ok", "db": "connected", "version": "1.0.0" }
```
Возвращает 503 если БД недоступна. Добавлена переменная `APP_VERSION` в env.

---

### Epic 3 — Кладовка (Pantry)

**Новая таблица:** `user_ingredients` — ингредиенты пользователя дома. Связана с таблицей `ingredients` через FK.
**Миграция:** `20260611132036_add_user_ingredients`

**Новый модуль `src/modules/pantry/`:**
| Файл | Описание |
|------|---------|
| `pantry.schema.ts` | Zod: `AddIngredientsSchema` |
| `pantry.service.ts` | getIngredients, addIngredients, removeIngredient, clearPantry |
| `pantry.controller.ts` | HTTP handlers |
| `pantry.routes.ts` | Все маршруты под `requireAuth` |

**4 новых эндпоинта `/api/v1/pantry`** (все требуют JWT):
- `GET /pantry` — список ингредиентов пользователя
- `POST /pantry` — добавить: `{ "ingredients": ["eggs", "rice"] }` (lowercase, upsert)
- `DELETE /pantry/:id` — удалить один
- `DELETE /pantry/clear` — очистить всё

**Рекомендации расширены** — новые query параметры в `GET /recipes/recommendations`:
- `useMyIngredients=true` — фильтрует по кладовке, сортирует по `matchScore` убыванию
- `minMatchScore=0.8` — минимальный порог (0 = все, 1 = только 100% совпадение)

Ответ с `useMyIngredients=true` добавляет к каждому рецепту:
```json
{ "matchScore": 0.75, "missingIngredients": ["olive oil", "basil"] }
```

**Тесты:** `tests/pantry.test.ts` — 7 тестов (P1–P7): getIngredients, addIngredients, removeIngredient, clearPantry

**Postman коллекция обновлена:** добавлены группы Pantry и Recipes со всеми новыми запросами.

**Итого тестов: 84 (было 77, +7 pantry)**

---

## Что не реализовано (намеренно, для следующих эпиков)

| Что | Когда |
|-----|-------|
| Refresh токены | После MVP |
| Сброс пароля | Отдельный feature |
| Telegram OAuth | Enum в схеме есть, endpoint позже |
| Rate limiting на login/register | Добавить express-rate-limit |
| Epic 3 Frontend | Экраны Pantry + Recipes + Recommendations на Flutter |

---

## Сессия 6 — 13 июня 2026 (Render деплой + CD + Render-адаптация скриптов)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6

### Деплой на Render (Free tier)

**Бэкенд живёт по адресу:** `https://moodfood-backend.onrender.com`

- Сервис: Web Service (Docker), Free tier
- PostgreSQL: Render Managed PostgreSQL, Free tier (удаляется через 90 дней)
- Health check: `/health` → `{ status: "ok", db: "connected", version: "1.0.0" }`
- Dockerfile: multi-stage Alpine + OpenSSL, `CMD ["node", "dist/server.js"]`
- Docker Command в Render: `node dist/server.js` (не migrate — это была причина первых ошибок)

**Важно про Free tier:**
- Засыпает после 15 мин неактивности, первый запрос ~30 сек
- DB автоматически удаляется через 90 дней → нужны бэкапы

### CD pipeline (GitHub Actions)

Добавлен job `deploy` в `.github/workflows/ci.yml`:
```yaml
deploy:
  needs: test
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  steps:
    - name: Trigger Render deploy
      run: |
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${{ secrets.RENDER_DEPLOY_HOOK_URL }}")
        if [ "$STATUS" != "200" ] && [ "$STATUS" != "201" ]; then exit 1; fi
```

Секрет `RENDER_DEPLOY_HOOK_URL` добавлен в GitHub Settings → Secrets.

Полный pipeline: пуш в любую ветку → тесты; пуш/мерж в main → тесты → авто-деплой на Render.

### Скрипты адаптированы для Render

**`scripts/deploy.sh`** — теперь триггерит Render Deploy Hook вместо docker-compose:
```bash
export RENDER_DEPLOY_HOOK_URL="https://api.render.com/deploy/srv-xxx?key=yyy"
bash scripts/deploy.sh
```
Используй для ручного передеплоя без пуша кода.

**`scripts/backup.sh`** — теперь использует External Database URL вместо docker exec:
```bash
export DATABASE_URL="postgresql://user:pass@dpg-xxx.render.com/moodfood"
bash scripts/backup.sh
# Сохраняет в ./backups/, хранение 7 дней, восстановление: psql "$DATABASE_URL" < backup.sql
```
External Database URL берётся в Render Dashboard → PostgreSQL → Info.

**`nginx/moodfood.conf`** — оставлен как есть, добавлена пометка что это только для VPS. На Render nginx не нужен.

---

## Сессия 7 — 17 июня 2026 (Epic 4: Payment — Bereke + PayPal)

> Автор: Nurkhaidarov Beksultan & Marlen Bahtiyar | Модель: Claude Sonnet 4.6

### Новые таблицы БД

**Миграция:** `add_orders`

**Новые enum'ы в schema.prisma:**
- `OrderStatus`: `created → pending → paid → fulfilled → completed → failed → refunded → cancelled`
- `PaymentGateway`: `bereke | paypal`

**Новая модель `Order`:**
```
id, userId, amount, currency, status, gateway,
gatewayOrderId, paymentUrl, transactionId, description,
createdAt, updatedAt
```

### Новые сервисы

| Файл | Описание |
|------|---------|
| `src/services/bereke.service.ts` | `bereRegisterOrder`, `bereGetStatus`, `bereRefund` — Bereke Bank REST API (form-encoded) |
| `src/services/paypal.service.ts` | `getPayPalToken`, `createPayPalOrder`, `capturePayPalOrder` — PayPal REST API |

**Bereke API (PAY-002):**
- `register.do` — создаёт платёжную сессию, возвращает `formUrl` для редиректа
- `getOrderStatusExtended.do` — верификация: `orderStatus=2` = оплачено
- `refund.do` — полный или частичный возврат (L2 из презентации)
- Сумма в тенге: 4 900 KZT → `490000`

**PayPal API (PAY-006):**
- `POST /v1/oauth2/token` → Bearer token
- `POST /v2/checkout/orders` — создаёт ордер, возвращает `approvalUrl`
- `POST /v2/checkout/orders/:id/capture` — захват после аппрува

### Модуль `src/modules/payment/`

| Файл | Описание |
|------|---------|
| `payment.schema.ts` | Zod: `CheckoutSchema`, `RefundSchema` |
| `payment.service.ts` | State machine + idempotency + вся бизнес-логика |
| `payment.controller.ts` | HTTP handlers |
| `payment.routes.ts` | 9 роутов |

**State machine `VALID_TRANSITIONS` (PAY-004):**
```
created   → pending, cancelled
pending   → paid, failed, cancelled
paid      → fulfilled, refunded
fulfilled → completed, refunded
failed    → pending
completed → (terminal)
refunded  → (terminal)
cancelled → (terminal)
```
Невалидный переход бросает `AppError(400, INVALID_STATUS_TRANSITION)`.

**Idempotency (PAY-005):** `POST /checkout` с теми же `userId + amount + gateway` в течение 5 минут возвращает существующий pending-ордер без повторной регистрации в банке.

**Callback (PAY-003):** `POST /payment/callback` — Bereke шлёт сюда server-to-server вне зависимости от браузера. Всегда возвращает 200 (иначе Bereke ретраит). Двойная верификация через `getOrderStatusExtended.do` перед апдейтом статуса.

### Все новые API эндпоинты `/api/v1/payment`

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `POST` | `/checkout` | JWT | Создать ордер + получить ссылку на оплату (Bereke или PayPal) |
| `GET` | `/success?orderId=` | — | Bereke редирект после успешной оплаты |
| `GET` | `/fail?orderId=` | — | Bereke редирект после отмены/ошибки |
| `POST` | `/callback` | — | Bereke server-to-server webhook |
| `GET` | `/paypal/success?token=` | — | PayPal capture после аппрува |
| `GET` | `/paypal/cancel` | — | PayPal отмена |
| `GET` | `/orders` | JWT | Список своих ордеров |
| `GET` | `/orders/:id` | JWT | Один ордер (только свой) |
| `POST` | `/orders/:id/refund` | JWT | Возврат через Bereke refund.do |

### Новые env переменные

```bash
# Bereke Bank
BEREKE_USERNAME=           # из Merchant Portal
BEREKE_PASSWORD=
BEREKE_BASE_URL=https://3dsec.berekebank.kz/payment/rest   # sandbox
BEREKE_RETURN_URL=https://moodfood-backend.onrender.com/api/v1/payment/success
BEREKE_FAIL_URL=https://moodfood-backend.onrender.com/api/v1/payment/fail

# PayPal
PAYPAL_CLIENT_ID=          # developer.paypal.com → My Apps
PAYPAL_CLIENT_SECRET=
PAYPAL_BASE_URL=https://api-m.sandbox.paypal.com
PAYPAL_RETURN_URL=https://moodfood-backend.onrender.com/api/v1/payment/paypal/success
PAYPAL_CANCEL_URL=https://moodfood-backend.onrender.com/api/v1/payment/paypal/cancel
```

### Тесты

| Файл | Кол-во | Что тестирует |
|------|--------|-------------|
| `tests/payment.test.ts` | 29 | State machine, Bereke checkout/success/fail/callback, PayPal checkout/capture, idempotency, orders CRUD, refund |

**Итого тестов: 113 (было 84, +29 payment) — все зелёные**

### Тестовые карты Bereke (sandbox)

| Карта | CVC | Срок | Результат |
|-------|-----|------|----------|
| 5555 5555 5555 5599 | 123 | 12/34 | ✅ 3DS |
| 4111 1111 1111 1111 | 123 | 12/26 | ✅ Frictionless |
| 5168 4948 9505 5780 | 123 | 12/26 | ❌ Fail |

### Запуск миграции

```powershell
docker-compose up -d postgres
# Создать .env из .env.example и заполнить DATABASE_URL
npx --no-install prisma migrate dev --name add_orders
```

---

## Сессия 8 — 18 июня 2026 (Wallet: пополнение баланса)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6

### Новые таблицы БД

**Миграция:** `add_wallet`

**Новые enum'ы в schema.prisma:**
- `OrderType`: `purchase | topup`
- `TransactionType`: `topup | payment | refund`

**Новая модель `Wallet`:**
```
id, userId (unique), balance, createdAt, updatedAt
```

**Новая модель `WalletTransaction`:**
```
id, walletId, orderId (unique, nullable), amount, currency, type, description, createdAt
```

**Изменения в `Order`:**
- Добавлено поле `orderType: OrderType @default(purchase)`
- Добавлена relation `walletTx WalletTransaction?`

### Новый модуль `src/modules/wallet/`

| Файл | Описание |
|------|---------|
| `wallet.schema.ts` | Zod: `TopupSchema`, `WalletTransactionsQuerySchema` |
| `wallet.service.ts` | `getWallet`, `getTransactions`, `getBalance`, `debitWallet` |
| `wallet.controller.ts` | HTTP handlers |
| `wallet.routes.ts` | 3 роута, все под `requireAuth` |

### Логика пополнения баланса

**Флоу:**
1. `POST /api/v1/wallet/topup { amount, gateway }` → создаёт `Order` с `orderType: topup` → возвращает payment URL
2. Пользователь оплачивает через Bereke/PayPal
3. При получении подтверждения оплаты (redirect или callback) → атомарная транзакция:
   - `Order.status` → `paid`
   - `Wallet.balance` +amount (upsert — создаёт кошелёк если нет)
   - Создаётся `WalletTransaction` с `type: topup`
4. `GET /api/v1/wallet` → текущий баланс + последние 20 транзакций

**Idempotency:** повторный `POST /topup` с теми же параметрами в течение 5 мин возвращает существующий pending ордер.

**`debitWallet`** — метод для будущего списания баланса (например, покупка premium). Проверяет `INSUFFICIENT_BALANCE` перед дебетом.

### Изменения в `payment.service.ts`

- `checkout()` теперь принимает `orderType` и сохраняет его в Order
- Добавлен приватный метод `creditWallet(userId, amount, currency, orderId)` — вызывается в `handleBereSuccess`, `handleBereCallback`, `handlePaypalSuccess` только если `orderType === topup`
- Обычные `purchase` ордера кошелёк не затрагивают

### Новые API эндпоинты `/api/v1/wallet`

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/` | JWT | Текущий баланс + последние 20 транзакций |
| `GET` | `/transactions?limit=&offset=` | JWT | Полная история транзакций с пагинацией |
| `POST` | `/topup` | JWT | Пополнить баланс — возвращает `{ orderId, paymentUrl }` |

### Тесты

| Файл | Кол-во | Что тестирует |
|------|--------|-------------|
| `tests/wallet.test.ts` | 14 | getWallet, getTransactions, getBalance, debitWallet (insufficient/not found), topup checkout, idempotency, wallet credit on Bereke success/callback, no credit for purchase |

**Итого тестов: 127 (было 113, +14 wallet) — все зелёные**

---

## Сессия 9 — 18 июня 2026 (Subscriptions: Monthly + Annual)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6

### Новые таблицы БД

**Миграция:** `add_subscriptions`

**Новые enum'ы в schema.prisma:**
- `SubscriptionPlanType`: `monthly | annual`
- `SubscriptionStatus`: `pending | active | cancelled | expired`
- `OrderType` расширен: +`subscription`

**Новая модель `SubscriptionPlan`:**
```
id, type (unique), name, priceKzt, priceUsd, durationDays, description, isActive, createdAt, updatedAt
```

**Новая модель `UserSubscription`:**
```
id, userId, planId, orderId (unique), status, startedAt, expiresAt, createdAt, updatedAt
```

### Тарифы (seed)

| Тариф | KZT | USD | Дней |
|-------|-----|-----|------|
| Monthly | 2,990 | $9.99 | 30 |
| Annual | 24,990 | $79.99 | 365 (-30%) |

Seed запускается: `npx --no-install ts-node prisma/seed.ts`

### Новый модуль `src/modules/subscription/`

| Файл | Описание |
|------|---------|
| `subscription.schema.ts` | Zod: `SubscribeSchema` |
| `subscription.service.ts` | getPlans, subscribe, getMySubscription, hasActiveSubscription, cancelSubscription |
| `subscription.controller.ts` | HTTP handlers |
| `subscription.routes.ts` | 4 роута |

### Логика подписки

**Флоу оформления:**
1. `POST /api/v1/subscriptions/subscribe { planType, gateway }` → создаёт `Order` (orderType: subscription) + pending `UserSubscription` → возвращает `paymentUrl`
2. Пользователь оплачивает через Bereke/PayPal
3. При подтверждении оплаты (redirect или callback):
   - Предыдущая активная подписка → `cancelled`
   - Новая подписка → `active`, `startedAt = now`, `expiresAt = now + durationDays`
   - Всё атомарно в `$transaction`

**Idempotency:** повторный `/subscribe` с теми же параметрами в течение 5 мин возвращает существующий pending ордер.

**Soft cancel:** `DELETE /me` меняет статус на `cancelled`, но доступ сохраняется до `expiresAt`.

**Auto-expire:** `getMySubscription` автоматически помечает просроченные подписки как `expired`.

### Изменения в `payment.service.ts`

- Добавлен приватный метод `activateSubscriptionForOrder(order)` — ищет `UserSubscription` по `orderId`, активирует
- Вызывается в `handleBereSuccess`, `handleBereCallback`, `handlePaypalSuccess` при `orderType === subscription`

### Новые API эндпоинты `/api/v1/subscriptions`

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/plans` | — | Список тарифов (публичный) |
| `GET` | `/me` | JWT | Текущая подписка пользователя |
| `POST` | `/subscribe` | JWT | Оформить подписку → `{ orderId, paymentUrl }` |
| `DELETE` | `/me` | JWT | Отменить подписку (soft cancel) |

### Тесты

| Файл | Кол-во | Что тестирует |
|------|--------|-------------|
| `tests/subscription.test.ts` | 14 | getPlans, subscribe (Bereke/PayPal), idempotency, plan not found, getMySubscription, auto-expiry, hasActive, cancel, activation + cancel previous |

**Итого тестов: 141 (было 127, +14 subscription) — все зелёные**

---

## Сессия 10 — 19 июня 2026 (Epic 4 по плану MoodFood: AI-рекомендации по настроению)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Opus 4.8

> ⚠️ Нумерация эпиков разошлась: «Epic 4» в коммитах команды = Payment, а **Epic 4 по
> исходному документу MoodFood = AI Meal Recommendations** — именно его реализует эта сессия
> (был в «Следующий шаг» как «AI рекомендации по настроению»).

### Сначала — починка: устаревший Prisma client

После `git pull` 3 сьюта (payment, subscription, wallet) **не запускались** —
`@prisma/client` не содержал моделей Order/Subscription/Wallet (клиент не был
перегенерирован после добавления схемы). Тесты: «84 passed, но 3 suite failed».

**Фикс:** `npx prisma generate` → **141 тест зелёный** (84 + 29 payment + 14 wallet + 14 subscription).
Это и был «не все тесты были добавлены» — они были, но не компилировались.

### Epic 4 — AI Meal Recommendations

**Новый эндпоинт (JWT):**

| Метод | Путь | Описание |
|-------|------|---------|
| `POST` | `/api/v1/recommendations` | Mood-check → 3 варианта (fastest / healthiest / cheapest) + AI-объяснение |

**Тело запроса** (всё опционально):
```json
{
  "mood": "tired",
  "energyLevel": 2,            // 1–5
  "stressLevel": "high",       // low | medium | high
  "sleepQuality": "poor",      // poor | normal | good
  "hungerLevel": "high",       // low | medium | high
  "budgetLevel": "low",        // переопределяет профиль
  "maxCookingTime": 20,        // только быстрые рецепты ≤ N мин
  "useMyIngredients": true     // матч по кладовке + замены ингредиентов
}
```

**Пайплайн (безопасный, по плану §13.3):**
`вход → фильтр по диете (hard) → фильтр по времени → скоринг по состоянию → выбор 3 → AI-объяснение → JSON`

**Новые файлы:**
| Файл | Описание |
|------|---------|
| `src/modules/recommendations/recommendation.scoring.ts` | Чистые функции: `stateFitScore`, `selectThreeOptions`, `suggestSubstitutions` (правила §12.4) |
| `src/modules/recommendations/recommendation.schema.ts` | Zod `RecommendationRequestSchema` |
| `src/modules/recommendations/recommendation.service.ts` | Оркестрация (DI: prisma + MealAiService) |
| `src/modules/recommendations/recommendation.controller.ts` | HTTP handler |
| `src/modules/recommendations/recommendation.routes.ts` | `POST /` под `requireAuth` |
| `src/services/meal-ai.service.ts` | Claude API (Anthropic SDK) + rule-based fallback |

**Скоринг (правила состояния):**
- Низкая энергия (energy ≤ 2 / mood tired) → белок + сложные углеводы, штраф за сахар
- Высокий стресс → простые сбалансированные блюда, штраф за тяжёлые (>650 ккал)
- Плохой сон → лёгкие блюда (≤450 ккал), штраф за тяжёлые (>600)
- Сильный голод → сытные (белок + калории)
- 3 варианта **всегда разные рецепты**: healthiest (макс fit) → fastest (мин время) → cheapest (мин цена)

**AI-слой (`MealAiService`):**
- Если `ANTHROPIC_API_KEY` задан → один batched-вызов Claude (модель из `ANTHROPIC_MODEL`,
  по умолчанию `claude-haiku-4-5`), система-промпт с правилами безопасности (НЕ медицинские советы, §12.5)
- Если ключа нет (dev / CI / тесты) → **детерминированный rule-based fallback** → приложение и тесты
  работают полностью офлайн, без сетевых вызовов и затрат
- `aiPowered: boolean` в ответе показывает, какой путь сработал

**Замены ингредиентов (Epic 4 «alternatives»):** при `useMyIngredients` к каждому варианту
добавляются `matchScore`, `missingIngredients`, `substitutions` (например chicken → eggs/beans),
причём замены отфильтрованы по ограничениям пользователя.

**Новые env:** `ANTHROPIC_API_KEY` (опц.), `ANTHROPIC_MODEL` (по умолч. `claude-haiku-4-5`).

**Новая зависимость:** `@anthropic-ai/sdk`.

### Тесты

| Файл | Кол-во | Что тестирует |
|------|--------|-------------|
| `tests/recommendation-scoring.test.ts` | 16 | Детекция состояния, fit-скоринг, выбор 3, замены |
| `tests/recommendation.test.ts` | 8 | Пайплайн, диета (hard), время, кладовка, 404, без профиля |
| `tests/meal-ai.test.ts` | 6 | Fallback без ключа, не-медицинский текст, формат |

**Итого тестов: 171 (было 141, +30) — все зелёные.** Никаких сетевых вызовов в тестах.

### Ручная проверка
```powershell
docker-compose up -d postgres
npx --no-install ts-node prisma/seed.ts        # 10 рецептов
npm run dev
# POST http://localhost:3000/api/v1/recommendations  (Bearer <jwt>)
# { "mood": "tired", "energyLevel": 2, "maxCookingTime": 20 }
```

---

## Сессия 11 — 19 июня 2026 (Epic 2 по плану MoodFood: Mood-check + история)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Opus 4.8

Закрыл недостающую backend-часть Epic 2 (по документу) — **сохранение чек-инов
состояния в БД и история** (бэклог-пункт «Mood history»). Раньше состояние только
принималось в `/recommendations`, но нигде не хранилось.

**Новая модель `MoodCheck`** (миграция `add_mood_checks`):
```
id, userId, mood, energyLevel (1–5), stressLevel, sleepQuality, hungerLevel, createdAt
@@index([userId, createdAt])
```
Поля состояния — nullable String/Int (валидация через Zod, как в `/recommendations`).

**Новый модуль `src/modules/moodcheck/`:** schema / service / controller / routes.

**Новые эндпоинты `/api/v1/mood-checks` (все JWT):**

| Метод | Путь | Описание |
|-------|------|---------|
| `POST` | `/mood-checks` | Записать чек-ин (нужно ≥1 поле) |
| `GET` | `/mood-checks` | История (пагинация, newest-first) |
| `GET` | `/mood-checks/latest` | Последний чек-ин (или `null`) |

**Тесты:** `tests/moodcheck.test.ts` — 5 (create с null-заполнением, история + пагинация, latest, пустой latest).

**Итого тестов: 176 (было 171, +5) — все зелёные.**

> Миграции в репозитории рассинхронены (для orders/wallet/subscription нет папок —
> схема = источник правды). Для mood_checks **добавил готовую миграцию** вручную:
> `prisma/migrations/20260619090000_add_mood_checks/migration.sql`. Применить:
> `npx --no-install prisma migrate deploy` (или `prisma db push`) когда поднят Postgres.

---

## Следующий шаг

- Применить миграцию `add_mood_checks` (когда Docker/Postgres запущен):
  ```powershell
  docker-compose up -d postgres
  npx --no-install prisma migrate deploy   # или: npx --no-install prisma db push
  ```
- Bereke callback URL прописать в Merchant Portal (ngrok для локала)
- Habit analytics / weekly tips (Epic 7 по документу — поверх mood history + воды, можно с AI)
- Water tracking (Epic 6 backend-часть)
- Избранное / сохранённые рецепты (Epic 5)
- Сброс пароля
- Rate limiting на login/register

---

*Сессия 1: 30 мая 2026 — Epic 1 Backend (36 тестов)*  
*Сессия 2: 2 июня 2026 — Apple/OTP/SQL/Git (55 тестов)*  
*Сессия 3: 6 июня 2026 — Epic 2 Backend, рецепты (77 тестов)*  
*Сессия 5: 11 июня 2026 — Infra (Docker/CI/CD) + Epic 3 Pantry (84 тестов)*  
*Сессия 6: 13 июня 2026 — Render деплой + CD pipeline + скрипты под Render*  
*Сессия 7: 17 июня 2026 — Epic 4 Payment: Bereke + PayPal + state machine (113 тестов)*  
*Сессия 8: 18 июня 2026 — Wallet: пополнение баланса + транзакции (127 тестов)*  
*Сессия 9: 18 июня 2026 — Subscriptions: Monthly + Annual тарифы (141 тест)*  
*Сессия 10: 19 июня 2026 — Epic 4 (план MoodFood): AI-рекомендации по настроению + fix Prisma client (171 тест)*  
*Сессия 11: 19 июня 2026 — Epic 2 (план MoodFood): Mood-check + история чек-инов (176 тестов)*  

