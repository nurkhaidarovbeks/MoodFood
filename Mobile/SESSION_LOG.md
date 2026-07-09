# MoodFood Mobile — Лог сессий разработки

> Репозиторий: https://github.com/nurkhaidarovbeks/MoodFood  
> Рабочая директория: `c:\Users\0penf\Corporate project\Mobile`  
> Модель: Claude Sonnet 4.6

---

## Как использовать этот файл

Этот файл — быстрый контекст для Claude. Если начинаешь новую сессию, дай Claude этот файл и скажи: *«Прочитай SESSION_LOG.md и продолжим работу»*. Он поймёт всё что было сделано и сможет продолжить без повторных объяснений.

---

## Проект

MoodFood — AI-приложение для рекомендаций еды на основе настроения, бюджета, аллергий и диетических ограничений пользователя. Мобильный клиент написан на Flutter.

**Стек:** Flutter + Dart + Dio (HTTP) + Provider (state) + FlutterSecureStorage + SharedPreferences

**Bundle ID:** `com.banb.moodfood`

---

## Архитектурные решения

| Решение | Обоснование |
|---------|------------|
| **Provider для state** | Простой и достаточный для MVP |
| **Dio + JWT интерцептор** | Автоматически добавляет `Authorization: Bearer` к запросам |
| **FlutterSecureStorage (mobile) / SharedPreferences (web)** | `kIsWeb` conditional — один `TokenStorage` для всех платформ |
| **google_sign_in удалён** | Грузил Google CDN при старте и вешал белый экран на web |
| **Bundle ID `com.banb.moodfood`** | `com.moodfood.app` уже был занят в Apple Developer |

---

## Структура приложения

```
Mobile/lib/
├── core/
│   ├── api/          ← Dio HTTP клиент, JWT интерцептор
│   ├── constants/    ← API URLs
│   ├── models/       ← User, Profile, MoodEntry
│   ├── providers/    ← AuthProvider, ProfileProvider, MoodProvider
│   ├── services/     ← AuthService, ProfileService
│   ├── storage/      ← TokenStorage (SecureStorage / SharedPreferences)
│   └── theme/        ← AppTheme с дизайн-токенами
├── features/
│   ├── auth/         ← Login, Register, OTP, Welcome, Splash
│   │   └── widgets/
│   │       └── auth_shared.dart  ← общие компоненты auth экранов
│   ├── home/         ← Home (3 таба)
│   ├── mood/         ← MoodCheck, MoodHistory
│   └── onboarding/   ← ProfileSetup (4 шага)
└── router/           ← AppRouter
```

---

## Дизайн-токены (Figma)

| Токен | Цвет |
|-------|------|
| Primary | `#7CB342` |
| Background | `#FAF9F7` |
| Text Dark | `#2D3436` |
| Text Secondary | `#717182` |

---

## Подключение к бэкенду

```dart
// Бэкенд запущен локально
const baseUrl = 'http://localhost:3000/api/v1';

// На Android-эмуляторе localhost указывает на сам эмулятор!
// Используй IP машины вместо localhost:
const baseUrl = 'http://10.0.2.2:3000/api/v1';
```

> Для полноценной интеграции нужен задеплоенный бэкенд (VPS). Пока бэкенд только локальный — фронт работает с заглушками.

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

---

## Запуск приложения

### На iPhone

```bash
# Подключить iPhone по USB, включить Developer Mode
# Настройки → Конфиденциальность и безопасность → Режим разработчика

cd Mobile
/Users/azharakhamitbek/flutter/bin/flutter run --release

# При первом запуске на iPhone:
# Настройки → Основные → VPN и управление устройством → Доверять
```

### В Chrome (без телефона)

```bash
cd Mobile
flutter run -d chrome
# Первый запуск: 3-5 минут (компиляция Dart → JS)
# После: 'r' — hot reload, 'R' — hot restart
```

### Требования

- Flutter 3.41.3+
- Xcode 26.5+ (для iOS)
- CocoaPods 1.16.2+
- iPhone с включённым Developer Mode

---

## Сессия 5 Mobile — 13 июня 2026 (Google Sign In)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6

### Google Sign In — реализован

**`pubspec.yaml`** — добавлен пакет:
```yaml
google_sign_in: ^6.2.2
```

**`ios/Runner/Info.plist`** — добавлены обязательные ключи для iOS:
```xml
<key>GIDClientID</key>
<string>189389207039-8bht9m53kvpqi00hqjfm5k1ov2vujt3h.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.189389207039-8bht9m53kvpqi00hqjfm5k1ov2vujt3h</string>
    </array>
  </dict>
</array>
```

**`lib/features/auth/widgets/auth_shared.dart`** — `_GoogleSignInBtn` переписан в `StatefulWidget`:
- `GoogleSignIn(scopes: ['email', 'profile'], serverClientId: '...')` — `serverClientId` обязателен, иначе `idToken` будет `null` на Android
- Получает `idToken` → отправляет на `POST /auth/google` через `AuthProvider.googleSignIn(idToken)`
- Показывает `CircularProgressIndicator` во время загрузки
- Обрабатывает ошибки через `SnackBar`

**`lib/core/services/auth_service.dart`** — добавлен метод:
```dart
Future<AuthResult> googleSignIn(String idToken) async { ... }
```

**`lib/core/providers/auth_provider.dart`** — добавлен метод:
```dart
Future<bool> googleSignIn(String idToken) => _run(() => _service.googleSignIn(idToken));
```

**Apple Sign In** — оставлен мёртвой заглушкой (`_SocialBtn`): нажатие показывает SnackBar "Apple sign-in coming soon". Для активации нужен entitlement Sign In with Apple в Xcode.

### Бэкенд подключён к продакшну

URL переключён на Render:
```dart
static const String baseUrl = 'https://moodfood-backend.onrender.com/api/v1';
```

---

## Сессия 6 Mobile — 19 июня 2026 (Полный редизайн UI по Figma)

> Автор: Azhara Khamitbek | Модель: Claude Sonnet 4.6  
> Ветка: `feature/flutter-frontend-epic1`  
> Коммит: `d5a7f05`

### Что сделано

#### Навигация — 5-табовый IndexedStack
Главный экран полностью переработан. Теперь 5 табов в `BottomNavigationBar` (Material 2, не NavigationBar):
- **Home** — сводка, быстрый mood check, карточки рецептов
- **Recipes** — чипы-фильтры + 2-колоночная сетка
- **AI Chat** — чат с ИИ, кнопки Camera/Gallery
- **Tracker** — график настроения на `CustomPainter`
- **Profile** — информация профиля, кнопки настроек

Все табы в `IndexedStack` — переход между ними не сбрасывает состояние.

#### Экраны — полный редизайн

| Экран | Файл | Что изменено |
|-------|------|-------------|
| Home | `home/screens/home_screen.dart` | 5-табовая навигация, `onSwitchTab` callback, все кнопки кликабельны |
| Onboarding | `onboarding/screens/onboarding_screen.dart` | Светлая тема по Figma, 4 слайда, skip, кликабельные точки-индикаторы |
| Recipes | `recipes/screens/recipes_screen.dart` | Чипы фильтры (Quick Meals, Budget, Energy Boost, High Protein), 2-кол сетка с эмодзи, `DraggableScrollableSheet` |
| Ingredients | `ingredients/screens/ingredients_screen.dart` | "What's in Your Fridge?", 4-кол сетка 24 ингредиента, match-count сортировка |
| Mood Check | `mood/screens/mood_check_screen.dart` | Слайдеры + 6 настроений + кнопка "Get AI Recommendations" |
| Profile Setup | `onboarding/screens/profile_setup_screen.dart` | 3-шаговый визард (Goals / Diet / Allergies) |
| Recommendations | `recommendations/screens/recommendations_screen.dart` | **НОВЫЙ FILE** — карточки по категориям |
| Notifications | `notifications/screens/notifications_screen.dart` | **НОВЫЙ FILE** — swipe-to-delete, счётчик непрочитанных, "Mark all read" |
| Settings | `settings/screens/settings_screen.dart` | Все 5 пустых `onTap: () {}` заменены реальными хендлерами |
| Premium | `premium/screens/premium_screen.dart` | Оранжевая тема, карточки Free vs Premium, Payment Sheet оверлей |

#### Роутер
`router/app_router.dart` — добавлен маршрут `/notifications`.

#### Провайдеры / сервисы
- `RecipeProvider` — добавлен режим demo (6 mock-рецептов), `loadMockData()`, `_isDemoMode` флаг
- `RecipeService` — подключён к `/recipes` эндпоинту бэкенда
- `IngredientsProvider` — `load()` + `toggle()` + `clear()`

### Исправленные ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `type '_Map<String, dynamic>' is not a subtype of type 'String?'` | Бэкенд возвращает `{ error: { message, code } }` вложенным объектом, а фронт делал `data['error'] as String?` | `api_client.dart`: проверка `if (errorObj is Map<String, dynamic>)` с извлечением вложенных полей |
| `Expected ':'` в `ingredients_screen.dart:74` | Каскадный оператор `..sort()` внутри тернарного выражения — парсер Dart не разбирает | Выделен `if/else` с локальной переменной `matchedRecipes` |
| `TextDirection.ltr` undefined в `home_screen.dart` (CustomPainter) | Конфликт имён с `dart:ui` | `import 'dart:ui' as ui` + `ui.TextDirection.ltr` |
| `use_build_context_synchronously` warning в `settings_screen.dart` | `Navigator...` вызывался с `context` после `await logout()` | Сохранён `navigator = Navigator.of(context)` до await |
| `0xe8008014` (invalid signature) при установке | Кэш старой `--no-codesign` сборки | `flutter clean` + полная пересборка |
| Onboarding не показывался | `onboarding_done = true` в SharedPreferences от предыдущего запуска | `auth_provider.logout()` теперь удаляет ключ `onboarding_done` |
| Кнопки Camera/Gallery в AI Chat не работали | `onPressed: () {}` — пустой хендлер | Теперь отправляют AI-сообщение `'Analyze this photo of my food'` |
| Кнопка "See all >" на Home ничего не делала | `onTap: () {}` — нет доступа к `setState` из дочернего виджета | `onSwitchTab` callback пробрасывается через конструктор `_HomeTab` |

### Состояние на конец сессии

- `flutter analyze` — **0 errors, 0 warnings** (только `info`-подсказки про `const`)
- Все экраны реализованы и кликабельны
- Бэкенд подключён: `https://moodfood-backend.onrender.com/api/v1`
- Demo-режим: mock-данные загружаются, все кнопки работают
- Коммит запушен в `feature/flutter-frontend-epic1`

### Что НЕ реализовано / остаётся

| Что | Приоритет | Детали |
|-----|-----------|--------|
| Apple Sign In | Низкий | Нужен entitlement Sign In with Apple в Xcode |
| Реальная оплата Premium | Средний | Сейчас UI-заглушка с Payment Sheet |
| Тёмная тема | Низкий | Тоггл в Settings есть, но реальный ThemeMode не меняется |
| Смена языка | Низкий | Диалог "Coming soon", только английский |
| Экран профиля (редактирование) | Средний | Profile Info → `/profile-setup`, нет отдельного edit-экрана |
| Push-уведомления | Средний | Экран Notifications есть, но реальный push не подключён |
| Tracker реальные данные | Высокий | Сейчас mock-данные в графике настроения |
| Сохранённые рецепты | Средний | Epic 4 |

---

## Сессия 9 Mobile — 25 июня 2026 (Epic 5 constants + Postman fix)

> Автор: Nurkhaidarov Beksultan | Модель: Claude Sonnet 4.6

### Что сделано

**`lib/core/constants/api_constants.dart`** — добавлены эндпоинты Favorites (Epic 5):
```dart
static const String favorites = '/favorites';
static const String favoritesCheck = '/favorites/check';
```

Теперь фронт может использовать:
- `GET ${ApiConstants.favorites}` — список избранного
- `POST ${ApiConstants.favorites}` — добавить рецепт
- `DELETE ${ApiConstants.favorites}/$favoriteId` — удалить
- `GET ${ApiConstants.favoritesCheck}/$recipeId` — проверить статус

---

## Сессия 10 Mobile — 26 июня 2026 (Epic 5 Frontend)

> Автор: Azhara Khamitbek | Модель: Claude Sonnet 4.6  
> Ветка: `feature/flutter-frontend-epic1`  
> Коммиты: `7c15421`, `1b63b92`

### Что сделано

#### Favorites — полная реализация

**`lib/core/services/favorites_service.dart`** — новый файл:
- `FavoriteItem` модель: `favoriteId`, `recipe`, `createdAt`
- `getFavorites()` → `GET /favorites`
- `addFavorite(recipeId)` → `POST /favorites { recipeId }` → возвращает `favoriteId`
- `removeFavorite(favoriteId)` → `DELETE /favorites/:id`
- `checkFavorite(recipeId)` → `GET /favorites/check/:recipeId`

**`lib/core/providers/favorites_provider.dart`** — новый файл:
- `Map<String, String> _favoriteIds` — `recipeId → favoriteId` для O(1) lookup
- `isFavorite(recipeId)` — мгновенная проверка
- `toggle(recipeId)` — оптимистичное обновление (UI меняется мгновенно, API вызов идёт фоном)
- `load()` — загружает список с бэкенда

**`lib/features/favorites/screens/favorites_screen.dart`** — новый файл:
- `_FavoriteCard` — фото (Unsplash по ключевому слову), название, chips (время/калории/сложность), P/F/C macro badges
- Кнопка ♥ → `FavoritesProvider.toggle()` для удаления из избранного
- `RefreshIndicator` для pull-to-refresh
- Empty state с кнопкой "Browse Recipes" → `/home` tab 1

**`lib/main.dart`** — добавлен `ChangeNotifierProvider(create: (_) => FavoritesProvider())`

**`lib/router/app_router.dart`** — добавлен маршрут `/favorites`

**`lib/features/recipes/screens/recipes_screen.dart`** — обновлён:
- Кнопка ♥ на карточке рецепта теперь использует `FavoritesProvider.toggle()` вместо `SharedPreferences`
- `context.watch<FavoritesProvider>().isFavorite(id)` — сердечко синхронизировано с бэкендом

#### Recipe detail — macros + cost + difficulty

В `_RecipeDetailSheet`:
- Difficulty chip добавлен в мета-строку (рядом с временем и калориями)
- Новый ряд P/F/C macro badges (синий/оранжевый/зелёный) + стоимость `~$X` (фиолетовый)
- Данные берутся из модели `Recipe` (поля `fatG`, `carbsG`, `proteinG`, `estimatedCost` от бэкенда)

#### Vision AI — AI Chat подключён к бэкенду

**`lib/core/services/vision_service.dart`** — новый файл:
- `extractIngredients(XFile)` → `POST /vision/ingredients` → список названий ингредиентов
- `recommendFromPhoto({photo, moodEntry, maxCookingTime})` → `POST /vision/recommendations` → `RecommendationResult`
- Конвертация: `XFile` → `base64` + `mimeType` → JSON тело

**`lib/features/home/screens/home_screen.dart`** — `_pickImage()` обновлён:
- Показывает "🔍 Analyzing your photo with AI..." пока идёт запрос
- Вызывает `VisionService().recommendFromPhoto(photo, moodEntry: todayEntry)`
- При успехе → навигация на `/recommendations` с preloaded результатом
- При ошибке → fallback-сообщение

**`lib/features/recommendations/screens/recommendations_screen.dart`** — добавлен параметр `RecommendationResult? preloaded`:
- Если передан — не делает лишний API запрос, сразу показывает результат Vision AI
- Обратная совместимость сохранена (Mood → Recommendations работает как раньше)

#### Profile tab — Favorites интеграция

- "Recipes Saved" счётчик читает `FavoritesProvider.items.length` (вместо SharedPreferences)
- "View all" → `Navigator.pushNamed(context, '/favorites')`
- `_ProfileTab.initState()` → вызывает `FavoritesProvider.load()` при открытии таба

#### Исправления фото и графика

**Фото в recipe detail sheet:**
- Заменён хардкодный `🥑` emoji на `Image.network` с тем же URL что и в grid карточке
- `_RecipeDetailSheet` получает `photoUrl` параметр, высота изображения 220px

**Алгоритм подбора фото для карточек:**
- Ключевые слова теперь сортируются по длине (дольше = специфичнее) перед поиском
- "Banana Oat Smoothie" → `smoothie` (7 букв) > `banana` (6 букв) → фото смузи
- Расширена таблица `_photos` с более высоким качеством (w=600, q=80) и лучшими ссылками

**Mood & Energy Trends график:**
- `CustomPaint` без явного размера получал `width=0` → все точки кластеризовались у левого края
- Исправлено: `SizedBox.expand()` внутри + `width: double.infinity` на родительском `SizedBox`

### Файлы изменены

| Файл | Изменение |
|------|-----------|
| `lib/core/models/recipe_model.dart` | `fatG`, `carbsG` поля добавлены |
| `lib/core/services/favorites_service.dart` | **НОВЫЙ** |
| `lib/core/services/vision_service.dart` | **НОВЫЙ** |
| `lib/core/providers/favorites_provider.dart` | **НОВЫЙ** |
| `lib/features/favorites/screens/favorites_screen.dart` | **НОВЫЙ** |
| `lib/features/recipes/screens/recipes_screen.dart` | Favorites интеграция, detail фото, macros, лучшие фото |
| `lib/features/home/screens/home_screen.dart` | Vision AI, chart fix, Favorites count, "View all" |
| `lib/features/recommendations/screens/recommendations_screen.dart` | `preloaded` параметр |
| `lib/main.dart` | `FavoritesProvider` в MultiProvider |
| `lib/router/app_router.dart` | `/favorites` маршрут |

### Проблемы и решения

| Проблема | Решение |
|----------|---------|
| `latestEntry` не существует в `MoodProvider` | Заменён на `todayEntry` |
| `_isSaved` в `_RecipeGridCardState` конфликтовал с FavoritesProvider | Удалён local state, `isSaved` вычисляется из `context.watch<FavoritesProvider>()` |
| `CustomPaint` давал `width=0` без child | `SizedBox.expand()` + `width: double.infinity` на родителе |
| Detail sheet показывал 🥑 для всех рецептов | Передаётся `photoUrl` параметр из grid card в `_RecipeDetailSheet` |
| "Banana Oat Smoothie" показывало фото банана | Ключевые слова сортируются по убыванию длины перед проверкой |

---

## Сессия 11 Mobile — 2 июля 2026 (Дизайн + Epic 6/7 фронтенд + интеграция)

> Автор: Azhara Khamitbek | Модель: Claude Opus 4.8
> Ветка: `feature/flutter-design` (от свежего `main`, backend Epic 6/7 уже влит)

### Дизайн — доводка под макеты Figma

- **Шрифт Inter подключён.** Тема объявляла `fontFamily: 'Inter'`, но шрифт нигде не бандлился (нет .ttf, нет google_fonts) → падало на системный. Скачал 5 весов Inter (400/500/600/700/800) в `assets/fonts/`, объявил в `pubspec.yaml`. Теперь типографика как в Figma **на всех экранах**.
- **Onboarding** — кнопка Next/Get Started: стрелка → шеврон `›` (как в макете).
- **Auth (Login/Sign Up)** — лого: эмодзи 🥗 → иконка листа `Icons.eco` на зелёном квадрате. Google-кнопка: серая `g_mobiledata` → настоящий цветной логотип Google (`assets/images/google_logo.png`).
- **Вода** — упрощена до `+/−` (по требованию): убран отдельный навороченный экран трекера, оставлена простая карточка на Home.
- Profile Setup (Goals/Diet/Allergies), Mood Check — сверены с макетами, уже совпадают.

### Новые экраны/фичи

- **Wallet (кошелёк)** — новый экран `features/wallet/screens/wallet_screen.dart`: карточка баланса (градиент), quick actions, список транзакций. Маршрут `/wallet`, вход из Profile. Подключён к `GET /wallet` (баланс + транзакции, ₸), loading/empty/pull-to-refresh.
- **2 плана подписки** — Premium: переключатель Monthly/Annual (`_PlanToggle`), динамическая цена ($9.99/мес ↔ $79.99/год «Save 30%»), выбранный `planType` уходит в оплату. Цены совпадают с backend seed.

### Epic 6 — Water & Regular Eating (фронтенд)

- **`WaterService` + `WaterProvider`** → `/water` (today/log/delete). UI в стаканах (250мл), «+» = `POST /water {amountMl:250}`, «−» = удаление последнего лога. Прогресс/цель с сервера.
- Home + Tracker «Water» читают живые данные с бэка (было SharedPreferences).
- **`NotificationService`** → `/notifications` (preferences/history). Экран Notifications показывает реальные напоминания (water/meal), относительное время, loading + empty state.
- Settings → тоггл «Notifications» читает/пишет `/notifications/preferences` (water + meal reminders).

### Epic 7 — Habit Analytics (фронтенд)

- **`InsightsService` + `InsightsProvider`** → `/insights/weekly`.
- Новая карточка «This Week» на Tracker: check-in rate, avg energy, hydration adherence, доминирующее настроение + блок «Tips for you» (правила-советы с бэка).

### Интеграция фронт↔бэк (перед слиянием)

- **Все frontend API-вызовы сверены с backend-роутами** — пути и методы совпадают 100% (auth, profile, recipes, pantry, favorites, vision, recommendations, mood-checks, subscriptions, wallet, water, notifications, insights).
- Wallet переведён с заглушки на реальный `GET /wallet`.
- `dart analyze` — **0 ошибок, 0 warnings** (убрал лишний `!` в recommendation_service).
- Приложение собрано и запущено на Cherry🍒 (Xcode build ~30s, debug, hot reload активен).

### Файлы

| Файл | Изменение |
|------|-----------|
| `pubspec.yaml` + `assets/fonts/Inter-*.ttf` | **НОВЫЕ** — бандл Inter |
| `assets/images/google_logo.png` | **НОВЫЙ** |
| `lib/core/services/water_service.dart` | **НОВЫЙ** |
| `lib/core/services/notification_service.dart` | **НОВЫЙ** |
| `lib/core/services/insights_service.dart` | **НОВЫЙ** |
| `lib/core/services/wallet_service.dart` | **НОВЫЙ** |
| `lib/core/providers/water_provider.dart` | **НОВЫЙ** |
| `lib/core/providers/insights_provider.dart` | **НОВЫЙ** |
| `lib/features/wallet/screens/wallet_screen.dart` | **НОВЫЙ** |
| `lib/core/constants/api_constants.dart` | + water/notifications/insights эндпоинты |
| `lib/features/home/screens/home_screen.dart` | вода→WaterProvider, «This Week» insights + tips |
| `lib/features/notifications/screens/notifications_screen.dart` | реальные данные `/notifications/history` |
| `lib/features/settings/screens/settings_screen.dart` | тоггл → `/notifications/preferences` |
| `lib/features/premium/screens/premium_screen.dart` | Monthly/Annual переключатель |
| `lib/features/auth/widgets/auth_shared.dart` | лого-лист + Google-лого |
| `lib/features/onboarding/screens/onboarding_screen.dart` | шеврон |
| `lib/main.dart` | + WaterProvider, InsightsProvider |

### Проблемы и решения

| Проблема | Решение |
|----------|---------|
| Шрифт Inter не рендерился | Скачан и забандлен (assets/fonts + pubspec) |
| «sandbox not in sync with Podfile.lock» при запуске | `pod install` в `ios/` |
| Прямой пуш в main | Откатил — по GUIDE только через PR, ветка `feature/flutter-design` запушена |
| `CustomPaint` insights карточка | derived из провайдера, loading/empty состояния |

---

## Сессия 12 Mobile — 3 июля 2026 (Water таб + редизайн рецептов + account-флоу)

> Автор: Azhara Khamitbek | Модель: Claude Opus 4.8
> Ветка: `feature/flutter-water-tab` (от свежего `main` d28f128)
> Бэкенд не трогался — только чтение эндпоинтов.

### Water таб (Epic 6 — полный фронтенд)

- **`WaterService`** расширен: `history()`, `getGoal()`, `updateGoal()` (+ модели `WaterDay/WaterHistory/WaterGoal`) поверх today/log/delete.
- **`WaterProvider`** расширен: история, цель, настройки напоминаний, custom-amount, удаление конкретного лога.
- **`features/water/screens/water_tab.dart`** — НОВЫЙ полноценный экран:
  * прогресс-кольцо (CustomPaint): totalMl/goalMl, %, стаканы, «осталось X мл»
  * быстрое добавление: Glass 250 / Bottle 500 / Custom (ввод мл) + Undo last
  * недельный график по дням (зелёный = цель достигнута, синий = нет)
  * сегодняшние логи со свайп-удалением
  * редактор цели (пресеты 1.5–3 L)
  * напоминания: вкл/выкл, интервал (1–4ч), окно Wake/Sleep (custom schedule)
- **6-й таб «Water»** (капля) в BottomNav между Tracker и Profile. Индексы табов проверены — только index 1 (Recipes) используется в коде, регрессий нет.
- Тап по водной карточке на Home → открывает Water таб.

### Фото рецептов — единая система (все 167)

- **`core/utils/recipe_photo.dart`** — НОВЫЙ util. Бэкенд НЕ отдаёт фото рецепта, поэтому подбор на фронте по названию.
- **Приоритетный матчинг** (не просто длина ключа): белки/сигнатурные блюда раньше сайдов → «Chicken Vegetable Soup» = суп, не брокколи.
- **~45 фото**, каждое проверено `curl` на HTTP 200 → ни одной битой ссылки, ни одного emoji-заглушки.
- Убраны 3 дублирующие фото-мапы (grid card, favorites) → всё через util.

### Редизайн экрана деталей рецепта (по макетам)

- **`features/recipes/screens/recipe_detail_screen.dart`** — НОВЫЙ полноэкранный экран вместо bottom-sheet:
  * фото-герой + back/♥/share
  * 3 цветные info-карты: Time (синяя) · Difficulty (оранжевая) · Servings (фиолетовая)
  * Mood Benefit (фиолет.) + Energy Impact (персик.) — выводятся из moodTags/calories
  * Nutrition Facts — 4 градиентные карты (Calories/Protein/Carbs/Fat) из реальных macros
  * Ingredients (фиолетовые буллеты) + Instructions (пронумерованные кружки)
  * золотая кнопка 🍳 Start Cooking
- Старый `_RecipeDetailSheet` + хелперы (`_IconButton/_MetaItem/_CollapsibleSection/_MacroBadge`) удалены (~400 строк мёртвого кода).
- ♥ в шапке синхронизирован с `FavoritesProvider`.

### Forgot password (auth)

- `AuthService`: + `forgotPassword(email)`, `resetPassword(token, password)` → `/auth/forgot-password`, `/auth/reset-password`.
- **`ForgotPasswordScreen`** — 2 шага: email → письмо → вставить token из письма + новый пароль. Маршрут `/forgot-password`. Ссылка «Forgot password?» на логине ведёт сюда (было `/otp`).

### Settings → секция Support

- **Contact Us** (email/телефон/часы), **Help & Support** (FAQ) — диалоги.
- **Cancel Subscription** — виден если Premium, отменяет через `SubscriptionProvider.cancelPremium()` → `DELETE /subscriptions/me`, с подтверждением.

### Итог

- `dart analyze` — **0 ошибок, 0 warnings**.
- Собрано и запущено на Cherry🍒 (debug, hot reload).
- Backend не тронут (проверено `git status`).

---

## Сессия 13 Mobile — 3 июля 2026 (Все 168 рецептов, фото-пулы, premium/payment фиксы, интеграция дисплеев)

> Автор: Azhara Khamitbek | Модель: Claude Opus 4.8
> Ветка: `feature/flutter-water-tab` | Backend не трогался (только чтение эндпоинтов)

### Рецепты — показываются ВСЕ 168 (было 20)
- `RecipeService.getRecipes` теперь **пагинирует**: бэкенд ограничивает страницу 100 (`limit≤100`), поэтому тянем страницами (limit=100, offset+=100) пока не придёт короткая. Раньше был хардкод `limit=20` → «20 recipes found». Теперь весь каталог.

### Фото рецептов — пуленепробиваемо + без повторов
- **`core/widgets/recipe_image.dart`** — НОВЫЙ виджет `RecipeImage`: сетевое фото + плавная загрузка + **красивый градиент + эмодзи-еды fallback** (по названию), если фото битое/медленное. Больше нет уродской «вилки-тарелки».
- **`core/utils/recipe_photo.dart`** переписан на **пулы** (2-4 фото на категорию): рецепт выбирает фото из пула по своему id → рецепты с одним ключом («Black Bean Burrito/Soup/Bowl») получают **разные** фото, а не одно.
- Починены видимые по скринам косяки: нут ≠ зелёный смузи, авокадо-блюда = фото авокадо-тоста (не розовый фон), капуста = салат (не брокколи); порядок правил: wrap/burrito/toast побеждают общий 'avocado'.
- `RecipeImage` применён везде: сетка рецептов, hero деталей, Today's Meals, favorites, Profile saved.
- ⚠️ Ограничение: фото подбираются на фронте (бэк не отдаёт image); из среды разработки сеть до Unsplash закрыта, поэтому часть ссылок не проверяема — но пулы + fallback гарантируют «не сломано» и минимум повторов.

### Premium / Payment фиксы
- **Payment Success**: был overflow 47px (полосатая полоса) → обёрнут в `LayoutBuilder + SingleChildScrollView + IntrinsicHeight` → скроллится, не переполняется.
- **Profile**: баннер «Upgrade to Premium» теперь скрыт если `isPremium` (было видно даже после покупки).

### Дожали интеграцию дисплеев (всё в БД)
- **Home «Today's Meals»** — реальные рецепты из `RecipeProvider` (было 3 захардкоженных), тап → детали.
- **Mood history** — `MoodCheckService.history()` + `MoodProvider.loadEntries` читает `GET /mood-checks` (было только локально; запись и так шла в БД).
- **Profile «Saved Recipes»** — реальные favorites из `FavoritesProvider` (было захардкожено), тап → детали; счётчик «Recipes Saved» уже реальный.

### Аудит связи фронт↔бэк
- Все frontend-вызовы сверены с backend-роутами. Всё, у чего есть эндпоинт — подключено.
- Не подключено (осознанно): **AI Chat текст** (эндпоинта на бэке нет; фото — через Vision), **Wallet Top-Up** (эндпоинт есть, оставили заглушкой), геймификация (Goals Hit/ачивки — эндпоинта нет).
- `dart analyze` — 0 ошибок, 0 warnings.

---

## Текущее состояние (3 июля 2026)

| Фича | Статус | Детали |
|------|--------|--------|
| Auth (email + Google) | ✅ | Login, Register, OTP, Splash |
| Onboarding (4 шага) | ✅ | Goals, Diet, Allergies → бэкенд |
| Home (6 табов) | ✅ | Today's Meals (реальные), Water, Calories, Mood |
| Mood Check | ✅ | Слайдеры + hungerLevel → бэкенд |
| Mood history | ✅ | Читается с `GET /mood-checks` (было локально) |
| AI Recommendations | ✅ | Реальные данные, fitScore, GPT объяснение |
| Recipes | ✅ | **Все 168** (пагинация), фото-пулы, RecipeImage fallback |
| Recipe detail (редизайн) | ✅ | Полноэкранный: info-карты, Mood/Energy, Nutrition Facts, ingredients, instructions, Start Cooking |
| Favorites | ✅ | Backend sync, optimistic toggle, экран, P/F/C badges |
| Recipe macros/cost | ✅ | P/F/C + ~$X, данные от бэкенда |
| Water таб (Epic 6) | ✅ | Отдельный таб: кольцо, +250/500/custom, история, цель, напоминания → `/water` |
| Forgot password | ✅ | 2-шаговый флоу → `/auth/forgot-password` + `/reset-password` |
| Settings: Contact/Help/Cancel Sub | ✅ | Секция Support + отмена подписки |
| Vision AI (фото → рецепты) | ✅ | Camera/Gallery → `/vision/recommendations` → RecommendationsScreen |
| Mood & Energy Chart | ✅ | CustomPaint теперь на полную ширину карточки |
| Premium / PayPal | ✅ | WebView flow, syncFromBackend, Monthly/Annual; баннер скрыт если куплен |
| Payment Success | ✅ | Скроллится, overflow исправлен |
| Saved Recipes (Profile) | ✅ | Реальные favorites, тап → детали |
| Editable Profile | ✅ | Имя + аватар (Camera/Gallery) |
| Water tracking (Epic 6) | ✅ | +/− стаканы → `/water` (бэкенд, было SharedPreferences) |
| Notifications / reminders (Epic 6) | ✅ | Экран + Settings-тоггл → `/notifications` |
| Habit analytics (Epic 7) | ✅ | «This Week» + tips → `/insights/weekly` |
| Wallet (кошелёк) | ✅ | Баланс + транзакции → `/wallet` (Top-Up — заглушка) |
| Шрифт Inter | ✅ | Забандлен, типографика как в Figma |
| AI Chat (текст) | ⏳ | Канёные ответы — текстового AI-эндпоинта на бэке нет |
| Реальный push (FCM/APNs) | ⏳ | In-app часть есть; нужна Firebase/APNs настройка + `POST /notifications/devices` |
| Apple Sign In | ⏳ | Заглушка, нужен entitlement |
| Тёмная тема (Dark/Light) | ⏳ | Следующий спринт — сквозная правка всех экранов |
| 3 языка (kk/ru/en) | ⏳ | Следующий спринт — самый большой блок |

---

## Следующий шаг

- Dark / Light mode (ThemeProvider + darkTheme, применить по всем экранам)
- Локализация kk / ru / en (LocaleProvider + словари, пикер в Settings)
- Реальный push: Firebase Messaging + APNs + регистрация device-token
- Deep-link для reset-password (чтобы token открывал приложение)
- Apple Sign In

---

*Сессия 4: 9–11 июня 2026 — Flutter Frontend Epic 1, все экраны auth + onboarding, iOS деплой*
*Сессия 5: 13 июня 2026 — Google Sign In реализован, Apple заглушка, подключение к Render*  
*Сессия 6: 19 июня 2026 — Полный редизайн всех экранов по Figma, все кнопки кликабельны, исправлены критические баги*
*Сессия 9: 25 июня 2026 — API constants для Favorites добавлены*
*Сессия 10: 26 июня 2026 — Epic 5 полностью: Favorites sync, Vision AI, macros UI, chart fix, photo matching*
*Сессия 11: 2 июля 2026 — Дизайн (Inter, лого, вода +/−), Wallet + 2 плана, Epic 6/7 фронтенд (water/notifications/insights), полная сверка фронт↔бэк, analyze 0 ошибок*
*Сессия 12: 3 июля 2026 — Water таб (полный Epic 6), единая система фото рецептов (167, curl-verified), редизайн деталей рецепта по макетам, forgot password флоу, Settings Support (Contact/Help/Cancel Sub)*
*Сессия 13: 3 июля 2026 — Все 168 рецептов (пагинация), RecipeImage + фото-пулы (без повторов, красивый fallback), Payment overflow фикс, Premium-баннер скрыт если куплен, Today's Meals/Mood history/Saved Recipes → реальные данные с бэка*
