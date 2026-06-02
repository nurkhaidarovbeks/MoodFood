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
  // When true: email/password registrations must verify their email before logging in.
  // Set to false for MVP / development to skip enforcement.
  REQUIRE_EMAIL_VERIFICATION: optional('REQUIRE_EMAIL_VERIFICATION', 'false') === 'true',
}
