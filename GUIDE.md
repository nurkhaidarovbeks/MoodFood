# MoodFood — Руководство для команды

> Последнее обновление: 2 июня 2026  
> Репозиторий: https://github.com/nurkhaidarovbeks/MoodFood

---

## Что такое MoodFood

AI-приложение для рекомендаций еды на основе настроения, бюджета, аллергий и диетических ограничений пользователя.

```
Flutter (Mobile)
      ↓  HTTP запросы (JSON)
  Backend API (Node.js + Express)
      ↓  SQL
  PostgreSQL (база данных)
```

---

## Структура репозитория

```
MoodFood/                    ← корень репозитория
├── Backend/                 ← серверная часть (готова)
│   ├── src/                 ← исходный код
│   ├── prisma/              ← схема и миграции БД
│   ├── tests/               ← автотесты (55 тестов)
│   ├── .env.example         ← шаблон переменных окружения
│   └── GUIDE.md             ← документация по бэкенду
├── Mobile/                  ← Flutter приложение (в разработке)
├── .gitignore
└── GUIDE.md                 ← этот файл
```

---

## Git — правила для команды

### Ветки

```
main              ← стабильный код (никто не пушит напрямую)
  ├── feature/epic-2-recipes
  ├── feature/flutter-auth
  └── fix/название-бага
```

**Правило одно: в `main` только через Pull Request.**

### Как работать с веткой

```bash
# 1. Перед началом работы — обновить main
git checkout main
git pull origin main

# 2. Создать ветку для своей задачи
git checkout -b feature/название-задачи

# 3. Работаешь, сохраняешь изменения
git add .
git commit -m "feat: описание что сделал"

# 4. Пушишь свою ветку (не main!)
git push origin feature/название-задачи

# 5. На GitHub открываешь Pull Request:
#    feature/название-задачи → main
#    Описываешь что сделал → Create Pull Request
```

### Как принять Pull Request

1. Открой Pull Request на GitHub
2. Посмотри на изменения во вкладке **Files changed**
3. Если всё ок — нажми **Merge pull request**
4. Удали ветку после мёрджа

### Формат коммитов

```
feat: новая функциональность
fix: исправление бага
refactor: рефакторинг без изменения логики
docs: изменения в документации
test: добавление/изменение тестов
```

Примеры:
```
feat: add recipe recommendations endpoint
fix: otp cooldown not resetting after verify
docs: update API endpoints in GUIDE
```

### Чего нельзя делать

- ❌ `git push origin main` — нельзя пушить прямо в main
- ❌ Коммитить `.env` файл — там секреты
- ❌ Коммитить папку `node_modules/`
- ❌ Делать `git push --force` на main

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

# 2. Создать .env файл
copy .env.example .env
# Открыть .env и заполнить переменные (см. секцию ниже)

# 3. Запустить PostgreSQL через Docker
docker-compose up -d

# 4. Применить миграции БД
npx prisma migrate dev

# 5. Запустить сервер
npm run dev
```

Сервер доступен на `http://localhost:3000`

### Переменные окружения (.env)

Скопируй `.env.example` → `.env` и заполни:

| Переменная | Обязательна | Описание |
|-----------|------------|---------|
| `DATABASE_URL` | ✅ | `postgresql://moodfood:moodfood_dev@localhost:5434/moodfood?schema=public` |
| `JWT_SECRET` | ✅ | Любая строка 32+ символов |
| `GOOGLE_CLIENT_ID` | Нет | Для Google OAuth |
| `APPLE_CLIENT_ID` | Нет | Bundle ID приложения для Apple Sign In |
| `SMTP_HOST` | Нет | Если пусто — письма выводятся в консоль |

### Команды

```powershell
npm run dev          # запуск в режиме разработки
npm test             # запустить все тесты (55 штук)
npm run build        # сборка для продакшена
npx prisma studio    # визуальный просмотр базы данных
docker-compose up -d # запустить PostgreSQL
```

---

## API — все эндпоинты

Базовый URL: `http://localhost:3000/api/v1`

Защищённые маршруты требуют заголовок:
```
Authorization: Bearer <jwt-токен>
```

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
| `GET` | `/profile` | ✅ JWT | Получить профиль пользователя |
| `PUT` | `/profile` | ✅ JWT | Создать / полностью заменить профиль |
| `PATCH` | `/profile` | ✅ JWT | Частично обновить профиль |

### Системные

| Метод | Путь | Auth | Описание |
|-------|------|------|---------|
| `GET` | `/health` | — | Проверка работы сервера |

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

### OTP вход
```json
// Шаг 1 — запросить код
POST /api/v1/auth/otp/send
{ "email": "user@example.com" }

// Шаг 2 — войти по коду (действует 5 минут)
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

---

## Диетические ограничения — ключи

| Ключ | Что исключает |
|------|-------------|
| `vegan` | Мясо, рыба, молочка, яйца, мёд |
| `vegetarian` | Мясо, рыба |
| `pescatarian` | Только мясо (рыба разрешена) |
| `lactose_free` | Молочные продукты |
| `gluten_free` | Пшеница, мука, хлеб, паста |
| `halal` | Свинина, алкоголь |
| `kosher` | Свинина, моллюски |
| `nut_allergy` | Все орехи, арахис |
| `egg_allergy` | Яйца, майонез |
| `soy_allergy` | Соя, тофу, мисо |

Кастомные ограничения — любой текст в `customRestrictions`, совпадение по названию ингредиента без учёта регистра.

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
| `OTP_MAX_ATTEMPTS` | 429 | Превышено кол-во попыток OTP |
| `OTP_RATE_LIMITED` | 429 | Подождите перед повторной отправкой |
| `UNAUTHORIZED` | 401 | JWT токен отсутствует или недействителен |
| `NOT_FOUND` | 404 | Маршрут не найден |

---

## Flutter — подключение к API

```dart
// В разработке (бэкенд на твоей машине)
const baseUrl = 'http://localhost:3000/api/v1';

// Пример запроса с токеном
final response = await dio.get(
  '$baseUrl/profile',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
```

> **Важно:** На Android-эмуляторе `localhost` указывает на сам эмулятор, а не на твою машину. Используй `10.0.2.2` вместо `localhost`:
> ```dart
> const baseUrl = 'http://10.0.2.2:3000/api/v1';
> ```

---

## Тесты

```powershell
cd Backend
npm test
```

55 тестов, запускаются без базы данных, занимают ~4 секунды.

| Файл | Что тестирует |
|------|-------------|
| `auth.test.ts` | Регистрация, вход, Google/Apple OAuth, OTP |
| `profile.test.ts` | Создание профиля, PATCH, GET |
| `dietary-restriction.test.ts` | Фильтрация по всем 10 типам ограничений |

---

## База данных

Посмотреть таблицы визуально:
```powershell
cd Backend
npx prisma studio
# Открывает http://localhost:5555
```

Или через pgAdmin:
- Host: `localhost`, Port: `5434`
- Database: `moodfood`, User: `moodfood`, Password: `moodfood_dev`

---

## Безопасность — что уже сделано

- Пароли хранятся только как bcrypt хэш (cost 12)
- OTP хранится только как SHA-256 хэш, сам код нигде не сохраняется
- Google и Apple токены верифицируются на серверах Google/Apple
- JWT проверяется на каждом защищённом маршруте
- Zod валидирует все входящие данные
- Prisma ORM — параметризованные запросы, SQL injection невозможен
- Rate limiting на OTP: 3 запроса/15 мин на отправку, 10 попыток/5 мин на проверку

---

*Backend разработан: май–июнь 2026*
