import dotenv from 'dotenv'
dotenv.config()

function required(key: string): string {
  const val = process.env[key]
  if (!val) throw new Error(`Missing required environment variable: ${key}`)
  return val
}

function optional(key: string, defaultValue: string): string {
  return process.env[key] ?? defaultValue
}

export const env = {
  NODE_ENV: optional('NODE_ENV', 'development'),
  PORT: parseInt(optional('PORT', '3000'), 10),
  DATABASE_URL: required('DATABASE_URL'),
  JWT_SECRET: required('JWT_SECRET'),
  JWT_EXPIRES_IN: optional('JWT_EXPIRES_IN', '7d'),
  GOOGLE_CLIENT_ID: optional('GOOGLE_CLIENT_ID', ''),
  APPLE_CLIENT_ID: optional('APPLE_CLIENT_ID', ''),
  SMTP_HOST: optional('SMTP_HOST', ''),
  SMTP_PORT: parseInt(optional('SMTP_PORT', '587'), 10),
  SMTP_USER: optional('SMTP_USER', ''),
  SMTP_PASS: optional('SMTP_PASS', ''),
  SMTP_FROM: optional('SMTP_FROM', 'noreply@moodfood.app'),
  APP_URL: optional('APP_URL', 'http://localhost:3000'),
  FRONTEND_URL: optional('FRONTEND_URL', 'http://localhost:5173'),
  REQUIRE_EMAIL_VERIFICATION: optional('REQUIRE_EMAIL_VERIFICATION', 'false') === 'true',
  APP_VERSION: optional('APP_VERSION', '1.0.0'),

  // ─── PayPal ──────────────────────────────────────────────────────────────
  PAYPAL_CLIENT_ID: optional('PAYPAL_CLIENT_ID', ''),
  PAYPAL_CLIENT_SECRET: optional('PAYPAL_CLIENT_SECRET', ''),
  PAYPAL_BASE_URL: optional('PAYPAL_BASE_URL', 'https://api-m.sandbox.paypal.com'),
  PAYPAL_RETURN_URL: optional('PAYPAL_RETURN_URL', 'http://localhost:3000/api/v1/payment/paypal/success'),
  PAYPAL_CANCEL_URL: optional('PAYPAL_CANCEL_URL', 'http://localhost:3000/api/v1/payment/paypal/cancel'),

  // ─── AI (OpenAI / ChatGPT) — meal recommendation explanations ────────────
  // If OPENAI_API_KEY is empty, the recommendation engine falls back to
  // deterministic rule-based explanations (app + tests work fully offline).
  OPENAI_API_KEY: optional('OPENAI_API_KEY', ''),
  // gpt-4o-mini — cheap & fast, ideal for short high-frequency blurbs.
  // Override with gpt-4o for higher-quality prose.
  OPENAI_MODEL: optional('OPENAI_MODEL', 'gpt-4o-mini'),
  // Vision model for photo ingredient recognition (fridge / receipt / list).
  // gpt-4o-mini supports vision and is cheap; gpt-4o is more accurate on hard
  // photos (blurry shelves, dense receipts) at higher cost.
  OPENAI_VISION_MODEL: optional('OPENAI_VISION_MODEL', 'gpt-4o-mini'),

  // Grafana Cloud remote_write (optional — only needed for production push)
  GRAFANA_REMOTE_WRITE_URL: optional('GRAFANA_REMOTE_WRITE_URL', ''),
  GRAFANA_REMOTE_WRITE_USER: optional('GRAFANA_REMOTE_WRITE_USER', ''),
  GRAFANA_REMOTE_WRITE_PASSWORD: optional('GRAFANA_REMOTE_WRITE_PASSWORD', ''),

  // ─── Push notifications (Firebase Cloud Messaging) ────────────────────────
  // If FCM_SERVER_KEY is empty, the push service no-ops (logs only) so the app
  // and tests run fully offline — device tokens are still stored and the
  // GET /notifications/due endpoint works for client-side polling.
  FCM_SERVER_KEY: optional('FCM_SERVER_KEY', ''),
  // Background reminder sweep cadence (minutes). 0 disables the sweep.
  REMINDER_SWEEP_MINUTES: parseInt(optional('REMINDER_SWEEP_MINUTES', '15'), 10),
}
