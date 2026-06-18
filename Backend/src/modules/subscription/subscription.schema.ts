import { z } from 'zod'

export const SubscribeSchema = z.object({
  planType: z.enum(['monthly', 'annual']),
  gateway:  z.enum(['bereke', 'paypal']).default('bereke'),
})

export type SubscribeInput = z.infer<typeof SubscribeSchema>
