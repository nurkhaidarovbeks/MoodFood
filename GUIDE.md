# MoodFood — Руководство команды

> Репозиторий: https://github.com/nurkhaidarovbeks/MoodFood  
> Последнее обновление: 13 июня 2026

---

## Что такое MoodFood

AI-приложение для рекомендаций еды на основе настроения, бюджета, аллергий и диетических ограничений.

```
Flutter (Mobile)
      ↓  HTTP запросы (JSON)
  Backend API (Node.js + Express, порт 3000)
      ↓  SQL
  PostgreSQL (порт 5434)
```

---

## Структура репозитория

```
MoodFood/
├── Backend/                 ← серверная часть (Node.js + TypeScript)
│   ├── src/
│   │   ├── config/          ← env.ts, database.ts
│   │   ├── middleware/      ← auth.ts, validate.ts, errorHandler.ts
│   │   ├── modules/
│   │   │   ├── auth/        ← регистрация, вход, Google/Apple, OTP
│   │   │   ├── profile/     ← профиль питания пользователя
│   │   │   ├── pantry/      ← кладовка ингредиентов пользователя
│   │   │   └── recipes/     ← рецепты, рекомендации
│   │   ├── services/
│   │   │   ├── email.service.ts
│   │   │   ├── google-oauth.service.ts
│   │   │   ├── apple-auth.service.ts
│   │   │   └── dietary-restriction.service.ts
│   │   └── utils/           ← jwt.ts, hash.ts
│   ├── prisma/              ← schema.prisma, миграции
│   ├── tests/               ← 84 автотестов
│   ├── .env.example         ← шаблон переменных
│   ├── docker-compose.yml   ← PostgreSQL через Docker
│   └── moodfood.postman_collection.json
├── Mobile/                  ← Flutter приложение
├── scripts/
│   ├── deploy.sh            ← триггер Render деплоя (curl Deploy Hook)
│   └── backup.sh            ← pg_dump через External Database URL
├── nginx/
│   └── moodfood.conf        ← конфиг для VPS (не нужен на Render)
├── .github/
│   └── workflows/ci.yml     ← CI/CD: тесты на всех ветках, деплой на main
└── GUIDE.md                 ← этот файл
```

---

## Git — правила команды

### Ветки

```
main              ← стабильный код (только через Pull Request)
  ├── feature/epic-3-mood
  ├── feature/flutter-auth
  └── fix/название-бага
```

**Прямой пуш в `main` запрещён.**

### Рабочий процесс

```bash
# 1. Перед началом — обновить main
git checkout main
git pull origin main

# 2. Создать ветку
git checkout -b feature/название-задачи

# 3. Работать, коммитить
git add .
git commit -m "feat: описание"

# 4. Запушить ветку
git push origin feature/название-задачи

# 5. На GitHub: открыть Pull Request → feature/... → main
```

### Формат коммитов

| Префикс | Когда |
|---------|-------|
| `feat:` | новая функциональность |
| `fix:` | исправление бага |
| `refactor:` | рефакторинг без изменения логики |
| `docs:` | изменения в документации |
| `test:` | тесты |
| `chore:` | настройка, инфраструктура |

### Чего нельзя

- `git push origin main` — только через PR
- Коммитить `.env` — там секреты
- Коммитить `node_modules/`
- `git push --force` на main

---

## CI/CD — как работает

```
Любой пуш в любую ветку
  → GitHub Actions: npm ci → prisma generate → 84 теста → tsc build

Пуш/мерж в main
  → GitHub Actions: тесты → curl Render Deploy Hook → авто-деплой на Render
```

Следи за прогрессом: https://github.com/nurkhaidarovbeks/MoodFood/actions

---

## Backend — быстрый старт

### Требования

- Node.js v18+
- Docker Desktop

### Установка

```powershell
cd Backend

# 1. Установить зависимости
npm install

# 2. Скопировать и заполнить .env
copy .env.example .env

# 3. Запустить PostgreSQL
docker-compose up -d

# 4. Создать таблицы
npx prisma migrate deploy

# 5. (Опционально) Заполнить тестовыми рецептами
npx ts-node prisma/seed.ts

# 6. Запустить сервер
npm run dev
```

Сервер: `http://localhost:3000`

### Переменные окружения (`.env`)

| Переменная | Обязательна | Описание |
|-----------|------------|---------|
| `DATABASE_URL` | ✅ | `postgresql://moodfood:moodfood_dev@localhost:5434/moodfood?schema=public` |
| `JWT_SECRET` | ✅ | Любая строка 32+ символов |
| `JWT_EXPIRES_IN` | — | Срок токена, по умолчанию `7d` |
| `REQUIRE_EMAIL_VERIFICATION` | — | `true`/`false`, по умолчанию `false` |
| `GOOGLE_CLIENT_ID` | — | Для Google OAuth |
| `APPLE_CLIENT_ID` | — | Bundle ID приложения для Apple Sign In |
| `SMTP_HOST` / `SMTP_USER` / `SMTP_PASS` | — | Если пусто — письма в консоль |
| `APP_URL` | — | URL сервера (для ссылок в письмах) |

### Команды

```powershell
npm run dev          # запуск сервера с hot-reload (режим разработки)
npm test             # все тесты (84 штуки, ~4 сек)
npm run build        # сборка TypeScript → JavaScript
npx prisma studio    # визуальный просмотр БД (http://localhost:5555)
```

**Два способа запустить окружение:**

```powershell
# Режим разработки — только БД в Docker, сервер локально
docker-compose up -d postgres   # поднять только PostgreSQL
npm run dev                     # запустить сервер с hot-reload

# Полный Docker — и БД, и бэкенд в контейнерах (production-like)
docker-compose up --build -d    # собрать образ и поднять всё
docker-compose down             # остановить всё
```

> Для разработки используй первый способ — hot-reload работает только при `npm run dev`.  
> Второй способ — для финального тестирования перед деплоем или на сервере.

---

## Деплой (Render)

Бэкенд задеплоен на Render (Free tier):

- **URL:** `https://moodfood-backend.onrender.com`
- **Health check:** `https://moodfood-backend.onrender.com/health`
- **Dashboard:** https://dashboard.render.com

**Важно про Free tier:**
- Сервер засыпает после 15 минут неактивности, первый запрос будет медленным (~30 сек)
- PostgreSQL удаляется через 90 дней — делай бэкапы регулярно

**Ручной деплой без пуша:**
```bash
export RENDER_DEPLOY_HOOK_URL="https://api.render.com/deploy/srv-xxx?key=yyy"
bash scripts/deploy.sh
```

**Бэкап БД:**
```bash
# DATABASE_URL берёшь в Render Dashboard → PostgreSQL → Info → External Database URL
export DATABASE_URL="postgresql://user:pass@dpg-xxx.render.com/moodfood"
bash scripts/backup.sh
# Сохраняет в ./backups/moodfood-YYYYMMDD-HHMMSS.sql (хранение 7 дней)
```

---

## API — все эндпоинты

| Окружение | Base URL |
|-----------|----------|
| Локальная разработка | `http://localhost:3000/api/v1` |
| Продакшн (Render) | `https://moodfood-backend.onrender.com/api/v1` |

Защищённые маршруты требуют заголовок:
```
Authorization: Bearer <jwt-токен>
```

### Системные

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/health` | — | Проверка сервера |

### Аутентификация

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `POST` | `/auth/register` | — | Регистрация email + пароль |
| `POST` | `/auth/login` | — | Вход email + пароль |
| `POST` | `/auth/google` | — | Вход через Google (ID token) |
| `POST` | `/auth/apple` | — | Вход через Apple (ID token) |
| `POST` | `/auth/otp/send` | — | Отправить OTP-код на email |
| `POST` | `/auth/otp/verify` | — | Войти по OTP-коду |
| `GET` | `/auth/verify-email?token=` | — | Подтвердить email по ссылке |
| `POST` | `/auth/resend-verification` | — | Переслать письмо верификации |

### Профиль

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/profile` | ✅ | Получить профиль |
| `PUT` | `/profile` | ✅ | Создать / полностью заменить профиль |
| `PATCH` | `/profile` | ✅ | Частично обновить профиль |

### Кладовка (Pantry)

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/pantry` | ✅ | Список ингредиентов пользователя |
| `POST` | `/pantry` | ✅ | Добавить ингредиенты `{ "ingredients": ["eggs", "rice"] }` |
| `DELETE` | `/pantry/clear` | ✅ | Очистить всю кладовку |
| `DELETE` | `/pantry/:id` | ✅ | Удалить один ингредиент |

### Рецепты

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/recipes` | — | Список рецептов (с фильтрацией) |
| `GET` | `/recipes/:id` | — | Один рецепт |
| `POST` | `/recipes` | ✅ | Создать рецепт |
| `PUT` | `/recipes/:id` | ✅ | Обновить рецепт |
| `PATCH` | `/recipes/:id` | ✅ | Частично обновить рецепт |
| `DELETE` | `/recipes/:id` | ✅ | Удалить рецепт |
| `GET` | `/recipes/recommendations` | ✅ | Рекомендации (ограничения + опционально `useMyIngredients=true&minMatchScore=0.8`) |

---

## Интеграция Backend ↔ Frontend

### Что уже готово

| Компонент | Статус |
|-----------|--------|
| Backend API (84 теста) | ✅ Готов |
| Деплой на Render | ✅ Живой |
| CI/CD (автодеплой при пуше в main) | ✅ Работает |
| Flutter Auth экраны (Login/Register/OTP) | ✅ Готовы |
| Flutter Google Sign In | ✅ Реализован |
| Flutter OnBoarding (ProfileSetup) | ✅ Готов |
| Flutter Pantry экран | ⏳ Нужно реализовать |
| Flutter Recipes экран | ⏳ Нужно реализовать |
| Flutter Apple Sign In | 🔒 Заглушка (требует iOS entitlement) |

---

### Шаг 1 — Переключить Flutter на продакшн URL

В файле `Mobile/lib/core/constants/api_constants.dart` смени базовый URL:

```dart
// Было (локальная разработка):
static const String baseUrl = 'http://localhost:3000/api/v1';

// Стало (продакшн):
static const String baseUrl = 'https://moodfood-backend.onrender.com/api/v1';
```

> На Android-эмуляторе для локальной разработки используй `http://10.0.2.2:3000/api/v1` вместо localhost.

---

### Шаг 2 — Как работает авторизация

**Все запросы после логина:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Flutter уже настроен: `Dio` интерцептор автоматически добавляет этот заголовок из `TokenStorage`.

**Флоу регистрации:**
```
POST /auth/register → { user, token }  ← сохрани token в TokenStorage
POST /auth/login    → { user, token }  ← сохрани token в TokenStorage
POST /auth/google   → { user, token }  ← idToken берём из GoogleSignIn SDK
```

**Поле `isProfileComplete` в ответе `/auth/login` и `/auth/register`:**
- `false` → перенаправить на онбординг (`/profile-setup`)
- `true` → перенаправить на главный экран (`/home`)

---

### Шаг 3 — Что передать фронтенд-разработчикам

**Основные данные:**

| Параметр | Значение |
|----------|---------|
| Production API URL | `https://moodfood-backend.onrender.com/api/v1` |
| Auth header | `Authorization: Bearer <token>` |
| Content-Type | `application/json` |
| Google Web Client ID | `189389207039-8bht9m53kvpqi00hqjfm5k1ov2vujt3h.apps.googleusercontent.com` |
| Bundle ID | `com.banb.moodfood` |

**Файлы для передачи:**
- `Backend/moodfood.postman_collection.json` — все запросы с примерами готовы, импортируй в Postman
- `Backend/.env.example` — переменные окружения для локального запуска бэкенда

---

### Шаг 4 — Порядок реализации экранов (что брать в работу)

**Epic 3 Frontend — всё API уже готово:**

**1. Экран Pantry (кладовка)**
```
GET  /pantry              → список ингредиентов пользователя
POST /pantry              { "ingredients": ["eggs", "rice", "tomato"] }
DELETE /pantry/:id        → удалить один ингредиент
DELETE /pantry/clear      → очистить всё
```

**2. Экран Recipes (список рецептов)**
```
GET /recipes?page=1&limit=20          → список с пагинацией
GET /recipes?mood=calm                → фильтр по настроению
GET /recipes/:id                      → один рецепт
```

**3. Экран Recommendations (рекомендации)**
```
GET /recipes/recommendations                              → по профилю (диет. ограничения)
GET /recipes/recommendations?useMyIngredients=true        → по ингредиентам из кладовки
GET /recipes/recommendations?useMyIngredients=true&minMatchScore=0.8
```

Ответ рекомендаций с `useMyIngredients=true`:
```json
{
  "id": "uuid",
  "title": "Vegetable Stir Fry",
  "matchScore": 0.75,
  "missingIngredients": ["olive oil", "basil"]
}
```

---

### Форматы ответов

**Успешная аутентификация:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Алибек",
    "authProvider": "email",
    "isEmailVerified": true,
    "isProfileComplete": false
  },
  "token": "eyJ..."
}
```

**Ошибка:**
```json
{
  "error": {
    "message": "Invalid credentials",
    "code": "INVALID_CREDENTIALS"
  }
}
```

---

## API — примеры запросов

### Регистрация
```json
POST /api/v1/auth/register
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "Алибек"
}
```

### OTP вход (без пароля)
```json
// Шаг 1 — запросить код (приходит на email, действует 5 минут)
POST /api/v1/auth/otp/send
{ "email": "user@example.com" }

// Шаг 2 — войти по коду
POST /api/v1/auth/otp/verify
{ "email": "user@example.com", "code": "123456" }
```

### Google Sign In
```json
POST /api/v1/auth/google
{ "idToken": "<google-id-token-из-SDK>" }
```

### Apple Sign In
```json
POST /api/v1/auth/apple
{
  "idToken": "<apple-id-token>",
  "name": "Алибек"   // только при первом входе
}
```

### Профиль питания
```json
PUT /api/v1/profile
Authorization: Bearer eyJ...

{
  "age": 22,
  "goal": "Питаться здорово",
  "lifestyle": "student",
  "budgetLevel": "low",
  "dietaryRestrictions": ["vegan"],
  "allergies": ["nut_allergy"],
  "customRestrictions": ["грибы", "кинза"]
}
```

### Кладовка
```json
POST /api/v1/pantry
Authorization: Bearer eyJ...
{ "ingredients": ["eggs", "rice", "tomato"] }

// Рецепты по ингредиентам из кладовки
GET /api/v1/recipes/recommendations?useMyIngredients=true&minMatchScore=0.8
Authorization: Bearer eyJ...
```

---

## Диетические ограничения

| Ключ | Что исключает |
|------|-------------|
| `vegan` | Мясо, рыба, молочка, яйца, мёд |
| `vegetarian` | Мясо, рыба |
| `pescatarian` | Только мясо (рыба разрешена) |
| `lactose_free` | Молочные продукты |
| `gluten_free` | Пшеница, мука, хлеб, паста, ячмень, рожь |
| `halal` | Свинина, алкоголь |
| `kosher` | Свинина, моллюски |
| `nut_allergy` | Все орехи, арахис |
| `egg_allergy` | Яйца, майонез |
| `soy_allergy` | Соя, тофу, мисо, соевый соус |

Кастомные ограничения — любой текст в `customRestrictions`, совпадение по имени ингредиента без учёта регистра.

**Важно:** рецепты фильтруются на бэкенде — фронтенд не может обойти ограничения.

---

## Коды ошибок

| Код | HTTP | Описание |
|-----|------|---------|
| `EMAIL_EXISTS` | 409 | Email уже зарегистрирован |
| `INVALID_CREDENTIALS` | 401 | Неверный email или пароль |
| `ACCOUNT_INACTIVE` | 403 | Аккаунт заблокирован |
| `EMAIL_NOT_VERIFIED` | 403 | Email не подтверждён |
| `INVALID_TOKEN` | 400 | Токен верификации недействителен |
| `INVALID_APPLE_TOKEN` | 401 | Apple ID token недействителен |
| `APPLE_NO_EMAIL` | 400 | Apple не вернул email |
| `INVALID_OTP` | 401 | OTP неверный или истёк |
| `OTP_MAX_ATTEMPTS` | 429 | Превышено количество попыток OTP (3) |
| `PANTRY_ITEM_NOT_FOUND` | 404 | Ингредиент не найден в кладовке пользователя |
| `RATE_LIMITED` | 429 | Слишком много запросов |
| `UNAUTHORIZED` | 401 | JWT токен отсутствует или недействителен |
| `NOT_FOUND` | 404 | Маршрут не найден |

---

## Mobile (Flutter) — быстрый старт

### Требования

- Flutter 3.41.3+
- Xcode 26.5+ (для iOS/macOS)
- iPhone с включённым Developer Mode (Настройки → Конфиденциальность → Режим разработчика)

### Установка Flutter (Windows)

1. Скачать с [flutter.dev/install/windows](https://docs.flutter.dev/get-started/install/windows)
2. Распаковать в `C:\flutter`
3. Добавить `C:\flutter\bin` в переменную PATH
4. Перезапустить терминал и проверить: `flutter doctor`

### Запуск

```bash
cd Mobile

# Установить зависимости
flutter pub get

# Запустить на iPhone (нужен подключённый телефон)
flutter run --release

# Запустить в Chrome (для проверки UI без телефона)
flutter run -d chrome
# Первый запуск занимает 3-5 минут (компиляция Dart → JS)
# После первого запуска: 'r' — hot reload, 'R' — hot restart
```

### Структура приложения

```
Mobile/lib/
├── core/
│   ├── api/          ← Dio HTTP клиент, JWT интерцептор
│   ├── constants/    ← API URLs
│   ├── models/       ← User, Profile, MoodEntry
│   ├── providers/    ← AuthProvider, ProfileProvider, MoodProvider
│   ├── services/     ← AuthService, ProfileService
│   ├── storage/      ← TokenStorage (SecureStorage)
│   └── theme/        ← AppTheme с дизайн-токенами
├── features/
│   ├── auth/         ← Login, Register, OTP, Welcome, Splash
│   ├── home/         ← Home (3 таба)
│   ├── mood/         ← MoodCheck, MoodHistory
│   └── onboarding/   ← ProfileSetup (4 шага)
└── router/           ← AppRouter
```

### Дизайн-токены (Figma)

| Токен | Цвет |
|-------|------|
| Primary | `#7CB342` |
| Background | `#FAF9F7` |
| Text Dark | `#2D3436` |
| Text Secondary | `#717182` |

### Подключение к бэкенду

```dart
// Продакшн (Render)
const baseUrl = 'https://moodfood-backend.onrender.com/api/v1';

// Локальная разработка
const baseUrl = 'http://localhost:3000/api/v1';

// На Android-эмуляторе localhost указывает на сам эмулятор!
const baseUrl = 'http://10.0.2.2:3000/api/v1';
```

### Текущее состояние Flutter

- Экраны auth (Login, Register, OTP, Splash, Welcome) — готовы
- Онбординг (ProfileSetup, 4 шага) — готов
- Home с тремя табами — готов
- Google Sign In — реализован (google_sign_in: ^6.2.2, serverClientId настроен)
- Apple Sign In — заглушка (показывает SnackBar "coming soon")
- Mood модуль — данные в SharedPreferences (не в бэкенде)
- Pantry экран — не реализован (API готов)
- Recipes экран — не реализован (API готов)
- Bundle ID: `com.banb.moodfood`

---

## База данных

```powershell
# Визуальный просмотр таблиц
cd Backend
npx prisma studio
# Открывает http://localhost:5555
```

Или через pgAdmin:
- Host: `localhost`, Port: `5434`
- Database: `moodfood`, User: `moodfood`, Password: `moodfood_dev`

### Основные таблицы

**`users`** — аккаунты пользователей: id, email, passwordHash, authProvider (`email`/`google`/`apple`), googleId, appleId, isEmailVerified, isActive, name, otpHash, otpExpires, otpAttempts

**`user_profiles`** — профиль питания: age, goal, lifestyle, budgetLevel, dietaryRestrictions, allergies, customRestrictions, onboardingCompleted

**`recipes`** — рецепты: title, description, ingredients (JSON), tags, mood, budget

**`ingredients`** — справочник ингредиентов: id, name (уникальный, lowercase), category

**`user_ingredients`** — кладовка: userId + ingredientId (уникальная пара), FK → users + ingredients

---

## Тесты

```powershell
cd Backend
npm test
```

84 теста, запускаются без реальной базы данных (~4 секунды).

| Файл | Тестов | Что тестирует |
|------|--------|-------------|
| `auth.test.ts` | 20 | Регистрация, вход, Google OAuth, Apple Sign In, OTP |
| `profile.test.ts` | 12 | Создание профиля, PATCH, GET |
| `dietary-restriction.test.ts` | 22 | Фильтрация по всем 10 типам + кастомные |
| `recipe.test.ts` | 23 | CRUD рецептов, рекомендации, фильтрация, matchScore |
| `pantry.test.ts` | 7 | Добавление, удаление, очистка кладовки |

---

## Безопасность

- Пароли — только bcrypt хэш (cost 12), никогда в открытом виде
- OTP — только SHA-256 хэш в БД, сам код только в письме
- Apple/Google токены верифицируются на серверах Apple/Google
- JWT проверяется на каждом защищённом маршруте
- Zod валидирует все входящие данные
- Prisma ORM — параметризованные запросы, SQL injection невозможен
- Rate limiting: OTP отправка — 3 запроса/15 мин, OTP проверка — 10 попыток/5 мин

---

## Состояние проекта

| Epic | Статус | Что сделано |
|------|--------|------------|
| Epic 1 | ✅ Готов | Auth (email, Google, Apple, OTP), профиль, диетические ограничения |
| Epic 2 | ✅ Готов | CRUD рецептов, рекомендации с фильтрацией |
| Epic 3 Backend | ✅ Готов | Кладовка (pantry), фильтрация рецептов по ингредиентам + matchScore |
| Epic 3 Frontend | ⏳ Следующий | Экраны Pantry + Recipes + Recommendations |
| Infra | ✅ Готово | Docker, GitHub Actions CI/CD, Render деплой |
| Epic 4 | ⏳ Следующий | AI-рекомендации по настроению, избранное, сброс пароля |

---

*Backend: май–июнь 2026 · 84 теста · Epics 1–3 Backend завершены · Деплой: Render*
