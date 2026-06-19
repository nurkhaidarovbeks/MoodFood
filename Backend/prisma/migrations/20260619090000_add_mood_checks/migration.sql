-- CreateTable
CREATE TABLE "mood_checks" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "mood" TEXT,
    "energy_level" INTEGER,
    "stress_level" TEXT,
    "sleep_quality" TEXT,
    "hunger_level" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mood_checks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "mood_checks_user_id_created_at_idx" ON "mood_checks"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "mood_checks" ADD CONSTRAINT "mood_checks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
