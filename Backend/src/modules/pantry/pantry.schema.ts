import { z } from 'zod'

export const AddIngredientsSchema = z.object({
  ingredients: z
    .array(z.string().min(1).max(200).transform(s => s.toLowerCase().trim()))
    .min(1)
    .max(50),
})

export type AddIngredientsInput = z.infer<typeof AddIngredientsSchema>
