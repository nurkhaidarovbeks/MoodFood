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

## Сессия 7 Mobile — 13–20 июня 2026 (Premium + PayPal + Profile + Recipes)

> Автор: Khamitbek Azhara | Модель: Claude Sonnet 4.6  
> Ветка: `feature/flutter-frontend-epic1`

### 1. Premium / Subscription — подключён к бэкенду

**Новые файлы:**
- `core/services/subscription_service.dart` — `getPlans()`, `subscribe()`, `getMySubscription()`, `cancel()`
- `core/providers/subscription_provider.dart` — `load()` (SharedPreferences), `syncFromBackend()`, `upgradeToPremium()`, `cancelPremium()`

**Изменения:**
- `splash_screen.dart` — параллельный `Future.wait([auth.checkAuthStatus(), sub.load()])`, после логина `sub.syncFromBackend()`
- Premium badge обновляется в реальном времени после оплаты
- API constants: `subscriptionPlans`, `subscriptionSubscribe`, `subscriptionMe`, `subscriptionCancel`

### 2. PayPal WebView flow

**Новый файл:** `features/payment/screens/paypal_webview_screen.dart`
- Открывает PayPal URL в WebView (`webview_flutter: ^4.10.0`)
- Перехватывает `/payment/paypal/success` → ждёт 2 сек → `syncFromBackend()` → `/payment-success`
- Перехватывает `/payment/paypal/cancel` → `pop()` + SnackBar
- Forte Bank: `SnackBar("Coming soon")`

`premium_screen.dart` обновлён:
- `_pay()` вызывает `POST /subscriptions/subscribe` → получает `paymentUrl` → открывает `PayPalWebViewScreen`
- Error banner над кнопкой Pay при ошибке API

### 3. Рецепты — реальные фото

`recipes_screen.dart`:
- `_photos` map: 12 ключевых слов продуктов → Unsplash URL
- 5 fallback фото (выбор по `recipe.id.hashCode`)
- Case-insensitive поиск: `title.toLowerCase().contains(key)`
- Фильтр bottom sheet: 5 опций (Mood / Dietary / Quick Meals / Budget / Pantry)

### 4. Редактируемый профиль

**Новый файл:** `features/profile/screens/edit_profile_screen.dart`
- Редактирование имени + аватара (Camera / Gallery через `image_picker: ^1.1.2`)
- Аватар сохраняется в SharedPreferences как base64

### 5. Water tracking (интерактивный)

`home_screen.dart` — `_StatsRow` → `_WaterCard`:
- Кнопки +/− меняют счётчик (0–12 стаканов)
- Сохранение: `SharedPreferences` ключ `water_glasses` → `"2026-06-13:5"` (сброс каждый день)

### 6. Фиксы валидации

| Проблема | Решение |
|----------|---------|
| Регистрация: "Validation failed" | Пароль мин. 8 символов (бэкенд Zod `min(8)`), было 6 |
| Profile Setup Step 3: "Validation failed" | UI-лейблы маппятся в backend DIETARY_RESTRICTION_KEYS: `Dairy→lactose_free`, `Eggs→egg_allergy`, `Soy→soy_allergy`, `Peanuts/Tree Nuts→nut_allergy`, `Wheat→gluten_free`. Неизвестные (`Fish`, `Keto`, `Paleo`) → `customRestrictions` |

### 7. Прочее

- `recommendations_screen.dart` — "Explore More Recipes" → `/home` с `arguments: {'tab': 1}`
- `home_screen.dart` — `didChangeDependencies()` читает tab-аргумент и переключает вкладку
- Saved recipes count в профиле загружается из SharedPreferences `saved_recipes`

**Коммиты:** `3a12c26`, `46ee561`, `f3afae7`, `11c36c9`, `aa0ee92`, `e3ec57a`

---

## Сессия 8 Mobile — 25 июня 2026 (Epic 4–5: AI Recommendations + Mood Backend)

> Автор: Khamitbek Azhara | Модель: Claude Sonnet 4.6  
> Ветка: `feature/flutter-frontend-epic1`

### 1. MoodCheck → синхронизация с бэкендом

**Изменения в модели `MoodEntry`:**
- Добавлено поле `hungerLevel: String?` (`low` / `medium` / `high`)
- `fromJson` / `toJson` обновлены (поле опциональное)

**Новый слайдер в `mood_check_screen.dart`:**
- "Hunger Level" между Stress и кнопкой Submit
- Диапазон: Not Hungry → Very Hungry → маппится `_hungerCategory()` → `low/medium/high`

**Новый сервис `core/services/mood_check_service.dart`:**
- `create(MoodEntry)` — `POST /api/v1/mood-checks` (fire-and-forget, не блокирует UI)
- `getLatest()` — `GET /api/v1/mood-checks/latest`

**`mood_provider.dart`** — после локального сохранения вызывает `_service.create(entry)` без `await`

### 2. AI Recommendations — реальные данные с бэкенда

**Новый сервис `core/services/recommendation_service.dart`:**
- `recommend(entry, useMyIngredients, maxCookingTime)` — `POST /api/v1/recommendations`
- Отправляет: `mood`, `energyLevel`, `stressLevel`, `sleepQuality`, `hungerLevel`
- Модели: `RecommendationResult`, `RecommendationOption`, `RecommendationRecipe`

**`recommendations_screen.dart` полностью переписан** (StatelessWidget → StatefulWidget):

| Элемент | Описание |
|---------|---------|
| Loading spinner | «Finding the perfect meals for you…» |
| `_RecommendationCard` | Цветной header по категории, fitScore badge (зелёный), время/калории/сложность |
| AI explanation | Блок с иконкой 🤖 и текстом от GPT-4o-mini |
| AI badge | «AI» chip в заголовке когда `aiPowered=true` |
| Missing ingredients | Оранжевые chips (pantry mode) |
| `_ErrorCard` | «Couldn't reach the server» + кнопка Retry |
| `_EmptyCard` | Для пустого ответа сервера |

**Цвета категорий:**

| Категория | Цвет |
|-----------|------|
| energizing | `#FFF3E0` (оранжевый) |
| calming | `#E8F5E9` (зелёный) |
| comforting | `#FCE4EC` (розовый) |
| light | `#E3F2FD` (голубой) |
| nourishing | `#F3E5F5` (фиолетовый) |

### 3. API Constants — добавлены

```dart
static const String moodChecks = '/mood-checks';
static const String moodChecksLatest = '/mood-checks/latest';
static const String aiRecommendations = '/recommendations';
```

### 4. Установка как нативное приложение

- Release build через Xcode (Product → Run) установлен на Cherry🍒
- Приложение запускается с иконки без `flutter run` и кабеля USB

### Обновлённая структура `core/services/`

```
core/services/
├── auth_service.dart
├── mood_check_service.dart        ← NEW
├── profile_service.dart
├── recipe_service.dart
├── recommendation_service.dart    ← NEW
└── subscription_service.dart
```

**Коммит:** `76aef51`

---

## Текущее состояние (25 июня 2026)

| Фича | Статус | Детали |
|------|--------|--------|
| Auth (email + Google) | ✅ | Login, Register, OTP, Splash |
| Onboarding (4 шага) | ✅ | Goals, Diet, Allergies → бэкенд |
| Home (5 табов) | ✅ | Water +/−, Calories, Mood summary |
| Mood Check | ✅ | Слайдеры + hungerLevel → бэкенд |
| AI Recommendations | ✅ | Реальные данные, fitScore, GPT объяснение |
| Recipes | ✅ | Фото, фильтры, сохранение (локально) |
| Premium / PayPal | ✅ | WebView flow, syncFromBackend |
| Editable Profile | ✅ | Имя + аватар (Camera/Gallery) |
| Water tracking | ✅ | +/− кнопки, SharedPreferences |
| Apple Sign In | ⏳ | Заглушка, нужен entitlement |
| Saved recipes → бэкенд | ⏳ | Сейчас только SharedPreferences |
| Habit analytics | ⏳ | Нет бэкенд эндпоинта |
| Push-уведомления | ⏳ | UI есть, real push нет |

---

## Следующий шаг

- Habit analytics / weekly tips (когда бэкенд добавит эндпоинт)
- Saved recipes → sync с бэкендом
- Apple Sign In (entitlement в Xcode)
- Push-уведомления

---

*Сессия 4: 9–11 июня 2026 — Flutter Frontend Epic 1, все экраны auth + onboarding, iOS деплой*  
*Сессия 5: 13 июня 2026 — Google Sign In реализован, Apple заглушка, подключение к Render*  
*Сессия 6: 19 июня 2026 — Полный редизайн всех экранов по Figma, все кнопки кликабельны, исправлены критические баги*  
*Сессия 7: 13–20 июня 2026 — Premium/PayPal WebView, recipe photos, editable profile, water tracking, validation fixes*  
*Сессия 8: 25 июня 2026 — Epic 4-5: MoodCheck → backend, AI Recommendations реальные данные, hungerLevel*
