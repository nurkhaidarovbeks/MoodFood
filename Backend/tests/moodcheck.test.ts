/**
 * MoodCheckService tests (Epic 2) — create, history pagination, latest.
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { MoodCheckService } from '../src/modules/moodcheck/moodcheck.service'

const sample = {
  id: 'mc-1',
  userId: 'user-1',
  mood: 'tired',
  energyLevel: 2,
  stressLevel: 'high',
  sleepQuality: 'poor',
  hungerLevel: 'high',
  createdAt: new Date('2026-06-19T08:00:00Z'),
}

let service: MoodCheckService

beforeEach(() => {
  mockReset(prismaMock)
  service = new MoodCheckService(prismaMock as any)
  prismaMock.$transaction.mockImplementation((ops: any) =>
    Array.isArray(ops) ? Promise.all(ops) : ops,
  )
})

describe('create', () => {
  it('persists a check-in for the user with null-filled missing fields', async () => {
    prismaMock.moodCheck.create.mockResolvedValueOnce(sample as any)

    const result = await service.create('user-1', { mood: 'tired', energyLevel: 2 })

    expect(result.id).toBe('mc-1')
    const arg = prismaMock.moodCheck.create.mock.calls[0]![0] as any
    expect(arg.data.userId).toBe('user-1')
    expect(arg.data.mood).toBe('tired')
    expect(arg.data.energyLevel).toBe(2)
    // unspecified fields are stored as null, not undefined
    expect(arg.data.stressLevel).toBeNull()
    expect(arg.data.sleepQuality).toBeNull()
    expect(arg.data.hungerLevel).toBeNull()
  })
})

describe('history', () => {
  it('returns newest-first entries with total and pagination', async () => {
    prismaMock.moodCheck.findMany.mockResolvedValueOnce([sample] as any)
    prismaMock.moodCheck.count.mockResolvedValueOnce(5)

    const result = await service.history('user-1', { limit: 20, offset: 0 })

    expect(result.moodChecks).toHaveLength(1)
    expect(result.total).toBe(5)
    expect(result.limit).toBe(20)
    expect(result.offset).toBe(0)

    const call = prismaMock.moodCheck.findMany.mock.calls[0]![0] as any
    expect(call.where).toEqual({ userId: 'user-1' })
    expect(call.orderBy).toEqual({ createdAt: 'desc' })
    expect(call.skip).toBe(0)
    expect(call.take).toBe(20)
  })

  it('respects limit and offset', async () => {
    prismaMock.moodCheck.findMany.mockResolvedValueOnce([] as any)
    prismaMock.moodCheck.count.mockResolvedValueOnce(0)

    await service.history('user-1', { limit: 5, offset: 10 })

    const call = prismaMock.moodCheck.findMany.mock.calls[0]![0] as any
    expect(call.skip).toBe(10)
    expect(call.take).toBe(5)
  })
})

describe('latest', () => {
  it('returns the most recent check-in', async () => {
    prismaMock.moodCheck.findFirst.mockResolvedValueOnce(sample as any)

    const result = await service.latest('user-1')

    expect(result?.id).toBe('mc-1')
    const call = prismaMock.moodCheck.findFirst.mock.calls[0]![0] as any
    expect(call.where).toEqual({ userId: 'user-1' })
    expect(call.orderBy).toEqual({ createdAt: 'desc' })
  })

  it('returns null when the user has no check-ins', async () => {
    prismaMock.moodCheck.findFirst.mockResolvedValueOnce(null)
    expect(await service.latest('user-1')).toBeNull()
  })
})
