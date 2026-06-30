import { PrismaClient } from '@prisma/client'
import { NotificationService } from '../modules/notifications/notification.service'
import { PushService } from './push.service'

/**
 * Background reminder sweep — periodically checks every user who has reminders
 * enabled and at least one registered device, and pushes any reminders that are
 * due (water / meal). Safe to run when FCM is unconfigured: PushService no-ops,
 * but reminders are still recorded so the in-app /due endpoint stays accurate.
 */
export async function runReminderSweep(
  prisma: PrismaClient,
  service: NotificationService,
  now: Date = new Date(),
): Promise<{ usersChecked: number; remindersSent: number }> {
  // Only users with reminders on AND a device token are worth checking.
  const settings = await prisma.reminderSetting.findMany({
    where: { OR: [{ waterRemindersOn: true }, { mealRemindersOn: true }] },
    select: { userId: true },
  })

  let remindersSent = 0
  let usersChecked = 0
  for (const { userId } of settings) {
    const deviceCount = await prisma.deviceToken.count({ where: { userId } })
    if (deviceCount === 0) continue
    usersChecked++
    try {
      const { sent } = await service.sendDueReminders(userId, now)
      remindersSent += sent
    } catch (err) {
      console.error(`[reminders] sweep failed for user ${userId}:`, (err as Error).message)
    }
  }
  return { usersChecked, remindersSent }
}

/**
 * Starts the recurring sweep. intervalMinutes <= 0 disables it (returns a no-op).
 * Returns a stop() handle (used by tests / graceful shutdown).
 */
export function startReminderSweep(
  prisma: PrismaClient,
  intervalMinutes: number,
): { stop: () => void } {
  if (!intervalMinutes || intervalMinutes <= 0) {
    console.log('[reminders] sweep disabled (REMINDER_SWEEP_MINUTES=0)')
    return { stop: () => {} }
  }

  const service = new NotificationService(prisma, new PushService())
  const tick = async () => {
    try {
      const { usersChecked, remindersSent } = await runReminderSweep(prisma, service)
      if (remindersSent > 0) {
        console.log(`[reminders] swept ${usersChecked} user(s), sent ${remindersSent} reminder(s)`)
      }
    } catch (err) {
      console.error('[reminders] sweep error:', (err as Error).message)
    }
  }

  const handle = setInterval(tick, intervalMinutes * 60_000)
  console.log(`[reminders] sweep running every ${intervalMinutes} min`)
  return { stop: () => clearInterval(handle) }
}
