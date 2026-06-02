import { z } from 'zod'

export const RegisterSchema = z.object({
  email: z
    .string({ required_error: 'Email is required' })
    .email('Invalid email address')
    .toLowerCase()
    .trim(),
  password: z
    .string({ required_error: 'Password is required' })
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password must be at most 128 characters'),
  name: z.string().min(1).max(100).trim().optional(),
})

export const LoginSchema = z.object({
  email: z
    .string({ required_error: 'Email is required' })
    .email('Invalid email address')
    .toLowerCase()
    .trim(),
  password: z.string({ required_error: 'Password is required' }).min(1),
})

export const GoogleAuthSchema = z.object({
  idToken: z.string({ required_error: 'Google ID token is required' }).min(1),
})

export const ResendVerificationSchema = z.object({
  email: z.string().email('Invalid email address').toLowerCase().trim(),
})

export const AppleAuthSchema = z.object({
  idToken: z.string({ required_error: 'Apple ID token is required' }).min(1),
  // Apple sends the user's name only on the very first login — optional thereafter
  name: z.string().min(1).max(100).trim().optional(),
})

export const OtpSendSchema = z.object({
  email: z
    .string({ required_error: 'Email is required' })
    .email('Invalid email address')
    .toLowerCase()
    .trim(),
})

export const OtpVerifySchema = z.object({
  email: z
    .string({ required_error: 'Email is required' })
    .email('Invalid email address')
    .toLowerCase()
    .trim(),
  code: z
    .string({ required_error: 'OTP code is required' })
    .length(6, 'OTP must be exactly 6 digits')
    .regex(/^\d{6}$/, 'OTP must contain only digits'),
})

export type RegisterInput = z.infer<typeof RegisterSchema>
export type LoginInput = z.infer<typeof LoginSchema>
export type GoogleAuthInput = z.infer<typeof GoogleAuthSchema>
export type AppleAuthInput = z.infer<typeof AppleAuthSchema>
export type OtpSendInput = z.infer<typeof OtpSendSchema>
export type OtpVerifyInput = z.infer<typeof OtpVerifySchema>
