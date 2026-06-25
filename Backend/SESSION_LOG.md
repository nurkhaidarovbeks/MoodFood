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
| `prisma/schema.prisma` | Схема: User, UserProfile, Recipe, Ingredient, RecipeIngredient, UserIngredient |
| `prisma/migrations/` | История миграций (коммитятся в git) |

**Поля User (все):**
```
id, email, name, passwordHash, authProvider (email/google/apple/telegram),
googleId, appleId,
isEmailVerified, emailVerificationToken, emailVerificationExpires,
otpHash, otpExpires, otpAttempts,
isActive, createdAt, updatedAt
```

**Поля UserProfile (все):**
```
id, userId, age, goal, lifestyle (student/professional/other),
budgetLevel (low/medium/high),
dietaryRestrictions (JSON), allergies (JSON), customRestrictions (JSON),
onboardingCompleted, profileCompletedAt
```

### Core
| Файл | Описание |
|------|---------|
| `src/config/env.ts` | Парсинг env, падает если нет обязательных переменных |
| `src/config/database.ts` | Singleton Prisma клиент |
| `src/utils/jwt.ts` | `signToken()`, `verifyToken()` |
| `src/utils/hash.ts` | `sha256()`, `generateToken()` |
| `src/utils/profile-completion.ts` | `isProfileComplete()` — нужны age+goal+lifestyle+budgetLevel |

### Сервисы
| Файл | Описание |
|------|---------|
| `src/services/email.service.ts` | `sendEmail()`, `sendVerificationEmail()`, `sendOtpEmail()` |
| `src/services/google-oauth.service.ts` | `verifyGoogleIdToken()` |
| `src/services/apple-auth.service.ts` | `verifyAppleIdToken()` |
| `src/services/dietary-restriction.service.ts` | `canUserSeeRecipe()`, `filterRecipesForUser()` — **через него все рецепты** |

### Middleware
| Файл | Описание |
|------|---------|
| `src/middleware/auth.ts` | `requireAuth` — проверяет JWT из `Authorization: Bearer` |
| `src/middleware/validate.ts` | `validate(schema)` — Zod валидация body |
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

### Точка входа
| Файл | Описание |
|------|---------|
| `src/app.ts` | Express: helmet, cors, роуты, 404, errorHandler |
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

---

## Все API эндпоинты

База: `http://localhost:3000/api/v1`

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
| `GET` | `/profile` | JWT | Получить профиль |
| `PUT` | `/profile` | JWT | Создать/заменить профиль |
| `PATCH` | `/profile` | JWT | Частично обновить профиль |
| `GET` | `/health` | — | Статус сервера + БД + версия |
| `GET` | `/pantry` | JWT | Список ингредиентов в кладовке |
| `POST` | `/pantry` | JWT | Добавить ингредиенты |
| `DELETE` | `/pantry/:id` | JWT | Удалить один ингредиент |
| `DELETE` | `/pantry/clear` | JWT | Очистить всю кладовку |
| `GET` | `/recipes` | — | Список рецептов (пагинация, фильтр по mood) |
| `GET` | `/recipes/:id` | — | Один рецепт |
| `POST` | `/recipes` | JWT | Создать рецепт |
| `PUT` | `/recipes/:id` | JWT | Полная замена рецепта |
| `PATCH` | `/recipes/:id` | JWT | Частичное обновление |
| `DELETE` | `/recipes/:id` | JWT | Удалить рецепт |
| `GET` | `/recipes/recommendations` | JWT | Рекомендации (ограничения + `?useMyIngredients=true`) |

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
- `PaymentGateway`: `paypal` (единственный шлюз)

**Новая модель `Order`:**
```
id, userId, amount, currency, status, orderType (purchase/topup/subscription),
gateway, gatewayOrderId, paymentUrl, transactionId, description,
createdAt, updatedAt
```

### Новые сервисы

| Файл | Описание |
|------|---------|
| `src/services/paypal.service.ts` | `getPayPalToken`, `createPayPalOrder`, `capturePayPalOrder` — PayPal REST API |

**PayPal API:**
- `POST /v1/oauth2/token` → Bearer token (Client Credentials)
- `POST /v2/checkout/orders` — создаёт ордер, возвращает `approvalUrl`
- `POST /v2/checkout/orders/:id/capture` — захват средств после аппрува пользователем

### Модуль `src/modules/payment/`

| Файл | Описание |
|------|---------|
| `payment.schema.ts` | Zod: `CheckoutSchema` (amount, gateway, orderType), `RefundSchema` |
| `payment.service.ts` | State machine + idempotency + `creditWallet` + `activateSubscriptionForOrder` |
| `payment.controller.ts` | HTTP handlers |
| `payment.routes.ts` | 6 роутов |

**State machine `VALID_TRANSITIONS`:**
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

**Idempotency:** `POST /checkout` с теми же параметрами в течение 5 минут возвращает существующий pending-ордер без повторного вызова PayPal API.

### API эндпоинты `/api/v1/payment`

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `POST` | `/checkout` | JWT | Создать ордер → получить PayPal `approvalUrl` |
| `GET` | `/paypal/success?token=` | — | PayPal редирект после оплаты → capture |
| `GET` | `/paypal/cancel?token=` | — | PayPal редирект при отмене |
| `GET` | `/orders` | JWT | Список своих ордеров |
| `GET` | `/orders/:id` | JWT | Один ордер (только свой) |
| `POST` | `/orders/:id/refund` | JWT | Возврат (смена статуса на refunded) |

### Env переменные

```bash
PAYPAL_CLIENT_ID=           # developer.paypal.com → My Apps
PAYPAL_CLIENT_SECRET=
PAYPAL_BASE_URL=https://api-m.sandbox.paypal.com
PAYPAL_RETURN_URL=https://moodfood-backend.onrender.com/api/v1/payment/paypal/success
PAYPAL_CANCEL_URL=https://moodfood-backend.onrender.com/api/v1/payment/paypal/cancel
```

### Тесты

| Файл | Кол-во | Что тестирует |
|------|--------|-------------|
| `tests/payment.test.ts` | 20 | State machine, PayPal checkout/success/cancel, idempotency, orders CRUD, refund |

### Запуск миграции

```powershell
docker-compose up -d postgres
npx --no-install prisma migrate dev --name add_orders
```

---

## Сессия 8 — 18 июня 2026 (Wallet: пополнение баланса)

> Автор: Nurkhaidarov Beksultan & Marlen Bahtiyar | Модель: Claude Sonnet 4.6

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
3. При подтверждении PayPal оплаты (`/paypal/success`) → атомарная транзакция:
   - `Order.status` → `paid`
   - `Wallet.balance` +amount (upsert — создаёт кошелёк если нет)
   - Создаётся `WalletTransaction` с `type: topup`
4. `GET /api/v1/wallet` → текущий баланс + последние 20 транзакций

**Idempotency:** повторный `POST /topup` с теми же параметрами в течение 5 мин возвращает существующий pending ордер.

**`debitWallet`** — метод для будущего списания баланса. Проверяет `INSUFFICIENT_BALANCE` перед дебетом.

### Изменения в `payment.service.ts`

- `checkout()` принимает `orderType` и сохраняет в Order
- Приватный метод `creditWallet(userId, amount, currency, orderId)` — вызывается в `handlePaypalSuccess` если `orderType === topup`
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
| `tests/wallet.test.ts` | 13 | getWallet, getTransactions, getBalance, debitWallet (insufficient/not found), topup checkout, idempotency, wallet credit on PayPal success, no credit for purchase |

**Итого тестов: 124 (было 113, +11 wallet) — все зелёные**

---

## Сессия 9 — 18 июня 2026 (Subscriptions: Monthly + Annual)

> Автор: Nurkhaidarov Beksultan & Marlen Bahtiyar | Модель: Claude Sonnet 4.6

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
2. Пользователь оплачивает через PayPal
3. При подтверждении PayPal оплаты (`/paypal/success`):
   - Предыдущая активная подписка → `cancelled`
   - Новая подписка → `active`, `startedAt = now`, `expiresAt = now + durationDays`
   - Всё атомарно в `$transaction`

**Idempotency:** повторный `/subscribe` с теми же параметрами в течение 5 мин возвращает существующий pending ордер.

**Soft cancel:** `DELETE /me` меняет статус на `cancelled`, но доступ сохраняется до `expiresAt`.

**Auto-expire:** `getMySubscription` автоматически помечает просроченные подписки как `expired`.

### Изменения в `payment.service.ts`

- Приватный метод `activateSubscriptionForOrder(order)` — ищет `UserSubscription` по `orderId`, активирует
- Вызывается в `handlePaypalSuccess` при `orderType === subscription`

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
| `tests/subscription.test.ts` | 14 | getPlans, subscribe (PayPal), idempotency, plan not found, getMySubscription, auto-expiry, hasActive, cancel, activation + cancel previous |

**Итого тестов: 138 (было 124, +14 subscription) — все зелёные**

---

## Сессия 10 — 19 июня 2026 (Epic 4: PayPal only + CI fix + credentials)

> Автор: Marlen Bahtiyar | Модель: Claude Sonnet 4.6

### Bereke Bank полностью удалён

Причина: безопасность (открытый доступ к credentials) + упрощение стека.

**Что удалено:**
- `src/services/bereke.service.ts` — очищен
- `BEREKE_*` переменные из `env.ts`, `.env`, `.env.example`
- `bereke` из `PaymentGateway` enum в Prisma схеме
- Эндпоинты `/payment/success`, `/payment/fail`, `/payment/callback` (Bereke-специфичные)
- Методы `handleBereSuccess`, `handleBereFail`, `handleBereCallback` из payment.service
- Все Bereke моки из тестов

**Единственный платёжный шлюз теперь:** PayPal

### PayPal credentials подтверждены

Добавлен скрипт `scripts/test-paypal.ts`:
```powershell
npx --no-install ts-node scripts/test-paypal.ts
```
Результат: ✅ токен получен, тестовый ордер `$1.00` создан, approval URL сгенерирован.

**Sandbox тест-аккаунты:** developer.paypal.com → Sandbox → Accounts

### CI/CD фикс

Исправлена TypeScript ошибка в `src/modules/wallet/wallet.controller.ts`:
```typescript
// Было (ошибка TS2352):
req.query as { limit: number; offset: number }

// Стало:
req.query as unknown as { limit: number; offset: number }
```

### Итоговый список эндпоинтов Epic 4 (актуальный)

**Payment (`/api/v1/payment`):**
- `POST /checkout` — `{ amount, gateway: "paypal", orderType }` → `{ paymentUrl }`
- `GET /paypal/success?token=` — capture после оплаты
- `GET /paypal/cancel?token=` — отмена
- `GET /orders` — история ордеров
- `GET /orders/:id` — один ордер
- `POST /orders/:id/refund` — возврат

**Wallet (`/api/v1/wallet`):**
- `GET /` — баланс + последние 20 транзакций
- `GET /transactions?limit=&offset=` — полная история
- `POST /topup` — `{ amount, gateway: "paypal" }` → `{ paymentUrl }`

**Subscriptions (`/api/v1/subscriptions`):**
- `GET /plans` — тарифы (публичный)
- `GET /me` — текущая подписка
- `POST /subscribe` — `{ planType: "monthly"|"annual", gateway: "paypal" }` → `{ paymentUrl }`
- `DELETE /me` — soft cancel

### Тесты после рефакторинга

**Итого тестов: 131 — все зелёные** (141 было до удаления Bereke)

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

---

## Сессия 13 — 24 июня 2026 (OpenAI switch + PayPal fix + Postman)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6 | Ветка: `feature/epic2-epic4-ai-recommendations`

### 1. Переключение с Anthropic на OpenAI (GPT-4o-mini)

**Причина:** GPT-4o-mini в ~5-6 раз дешевле Claude Haiku для коротких объяснений блюд.

**Изменения:**
- Удалён пакет `@anthropic-ai/sdk`, установлен `openai`
- `src/services/meal-ai.service.ts` переписан: `client.messages.create` → `client.chat.completions.create`
- `src/config/env.ts`: `ANTHROPIC_API_KEY` / `ANTHROPIC_MODEL` → `OPENAI_API_KEY` / `OPENAI_MODEL`
- `OPENAI_MODEL` по умолчанию: `gpt-4o-mini`
- Rule-based fallback и логика `withFallback` — без изменений

**На Render нужно добавить:**
```
OPENAI_API_KEY=sk-proj-...   (ключ из platform.openai.com, проект "Moodfood")
```

**166 тестов — все зелёные** (тесты работают офлайн через rule-based fallback, без вызова API).

### 2. Фикс PayPal 500

**Проблема:** `data.links.find(...)` падал с TypeError когда PayPal возвращал ответ об ошибке (нет учётных данных в Render) → 500 вместо понятного сообщения.

**Фикс в `src/services/paypal.service.ts`:**
- Добавлен `readPayPalError(res, context)` — читает тело ошибки PayPal, бросает `AppError(502, ...)`
- Во всех 3 функциях: `if (!res.ok) await readPayPalError(res, ...)`
- Guard `PAYPAL_NOT_CONFIGURED` — `AppError(500)` если нет CLIENT_ID/SECRET
- `data.links?.find(...)` — null-safe

**На Render нужны переменные:**
```
PAYPAL_CLIENT_ID=...
PAYPAL_CLIENT_SECRET=...
PAYPAL_BASE_URL=https://api-m.sandbox.paypal.com
PAYPAL_RETURN_URL=https://moodfood-backend.onrender.com/api/v1/payment/paypal/success
PAYPAL_CANCEL_URL=https://moodfood-backend.onrender.com/api/v1/payment/paypal/cancel
```

### 3. Полное обновление Postman-коллекции

Файл: `Backend/moodfood.postman_collection.json`  
`host` = `https://moodfood-backend.onrender.com`

**Новые разделы:**
- 💳 Payment (checkout, orders, refund, PayPal callbacks)
- 👛 Wallet (баланс, пополнение, транзакции)
- 📦 Subscriptions (планы, подписка, отмена)

**Step-by-Step Test** расширен до **10 шагов** с автоматическими `pm.test` проверками:
1. Register (saves token) / 1b. Login
2. Fill Profile
3. Add Pantry Ingredients
4. Create Mood-Check
5. Get Latest Mood-Check
6. AI Recommendations (basic) — проверяет `options`, `category`, `fitScore`, `explanation`
7. AI Recommendations (pantry + substitutions) — проверяет `matchScore`, `missingIngredients`
8. Mood-Check History
9. Get Subscription Plans
10. Get Wallet Balance

---

## Сессия 14 — 13–20 июня 2026 (Flutter Frontend: Epic 1–3 UI + PayPal)

> Автор: Azharakhamitbek | Модель: Claude Sonnet 4.6 | Ветка: `feature/flutter-frontend-epic1`

### 1. Интерактивный UI — все кнопки кликабельны

Все экраны приложения доведены до рабочего состояния:
- Фильтр рецептов: кнопка открывает bottom sheet с 5 опциями (Mood, Dietary, Quick Meals, Budget, Pantry)
- AI Chat: кнопки Camera/Gallery открывают системный image picker
- Notifications: кнопки Mark All Read, Delete работают
- Home tab navigation: кнопки переключают табы через `IndexedStack`

### 2. Premium / Subscription

- `SubscriptionProvider` + `SubscriptionService` — новые файлы
- Splash screen: параллельно загружает `sub.load()` + `auth.checkAuthStatus()`
- После логина: `sub.syncFromBackend()` — синхронизирует статус с `/subscriptions/me`
- Premium badge обновляется в реальном времени после оплаты
- API constants: добавлены `subscriptionPlans`, `subscriptionSubscribe`, `subscriptionMe`, `subscriptionCancel`

### 3. PayPal WebView flow

- Новый экран `PayPalWebViewScreen` — открывает PayPal в WebView
- Перехватывает `/payment/paypal/success` → синхронизирует подписку → `/payment-success`
- Перехватывает `/payment/paypal/cancel` → pop с SnackBar
- `_PaymentSheetState._pay()` вызывает `POST /subscriptions/subscribe` → получает `paymentUrl` → открывает WebView
- Forte Bank: "coming soon" Snackbar

### 4. Рецепты с реальными фото

- `_photos` map с 12 ключами продуктов → Unsplash URL
- 5 fallback фото на случай отсутствия совпадения
- Поиск по `title.toLowerCase().contains(entry.key)` — регистронезависимый

### 5. Редактируемый профиль

- `EditProfileScreen`: имя + аватар (Camera/Gallery через image_picker)
- Avatar сохраняется в SharedPreferences как base64
- `ProfileProvider.updateAvatar()` / `updateName()`

### 6. Water tracking

- Виджет `_StatsRow` → `_WaterCard` с кнопками +/−
- Сохранение: `SharedPreferences` ключ `water_glasses` в формате `2026-06-13:5`
- Автосброс каждый день (по дате)

### 7. Фиксы валидации

- Регистрация: пароль мин. 8 символов (соответствие backend Zod `min(8)`)
- Profile Setup Step 3: маппинг UI-лейблов → backend DIETARY_RESTRICTION_KEYS:
  - `Dairy` → `lactose_free`, `Eggs` → `egg_allergy`, `Soy` → `soy_allergy`
  - `Peanuts`/`Tree Nuts` → `nut_allergy`, `Wheat` → `gluten_free`
  - `Fish`, `Shellfish`, `Keto`, `Paleo` → `customRestrictions` (не блокируют валидацию)

**Коммиты:**
- `3a12c26` feat(mobile): premium flow, editable profile, interactive UI
- `46ee561` fix(mobile): load premium on cold start; sync Tracker water + Profile saved count
- `f3afae7` fix(mobile): recipe photos, filter sheet, recommendations navigation
- `11c36c9` feat(mobile): connect PayPal payment to live backend
- `aa0ee92` fix(mobile): align password validation with backend requirements
- `e3ec57a` fix(mobile): map allergy/diet labels to backend DIETARY_RESTRICTION_KEYS

---

## Сессия 15 — 25 июня 2026 (Flutter Frontend: Epic 4–5 AI Recommendations)

> Автор: Azharakhamitbek | Модель: Claude Sonnet 4.6 | Ветка: `feature/flutter-frontend-epic1`

### 1. MoodCheck → синхронизация с бэкендом

- `MoodEntry` модель: добавлено опциональное поле `hungerLevel`
- `MoodCheckScreen`: новый слайдер **Hunger Level** (Not Hungry → Very Hungry → `low/medium/high`)
- Новый сервис `MoodCheckService`:
  - `create(entry)` — `POST /api/v1/mood-checks` (fire-and-forget, не блокирует UI)
  - `getLatest()` — `GET /api/v1/mood-checks/latest`
- `MoodProvider.saveMoodEntry()`: сохраняет локально → fire-and-forget sync на бэкенд

### 2. AI Recommendations — реальные данные с бэкенда

**Новый сервис `RecommendationService`:**
- `recommend(entry, useMyIngredients, maxCookingTime)` — `POST /api/v1/recommendations`
- Отправляет: `mood`, `energyLevel`, `stressLevel`, `sleepQuality`, `hungerLevel`
- Парсит ответ: `RecommendationOption` (fitScore, category, explanation, recipe, missingIngredients)

**`RecommendationsScreen` полностью переписан:**
- Loading spinner: «Finding the perfect meals for you…»
- `_RecommendationCard`: цветной header по категории (energizing/calming/comforting/light/nourishing), fitScore badge, время готовки, калории, сложность
- AI explanation block с иконкой 🤖
- AI badge («AI») в заголовке когда `aiPowered=true`
- Missing ingredients (pantry mode): chips с оранжевыми badge
- `_ErrorCard`: «Couldn't reach the server» + кнопка Retry
- `_EmptyCard`: для пустого ответа от сервера

### 3. API Constants

Добавлены:
- `moodChecks = '/mood-checks'`
- `moodChecksLatest = '/mood-checks/latest'`
- `aiRecommendations = '/recommendations'`

### 4. Установка как нативное приложение

- Приложение собрано через Xcode (Product → Run) и установлено на Cherry🍒 как полноценное iOS приложение
- Больше не требует `flutter run` для запуска — открывается с иконки

**Коммит:** `76aef51` feat(mobile): Epic 4-5 — connect AI recommendations to backend

---

## Сессия 16 — 25 июня 2026 (Epic 5 Backend: macros + Favorites)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6 | Ветка: `feature/epic2-epic4-ai-recommendations`

### Что сделано

**Макросы (fatG / carbsG) в Recipe:**
- `prisma/schema.prisma` — добавлены `fatG Float?` и `carbsG Float?` в модель `Recipe`
- `src/modules/recipes/recipe.schema.ts` — добавлены поля в `RecipeCreateSchema`
- `src/modules/recipes/recipe.service.ts` — поля переданы в `formatRecipe`, `createRecipe`, `updateRecipe`, `patchRecipe`
- `prisma/seed.ts` — все 20 рецептов дополнены реальными значениями fat/carbs (в граммах)

**Favorites (избранные рецепты):**
- Новая модель `UserFavorite` в схеме (уникальный `[userId, recipeId]`, индекс `[userId, createdAt]`)
- Миграция: `prisma/migrations/20260625100000_add_recipe_macros_favorites/migration.sql`
- Новый модуль `src/modules/favorites/` (schema / service / controller / routes)
- 4 эндпоинта под `requireAuth`:
  - `GET /api/v1/favorites` — список с пагинацией, newest-first
  - `POST /api/v1/favorites { recipeId }` — добавить, 409 если уже есть
  - `DELETE /api/v1/favorites/:id` — удалить по favoriteId
  - `GET /api/v1/favorites/check/:recipeId` — → `{ isFavorite, favoriteId }`
- Зарегистрированы в `src/app.ts`
- `tests/favorites.test.ts` — 9 тестов: getFavorites (2), addFavorite (3), removeFavorite (2), isFavorite (2)

**Postman коллекция полностью перестроена:**
- 10 папок по Epic 1–5 + Payment/Wallet/Subscriptions + Step-by-Step Integration Test
- 76 запросов с pm.test проверками
- Epic 5 — Favorites: 10 запросов (happy path + edge cases + 401)

**Итого тестов: 175 (было 166, +9) — все зелёные**
**Prisma клиент перегенерирован: `npx prisma generate`**

### Применить миграцию на продакшн (Render)
```bash
npx prisma migrate deploy
# или
npx prisma db push
```

### Закрытие пробела Epic 4 — budget-based scoring
Был недореализован пункт бэклога Epic 4 «Budget-based recommendations». `budgetLevel`
принимался в запросе, но не влиял на `stateFitScore` (бюджет отражался только через
опцию cheapest). Добавлено правило:
- `recommendation.scoring.ts`: новый `isBudgetConscious()` + правило в `stateFitScore` —
  при `budgetLevel='low'` дешёвым блюдам (≤$4) +0.15, дорогим (>$7) −0.15
- Бюджет берётся из запроса, fallback — из профиля (`user.profile.budgetLevel`)
- Тесты: +4 (детектор, 2 fit-теста, 1 пайплайн-тест) → **179 тестов, все зелёные**
- Применён к Render: миграция `20260625100000_add_recipe_macros_favorites` (через
  `prisma migrate resolve --applied 20260619090000_add_mood_checks` + `migrate deploy`)

---

## Сессия 17 — 25 июня 2026 (Epic 4: AI-распознавание фото + budget scoring)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Opus 4.8 | Ветка: `feature/epic2-epic4-ai-recommendations`

### 1. Budget-based scoring (закрытие пробела Epic 4)
- `recommendation.scoring.ts`: `isBudgetConscious()` + правило в `stateFitScore` —
  при `budgetLevel='low'` дешёвым блюдам (≤$4) +0.15, дорогим (>$7) −0.15
- +4 теста → промежуточно 179

### 2. AI-распознавание фото (фото → ингредиенты → блюда)

Фото холодильника / чека / списка продуктов → AI извлекает ингредиенты → рекомендации.

**Новый сервис `src/services/vision-ai.service.ts`** (OpenAI Vision):
- `VisionAiService.extractIngredients(image)` — vision-вызов GPT-4o-mini
- Чистые экспортируемые хелперы (юнит-тестируемы): `buildDataUrl`, `parseVisionJson`,
  `normalizeVisionResult`, `normalizeName`
- Инъекция клиента (`opts.client`) → тесты полностью офлайн, без сети

**Корректность (главный приоритет):**
- Строгий system-prompt: только видимые/читаемые items, без выдумок, low confidence при сомнении
- Чеки: игнор цен/итогов/магазина/не-еды; мультиязычность (рус/каз/eng) → `normalizedName` на англ.
- `temperature: 0`, `response_format: json_object`, защитная Zod-валидация ответа модели
- Защита от prompt-injection в тексте на фото (system-prompt: текст = данные, не инструкции)
- Дедуп по нормализованному имени, кламп confidence 0..1, сортировка
- Валидация фото ДО вызова сети: формат (JPEG/PNG/WebP, HEIC отклоняется), размер ≤10 МБ, base64

**Новый модуль `src/modules/vision/`:** schema / service / controller / routes
- `POST /api/v1/vision/ingredients` — extract-only (confidence, detectedSource, confident/lowConfidence)
- `POST /api/v1/vision/recommendations` — one-shot: фото → 3 блюда

**Интеграция с пайплайном рекомендаций:**
- `recommendation.service.ts`: новый параметр `opts.availableIngredientNames` — матчинг
  ингредиентов ПО ИМЕНИ (для фото), а не по pantryId. Единый пайплайн → диета остаётся
  жёстким фильтром, замены фильтруются по ограничениям
- pantry НЕ трогается (решение продукта): извлечённые ингредиенты только возвращаются

**Инфраструктура:**
- `app.ts`: глобальный json-парсер (1mb) пропускает `/vision`; роутер vision монтирует
  свой парсер на 14mb (фото в base64 большие)
- Rate limit: 20 запросов / 15 мин на пользователя (vision-вызовы платные)
- `env.ts` / `.env.example`: `OPENAI_VISION_MODEL` (по умолч. `gpt-4o-mini`)

**Тесты:** `tests/vision.test.ts` — 25 тестов (валидация фото, парсинг, нормализация,
non-food/галлюцинации, extract-split, one-shot name-matching, 422/503/502 коды)

**Итого тестов: 204 (было 179, +25) — все зелёные, офлайн. tsc build чистый.**

### На Render нужно
```
OPENAI_API_KEY=sk-proj-...        # без него /vision → 503
OPENAI_VISION_MODEL=gpt-4o-mini   # опционально, gpt-4o точнее
```

---

## Сессия 18 — 25 июня 2026 (Здоровое питание: рецепты, health-score, словарь продуктов)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Opus 4.8 | Ветка: `feature/epic2-epic4-ai-recommendations`

Приложение про здоровое питание — усилил три вещи: больше полезных рецептов, надёжное
понимание продуктов в любой форме, и отсечение явно вредного.

### 1. Словарь продуктов `src/services/ingredient-knowledge.ts`
- `canonicalizeIngredient(name)` — приводит ~90 синонимов к каноничному англ. имени:
  британское/американское (aubergine→eggplant, courgette→zucchini, capsicum→bell pepper,
  coriander→cilantro, rocket→arugula), транслит (tvorog→cottage cheese, smetana→sour cream,
  grechka→buckwheat), варианты/сокращения (minced beef→ground beef, chick peas→chickpeas,
  tinned tuna→canned tuna, oatmeal→rolled oats)
- Интегрирован в `ingredientMatches` (обе стороны канонизируются) и в vision-нормализацию
  (распознанное имя приводится к каноничному) → один продукт узнаётся в любой формулировке

### 2. Health-scoring `recommendation.scoring.ts`
- `healthScore(recipe)` 0–100: +белок, +овощи/бобовые/фрукты, +цельные злаки/семена;
  −сахар, −алкоголь, −очень калорийное (>600/>700), −много жира/углеводов
- `isClearlyUnhealthy(recipe)` — консервативный guardrail: отсекает только явно вредное
  (≥800 ккал, сладкое-низкобелковое-калорийное, healthScore<35). Сбалансированные блюда
  никогда не отсекаются
- В пайплайне: вредное фильтруется ДО выбора 3 блюд (с фолбэком если осталось <3),
  `healthScore` отдаётся в каждом варианте ответа `/recommendations`
- `ScorableRecipe`/`RecipeRow` дополнены `fatG`/`carbsG`; `formatRecipe` в рекомендациях
  теперь тоже отдаёт `fatG`/`carbsG`

### 3. Рецепты `prisma/seed.ts`: 20 → 44
- +24 здоровых, быстрых, студенческих рецепта вокруг частых продуктов (яйца, сыр, йогурт,
  молоко, хлеб, болгарский перец, колбаса, овсянка, курица, тунец, бобовые, рис, овощи)
- Все с полными макросами (calories/protein/fat/carbs), категориями, moodTags
- Идемпотентно (skip по title) — повторный запуск не плодит дубли

### Тесты
- `tests/ingredient-knowledge.test.ts` — 7 (канонизация спеллингов/транслита/вариантов)
- `recommendation-scoring.test.ts` — +синоним-матчинг, healthScore, isClearlyUnhealthy
- **Итого: 226 тестов (было 212, +14) — все зелёные, офлайн. tsc build чистый.**

### Применить на Render (чтобы новые рецепты появились в проде)
```bash
DATABASE_URL="<render-external-url>" npx ts-node prisma/seed.ts
```
Схема не менялась — миграция не нужна, только пере-seed для +24 рецептов.

---

## Следующий шаг

- Добавить на Render env-переменные: `OPENAI_API_KEY`, все `PAYPAL_*`
- Habit analytics / weekly tips (Epic 5+)
- Сохранённые рецепты → синхронизация с бэкендом
- Сброс пароля
- Rate limiting на login/register (бэкенд)

---

*Сессия 1: 30 мая 2026 — Epic 1 Backend (36 тестов)*
*Сессия 2: 2 июня 2026 — Apple/OTP/SQL/Git (55 тестов)*
*Сессия 3: 6 июня 2026 — Epic 2 Backend, рецепты (77 тестов)*
*Сессия 5: 11 июня 2026 — Infra (Docker/CI/CD) + Epic 3 Pantry (84 тестов)*
*Сессия 6: 13 июня 2026 — Render деплой + CD pipeline + скрипты под Render*
*Сессия 7: 17 июня 2026 — Epic 4 Payment: PayPal + state machine (84+20 тестов)*
*Сессия 8: 18 июня 2026 — Wallet: пополнение баланса + транзакции*
*Сессия 9: 18 июня 2026 — Subscriptions: Monthly + Annual тарифы*
*Сессия 10: 19 июня 2026 — Bereke удалён, PayPal only, credentials ✅, CI fix (131 тест)*
*Сессия 11: 19 июня 2026 — Epic 4: AI-рекомендации по настроению (171 тест)*
*Сессия 12: 19 июня 2026 — Epic 2: Mood-check + история чек-инов (176 тестов)*
*Сессия 13: 24 июня 2026 — OpenAI switch (gpt-4o-mini) + PayPal fix + Postman полная (166 тестов)*

