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

## Что не реализовано (для следующих эпиков)

| Что | Когда |
|-----|-------|
| Apple Sign In | Нужен entitlement Sign In with Apple в Xcode + iOS OAuth клиент |
| Экран Pantry (кладовка) | Epic 3 фронт — API готов |
| Экран Recipes | Epic 3 фронт — API готов |
| Экран Recommendations | Epic 3 фронт — API готов (matchScore + missingIngredients) |
| Mood → рецепты связка | Epic 4 |
| Сохранённые рецепты | Epic 4 |

---

## Следующий шаг — Epic 3 Frontend

- Экран Pantry: добавить/удалить ингредиенты (API: GET/POST/DELETE /pantry)
- Экран Recipes: список + фильтрация по настроению (API: GET /recipes?mood=calm)
- Экран Recommendations: с matchScore и missingIngredients (API: GET /recipes/recommendations?useMyIngredients=true)

---

*Сессия 4: 9–11 июня 2026 — Flutter Frontend Epic 1, все экраны auth + onboarding, iOS деплой*  
*Сессия 5: 13 июня 2026 — Google Sign In реализован, Apple заглушка, подключение к Render*
