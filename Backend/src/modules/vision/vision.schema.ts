import { z } from 'zod'

// Shared image field. imageBase64 may be raw base64 OR a full data URL.
// mimeType is required only for raw base64 (validated again in the service).
const imageFields = {
  imageBase64: z.string().min(100, 'imageBase64 looks too short to be a photo'),
  mimeType: z.enum(['image/jpeg', 'image/png', 'image/webp']).optional(),
}

// POST /vision/ingredients — extract only.
export const VisionExtractSchema = z.object({
  ...imageFields,
  // Items below this confidence are returned but flagged as low-confidence.
  minConfidence: z.coerce.number().min(0).max(1).default(0.4),
})

// POST /vision/recommendations — photo → extract → 3 dishes.
// Includes the same mood/budget/time signals as the text recommendation flow
// (useMyIngredients is intentionally omitted — the photo IS the ingredient source).
export const VisionRecommendSchema = z.object({
  ...imageFields,
  minConfidence: z.coerce.number().min(0).max(1).default(0.4),
  mood: z.string().max(50).optional(),
  energyLevel: z.coerce.number().int().min(1).max(5).optional(),
  stressLevel: z.enum(['low', 'medium', 'high']).optional(),
  sleepQuality: z.enum(['poor', 'normal', 'good']).optional(),
  hungerLevel: z.enum(['low', 'medium', 'high']).optional(),
  budgetLevel: z.enum(['low', 'medium', 'high']).optional(),
  maxCookingTime: z.coerce.number().int().positive().max(240).optional(),
})

export type VisionExtractInput = z.infer<typeof VisionExtractSchema>
export type VisionRecommendInput = z.infer<typeof VisionRecommendSchema>
