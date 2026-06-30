/**
 * WaterService tests (Epic 6) — logging, today's progress, history, delete,
 * and goal updates. Day windows use timezoneOffsetMin = 0 for determinism.
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { WaterService } from '../src/modules/water/water.service'

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

const todayLog = (amountMl: number) => ({
  id: 'wl-1',
  userId: 'user-1',
  amountMl,
  createdAt: new Date(),
})

let service: WaterService

beforeEach(() => {
  mockReset(prismaMock)
  service = new WaterService(prismaMock as any)
  prismaMock.reminderSetting.findUnique.mockResolvedValue(settings as any)
})

describe('log', () => {
  it('records an intake and returns today\'s progress vs goal', async () => {
    prismaMock.waterLog.create.mockResolvedValueOnce(todayLog(250) as any)
    prismaMock.waterLog.findMany.mockResolvedValueOnce([todayLog(250)] as any)

    const result = await service.log('user-1', { amountMl: 250 })

    expect(prismaMock.waterLog.create).toHaveBeenCalledWith({
      data: { userId: 'user-1', amountMl: 250 },
    })
    expect(result.totalMl).toBe(250)
    expect(result.goalMl).toBe(2000)
    expect(result.remainingMl).toBe(1750)
    expect(result.goalReached).toBe(false)
    expect(result.progress).toBeCloseTo(0.13, 2)
  })
})

describe('today', () => {
  it('marks the goal reached once total >= goal', async () => {
    prismaMock.waterLog.findMany.mockResolvedValueOnce([todayLog(1500), todayLog(700)] as any)

    const result = await service.today('user-1')

    expect(result.totalMl).toBe(2200)
    expect(result.goalReached).toBe(true)
    expect(result.remainingMl).toBe(0)
    expect(result.progress).toBe(1)
  })
})

describe('history', () => {
  it('returns one bucket per day with zero-filled gaps', async () => {
    prismaMock.waterLog.findMany.mockResolvedValueOnce([todayLog(500)] as any)

    const result = await service.history('user-1', 7)

    expect(result.days).toHaveLength(7)
    expect(result.goalMl).toBe(2000)
    // Every entry has a date + totalMl
    for (const d of result.days) {
      expect(typeof d.date).toBe('string')
      expect(typeof d.totalMl).toBe('number')
    }
  })
})

describe('deleteLog', () => {
  it('removes the user\'s own log', async () => {
    prismaMock.waterLog.findUnique.mockResolvedValueOnce(todayLog(250) as any)
    prismaMock.waterLog.delete.mockResolvedValueOnce(todayLog(250) as any)
    prismaMock.waterLog.findMany.mockResolvedValueOnce([] as any)

    const result = await service.deleteLog('user-1', 'wl-1')
    expect(prismaMock.waterLog.delete).toHaveBeenCalledWith({ where: { id: 'wl-1' } })
    expect(result.totalMl).toBe(0)
  })

  it('throws 404 for a log owned by someone else', async () => {
    prismaMock.waterLog.findUnique.mockResolvedValueOnce({ ...todayLog(250), userId: 'other' } as any)

    await expect(service.deleteLog('user-1', 'wl-1')).rejects.toMatchObject({
      statusCode: 404,
      code: 'WATER_LOG_NOT_FOUND',
    })
  })
})

describe('updateGoal', () => {
  it('updates only the provided fields', async () => {
    prismaMock.reminderSetting.update.mockResolvedValueOnce({ ...settings, waterGoalMl: 2500 } as any)
    prismaMock.reminderSetting.findUnique.mockResolvedValue({ ...settings, waterGoalMl: 2500 } as any)

    const result = await service.updateGoal('user-1', { waterGoalMl: 2500 })

    const arg = prismaMock.reminderSetting.update.mock.calls[0]![0] as any
    expect(arg.data).toEqual({ waterGoalMl: 2500 })
    expect(result.waterGoalMl).toBe(2500)
  })
})
