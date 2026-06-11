# MoodFood — Руководство команды

> Репозиторий: https://github.com/nurkhaidarovbeks/MoodFood  
> Последнее обновление: 11 июня 2026

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
│   │   │   └── recipes/     ← рецепты, рекомендации
│   │   ├── services/
│   │   │   ├── email.service.ts
│   │   │   ├── google-oauth.service.ts
│   │   │   ├── apple-auth.service.ts
│   │   │   └── dietary-restriction.service.ts
│   │   └── utils/           ← jwt.ts, hash.ts
│   ├── prisma/              ← schema.prisma, миграции
│   ├── tests/               ← 77 автотестов
│   ├── .env.example         ← шаблон переменных
│   ├── docker-compose.yml   ← PostgreSQL через Docker
│   └── moodfood.postman_collection.json
├── Mobile/                  ← Flutter приложение
├── .gitignore
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

### Чего нельзя

- `git push origin main` — только через PR
- Коммитить `.env` — там секреты
- Коммитить `node_modules/`
- `git push --force` на main

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
npm run dev          # запуск в режиме разработки
npm test             # все тесты (77 штук, ~4 сек)
npm run build        # сборка TypeScript → JavaScript
npx prisma studio    # визуальный просмотр БД (http://localhost:5555)
docker-compose up -d # запустить PostgreSQL
docker-compose down  # остановить PostgreSQL
```

---

## API — все эндпоинты

Базовый URL: `http://localhost:3000/api/v1`

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

### Рецепты

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/recipes` | — | Список рецептов (с фильтрацией) |
| `GET` | `/recipes/:id` | — | Один рецепт |
| `POST` | `/recipes` | ✅ | Создать рецепт |
| `PUT` | `/recipes/:id` | ✅ | Обновить рецепт |
| `PATCH` | `/recipes/:id` | ✅ | Частично обновить рецепт |
| `DELETE` | `/recipes/:id` | ✅ | Удалить рецепт |
| `GET` | `/recipes/recommendations` | ✅ | Персональные рекомендации (с учётом ограничений) |

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

// Ответ 201
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

### Вход через email
```json
POST /api/v1/auth/login
{ "email": "user@example.com", "password": "SecurePass123!" }

// Ответ 200
{ "user": { ... }, "token": "eyJ..." }
```

### OTP вход (без пароля)
```json
// Шаг 1 — запросить код (приходит на email, действует 5 минут)
POST /api/v1/auth/otp/send
{ "email": "user@example.com" }

// Шаг 2 — войти по коду
POST /api/v1/auth/otp/verify
{ "email": "user@example.com", "code": "123456" }

// Ответ 200
{ "user": { ... }, "token": "eyJ..." }
```

### Apple Sign In
```json
POST /api/v1/auth/apple
{
  "idToken": "<apple-id-token>",
  "name": "Алибек"   // только при первом входе, потом необязательно
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

### Рецепты
```json
// Список с пагинацией
GET /api/v1/recipes?page=1&limit=10

// Персональные рекомендации (учитывает профиль пользователя)
GET /api/v1/recipes/recommendations
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
// Бэкенд запущен локально
const baseUrl = 'http://localhost:3000/api/v1';

// На Android-эмуляторе localhost указывает на сам эмулятор!
// Используй IP машины вместо localhost:
const baseUrl = 'http://10.0.2.2:3000/api/v1';
```

### Текущее состояние Flutter

- Экраны auth (Login, Register, OTP, Splash, Welcome) — готовы
- Онбординг (ProfileSetup, 4 шага) — готов
- Home с тремя табами — готов
- Mood модуль — данные в SharedPreferences (не в бэкенде)
- Google/Apple кнопки — заглушки (показывают SnackBar)
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

---

## Тесты

```powershell
cd Backend
npm test
```

77 тестов, запускаются без реальной базы данных (~4 секунды).

| Файл | Что тестирует |
|------|-------------|
| `auth.test.ts` | Регистрация, вход, Google OAuth, Apple Sign In, OTP |
| `profile.test.ts` | Создание профиля, PATCH, GET |
| `dietary-restriction.test.ts` | Фильтрация по всем 10 типам + кастомные |
| `recipe.test.ts` | CRUD рецептов, рекомендации, фильтрация |

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
| Epic 3 | ⏳ Следующий | Mood модуль, AI-рекомендации |

---

*Backend: май–июнь 2026*
