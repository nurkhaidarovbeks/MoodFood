import { PrismaClient } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import {
  getOrCreateReminderSetting,
  localDayRange,
} from '../../services/reminder-settings'
import { PushService } from '../../services/push.service'
import type {
  RegisterDeviceInput,
  UpdatePreferencesInput,
} from './notification.schema'

export interface DueReminder {
  type: 'water' | 'meal'
  title: string
  body: string
}

// Meal reminder slots (local minutes-from-midnight): breakfast, lunch, dinner.
const MEAL_SLOTS = [8 * 60, 13 * 60, 19 * 60]
const MEAL_WINDOW_MIN = 30 // fire within ±30 min of a slot
const MEAL_COOLDOWN_MS = 3 * 60 * 60 * 1000 // don't repeat within 3h

/**
 * NotificationService — device-token registry, reminder preferences, and the
 * core reminder logic shared by the polling endpoint (GET /due) and the
 * background sweep. Reminder computation is pure-ish (reads DB, no side effects)
 * so it can be tested without sending anything.
 */
export class NotificationService {
  constructor(
    private prisma: PrismaClient,
    private push: PushService,
  ) {}

  // ─── Device tokens ──────────────────────────────────────────────────────────

  async registerDevice(userId: string, input: RegisterDeviceInput) {
    // A token belongs to one device; re-registering refreshes its owner & seen.
    const device = await this.prisma.deviceToken.upsert({
      where: { token: input.token },
      create: { userId, token: input.token, platform: input.platform },
      update: { userId, platform: input.platform, lastSeenAt: new Date() },
    })
    return { id: device.id, platform: device.platform, registered: true }
  }

  async removeDevice(userId: string, token: string) {
    const device = await this.prisma.deviceToken.findUnique({ where: { token } })
    if (!device || device.userId !== userId) {
      throw new AppError(404, 'Device token not found', 'DEVICE_NOT_FOUND')
    }
    await this.prisma.deviceToken.delete({ where: { token } })
    return { removed: true }
  }

  // ─── Preferences ────────────────────────────────────────────────────────────

  async getPreferences(userId: string) {
    const s = await getOrCreateReminderSetting(this.prisma, userId)
    return {
      waterRemindersOn: s.waterRemindersOn,
      waterIntervalMin: s.waterIntervalMin,
      mealRemindersOn: s.mealRemindersOn,
      wakeTime: s.wakeTime,
      sleepTime: s.sleepTime,
      timezoneOffsetMin: s.timezoneOffsetMin,
    }
  }

  async updatePreferences(userId: string, input: UpdatePreferencesInput) {
    await getOrCreateReminderSetting(this.prisma, userId)
    await this.prisma.reminderSetting.update({
      where: { userId },
      data: {
        ...(input.waterRemindersOn !== undefined && { waterRemindersOn: input.waterRemindersOn }),
        ...(input.waterIntervalMin !== undefined && { waterIntervalMin: input.waterIntervalMin }),
        ...(input.mealRemindersOn !== undefined && { mealRemindersOn: input.mealRemindersOn }),
        ...(input.wakeTime !== undefined && { wakeTime: input.wakeTime }),
        ...(input.sleepTime !== undefined && { sleepTime: input.sleepTime }),
        ...(input.timezoneOffsetMin !== undefined && { timezoneOffsetMin: input.timezoneOffsetMin }),
      },
    })
    return this.getPreferences(userId)
  }

  async history(userId: string, limit: number) {
    const items = await this.prisma.notificationLog.findMany({
      where: { userId },
      orderBy: { sentAt: 'desc' },
      take: limit,
    })
    return { items, total: items.length }
  }

  // ─── Reminder computation ─────────────────────────────────────────────────────

  /**
   * Returns the reminders that are due for the user right now, based on their
   * settings, today's water intake, last intake time, and recent reminders.
   * Pure read — does not send or log anything.
   */
  async computeDueReminders(userId: string, now: Date = new Date()): Promise<DueReminder[]> {
    const s = await getOrCreateReminderSetting(this.prisma, userId)
    const due: DueReminder[] = []

    // Outside the user's waking window → never remind.
    const localMin = localMinutesOfDay(now, s.timezoneOffsetMin)
    if (!withinWindow(localMin, s.wakeTime, s.sleepTime)) return due

    // ── Water ──
    if (s.waterRemindersOn) {
      const { start, end } = localDayRange(s.timezoneOffsetMin)
      const [todayLogs, lastWaterReminder] = await Promise.all([
        this.prisma.waterLog.findMany({
          where: { userId, createdAt: { gte: start, lt: end } },
          orderBy: { createdAt: 'desc' },
        }),
        this.lastNotification(userId, 'water'),
      ])

      const totalMl = todayLogs.reduce((sum, l) => sum + l.amountMl, 0)
      const goalReached = totalMl >= s.waterGoalMl
      const lastIntakeAt = todayLogs[0]?.createdAt ?? null
      const intervalMs = s.waterIntervalMin * 60_000

      // Reference = most recent of (last intake, last reminder, window start).
      const refs = [start.getTime()]
      if (lastIntakeAt) refs.push(lastIntakeAt.getTime())
      if (lastWaterReminder) refs.push(lastWaterReminder.getTime())
      const sinceMs = now.getTime() - Math.max(...refs)

      if (!goalReached && sinceMs >= intervalMs) {
        const remaining = Math.max(0, s.waterGoalMl - totalMl)
        due.push({
          type: 'water',
          title: '💧 Time to hydrate',
          body: `You're at ${totalMl} ml today — ${remaining} ml to reach your ${s.waterGoalMl} ml goal.`,
        })
      }
    }

    // ── Meals ──
    if (s.mealRemindersOn) {
      const nearSlot = MEAL_SLOTS.some(slot => Math.abs(localMin - slot) <= MEAL_WINDOW_MIN)
      if (nearSlot) {
        const lastMeal = await this.lastNotification(userId, 'meal')
        const cool = !lastMeal || now.getTime() - lastMeal.getTime() >= MEAL_COOLDOWN_MS
        if (cool) {
          due.push({
            type: 'meal',
            title: '🍽️ Mealtime check-in',
            body: 'Log how you feel and get a healthy meal idea for what you have at home.',
          })
        }
      }
    }

    return due
  }

  /** Computes due reminders, sends them to the user's devices, and logs each. */
  async sendDueReminders(userId: string, now: Date = new Date()) {
    const due = await this.computeDueReminders(userId, now)
    if (due.length === 0) return { sent: 0, reminders: [] as DueReminder[] }

    const tokens = (
      await this.prisma.deviceToken.findMany({ where: { userId }, select: { token: true } })
    ).map(d => d.token)

    for (const r of due) {
      await this.push.send(tokens, { title: r.title, body: r.body }, r.type)
      await this.prisma.notificationLog.create({
        data: { userId, type: r.type, title: r.title, body: r.body },
      })
    }
    return { sent: due.length, reminders: due }
  }

  /** Sends a one-off test notification to all of the user's devices. */
  async sendTest(userId: string) {
    const tokens = (
      await this.prisma.deviceToken.findMany({ where: { userId }, select: { token: true } })
    ).map(d => d.token)

    const message = {
      title: '🔔 MoodFood test notification',
      body: 'Push notifications are working. You will get reminders to drink water and eat well.',
    }
    const result = await this.push.send(tokens, message, 'test')
    await this.prisma.notificationLog.create({
      data: { userId, type: 'test', title: message.title, body: message.body },
    })
    return { ...result, pushEnabled: this.push.enabled }
  }

  private async lastNotification(userId: string, type: string): Promise<Date | null> {
    const last = await this.prisma.notificationLog.findFirst({
      where: { userId, type },
      orderBy: { sentAt: 'desc' },
      select: { sentAt: true },
    })
    return last?.sentAt ?? null
  }
}

// ─── Time helpers ─────────────────────────────────────────────────────────────

/** Minutes since local midnight for a UTC instant + timezone offset. */
export function localMinutesOfDay(date: Date, offsetMin: number): number {
  const local = new Date(date.getTime() + offsetMin * 60_000)
  return local.getUTCHours() * 60 + local.getUTCMinutes()
}

function parseHHmm(s: string): number {
  const [h, m] = s.split(':').map(Number)
  return (h ?? 0) * 60 + (m ?? 0)
}

/** True when localMin is inside [wake, sleep]; handles past-midnight sleep times. */
export function withinWindow(localMin: number, wake: string, sleep: string): boolean {
  const w = parseHHmm(wake)
  const s = parseHHmm(sleep)
  if (s > w) return localMin >= w && localMin <= s
  // Window wraps past midnight (e.g. wake 08:00, sleep 01:00).
  return localMin >= w || localMin <= s
}
