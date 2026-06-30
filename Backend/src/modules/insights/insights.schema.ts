import { z } from 'zod'

// ─── Weekly insights window ───────────────────────────────────────────────────

export const InsightsQuerySchema = z.object({
  days: z.coerce.number().int().min(3).max(31).default(7),
})

export type InsightsQuery = z.infer<typeof InsightsQuerySchema>
