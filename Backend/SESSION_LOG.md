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

## Сессия 4 — 9–11 июня 2026 (Flutter Frontend — Epic 1)

> Автор: Khamitbek Azhara | Модель: Claude Sonnet 4.6  
> Директория: `Mobile/` (бэкенд не трогался)

### Что сделано

**Анализ и линтинг:**
- Исправлены все flutter analyze предупреждения → **0 issues**
- `withOpacity` → `withValues(alpha:)` в 6 файлах (deprecated API)
- Удалён неиспользуемый `import 'dart:math'`
- Добавлен `const` к виджетам где требовал линтер

**Исправление SDK:**
- Восстановлены удалённые файлы Flutter SDK через `git restore`
- Создан `/flutter/bin/cache/pkg/sky_engine/lib/_embedder.yaml` — исправил 715 ошибок "Undefined class"
- Перекачан dart-sdk кэш (212 МБ) — исправил crash `ddc_module_loader.js not found`

**Веб-платформа:**
- `TokenStorage` — добавлен `kIsWeb` conditional: web → `SharedPreferences`, mobile → `FlutterSecureStorage`
- Удалён пакет `google_sign_in` — загружал Google CDN скрипт при старте и вешал белый экран
- Обновлён `web/index.html` — убран google-signin meta тег

**Дизайн по Figma:**
- Обновлён `app_theme.dart` — цвета Figma: `#7CB342`, `#FAF9F7`, `#2D3436`, `#717182`
- Создан `auth_shared.dart` — общие компоненты: `AuthHeader`, `AuthTabToggle`, `AuthFieldLabel`, `AuthErrorBanner`, `AuthSubmitButton`, `AuthOrDivider`, `AuthSocialButtons`
- Переписан `login_screen.dart` по Figma
- Переписан `register_screen.dart` по Figma

**iOS деплой:**
- Установлен Xcode 26.5 + iOS 26.5 platform support
- Установлен CocoaPods 1.16.2 через Homebrew
- Настроен code signing: Personal Team, Bundle ID `com.banb.moodfood`
- Обновлён `ios/Podfile` — `platform :ios, '13.0'`, deployment target для всех pods
- Создан `ios/Flutter/AppFrameworkInfo.plist` (удалился после flutter clean)
- Создан `ios/Runner/AppDelegate.swift` (отсутствовал)
- Приложение успешно запущено на iPhone Cherry🍒 в debug и release режиме

### Экраны — все реализованы

| Экран | Файл | Статус |
|-------|------|--------|
| Splash | `auth/screens/splash_screen.dart` | ✅ |
| Welcome | `auth/screens/welcome_screen.dart` | ✅ |
| Login | `auth/screens/login_screen.dart` | ✅ Figma |
| Register | `auth/screens/register_screen.dart` | ✅ Figma |
| OTP | `auth/screens/otp_screen.dart` | ✅ |
| Profile Setup | `onboarding/screens/profile_setup_screen.dart` | ✅ 4 шага |
| Home | `home/screens/home_screen.dart` | ✅ |
| Mood Check | `mood/screens/mood_check_screen.dart` | ✅ |
| Mood History | `mood/screens/mood_history_screen.dart` | ✅ |

### Проблемы и решения

| Проблема | Решение |
|----------|---------|
| 715 "Undefined class" от flutter analyze | Создан `_embedder.yaml` в sky_engine |
| `ddc_module_loader.js` crash на web | Перекачан dart-sdk кэш |
| `flutter_secure_storage` не работает на web | `kIsWeb` conditional в TokenStorage |
| Белый экран в Chrome (5+ минут) | Удалён google_sign_in — грузил Google CDN |
| `No valid code signing certificates` | Настроен Personal Team в Xcode |
| `Failed Registering Bundle Identifier` | Изменён Bundle ID на `com.banb.moodfood` |
| `CocoaPods not installed` | `brew install cocoapods` |
| `AppFrameworkInfo.plist` не найден | Создан вручную после flutter clean |
| `AppDelegate.swift` не найден | Создан стандартный файл |
| `errSecInternalComponent` | flutter clean + повторная сборка |
| Deployment target 9.0 для pods | `platform :ios, '13.0'` в Podfile |

### Запуск приложения на iPhone

```bash
# Подключить iPhone по USB, включить Developer Mode
# Настройки → Конфиденциальность и безопасность → Режим разработчика

cd ~/MoodFood/Mobile
/Users/azharakhamitbek/flutter/bin/flutter run --release

# При первом запуске на iPhone:
# Настройки → Основные → VPN и управление устройством → Доверять
```

---

## Что не реализовано (намеренно, для следующих эпиков)

| Что | Когда |
|-----|-------|
| Refresh токены | После MVP |
| Сброс пароля | Отдельный feature |
| Telegram OAuth | Enum в схеме есть, endpoint позже |
| Рекомендации рецептов | Epic 2 — DietaryRestrictionService уже готов |
| Rate limiting на login/register | Добавить express-rate-limit |
| Деплой | После Flutter |

---

## Следующий шаг — Epic 4+

- Epic 4: AI рекомендации по настроению (Mood-check → рецепты)
- Избранное / сохранённые рецепты
- Сброс пароля
- Rate limiting на login/register
- Деплой на VPS (nginx/moodfood.conf + scripts/deploy.sh готовы)

---

*Сессия 1: 30 мая 2026 — Epic 1 Backend (36 тестов)*  
*Сессия 2: 2 июня 2026 — Apple/OTP/SQL/Git (55 тестов)*  
*Сессия 3: 6 июня 2026 — Epic 2 Backend, рецепты (77 тестов)*  
*Сессия 4: 9–11 июня 2026 — Flutter Frontend Epic 1-2, все экраны, iOS деплой*  
*Сессия 5: 11 июня 2026 — Infra (Docker/CI/CD) + Epic 3 Pantry (84 тестов)*  

