import { z } from 'zod'

export const TopupSchema = z.object({
  amount: z.number().positive('Amount must be positive'),
  gateway: z.enum(['bereke', 'paypal']).default('bereke'),
})

export const WalletTransactionsQuerySchema = z.object({
  limit:  z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
})

export type TopupInput = z.infer<typeof TopupSchema>
