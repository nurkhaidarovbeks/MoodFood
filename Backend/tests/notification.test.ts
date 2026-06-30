/**
 * NotificationService + PushService tests — device registry, reminder
 * computation (water/meal due logic), window helpers, and the offline push
 * no-op path (no FCM_SERVER_KEY in the test env).
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import {
  NotificationService,
  withinWindow,
  localMinutesOfDay,
} from '../src/modules/notifications/notification.service'
import { PushService } from '../src/services/push.service'

const baseSettings = {
  id: 'rs-1',
  userId: 'user-1',
  waterGoalMl: 2000,
  waterRemindersOn: true,
  waterIntervalMin: 1,
  mealRemindersOn: false,
  wakeTime: '00:00',
  sleepTime: '23:59',
  timezoneOffsetMin: 0,
  createdAt: new Date(),
  updatedAt: new Date(),
}

let push: PushService
let service: NotificationService

beforeEach(() => {
  mockReset(prismaMock)
  push = new PushService({ serverKey: '' }) // disabled → no-op
  service = new NotificationService(prismaMock as any, push)
})

// ─── Pure time helpers ────────────────────────────────────────────────────────

describe('time helpers', () => {
  it('withinWindow handles normal and past-midnight windows', () => {
    expect(withinWindow(12 * 60, '08:00', '23:00')).toBe(true)
    expect(withinWindow(6 * 60, '08:00', '23:00')).toBe(false)
    // wraps midnight: awake 08:00 → 01:00
    expect(withinWindow(0 * 60 + 30, '08:00', '01:00')).toBe(true)
    expect(withinWindow(3 * 60, '08:00', '01:00')).toBe(false)
  })

  it('localMinutesOfDay applies the timezone offset', () => {
    const noonUtc = new Date('2026-07-01T12:00:00Z')
    expect(localMinutesOfDay(noonUtc, 0)).toBe(12 * 60)
    expect(localMinutesOfDay(noonUtc, 60)).toBe(13 * 60) // +1h
  })
})

// ─── Device registry ──────────────────────────────────────────────────────────

describe('registerDevice', () => {
  it('upserts the token under the user', async () => {
    prismaMock.deviceToken.upsert.mockResolvedValueOnce({
      id: 'd-1',
      platform: 'android',
    } as any)

    const result = await service.registerDevice('user-1', { token: 'tok-123456789', platform: 'android' })
    expect(result.registered).toBe(true)
    expect(prismaMock.deviceToken.upsert).toHaveBeenCalled()
  })
})

// ─── Reminder computation ─────────────────────────────────────────────────────

describe('computeDueReminders', () => {
  it('returns a water reminder when overdue and goal not reached', async () => {
    prismaMock.reminderSetting.findUnique.mockResolvedValueOnce(baseSettings as any)
    prismaMock.waterLog.findMany.mockResolvedValueOnce([] as any) // nothing drunk yet
    prismaMock.notificationLog.findFirst.mockResolvedValueOnce(null) // never reminded

    const due = await service.computeDueReminders('user-1')
    expect(due.some(d => d.type === 'water')).toBe(true)
  })

  it('does not remind about water once the goal is reached', async () => {
    prismaMock.reminderSetting.findUnique.mockResolvedValueOnce(baseSettings as any)
    prismaMock.waterLog.findMany.mockResolvedValueOnce([
      { id: 'w', userId: 'user-1', amountMl: 2200, createdAt: new Date() },
    ] as any)
    prismaMock.notificationLog.findFirst.mockResolvedValueOnce(null)

    const due = await service.computeDueReminders('user-1')
    expect(due.some(d => d.type === 'water')).toBe(false)
  })

  it('returns nothing outside the waking window', async () => {
    // Awake only 08:00–09:00; a 10:00 call is outside the window.
    prismaMock.reminderSetting.findUnique.mockResolvedValueOnce({
      ...baseSettings,
      wakeTime: '08:00',
      sleepTime: '09:00',
    } as any)

    const now = new Date()
    now.setUTCHours(10, 0, 0, 0) // 10:00 UTC, offset 0 → outside 08:00–09:00
    const due = await service.computeDueReminders('user-1', now)
    expect(due).toHaveLength(0)
  })
})

// ─── Test push (offline no-op) ────────────────────────────────────────────────

describe('sendTest', () => {
  it('reports push disabled and still logs the notification', async () => {
    prismaMock.deviceToken.findMany.mockResolvedValueOnce([{ token: 't1' }] as any)
    prismaMock.notificationLog.create.mockResolvedValueOnce({} as any)

    const result = await service.sendTest('user-1')
    expect(result.pushEnabled).toBe(false)
    expect(result.providerConfigured).toBe(false)
    expect(result.tokens).toBe(1)
    expect(prismaMock.notificationLog.create).toHaveBeenCalled()
  })
})

describe('PushService', () => {
  it('no-ops when no server key is configured', async () => {
    const p = new PushService({ serverKey: '' })
    expect(p.enabled).toBe(false)
    const r = await p.send(['t1', 't2'], { title: 'hi', body: 'there' }, 'test')
    expect(r.providerConfigured).toBe(false)
    expect(r.delivered).toBe(false)
    expect(r.tokens).toBe(2)
  })

  it('skips cleanly with no tokens', async () => {
    const p = new PushService({ serverKey: 'fake-key' })
    const r = await p.send([], { title: 'hi', body: 'there' })
    expect(r.tokens).toBe(0)
    expect(r.delivered).toBe(false)
  })
})
