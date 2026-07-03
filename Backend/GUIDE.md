# MoodFood Backend — Полное руководство

> **📦 АРХИВНЫЙ ДОКУМЕНТ (Epic 1, 30 мая 2026).** Отражает только первый этап
> (auth + профиль, 36 тестов). Проект с тех пор вырос до **Epics 1–7, 255 тестов**.
> Актуальное руководство и все эндпоинты — в корневом `GUIDE.md`; история — в
> `Backend/SESSION_LOG.md`; запросы — в `moodfood.postman_collection.json`.
> Файл оставлен как историческая справка.

> Написано: 30 мая 2026  
> Версия: Epic 1 — Регистрация и профиль пользователя

---

## Что такое MoodFood Backend

MoodFood — это AI-приложение для питания, которое рекомендует еду на основе настроения, уровня энергии, бюджета, аллергий и диетических ограничений пользователя.

**Backend** — это сервер, который:
- Хранит данные пользователей в базе данных
- Принимает запросы от мобильного приложения или веба
- Проверяет, кто ты (аутентификация)
- Отдаёт только те рецепты, которые тебе можно есть (фильтрация)

```
Телефон / Браузер
      ↓  HTTP запросы (JSON)
  Backend API (порт 3000)
      ↓  SQL запросы
  PostgreSQL База данных
```

---

## Стек технологий

| Что | Технология | Зачем |
|-----|-----------|-------|
| Язык | TypeScript | Типобезопасность, меньше багов |
| Сервер | Express.js | HTTP роутинг |
| База данных | PostgreSQL | Основное хранилище |
| ORM | Prisma 5 | Работа с БД без написания SQL вручную |
| Аутентификация | JWT (токены) | Безопасный вход без сессий |
| Хэширование паролей | bcrypt | Пароли никогда не хранятся в открытом виде |
| Валидация | Zod | Проверка входящих данных |
| Google OAuth | google-auth-library | Вход через Google |
| Email | Nodemailer | Письма подтверждения |
| Тесты | Jest | Автоматическая проверка логики |

---

## Структура папок

```
Backend/
├── src/
│   ├── config/
│   │   ├── env.ts              ← читает .env переменные
│   │   └── database.ts         ← подключение к PostgreSQL
│   ├── utils/
│   │   ├── jwt.ts              ← создание/проверка токенов
│   │   ├── hash.ts             ← SHA-256, генерация токенов
│   │   └── profile-completion.ts ← логика "профиль заполнен?"
│   ├── services/
│   │   ├── email.service.ts           ← отправка писем (или лог в консоль)
│   │   ├── google-oauth.service.ts    ← проверка Google токена
│   │   └── dietary-restriction.service.ts ← ФИЛЬТРАЦИЯ РЕЦЕПТОВ
│   ├── middleware/
│   │   ├── auth.ts             ← проверка JWT на каждом запросе
│   │   ├── validate.ts         ← валидация тела запроса через Zod
│   │   └── errorHandler.ts     ← единый обработчик ошибок
│   ├── modules/
│   │   ├── auth/               ← регистрация, вход, Google, верификация email
│   │   └── profile/            ← профиль питания пользователя
│   ├── app.ts                  ← Express приложение (роуты, middleware)
│   └── server.ts               ← точка входа, запуск сервера
├── prisma/
│   └── schema.prisma           ← схема базы данных
├── tests/
│   ├── auth.test.ts            ← тесты аутентификации
│   ├── profile.test.ts         ← тесты профиля
│   └── dietary-restriction.test.ts ← тесты фильтрации рецептов
├── .env                        ← секреты (не коммитить в git!)
├── .env.example                ← шаблон для новых разработчиков
├── docker-compose.yml          ← PostgreSQL через Docker
└── moodfood.postman_collection.json ← готовые запросы для Postman
```

---

## База данных — таблицы

### `users` — аккаунты пользователей
| Поле | Тип | Описание |
|------|-----|---------|
| id | UUID | Уникальный ID |
| email | String | Уникальный email |
| passwordHash | String | bcrypt хэш пароля (не сам пароль!) |
| authProvider | Enum | `email`, `google`, `telegram` |
| googleId | String | ID аккаунта Google |
| isEmailVerified | Boolean | Подтверждён ли email |
| emailVerificationToken | String | SHA-256 хэш токена верификации |
| emailVerificationExpires | DateTime | Срок действия токена |
| isActive | Boolean | Активен ли аккаунт |
| name | String | Имя пользователя |
| createdAt / updatedAt | DateTime | Временные метки |

### `user_profiles` — профиль питания
| Поле | Тип | Описание |
|------|-----|---------|
| userId | UUID | Связь с users |
| age | Int | Возраст |
| goal | String | Цель (например "есть здоровее") |
| lifestyle | Enum | `student`, `professional`, `other` |
| budgetLevel | Enum | `low`, `medium`, `high` |
| dietaryRestrictions | JSON | Массив ключей: `["vegan", "gluten_free"]` |
| allergies | JSON | Массив ключей: `["nut_allergy"]` |
| customRestrictions | JSON | Свободный текст: `["грибы", "кинза"]` |
| onboardingCompleted | Boolean | Профиль заполнен? |
| profileCompletedAt | DateTime | Когда был заполнен |

### `recipes`, `ingredients`, `recipe_ingredients`
Таблицы для рецептов и их ингредиентов. Используются для фильтрации.

---

## Запуск проекта

### Требования
- Node.js (уже установлен — v24.3.0)
- Docker Desktop (уже установлен)

### 1. Запустить Docker Desktop
Найти в Start Menu → запустить → подождать зелёную иконку в трее.

### 2. PostgreSQL через Docker
```powershell
cd "c:\Users\0penf\Corporate project\Backend"
docker-compose up -d
```
PostgreSQL будет доступен на `localhost:5432`.

### 3. Создать таблицы
```powershell
npm run db:generate   # генерирует Prisma клиент из схемы
npm run db:migrate    # создаёт таблицы в БД (введи имя: "init")
```

### 4. Запустить сервер
```powershell
npm run dev
```
Сервер: `http://localhost:3000`

### 5. Посмотреть данные в БД (визуально)
```powershell
npm run db:studio
```
Открывает браузер с таблицами — как Excel для твоей базы данных.

### Другие команды
```powershell
npm test              # запустить все тесты
npm run build         # собрать TypeScript → JavaScript для продакшена
npm start             # запустить собранный продакшен билд
```

---

## API Endpoints

Все запросы и ответы — в формате JSON.  
Базовый URL: `http://localhost:3000/api/v1`

Защищённые маршруты требуют заголовок:
```
Authorization: Bearer <твой-jwt-токен>
```

---

### Аутентификация

#### `POST /auth/register` — регистрация
```json
// Запрос
{
  "email": "alice@example.com",
  "password": "SecurePass123!",
  "name": "Alice"
}

// Ответ 201
{
  "user": {
    "id": "uuid",
    "email": "alice@example.com",
    "name": "Alice",
    "authProvider": "email",
    "isEmailVerified": true,
    "isProfileComplete": false
  },
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "requiresEmailVerification": false
}
```

**Ошибки:**
- `400` — невалидный email или слабый пароль
- `409` — email уже зарегистрирован

---

#### `POST /auth/login` — вход
```json
// Запрос
{
  "email": "alice@example.com",
  "password": "SecurePass123!"
}

// Ответ 200
{
  "user": { ... },
  "token": "eyJ..."
}
```

**Ошибки:**
- `401` — неверный email или пароль
- `403 ACCOUNT_INACTIVE` — аккаунт заблокирован
- `403 EMAIL_NOT_VERIFIED` — email не подтверждён (если включена верификация)

---

#### `POST /auth/google` — вход через Google
```json
// Запрос (idToken получается на фронтенде через Google SDK)
{
  "idToken": "<google-id-token>"
}

// Ответ 200
{
  "user": {
    "authProvider": "google",
    "isEmailVerified": true,
    ...
  },
  "token": "eyJ..."
}
```

Backend проверяет токен на серверах Google — фронтенд не может подделать данные.

---

#### `GET /auth/verify-email?token=<токен>` — подтверждение email
Ссылка приходит в письме. При `REQUIRE_EMAIL_VERIFICATION=false` не нужна.

#### `POST /auth/resend-verification` — переслать письмо
```json
{ "email": "alice@example.com" }
```

---

### Профиль пользователя

Все маршруты требуют токен.

#### `GET /profile` — получить профиль
```json
// Ответ 200
{
  "user": {
    "id": "uuid",
    "email": "alice@example.com",
    "isProfileComplete": false
  },
  "profile": null
}
// profile = null если ещё не заполнен
```

---

#### `PUT /profile` — создать или полностью обновить профиль
```json
// Запрос
{
  "age": 22,
  "goal": "Есть здоровее и чувствовать себя бодрее",
  "lifestyle": "student",
  "budgetLevel": "low",
  "dietaryRestrictions": ["vegan", "gluten_free"],
  "allergies": ["nut_allergy"],
  "customRestrictions": ["грибы", "кинза"]
}

// Ответ 200
{
  "profile": { ... },
  "isProfileComplete": true
}
```

**Профиль считается заполненным** когда указаны: `age`, `goal`, `lifestyle`, `budgetLevel`.

---

#### `PATCH /profile` — частичное обновление
Отправляешь только то, что хочешь изменить. Остальные поля не трогаются.
```json
// Запрос — меняем только цель
{ "goal": "Набрать мышечную массу" }
```

---

## Диетические ограничения

### Стандартные ключи

| Ключ | Что исключает |
|------|-------------|
| `vegan` | Мясо, рыба, яйца, молочка, мёд |
| `vegetarian` | Мясо, рыба |
| `pescatarian` | Только мясо (рыба разрешена) |
| `lactose_free` | Молоко, сыр, йогурт, масло, сливки |
| `gluten_free` | Пшеница, мука, хлеб, паста, ячмень, рожь |
| `halal` | Свинина, алкоголь |
| `kosher` | Свинина, моллюски, креветки |
| `nut_allergy` | Все орехи, арахис, миндаль, кешью и др. |
| `egg_allergy` | Яйца, майонез |
| `soy_allergy` | Соя, тофу, мисо, соевый соус |

### Кастомные ограничения
Любой текст в `customRestrictions` — совпадение ищется по названию ингредиента без учёта регистра.

### Как работает фильтрация
Когда backend выдаёт рецепты, он проверяет каждый рецепт через `canUserSeeRecipe()` — рецепты с запрещёнными ингредиентами **никогда не попадают в ответ**. Фронтенд не может это обойти.

---

## Email верификация

Управляется через `REQUIRE_EMAIL_VERIFICATION` в `.env`:

| Значение | Поведение |
|---------|----------|
| `false` (по умолчанию) | Верификация не нужна — MVP режим |
| `true` | После регистрации нужно кликнуть ссылку в письме |

Если SMTP не настроен — ссылка выводится в консоль сервера (dev stub).

---

## Переменные окружения (`.env`)

| Переменная | Обязательна | Описание |
|-----------|------------|---------|
| `DATABASE_URL` | Да | PostgreSQL строка подключения |
| `JWT_SECRET` | Да | Секрет для подписи токенов (мин. 32 символа) |
| `JWT_EXPIRES_IN` | Нет | Срок токена (по умолчанию `7d`) |
| `REQUIRE_EMAIL_VERIFICATION` | Нет | `true`/`false` (по умолчанию `false`) |
| `GOOGLE_CLIENT_ID` | Нет | Для Google OAuth |
| `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` | Нет | Для реальной отправки писем |
| `APP_URL` | Нет | URL сервера (для ссылок в письмах) |

---

## Безопасность

- Пароли хранятся только как bcrypt хэш (cost factor 12)
- Токены верификации email — только SHA-256 хэш в БД, сам токен только в письме
- JWT токены проверяются на каждом защищённом маршруте
- Google токены проверяются на серверах Google (не доверяем фронтенду)
- Ответы никогда не содержат `passwordHash` или токены верификации
- Zod валидирует все входящие данные на границе системы

---

## Тесты

```powershell
npm test
```

Тесты запускаются **без реальной базы данных** — Prisma замокан.

| Файл | Что тестирует |
|------|-------------|
| `auth.test.ts` | Регистрация, дубли email, вход, Google OAuth |
| `profile.test.ts` | Создание профиля, ограничения, PATCH |
| `dietary-restriction.test.ts` | Фильтрация по всем 10 типам + кастомные |

**Итого: 36 тестов, все проходят.**

---

## Что будет дальше (следующие Epics)

- **Epic 2** — рекомендации рецептов (сервис фильтрации уже готов, нужно только подключить)
- **Epic 3+** — настроение, энергия, AI-рекомендации
- Refresh токены
- Rate limiting
- Telegram OAuth
- Сброс пароля

---

*Backend разработан: 30 мая 2026*  
*Автор сессии: Claude Sonnet 4.6*
