# MoodFood Backend — API Documentation

> **⚠️ Частичный документ (Epic 1–2/4 эра).** Здесь описаны auth / profile /
> recommendations / mood-checks. Полный и актуальный список **всех** эндпоинтов
> (pantry, recipes, favorites, vision, payment, wallet, subscription, **water,
> insights, notifications, password reset**) — в корневом `GUIDE.md` и в
> `moodfood.postman_collection.json`. Актуально на 2 июля 2026 · 255 тестов.

## Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js + TypeScript |
| Framework | Express.js |
| ORM | Prisma 5 |
| Database | PostgreSQL |
| Auth | JWT (jsonwebtoken) |
| Passwords | bcrypt (cost factor 12) |
| Validation | Zod |
| Google OAuth | google-auth-library (server-side token verification) |
| Email | Nodemailer + console stub for development |
| Tests | Jest + jest-mock-extended |

---

## Required Environment Variables

Copy `.env.example` → `.env` and fill in values.

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `JWT_SECRET` | Yes | Secret for signing JWTs (min 32 chars) |
| `JWT_EXPIRES_IN` | No | JWT TTL (default: `7d`) |
| `REQUIRE_EMAIL_VERIFICATION` | No | `true` to enforce email verification before login (default: `false`) |
| `GOOGLE_CLIENT_ID` | No | Google OAuth Client ID from Google Cloud Console |
| `SMTP_HOST` | No | SMTP hostname — if blank, emails are logged to console (dev stub) |
| `SMTP_PORT` | No | SMTP port (default: `587`) |
| `SMTP_USER` | No | SMTP username |
| `SMTP_PASS` | No | SMTP password |
| `SMTP_FROM` | No | Sender address (default: `noreply@moodfood.app`) |
| `APP_URL` | No | Base URL of this API server (for verification link) |
| `FRONTEND_URL` | No | Frontend URL for CORS allowlist |
| `ANTHROPIC_API_KEY` | No | Claude API key for AI meal explanations. If blank, recommendations use a deterministic rule-based fallback (fully offline) |
| `ANTHROPIC_MODEL` | No | Claude model for explanations (default: `claude-haiku-4-5`) |

---

## Email Verification Behavior

- Controlled by `REQUIRE_EMAIL_VERIFICATION` env var.
- When `false` (default): users registered via email/password are marked `isEmailVerified = true` immediately. Login works without any extra step.
- When `true`: users receive a verification email. Login is blocked with `EMAIL_NOT_VERIFIED (403)` until the link is clicked. Token is valid for 24 hours.
- Google OAuth users are always considered verified (`email_verified` comes from Google's token).
- In development with no SMTP configured, the verification URL is printed to the server console.

---

## Google OAuth Configuration

1. Create credentials at <https://console.cloud.google.com/>.
2. Add your domain to "Authorized JavaScript origins" and "Authorized redirect URIs".
3. Set `GOOGLE_CLIENT_ID` in `.env`.

**Token flow** (ID token approach, suitable for mobile/SPA):
1. Frontend authenticates with Google and obtains a Google ID token.
2. Frontend sends the ID token to `POST /api/v1/auth/google`.
3. Backend verifies the token server-side via Google's public keys.
4. Backend creates or logs in the user and returns a JWT.

---

## Dietary Restriction Enum Values

These are the valid values for `dietaryRestrictions` and `allergies` arrays:

| Key | Meaning |
|---|---|
| `vegan` | Excludes all animal products (meat, seafood, dairy, eggs, honey) |
| `vegetarian` | Excludes meat and seafood (dairy and eggs allowed) |
| `pescatarian` | Excludes land meat; fish and seafood allowed |
| `lactose_free` | Excludes dairy products |
| `gluten_free` | Excludes wheat, barley, rye, and gluten-containing ingredients |
| `halal` | Excludes pork products and alcohol |
| `kosher` | Excludes pork and shellfish |
| `nut_allergy` | Excludes all tree nuts and peanuts |
| `egg_allergy` | Excludes eggs and egg-derived ingredients |
| `soy_allergy` | Excludes soy, tofu, miso, and soy-derived ingredients |

Custom restrictions can be added as free-text strings in `customRestrictions`. They are matched case-insensitively against ingredient names and categories.

---

## API Endpoints

Base path: `/api/v1`

All authenticated endpoints require:
```
Authorization: Bearer <jwt-token>
```

---

### Auth Endpoints

#### `POST /api/v1/auth/register`

Register with email and password.

**Request body:**
```json
{
  "email": "alice@example.com",
  "password": "SecurePass123!",
  "name": "Alice"
}
```

**Success `201`:**
```json
{
  "user": {
    "id": "uuid",
    "email": "alice@example.com",
    "name": "Alice",
    "authProvider": "email",
    "isEmailVerified": false,
    "isProfileComplete": false
  },
  "token": "eyJ...",
  "requiresEmailVerification": true
}
```

**Errors:**
- `400 VALIDATION_ERROR` — invalid email or weak password
- `409 EMAIL_EXISTS` — email already registered

---

#### `POST /api/v1/auth/login`

Login with email and password.

**Request body:**
```json
{
  "email": "alice@example.com",
  "password": "SecurePass123!"
}
```

**Success `200`:**
```json
{
  "user": {
    "id": "uuid",
    "email": "alice@example.com",
    "name": "Alice",
    "authProvider": "email",
    "isEmailVerified": true,
    "isProfileComplete": false
  },
  "token": "eyJ..."
}
```

**Errors:**
- `401 INVALID_CREDENTIALS` — wrong email or password
- `403 ACCOUNT_INACTIVE` — account disabled
- `403 EMAIL_NOT_VERIFIED` — verification required and email not yet verified

---

#### `POST /api/v1/auth/google`

Login or register using a Google ID token obtained from the frontend.

**Request body:**
```json
{
  "idToken": "<google-id-token>"
}
```

**Success `200`:**
```json
{
  "user": {
    "id": "uuid",
    "email": "alice@gmail.com",
    "name": "Alice",
    "authProvider": "google",
    "isEmailVerified": true,
    "isProfileComplete": false
  },
  "token": "eyJ..."
}
```

**Errors:**
- `401 INVALID_GOOGLE_TOKEN` — token is invalid or expired
- `400 GOOGLE_EMAIL_UNVERIFIED` — Google token has `email_verified = false`
- `501 GOOGLE_NOT_CONFIGURED` — `GOOGLE_CLIENT_ID` not set on server

---

#### `GET /api/v1/auth/verify-email?token=<raw-token>`

Verify email address using the token from the verification email link.

**Success `200`:**
```json
{
  "message": "Email verified successfully. You can now log in."
}
```

**Errors:**
- `400 INVALID_TOKEN` — token is invalid or expired
- `400 MISSING_TOKEN` — no token query param

---

#### `POST /api/v1/auth/resend-verification`

Resend the verification email.

**Request body:**
```json
{
  "email": "alice@example.com"
}
```

**Success `200`:** (same message regardless of whether email exists, to prevent enumeration)
```json
{
  "message": "If this email is registered and unverified, a new verification email has been sent."
}
```

---

### Profile Endpoints

All profile routes require `Authorization: Bearer <token>`.

#### `GET /api/v1/profile`

Get the current user's profile and completion status.

**Success `200`:**
```json
{
  "user": {
    "id": "uuid",
    "email": "alice@example.com",
    "name": "Alice",
    "authProvider": "email",
    "isEmailVerified": true,
    "isProfileComplete": true
  },
  "profile": {
    "age": 25,
    "goal": "Eat healthier and feel more energetic",
    "lifestyle": "student",
    "budgetLevel": "low",
    "dietaryRestrictions": ["vegan", "gluten_free"],
    "allergies": ["nut_allergy"],
    "customRestrictions": ["mushrooms"]
  }
}
```

If profile has never been saved, `profile` is `null` and `isProfileComplete` is `false`.

---

#### `PUT /api/v1/profile`

Create or fully replace the nutrition profile.

**Request body:**
```json
{
  "age": 25,
  "goal": "Eat healthier and feel more energetic",
  "lifestyle": "student",
  "budgetLevel": "low",
  "dietaryRestrictions": ["vegan", "gluten_free"],
  "allergies": ["nut_allergy"],
  "customRestrictions": ["mushrooms", "cilantro"]
}
```

**Validation rules:**
- `age`: integer 1–120
- `goal`: string max 500 chars
- `lifestyle`: one of `student | professional | other`
- `budgetLevel`: one of `low | medium | high`
- `dietaryRestrictions` / `allergies`: arrays of valid restriction keys (duplicates removed)
- `customRestrictions`: free-text strings, max 100 chars each (lowercased, deduplicated)

**Success `200`:**
```json
{
  "profile": { ... },
  "isProfileComplete": true
}
```

**Profile is "complete"** when all four core fields are filled: `age`, `goal`, `lifestyle`, `budgetLevel`.

---

#### `PATCH /api/v1/profile`

Partially update the nutrition profile. Only provided fields are changed; others are preserved.

**Request body** (any subset of PUT fields):
```json
{
  "goal": "Build muscle"
}
```

**Success `200`:**
```json
{
  "profile": { ... },
  "isProfileComplete": false
}
```

---

### `POST /api/v1/recommendations` 🔒

AI meal recommendations driven by a mood-check. Returns up to three distinct
options — **fastest**, **healthiest**, **cheapest** — each with a short
explanation of why it fits the user's current state. Dietary restrictions and
allergies are enforced as a hard filter (via `DietaryRestrictionService`).

**Request body** (all fields optional — more signals = better fit):
```json
{
  "mood": "tired",
  "energyLevel": 2,
  "stressLevel": "high",
  "sleepQuality": "poor",
  "hungerLevel": "high",
  "budgetLevel": "low",
  "maxCookingTime": 20,
  "useMyIngredients": true
}
```

| Field | Type | Notes |
|---|---|---|
| `mood` | string | e.g. `tired`, `stressed`, `happy`, `low_energy` |
| `energyLevel` | int 1–5 | ≤ 2 is treated as low energy |
| `stressLevel` | `low`/`medium`/`high` | |
| `sleepQuality` | `poor`/`normal`/`good` | |
| `hungerLevel` | `low`/`medium`/`high` | |
| `budgetLevel` | `low`/`medium`/`high` | overrides the profile's budget |
| `maxCookingTime` | int (minutes) | only recipes ≤ N min |
| `useMyIngredients` | boolean | match against pantry + suggest substitutions |

**Success `200`:**
```json
{
  "state": { "mood": "tired", "energyLevel": 2, "budgetLevel": "low" },
  "aiPowered": false,
  "options": [
    {
      "category": "healthiest",
      "fitScore": 0.87,
      "recipe": { "id": "...", "title": "Salmon with Quinoa", "cookingTimeMin": 30, "calories": 520, "proteinG": 48, "ingredients": [ ... ] },
      "explanation": "Packed with 48g of protein for a steady energy lift, the most nourishing fit for how you feel right now.",
      "matchScore": 0.0,
      "missingIngredients": ["salmon", "quinoa"],
      "substitutions": { "salmon": ["tuna", "tofu"] }
    }
  ]
}
```

- `aiPowered` — `true` when explanations came from the Claude API, `false` when the
  rule-based fallback was used (no `ANTHROPIC_API_KEY`).
- `matchScore` / `missingIngredients` / `substitutions` appear only when
  `useMyIngredients` is `true`.

---

### `POST /api/v1/mood-checks` 🔒

Records a mood-check (Epic 2 state check-in). At least one field is required.

**Request body:**
```json
{
  "mood": "tired",
  "energyLevel": 2,
  "stressLevel": "high",
  "sleepQuality": "poor",
  "hungerLevel": "high"
}
```

**Success `201`:** the saved check-in (`id`, `userId`, fields, `createdAt`).

---

### `GET /api/v1/mood-checks?limit=20&offset=0` 🔒

Paginated history of the user's check-ins, newest first.

**Success `200`:**
```json
{ "moodChecks": [ { "id": "...", "mood": "tired", "createdAt": "..." } ], "total": 5, "limit": 20, "offset": 0 }
```

---

### `GET /api/v1/mood-checks/latest` 🔒

The user's most recent check-in, or `null` if none exist.

---

## How to Run Tests

```bash
# Install dependencies
cd Backend
npm install

# Run all tests
npm test

# Run with coverage report
npm run test:coverage
```

Tests are unit tests using jest-mock-extended to mock the Prisma client. No real database connection is required to run them.

---

## How to Run the Server

```bash
# 1. Copy env file
cp .env.example .env
# Fill in DATABASE_URL, JWT_SECRET

# 2. Install dependencies
npm install

# 3. Generate Prisma client and run migrations
npm run db:generate
npm run db:migrate

# 4. Start development server
npm run dev

# 5. Build for production
npm run build
npm start
```

---

## Recipe Filtering Architecture

Any backend endpoint that returns recipes to users **must** apply dietary restriction filtering. The central service is at:

```
src/services/dietary-restriction.service.ts
```

Use it like this in any future recommendation / search endpoint:

```typescript
import { filterRecipesForUser } from '../../services/dietary-restriction.service'

// Fetch user profile (dietaryRestrictions, allergies, customRestrictions)
// Fetch candidate recipes with their ingredients
// Apply filter — restricted recipes are never returned
const visibleRecipes = filterRecipesForUser(userProfile, allRecipes)
```

The service performs case-insensitive substring matching on ingredient names and categories against all active restrictions and allergies.

---

## Assumptions and Out-of-Scope Items

### Assumptions made
- PostgreSQL is the target database (Prisma schema uses PostgreSQL-specific features).
- JWT is stateless — no token revocation / blacklist for MVP.
- Google OAuth uses the ID token flow (mobile/SPA) rather than server-side redirect OAuth.
- `profile_completed_at` records the first time all required profile fields are filled; it is not overwritten on subsequent edits.
- `emailVerificationToken` in the database stores a SHA-256 hash of the raw token; the raw token is only ever held in memory and sent via email.

### Implemented since this doc was written (see GUIDE.md for details)
- ✅ Recipe recommendation engine (Epic 4) — mood-based 3 options + product-aware matching (staple-aware, ≥60% cookable), 168 recipes.
- ✅ Vision AI (photo → ingredients → dishes), Pantry, Favorites.
- ✅ Payment (PayPal), Wallet, Subscriptions (idempotent, order state machine).
- ✅ Water tracking + reminders + push (FCM), Habit insights (Epic 6/7).
- ✅ Password reset (`/auth/forgot-password`, `/auth/reset-password`).
- ✅ Rate limiting (login/register/otp/forgot-password).

### Still not implemented (intentional / future)
- Frontend screens, onboarding UI, navigation (lives in `Mobile/`).
- Refresh tokens (MVP uses single long-lived access token).
- OAuth authorization code flow with redirect URLs (only ID token verification).
- Telegram OAuth (schema has the enum value; no endpoint yet).
- Admin user management.
