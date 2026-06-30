-- Epic 6 (water tracking + reminders), push notifications, and password reset.

-- ─── Password reset columns on users ────────────────────────────────────────
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "password_reset_token" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "password_reset_expires" TIMESTAMP(3);

-- ─── Water logs ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "water_logs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "amount_ml" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "water_logs_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "water_logs_user_id_created_at_idx" ON "water_logs"("user_id", "created_at");

-- ─── Reminder settings ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "reminder_settings" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "water_goal_ml" INTEGER NOT NULL DEFAULT 2000,
    "water_reminders_on" BOOLEAN NOT NULL DEFAULT true,
    "water_interval_min" INTEGER NOT NULL DEFAULT 120,
    "meal_reminders_on" BOOLEAN NOT NULL DEFAULT false,
    "wake_time" TEXT NOT NULL DEFAULT '08:00',
    "sleep_time" TEXT NOT NULL DEFAULT '23:00',
    "timezone_offset_min" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "reminder_settings_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "reminder_settings_user_id_key" ON "reminder_settings"("user_id");

-- ─── Device tokens ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "device_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL DEFAULT 'android',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "device_tokens_token_key" ON "device_tokens"("token");
CREATE INDEX IF NOT EXISTS "device_tokens_user_id_idx" ON "device_tokens"("user_id");

-- ─── Notification log ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "notification_logs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "sent_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "notification_logs_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "notification_logs_user_id_sent_at_idx" ON "notification_logs"("user_id", "sent_at");

-- ─── Foreign keys ───────────────────────────────────────────────────────────
ALTER TABLE "water_logs" ADD CONSTRAINT "water_logs_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "reminder_settings" ADD CONSTRAINT "reminder_settings_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "device_tokens" ADD CONSTRAINT "device_tokens_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "notification_logs" ADD CONSTRAINT "notification_logs_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
