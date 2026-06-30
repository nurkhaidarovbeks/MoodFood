import { PrismaClient } from '@prisma/client'

/**
 * Shared accessor for a user's ReminderSetting row (Epic 6 hydration goal +
 * push/meal reminder preferences). Both the water and notifications modules read
 * and update the same row, so creation is centralised here to avoid drift.
 * Returns the existing row or lazily creates one with sensible defaults.
 */
export async function getOrCreateReminderSetting(prisma: PrismaClient, userId: string) {
  const existing = await prisma.reminderSetting.findUnique({ where: { userId } })
  if (existing) return existing
  return prisma.reminderSetting.create({ data: { userId } })
}

/**
 * Local-day [start, end) UTC window for the user, honouring their stored
 * timezone offset (minutes east of UTC). daysAgo shifts the window back.
 */
export function localDayRange(offsetMin: number, daysAgo = 0): { start: Date; end: Date } {
  const local = new Date(Date.now() + offsetMin * 60_000)
  local.setUTCHours(0, 0, 0, 0)
  local.setUTCDate(local.getUTCDate() - daysAgo)
  const start = new Date(local.getTime() - offsetMin * 60_000)
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000)
  return { start, end }
}

/** YYYY-MM-DD label for a UTC instant shifted into the user's local timezone. */
export function localDateKey(date: Date, offsetMin: number): string {
  return new Date(date.getTime() + offsetMin * 60_000).toISOString().slice(0, 10)
}
