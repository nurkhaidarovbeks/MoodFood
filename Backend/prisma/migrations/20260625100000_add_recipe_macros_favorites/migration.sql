-- Add fat_g and carbs_g columns to recipes table
ALTER TABLE "recipes" ADD COLUMN "fat_g" DOUBLE PRECISION;
ALTER TABLE "recipes" ADD COLUMN "carbs_g" DOUBLE PRECISION;

-- Create user_favorites table
CREATE TABLE "user_favorites" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "recipe_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_favorites_pkey" PRIMARY KEY ("id")
);

-- Unique constraint: one bookmark per user per recipe
CREATE UNIQUE INDEX "user_favorites_user_id_recipe_id_key" ON "user_favorites"("user_id", "recipe_id");

-- Index for fast lookup of user's favorites ordered by time
CREATE INDEX "user_favorites_user_id_created_at_idx" ON "user_favorites"("user_id", "created_at");

-- Foreign keys
ALTER TABLE "user_favorites" ADD CONSTRAINT "user_favorites_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_favorites" ADD CONSTRAINT "user_favorites_recipe_id_fkey"
    FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE CASCADE;
