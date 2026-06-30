import { z } from 'zod'

// ─── Log a water intake (Epic 6) ──────────────────────────────────────────────
// amountMl bounded to a sane single-serving range (a sip to a large bottle).

export const LogWaterSchema = z.object({
  amountMl: z.coerce.number().int().min(10).max(3000),
})

// ─── Hydration history ────────────────────────────────────────────────────────

export const WaterHistoryQuerySchema = z.object({
  days: z.coerce.number().int().positive().max(90).default(7),
})

// ─── Update hydration goal / reminder cadence ─────────────────────────────────

export const UpdateWaterGoalSchema = z
  .object({
    waterGoalMl: z.coerce.number().int().min(500).max(8000).optional(),
    waterRemindersOn: z.coerce.boolean().optional(),
    waterIntervalMin: z.coerce.number().int().min(30).max(480).optional(),
    wakeTime: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).optional(),
    sleepTime: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).optional(),
    timezoneOffsetMin: z.coerce.number().int().min(-720).max(840).optional(),
  })
  .refine(d => Object.values(d).some(v => v !== undefined), {
    message: 'Provide at least one field to update',
  })

export type LogWaterInput = z.infer<typeof LogWaterSchema>
export type WaterHistoryQuery = z.infer<typeof WaterHistoryQuerySchema>
export type UpdateWaterGoalInput = z.infer<typeof UpdateWaterGoalSchema>
