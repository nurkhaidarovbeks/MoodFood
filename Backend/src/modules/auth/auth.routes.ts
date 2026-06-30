import { Router } from 'express'
import rateLimit from 'express-rate-limit'
import prisma from '../../config/database'
import { AuthService } from './auth.service'
import { AuthController } from './auth.controller'
import { validate } from '../../middleware/validate'
import {
  RegisterSchema,
  LoginSchema,
  GoogleAuthSchema,
  ResendVerificationSchema,
  AppleAuthSchema,
  OtpSendSchema,
  OtpVerifySchema,
  ForgotPasswordSchema,
  ResetPasswordSchema,
} from './auth.schema'

const router = Router()
const authService = new AuthService(prisma)
const authController = new AuthController(authService)

// ─── Rate limiters ────────────────────────────────────────────────────────────

// Max 3 OTP send requests per email per 15 minutes
const otpSendLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3,
  keyGenerator: (req) => {
    const email = req.body?.email as string | undefined
    if (email) return email
    return (req.socket.remoteAddress ?? 'unknown').replace(/^::ffff:/, '')
  },
  message: { error: { message: 'Too many OTP requests. Try again in 15 minutes.', code: 'RATE_LIMITED' } },
  standardHeaders: true,
  legacyHeaders: false,
})

// Max 10 OTP verify attempts per IP per 5 minutes
const otpVerifyLimiter = rateLimit({
  windowMs: 5 * 60 * 1000,
  max: 10,
  message: { error: { message: 'Too many verification attempts. Try again in 5 minutes.', code: 'RATE_LIMITED' } },
  standardHeaders: true,
  legacyHeaders: false,
})

// Brute-force guard for credential endpoints — 10 attempts per IP per 15 min.
const credentialsLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: { message: 'Too many attempts. Try again in 15 minutes.', code: 'RATE_LIMITED' } },
  standardHeaders: true,
  legacyHeaders: false,
})

// Max 3 password-reset requests per email per 15 minutes
const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3,
  keyGenerator: (req) => {
    const email = req.body?.email as string | undefined
    if (email) return email
    return (req.socket.remoteAddress ?? 'unknown').replace(/^::ffff:/, '')
  },
  message: { error: { message: 'Too many password reset requests. Try again in 15 minutes.', code: 'RATE_LIMITED' } },
  standardHeaders: true,
  legacyHeaders: false,
})

// ─── Routes ───────────────────────────────────────────────────────────────────

router.post('/register', credentialsLimiter, validate(RegisterSchema), (req, res, next) =>
  authController.register(req, res, next),
)

router.post('/login', credentialsLimiter, validate(LoginSchema), (req, res, next) =>
  authController.login(req, res, next),
)

router.post('/forgot-password', forgotPasswordLimiter, validate(ForgotPasswordSchema), (req, res, next) =>
  authController.forgotPassword(req, res, next),
)

router.post('/reset-password', validate(ResetPasswordSchema), (req, res, next) =>
  authController.resetPassword(req, res, next),
)

router.post('/google', validate(GoogleAuthSchema), (req, res, next) =>
  authController.googleAuth(req, res, next),
)

router.post('/apple', validate(AppleAuthSchema), (req, res, next) =>
  authController.appleAuth(req, res, next),
)

router.post('/otp/send', otpSendLimiter, validate(OtpSendSchema), (req, res, next) =>
  authController.sendOtp(req, res, next),
)

router.post('/otp/verify', otpVerifyLimiter, validate(OtpVerifySchema), (req, res, next) =>
  authController.verifyOtp(req, res, next),
)

router.get('/verify-email', (req, res, next) =>
  authController.verifyEmail(req, res, next),
)

router.post('/resend-verification', validate(ResendVerificationSchema), (req, res, next) =>
  authController.resendVerification(req, res, next),
)

export default router
