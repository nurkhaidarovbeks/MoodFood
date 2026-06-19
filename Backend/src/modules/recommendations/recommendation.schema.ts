import { z } from 'zod'

// ─── Mood-check → recommendation request ──────────────────────────────────────
//
// All fields optional: the more signals the user provides, the better the fit.
// `budgetLevel` overrides the profile's budget for this request only.

export const RecommendationRequestSchema = z.object({
  mood: z.string().max(50).optional(),
  energyLevel: z.coerce.number().int().min(1).max(5).optional(),
  stressLevel: z.enum(['low', 'medium', 'high']).optional(),
  sleepQuality: z.enum(['poor', 'normal', 'good']).optional(),
  hungerLevel: z.enum(['low', 'medium', 'high']).optional(),
  budgetLevel: z.enum(['low', 'medium', 'high']).optional(),
  // Only quick recipes — filter to ≤ N minutes (Epic 4: "Filter by 10–20 min").
  maxCookingTime: z.coerce.number().int().positive().max(240).optional(),
  // Match against the user's pantry and surface missing-ingredient substitutions.
  useMyIngredients: z.coerce.boolean().default(false),
})

export type RecommendationRequestInput = z.infer<typeof RecommendationRequestSchema>
