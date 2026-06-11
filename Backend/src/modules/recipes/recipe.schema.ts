import { z } from 'zod'

// ─── Ingredient input (nested inside recipe create/update) ────────────────────

const IngredientInputSchema = z.object({
  name: z.string().min(1).max(200),
  category: z.string().max(100).optional(),
  amount: z.string().max(50).optional(),
  unit: z.string().max(50).optional(),
})

// ─── Create / full replace ────────────────────────────────────────────────────

export const RecipeCreateSchema = z.object({
  title: z.string().min(1).max(200),
  cookingTimeMin: z.number().int().positive().optional(),
  difficulty: z.enum(['easy', 'medium', 'hard']).optional(),
  estimatedCost: z.number().positive().optional(),
  calories: z.number().positive().optional(),
  proteinG: z.number().positive().optional(),
  steps: z.string().optional(),
  moodTags: z.array(z.string().min(1)).default([]),
  ingredients: z.array(IngredientInputSchema).default([]),
})

// ─── Partial update ────────────────────────────────────────────────────────────

export const RecipePatchSchema = RecipeCreateSchema.partial()

// ─── Query params for list / recommendations ──────────────────────────────────

export const RecipeQuerySchema = z.object({
  mood: z.string().optional(),
  limit: z.coerce.number().int().positive().max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
  // Ingredient matching — only used in /recommendations
  useMyIngredients: z.coerce.boolean().default(false),
  minMatchScore: z.coerce.number().min(0).max(1).default(0),
})

// ─── Types ─────────────────────────────────────────────────────────────────────

export type RecipeCreateInput = z.infer<typeof RecipeCreateSchema>
export type RecipePatchInput = z.infer<typeof RecipePatchSchema>
export type RecipeQueryInput = z.infer<typeof RecipeQuerySchema>
