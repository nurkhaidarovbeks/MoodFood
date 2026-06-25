import { z } from 'zod'

export const CheckoutSchema = z.object({
  amount: z.number().positive('Amount must be positive'),
  description: z.string().min(1).max(200).optional(),
  gateway: z.enum(['paypal']).default('paypal'),
  orderType: z.enum(['purchase', 'topup', 'subscription']).default('purchase'),
})

export const PaypalSuccessQuerySchema = z.object({
  token: z.string().min(1),
})

export const BereSuccessQuerySchema = z.object({
  orderId: z.string().min(1),
})

export const RefundSchema = z.object({
  amount: z.number().positive().optional(),
})

export type CheckoutInput = z.input<typeof CheckoutSchema>
export type RefundInput = z.infer<typeof RefundSchema>
