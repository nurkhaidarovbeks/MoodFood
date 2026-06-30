import { PrismaClient } from '@prisma/client'
import {
  getOrCreateReminderSetting,
  localDayRange,
  localDateKey,
} from '../../services/reminder-settings'

/**
 * InsightsService — Epic 7 habit analytics. Aggregates the user's mood check-ins
 * and hydration over a rolling window into a weekly summary plus actionable,
 * rule-based tips. Everything is derived from data already captured by Epics 2
 * and 6 — no new tracking is required.
 */
export class InsightsService {
  constructor(private prisma: PrismaClient) {}

  async weekly(userId: string, days: number) {
    const settings = await getOrCreateReminderSetting(this.prisma, userId)
    const tz = settings.timezoneOffsetMin
    const goalMl = settings.waterGoalMl

    const windowStart = localDayRange(tz, days - 1).start
    const windowEnd = localDayRange(tz, 0).end

    const [moodChecks, waterLogs] = await Promise.all([
      this.prisma.moodCheck.findMany({
        where: { userId, createdAt: { gte: windowStart, lt: windowEnd } },
        orderBy: { createdAt: 'asc' },
      }),
      this.prisma.waterLog.findMany({
        where: { userId, createdAt: { gte: windowStart, lt: windowEnd } },
        orderBy: { createdAt: 'asc' },
      }),
    ])

    const mood = this.summariseMood(moodChecks)
    const hydration = this.summariseHydration(waterLogs, days, tz, goalMl)
    const checkInDays = new Set(moodChecks.map(m => localDateKey(m.createdAt, tz)))

    const summary = {
      periodDays: days,
      moodCheckIns: moodChecks.length,
      daysWithCheckIn: checkInDays.size,
      checkInRate: Math.round((checkInDays.size / days) * 100) / 100,
      avgEnergy: mood.avgEnergy,
      dominantMood: mood.dominantMood,
      moodCounts: mood.moodCounts,
      stressCounts: mood.stressCounts,
      poorSleepDays: mood.poorSleepCount,
      hydration,
    }

    return { ...summary, tips: this.buildTips(mood, hydration, checkInDays.size, days) }
  }

  async tips(userId: string, days: number) {
    const full = await this.weekly(userId, days)
    return { tips: full.tips }
  }

  // ─── Aggregation ────────────────────────────────────────────────────────────

  private summariseMood(checks: Array<{
    mood: string | null
    energyLevel: number | null
    stressLevel: string | null
    sleepQuality: string | null
  }>) {
    const moodCounts: Record<string, number> = {}
    const stressCounts: Record<string, number> = {}
    let energySum = 0
    let energyN = 0
    let poorSleepCount = 0

    for (const c of checks) {
      if (c.mood) moodCounts[c.mood] = (moodCounts[c.mood] ?? 0) + 1
      if (c.stressLevel) stressCounts[c.stressLevel] = (stressCounts[c.stressLevel] ?? 0) + 1
      if (typeof c.energyLevel === 'number') {
        energySum += c.energyLevel
        energyN++
      }
      if (c.sleepQuality === 'poor') poorSleepCount++
    }

    const dominantMood =
      Object.entries(moodCounts).sort((a, b) => b[1] - a[1])[0]?.[0] ?? null
    const avgEnergy = energyN > 0 ? Math.round((energySum / energyN) * 10) / 10 : null

    return { moodCounts, stressCounts, avgEnergy, dominantMood, poorSleepCount }
  }

  private summariseHydration(
    logs: Array<{ amountMl: number; createdAt: Date }>,
    days: number,
    tz: number,
    goalMl: number,
  ) {
    const perDay = new Map<string, number>()
    for (let d = days - 1; d >= 0; d--) {
      perDay.set(localDateKey(localDayRange(tz, d).start, tz), 0)
    }
    for (const l of logs) {
      const key = localDateKey(l.createdAt, tz)
      if (perDay.has(key)) perDay.set(key, (perDay.get(key) ?? 0) + l.amountMl)
    }

    const totals = [...perDay.values()]
    const goalReachedDays = totals.filter(t => t >= goalMl).length
    const totalMl = totals.reduce((a, b) => a + b, 0)

    return {
      goalMl,
      avgDailyMl: Math.round(totalMl / days),
      goalReachedDays,
      adherence: Math.round((goalReachedDays / days) * 100) / 100,
    }
  }

  // ─── Rule-based tips ──────────────────────────────────────────────────────────

  private buildTips(
    mood: { avgEnergy: number | null; stressCounts: Record<string, number>; poorSleepCount: number },
    hydration: { adherence: number; avgDailyMl: number; goalMl: number },
    daysWithCheckIn: number,
    days: number,
  ): string[] {
    const tips: string[] = []

    if (mood.avgEnergy !== null && mood.avgEnergy <= 2.5) {
      tips.push(
        'Your energy has been low this week. Lean on protein + complex carbs (eggs & oats, chicken & rice, lentils) and go easy on sugary quick fixes.',
      )
    }
    const highStress = mood.stressCounts['high'] ?? 0
    if (highStress >= 2) {
      tips.push(
        'Several high-stress check-ins. Favour simple, warm, balanced meals (soups, stews, rice bowls) and keep portions moderate.',
      )
    }
    if (mood.poorSleepCount >= 2) {
      tips.push(
        'Poor sleep showed up more than once. Keep dinners lighter (≤450 kcal) and avoid heavy, greasy meals late in the evening.',
      )
    }
    if (hydration.adherence < 0.5) {
      tips.push(
        `You hit your water goal on less than half the days (avg ${hydration.avgDailyMl} ml/day). Turn on water reminders and keep a bottle in sight.`,
      )
    } else if (hydration.adherence >= 0.8) {
      tips.push('Great hydration consistency this week — keep it up! 💧')
    }
    if (daysWithCheckIn < Math.ceil(days / 2)) {
      tips.push(
        'Checking in daily makes recommendations sharper. Try a quick mood check each morning.',
      )
    }
    if (tips.length === 0) {
      tips.push('You\'re tracking well and your habits look balanced. Keep the streak going! 🎉')
    }
    return tips
  }
}
