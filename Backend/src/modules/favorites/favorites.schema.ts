import { z } from 'zod'

export const FavoriteAddSchema = z.object({
  recipeId: z.string().uuid(),
})

export const FavoritesQuerySchema = z.object({
  limit: z.coerce.number().int().positive().max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
})

export type FavoriteAddInput = z.infer<typeof FavoriteAddSchema>
export type FavoritesQueryInput = z.infer<typeof FavoritesQuerySchema>
