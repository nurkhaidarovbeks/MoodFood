# MoodFood Backend — Лог сессии разработки

> Дата: 30 мая 2026  
> Задача: Реализовать Epic 1 — Регистрация и профиль пользователя (только backend)

---

## Контекст задачи

Проект MoodFood — AI-приложение для питания. На момент начала сессии папка `Backend/` была **полностью пустой** — ни одного файла. Всё было написано с нуля.

Задача включала:
- Email/password регистрацию и вход
- Google OAuth (проверка токена на сервере)
- Email верификацию (с конфигурируемым MVP-режимом)
- Профиль питания (создание, полное обновление, частичное обновление)
- Диетические ограничения и аллергии (10 типов + кастомные)
- Центральную фильтрацию рецептов — запрещённые рецепты никогда не попадают в ответ
- Тесты для всей логики

---

## Принятые архитектурные решения

| Решение | Обоснование |
|---------|------------|
| **Node.js + TypeScript + Express** | Нет существующего кода — выбран наиболее распространённый продакшен-стек |
| **Prisma + PostgreSQL** | Соответствует описанию сущностей в задаче; хорошая поддержка миграций |
| **JWT (stateless)** | Без refresh токенов для MVP — упрощает старт |
| **bcrypt, cost=12** | Стандарт для хэширования паролей |
| **Dependency Injection для сервисов** | `AuthService(prisma)`, `ProfileService(prisma)` — позволяет легко мокать в тестах |
| **jest-mock-extended + moduleNameMapper** | Тесты без реальной БД — `*/config/database` маппится на мок автоматически |
| **SHA-256 для токенов верификации** | Сырой токен — только в письме, в БД только хэш |
| **Центральный DietaryRestrictionService** | Одно место фильтрации, все будущие endpoint'ы обязаны через него проходить |
| **Email stub в dev** | Если SMTP не настроен — письма выводятся в консоль |

---

## Все созданные файлы

### Конфигурация проекта
| Файл | Описание |
|------|---------|
| `package.json` | Зависимости и npm скрипты |
| `tsconfig.json` | Настройки TypeScript компилятора |
| `jest.config.ts` | Конфигурация тестов с moduleNameMapper для мока БД |
| `.env.example` | Шаблон переменных окружения |
| `.env` | Реальные переменные для локальной разработки (создан в конце сессии) |
| `docker-compose.yml` | PostgreSQL через Docker одной командой |

### База данных
| Файл | Описание |
|------|---------|
| `prisma/schema.prisma` | Схема БД — модели User, UserProfile, Recipe, Ingredient, RecipeIngredient |

**Новые поля относительно исходной спецификации:**
- `users`: `isEmailVerified`, `googleId`, `emailVerificationToken` (SHA-256 хэш), `emailVerificationExpires`
- `user_profiles`: `customRestrictions` (JSON), `onboardingCompleted` (bool), `profileCompletedAt` (DateTime)

### Core — конфиг и утилиты
| Файл | Описание |
|------|---------|
| `src/config/env.ts` | Парсинг и валидация env переменных |
| `src/config/database.ts` | Singleton Prisma клиент |
| `src/utils/jwt.ts` | `signToken()`, `verifyToken()` |
| `src/utils/hash.ts` | `sha256()`, `generateToken()` |
| `src/utils/profile-completion.ts` | `isProfileComplete()` — логика "профиль заполнен?" |

### Сервисы
| Файл | Описание |
|------|---------|
| `src/services/email.service.ts` | Отправка писем через Nodemailer; dev stub если SMTP не настроен |
| `src/services/google-oauth.service.ts` | `verifyGoogleIdToken()` — проверка на серверах Google |
| `src/services/dietary-restriction.service.ts` | **Критический сервис.** `canUserSeeRecipe()`, `filterRecipesForUser()` |

### Middleware
| Файл | Описание |
|------|---------|
| `src/middleware/auth.ts` | `requireAuth` — проверяет JWT из заголовка Authorization |
| `src/middleware/validate.ts` | `validate(schema)` — Zod валидация тела запроса |
| `src/middleware/errorHandler.ts` | `AppError` класс + глобальный обработчик ошибок |

### Модуль Auth
| Файл | Описание |
|------|---------|
| `src/modules/auth/auth.schema.ts` | Zod схемы: `RegisterSchema`, `LoginSchema`, `GoogleAuthSchema` |
| `src/modules/auth/auth.service.ts` | Бизнес-логика: register, login, googleAuth, verifyEmail, resendVerification |
| `src/modules/auth/auth.controller.ts` | HTTP handlers — вызывают сервис, передают ошибки в next() |
| `src/modules/auth/auth.routes.ts` | Express роутер — wires up сервис, контроллер, middleware |

### Модуль Profile
| Файл | Описание |
|------|---------|
| `src/modules/profile/profile.schema.ts` | Zod схемы: `ProfileUpsertSchema`, `ProfilePatchSchema` |
| `src/modules/profile/profile.service.ts` | Бизнес-логика: getProfile, upsertProfile, patchProfile |
| `src/modules/profile/profile.controller.ts` | HTTP handlers |
| `src/modules/profile/profile.routes.ts` | Express роутер с `requireAuth` на всех маршрутах |

### Точка входа
| Файл | Описание |
|------|---------|
| `src/app.ts` | Express app — helmet, cors, роуты, 404 handler, errorHandler |
| `src/server.ts` | Запуск сервера, подключение к БД, graceful shutdown |

### Тесты
| Файл | Тесты |
|------|-------|
| `tests/env.setup.ts` | Устанавливает process.env до импорта модулей |
| `tests/__mocks__/database.ts` | Мок Prisma клиента через jest-mock-extended |
| `tests/auth.test.ts` | 12 тестов: регистрация, дубли, вход, Google OAuth, профиль после регистрации |
| `tests/profile.test.ts` | 8 тестов: создание профиля, ограничения, кастомные, PATCH, GET |
| `tests/dietary-restriction.test.ts` | 24 теста: все 10 типов ограничений, кастомные, регистр, edge cases |

### Документация и инструменты
| Файл | Описание |
|------|---------|
| `API_DOCS.md` | Техническая API документация (eng) |
| `GUIDE.md` | Полное руководство на русском |
| `SESSION_LOG.md` | Этот файл |
| `moodfood.postman_collection.json` | Готовая коллекция для Postman |

---

## Добавленные API endpoints

| Метод | Маршрут | Auth | Описание |
|-------|---------|------|---------|
| `POST` | `/api/v1/auth/register` | — | Регистрация email/password |
| `POST` | `/api/v1/auth/login` | — | Вход email/password |
| `POST` | `/api/v1/auth/google` | — | Вход/регистрация через Google |
| `GET` | `/api/v1/auth/verify-email?token=` | — | Подтверждение email |
| `POST` | `/api/v1/auth/resend-verification` | — | Переслать письмо верификации |
| `GET` | `/api/v1/profile` | JWT | Получить профиль |
| `PUT` | `/api/v1/profile` | JWT | Создать/заменить профиль |
| `PATCH` | `/api/v1/profile` | JWT | Частично обновить профиль |
| `GET` | `/health` | — | Healthcheck сервера |

---

## Результаты тестов

```
Tests: 36 passed, 36 total
Test Suites: 3 passed, 3 total
```

### Исправленные баги в ходе сессии

**Баг 1 — Двойная генерация токена верификации**  
В `auth.service.ts` метод `register` генерировал токен дважды — первый терялся.  
Исправлено: токен генерируется один раз, хэш передаётся в `user.create`, сырой токен отправляется в письмо.

**Баг 2 — JSDoc комментарий в `__mocks__/database.ts`**  
Строка `"*/config/database"` внутри блочного комментария `/** */` закрывала комментарий раньше времени. TypeScript парсил текст комментария как код.  
Исправлено: блочный комментарий заменён на строчные `//`.

**Баг 3 — Несовместимость типов Prisma enum**  
В `profile.service.ts` поля `lifestyle` и `budgetLevel` передавались как `string | null`, но Prisma ожидает `Lifestyle | null` и `BudgetLevel | null`.  
Исправлено: импорт `Lifestyle`, `BudgetLevel` из `@prisma/client` и явный каст.

---

## Ограничения сессии (намеренно не реализовано)

| Что | Почему |
|-----|--------|
| Фронтенд, UI, экраны | Вне скопа Epic 1 |
| Refresh токены | MVP — один долгоживущий токен |
| Rate limiting | Добавить `express-rate-limit` в следующей итерации |
| Telegram OAuth | Enum есть в схеме, endpoint не нужен пока |
| Сброс пароля | Отдельный feature |
| Recommendation engine | Epic 2+ — сервис фильтрации уже готов к подключению |
| Authorization code flow для Google | MVP использует ID token flow (для мобилок) |

---

## Как запустить прямо сейчас

```powershell
# Предусловие: запустить Docker Desktop

cd "c:\Users\0penf\Corporate project\Backend"

docker-compose up -d        # запустить PostgreSQL
npm run db:generate         # сгенерировать Prisma клиент
npm run db:migrate          # создать таблицы (ввести имя: "init")
npm run dev                 # запустить сервер на :3000

# В Postman: импортировать moodfood.postman_collection.json
```

---

*Сессия завершена: 30 мая 2026*  
*Модель: Claude Sonnet 4.6*
