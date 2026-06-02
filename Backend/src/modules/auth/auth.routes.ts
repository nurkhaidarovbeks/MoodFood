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
} from './auth.schema'

const router = Router()
const authService = new AuthService(prisma)
const authController = new AuthController(authService)

// ─── Rate limiters ────────────────────────────────────────────────────────────

// Max 3 OTP send requests per email per 15 minutes
const otpSendLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3,
  keyGenerator: (req) => (req.body?.email as string | undefined) ?? req.ip ?? 'unknown',
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

// ─── Routes ───────────────────────────────────────────────────────────────────

router.post('/register', validate(RegisterSchema), (req, res, next) =>
  authController.register(req, res, next),
)

router.post('/login', validate(LoginSchema), (req, res, next) =>
  authController.login(req, res, next),
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
