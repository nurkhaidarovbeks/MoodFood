/**
 * InsightsService tests (Epic 7) — weekly habit aggregation + rule-based tips.
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { InsightsService } from '../src/modules/insights/insights.service'

const settings = {
  id: 'rs-1',
  userId: 'user-1',
  waterGoalMl: 2000,
  waterRemindersOn: true,
  waterIntervalMin: 120,
  mealRemindersOn: false,
  wakeTime: '08:00',
  sleepTime: '23:00',
  timezoneOffsetMin: 0,
  createdAt: new Date(),
  updatedAt: new Date(),
}

const mood = (over: Partial<{ mood: string; energyLevel: number; stressLevel: string; sleepQuality: string }>) => ({
  id: 'm',
  userId: 'user-1',
  mood: over.mood ?? null,
  energyLevel: over.energyLevel ?? null,
  stressLevel: over.stressLevel ?? null,
  sleepQuality: over.sleepQuality ?? null,
  createdAt: new Date(),
})

let service: InsightsService

beforeEach(() => {
  mockReset(prismaMock)
  service = new InsightsService(prismaMock as any)
  prismaMock.reminderSetting.findUnique.mockResolvedValue(settings as any)
})

describe('weekly', () => {
  it('aggregates mood + hydration and surfaces a low-energy tip', async () => {
    prismaMock.moodCheck.findMany.mockResolvedValueOnce([
      mood({ mood: 'tired', energyLevel: 2, stressLevel: 'high' }),
      mood({ mood: 'tired', energyLevel: 1, stressLevel: 'high' }),
      mood({ mood: 'calm', energyLevel: 3 }),
    ] as any)
    prismaMock.waterLog.findMany.mockResolvedValueOnce([] as any) // no hydration

    const result = await service.weekly('user-1', 7)

    expect(result.moodCheckIns).toBe(3)
    expect(result.dominantMood).toBe('tired')
    expect(result.avgEnergy).toBeCloseTo(2, 1)
    expect(result.hydration.adherence).toBe(0)
    // low energy + high stress + poor hydration → at least 2 tips
    expect(result.tips.length).toBeGreaterThanOrEqual(2)
    expect(result.tips.join(' ').toLowerCase()).toContain('energy')
  })

  it('returns an encouraging tip when habits look balanced', async () => {
    prismaMock.moodCheck.findMany.mockResolvedValueOnce([
      mood({ mood: 'happy', energyLevel: 4 }),
      mood({ mood: 'happy', energyLevel: 5 }),
      mood({ mood: 'focused', energyLevel: 4 }),
      mood({ mood: 'calm', energyLevel: 4 }),
    ] as any)
    // 7 days all hitting goal
    const logs = Array.from({ length: 7 }, (_, i) => ({
      id: `w${i}`,
      userId: 'user-1',
      amountMl: 2100,
      createdAt: new Date(Date.now() - i * 24 * 60 * 60 * 1000),
    }))
    prismaMock.waterLog.findMany.mockResolvedValueOnce(logs as any)

    const result = await service.weekly('user-1', 7)
    expect(result.avgEnergy).toBeGreaterThanOrEqual(4)
    expect(result.tips.length).toBeGreaterThanOrEqual(1)
  })
})

describe('tips', () => {
  it('returns only the tips array', async () => {
    prismaMock.moodCheck.findMany.mockResolvedValueOnce([] as any)
    prismaMock.waterLog.findMany.mockResolvedValueOnce([] as any)

    const result = await service.tips('user-1', 7)
    expect(Array.isArray(result.tips)).toBe(true)
    expect(Object.keys(result)).toEqual(['tips'])
  })
})
