import { PrismaClient } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import {
  getOrCreateReminderSetting,
  localDayRange,
  localDateKey,
} from '../../services/reminder-settings'
import { waterLogsTotal } from '../../services/metrics.service'
import type { LogWaterInput, UpdateWaterGoalInput } from './water.schema'

/**
 * WaterService — Epic 6 hydration tracking. Logs intakes, reports the day's
 * progress against the user's goal, and exposes a daily history. Day boundaries
 * honour the user's stored timezone offset so "today" matches their phone.
 */
export class WaterService {
  constructor(private prisma: PrismaClient) {}

  async log(userId: string, input: LogWaterInput) {
    const settings = await getOrCreateReminderSetting(this.prisma, userId)
    await this.prisma.waterLog.create({ data: { userId, amountMl: input.amountMl } })
    waterLogsTotal.inc()
    return this.today(userId, settings.timezoneOffsetMin, settings.waterGoalMl)
  }

  /** Today's total vs goal, plus the individual logs (newest first). */
  async today(userId: string, offsetMin?: number, goalMl?: number) {
    const settings =
      offsetMin === undefined || goalMl === undefined
        ? await getOrCreateReminderSetting(this.prisma, userId)
        : null
    const tz = offsetMin ?? settings!.timezoneOffsetMin
    const goal = goalMl ?? settings!.waterGoalMl

    const { start, end } = localDayRange(tz)
    const logs = await this.prisma.waterLog.findMany({
      where: { userId, createdAt: { gte: start, lt: end } },
      orderBy: { createdAt: 'desc' },
    })

    const totalMl = logs.reduce((sum, l) => sum + l.amountMl, 0)
    const progress = goal > 0 ? Math.min(1, Math.round((totalMl / goal) * 100) / 100) : 1

    return {
      date: localDateKey(start, tz),
      goalMl: goal,
      totalMl,
      remainingMl: Math.max(0, goal - totalMl),
      progress,
      goalReached: totalMl >= goal,
      logs,
    }
  }

  /** Per-day totals for the last `days` days (oldest → newest), goal included. */
  async history(userId: string, days: number) {
    const settings = await getOrCreateReminderSetting(this.prisma, userId)
    const tz = settings.timezoneOffsetMin
    const { start } = localDayRange(tz, days - 1)
    const { end } = localDayRange(tz, 0)

    const logs = await this.prisma.waterLog.findMany({
      where: { userId, createdAt: { gte: start, lt: end } },
      orderBy: { createdAt: 'asc' },
    })

    // Seed every day in the window with 0 so gaps render as empty days.
    const totals = new Map<string, number>()
    for (let d = days - 1; d >= 0; d--) {
      const r = localDayRange(tz, d)
      totals.set(localDateKey(r.start, tz), 0)
    }
    for (const l of logs) {
      const key = localDateKey(l.createdAt, tz)
      if (totals.has(key)) totals.set(key, (totals.get(key) ?? 0) + l.amountMl)
    }

    const goal = settings.waterGoalMl
    return {
      goalMl: goal,
      days: [...totals.entries()].map(([date, totalMl]) => ({
        date,
        totalMl,
        goalReached: totalMl >= goal,
      })),
    }
  }

  async deleteLog(userId: string, id: string) {
    const log = await this.prisma.waterLog.findUnique({ where: { id } })
    if (!log || log.userId !== userId) {
      throw new AppError(404, 'Water log not found', 'WATER_LOG_NOT_FOUND')
    }
    await this.prisma.waterLog.delete({ where: { id } })
    return this.today(userId)
  }

  async getGoal(userId: string) {
    const s = await getOrCreateReminderSetting(this.prisma, userId)
    return {
      waterGoalMl: s.waterGoalMl,
      waterRemindersOn: s.waterRemindersOn,
      waterIntervalMin: s.waterIntervalMin,
      wakeTime: s.wakeTime,
      sleepTime: s.sleepTime,
      timezoneOffsetMin: s.timezoneOffsetMin,
    }
  }

  async updateGoal(userId: string, input: UpdateWaterGoalInput) {
    await getOrCreateReminderSetting(this.prisma, userId)
    await this.prisma.reminderSetting.update({
      where: { userId },
      data: {
        ...(input.waterGoalMl !== undefined && { waterGoalMl: input.waterGoalMl }),
        ...(input.waterRemindersOn !== undefined && { waterRemindersOn: input.waterRemindersOn }),
        ...(input.waterIntervalMin !== undefined && { waterIntervalMin: input.waterIntervalMin }),
        ...(input.wakeTime !== undefined && { wakeTime: input.wakeTime }),
        ...(input.sleepTime !== undefined && { sleepTime: input.sleepTime }),
        ...(input.timezoneOffsetMin !== undefined && { timezoneOffsetMin: input.timezoneOffsetMin }),
      },
    })
    return this.getGoal(userId)
  }
}
