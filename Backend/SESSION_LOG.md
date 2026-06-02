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
| `docker-compose.yml` | PostgreSQL на порту **5434** |

### База данных
| Файл | Описание |
|------|---------|
| `prisma/schema.prisma` | Схема: User, UserProfile, Recipe, Ingredient, RecipeIngredient |
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
| `GET` | `/health` | — | Статус сервера |

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
npm test                                          # 55 тестов

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

## Следующий шаг — Epic 2: рецепты

`DietaryRestrictionService` уже написан и протестирован. Нужно:
1. CRUD для рецептов (`POST/GET/PUT/DELETE /api/v1/recipes`)
2. Эндпоинт рекомендаций (`GET /api/v1/recipes/recommendations`) — применяет `filterRecipesForUser()`
3. Seed-данные с тестовыми рецептами

---

*Сессия 1: 30 мая 2026 — Epic 1 (36 тестов)*  
*Сессия 2: 2 июня 2026 — Apple/OTP/SQL/Git (55 тестов)*  
*Модель: Claude Sonnet 4.6*
