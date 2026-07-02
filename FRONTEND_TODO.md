# MoodFood — Frontend TODO (Flutter)

> Файл для команды фронтенда. Все API эндпоинты уже реализованы и задеплоены на Render.
> Base URL: `https://moodfood-backend.onrender.com/api/v1`
> Актуально на: 2 июля 2026

> **СТАТУС (2 июля 2026):** большинство задач ниже **выполнено** — фронт закрыл
> Epic 4 (рекомендации + Vision), Epic 5 (рецепты + избранное), Epic 6 (вода +
> напоминания) и Epic 7 (инсайты). См. `Mobile/SESSION_LOG.md` (сессия 11).
>
> **Реально осталось на фронте:**
> - **Apple Sign In** — подключить `POST /auth/apple` (бэкенд готов)
> - **Сброс пароля** — экран + `POST /auth/forgot-password` → `POST /auth/reset-password` (бэкенд готов)
> - Тёмная тема, смена языка (низкий приоритет)
>
> Раздел ниже — исходный бэклог задач Epic 4/5 (историческая справка).

---

## Epic 1 — Авторизация и профиль

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 1.1 | **Apple Sign In** — активировать вместо заглушки | Низкий | Нужен entitlement `Sign In with Apple` в Xcode. Эндпоинт `POST /auth/apple` готов |

---

## Epic 2 — Mood Check

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 2.1 | **Tracker — реальный график настроения** — подключить к бэкенду | Высокий | `GET /mood-checks?limit=7` → строить график по `energyLevel` / `mood`. Сейчас моки |

---

## Epic 3 — Кладовка (Pantry)

Бэкенд готов. Нужно убедиться что все операции реально вызывают API:

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 3.1 | **Удаление отдельного ингредиента из UI** — проверить что `DELETE /pantry/:id` вызывается | Средний | В ingredients_screen кнопка удаления есть — убедиться что она использует `pantryIngredientId`, а не `ingredientId` |

---

## Epic 4 — AI Рекомендации

### 4a. Существующий экран рекомендаций

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 4.1 | **Показывать `healthScore`** на карточке рекомендации | Высокий | API теперь возвращает `healthScore` (0–100) в каждом option. Добавить бейдж рядом с `fitScore` |

### 4b. AI Photo Recognition (новая фича — бэкенд готов)

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 4.2 | **Кнопка камеры/галереи → извлечение ингредиентов** | Высокий | Кнопки Camera/Gallery уже есть в AI Chat. Вместо заглушки: конвертировать фото в base64 → `POST /vision/ingredients` |
| 4.3 | **Экран подтверждения ингредиентов** | Высокий | После распознавания показать список `confident` ингредиентов с возможностью добавить/убрать. Поле `raw` — оригинальный текст с фото, `name` — нормализованное имя |
| 4.4 | **Блюда из фото** — вызов `POST /vision/recommendations` | Высокий | После подтверждения → отправить те же поля что и обычные рекомендации + `imageBase64`. Ответ: `{ vision, recommendation }` — показать recommendation.options |
| 4.5 | **Предупреждения `detectedSource` и `lowConfidence`** | Средний | Если `nonFoodDetected=true` → «Попробуй сфоткать чётче». Если `lowConfidence` не пустой → «Не уверен насчёт: [список]» с возможностью подтвердить |

Тело запроса `POST /vision/ingredients`:
```json
{
  "imageBase64": "<base64 без префикса data:>",
  "mimeType": "image/jpeg",
  "minConfidence": 0.4
}
```

> HEIC (iPhone по умолчанию) нужно конвертировать в JPEG на устройстве перед отправкой.

---

## Epic 5 — Рецепты и избранное

### 5a. Карточка рецепта (RecipesScreen grid card)

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 5.1 | **Показывать `estimatedCost`** на карточке | Высокий | Формат: `~ $2.50`. Поле `recipe.estimatedCost` (Float) уже приходит в API |

### 5b. Детальный лист рецепта (`_RecipeDetailSheet`)

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 5.2 | **Macro-box** — `🔥 420 kcal \| P: 25g \| F: 12g \| C: 40g` | Высокий | Поля: `calories`, `proteinG`, `fatG`, `carbsG`. Показать под названием рецепта |
| 5.3 | **`estimatedCost` в деталях** | Высокий | `~ $2.50 / serving` рядом со временем готовки |
| 5.4 | **Difficulty badge** | Средний | Поле `difficulty` (easy/medium/hard) уже есть в модели. Сейчас показывается только на карточке, но не в деталях |
| 5.5 | **Реальное фото** в детальном листе | Средний | Сейчас захардкожен эмодзи 🥑. Использовать ту же логику `_photoUrl` что на карточке |
| 5.6 | **Реальное описание** рецепта | Средний | Сейчас статичный текст `"A nutritious and delicious meal..."`. Можно взять из поля `steps` (первые 2 предложения) или из AI-объяснения |

### 5c. Избранное (Favorites) — бэкенд полностью готов

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| 5.7 | **`FavoritesService`** | Высокий | `add(recipeId)` → `POST /favorites`, `remove(favoriteId)` → `DELETE /favorites/:id`, `list()` → `GET /favorites`, `check(recipeId)` → `GET /favorites/check/:recipeId` |
| 5.8 | **`FavoritesProvider`** | Высокий | State: `List<FavoriteItem>`, `Set<String> favoriteRecipeIds`. Методы: `load()`, `toggle(recipeId)`, `isFavorite(recipeId)` |
| 5.9 | **Синхронизация сердечка** с бэкендом | Высокий | Сейчас `_toggleSave()` сохраняет только в `SharedPreferences`. Заменить на `FavoritesProvider.toggle(recipeId)`. Оптимистичный UI: менять иконку сразу, откатить при ошибке |
| 5.10 | **Экран Favorites** | Высокий | Список сохранённых рецептов из бэкенда. При нажатии → открывает `_RecipeDetailSheet`. Константы уже добавлены: `ApiConstants.favorites` |
| 5.11 | **Empty state** на экране Favorites | Средний | «Ты ещё не сохранил рецепты» + кнопка перейти в Recipes |
| 5.12 | **Инициализация heart-состояния** при загрузке | Средний | При открытии карточки вызвать `GET /favorites/check/:recipeId` → заполнить `_isSaved`. Или загрузить все favoriteIds разом при старте |

Формат ответа `GET /favorites`:
```json
{
  "favorites": [
    { "favoriteId": "...", "savedAt": "...", "recipe": { ...полный рецепт... } }
  ],
  "total": 3, "limit": 20, "offset": 0
}
```

Формат ответа `GET /favorites/check/:recipeId`:
```json
{ "isFavorite": true, "favoriteId": "uuid" }
```

---

## Общее

| # | Задача | Приоритет | Заметки |
|---|--------|-----------|---------|
| G.1 | **Push-уведомления** — подключить реальный push | Низкий | ✅ Бэкенд готов: `POST /notifications/devices` (регистрация токена), `GET /notifications/due` (polling), prefs. Осталось FE: FCM-токен устройства → отправить на бэкенд; либо `flutter_local_notifications` по данным `/due` |
| G.2 | **Тёмная тема** — реально переключать `ThemeMode` | Низкий | Тоггл в Settings есть, но `ThemeMode` не меняется |
| G.3 | **Смена языка** | Низкий | Сейчас диалог «Coming soon» |

---

## API — краткая шпаргалка (новые эндпоинты)

```
# Избранное
GET    /favorites                        → список (пагинация)
POST   /favorites  { recipeId }          → добавить (201 / 409 если уже есть)
DELETE /favorites/:favoriteId            → удалить
GET    /favorites/check/:recipeId        → { isFavorite, favoriteId }

# AI-фото
POST   /vision/ingredients  { imageBase64, mimeType, minConfidence }
           → { detectedSource, confident[], lowConfidence[], warnings }
POST   /vision/recommendations  { imageBase64, mimeType, minConfidence, mood?, energyLevel?, ... }
           → { vision: {...}, recommendation: { options[], aiPowered } }

# Рекомендации (обновлены)
POST   /recommendations  { mood, energyLevel, ... }
           → { options: [{ category, fitScore, healthScore, recipe, explanation }] }
```

---

## Порядок реализации (рекомендуемый)

```
1. Epic 5: FavoritesService + FavoritesProvider + синхронизация сердечка    ← самое важное
2. Epic 5: Macro-box + cost в детальном листе рецепта
3. Epic 4: healthScore badge на карточке рекомендации
4. Epic 4: Photo flow (camera → /vision/ingredients → confirm → /vision/recommendations)
5. Epic 5: Экран Favorites + empty state
6. Epic 2: Tracker — реальный график (GET /mood-checks)
7. Epic 5: Реальное фото/описание в деталях, difficulty badge
8. Низкий приоритет: push-уведомления, тёмная тема, Apple Sign In
```
