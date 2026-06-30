import { z } from 'zod'

// ─── Register / remove a device push token ────────────────────────────────────

export const RegisterDeviceSchema = z.object({
  token: z.string().min(10).max(4096),
  platform: z.enum(['android', 'ios', 'web']).default('android'),
})

// ─── Update notification preferences ──────────────────────────────────────────

export const UpdatePreferencesSchema = z
  .object({
    waterRemindersOn: z.coerce.boolean().optional(),
    waterIntervalMin: z.coerce.number().int().min(30).max(480).optional(),
    mealRemindersOn: z.coerce.boolean().optional(),
    wakeTime: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).optional(),
    sleepTime: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/).optional(),
    timezoneOffsetMin: z.coerce.number().int().min(-720).max(840).optional(),
  })
  .refine(d => Object.values(d).some(v => v !== undefined), {
    message: 'Provide at least one field to update',
  })

export const NotificationHistoryQuerySchema = z.object({
  limit: z.coerce.number().int().positive().max(100).default(20),
})

export type RegisterDeviceInput = z.infer<typeof RegisterDeviceSchema>
export type UpdatePreferencesInput = z.infer<typeof UpdatePreferencesSchema>
export type NotificationHistoryQuery = z.infer<typeof NotificationHistoryQuerySchema>
