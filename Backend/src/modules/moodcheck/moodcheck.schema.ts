import { z } from 'zod'

// ─── Create a mood-check (Epic 2 state check-in) ──────────────────────────────
// All fields optional, but at least one must be provided — an empty check-in
// carries no signal.

export const CreateMoodCheckSchema = z
  .object({
    mood: z.string().min(1).max(50).optional(),
    energyLevel: z.coerce.number().int().min(1).max(5).optional(),
    stressLevel: z.enum(['low', 'medium', 'high']).optional(),
    sleepQuality: z.enum(['poor', 'normal', 'good']).optional(),
    hungerLevel: z.enum(['low', 'medium', 'high']).optional(),
  })
  .refine(data => Object.values(data).some(v => v !== undefined), {
    message: 'Provide at least one of: mood, energyLevel, stressLevel, sleepQuality, hungerLevel',
  })

// ─── History pagination ────────────────────────────────────────────────────────

export const MoodCheckHistoryQuerySchema = z.object({
  limit: z.coerce.number().int().positive().max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
})

export type CreateMoodCheckInput = z.infer<typeof CreateMoodCheckSchema>
export type MoodCheckHistoryQuery = z.infer<typeof MoodCheckHistoryQuerySchema>
