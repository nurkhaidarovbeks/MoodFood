import bcrypt from 'bcrypt'
import crypto from 'crypto'
import { PrismaClient } from '@prisma/client'
import { signToken } from '../../utils/jwt'
import { generateToken, sha256 } from '../../utils/hash'
import { isProfileComplete } from '../../utils/profile-completion'
import { sendVerificationEmail, sendOtpEmail } from '../../services/email.service'
import { verifyGoogleIdToken } from '../../services/google-oauth.service'
import { verifyAppleIdToken } from '../../services/apple-auth.service'
import { AppError } from '../../middleware/errorHandler'
import { env } from '../../config/env'
import type { RegisterInput, LoginInput, GoogleAuthInput, AppleAuthInput, OtpVerifyInput } from './auth.schema'

const BCRYPT_ROUNDS = 12
const VERIFICATION_EXPIRES_HOURS = 24
const OTP_EXPIRES_MS = 5 * 60 * 1000   // 5 minutes
const OTP_MAX_ATTEMPTS = 3
const OTP_RESEND_COOLDOWN_MS = 60 * 1000  // 1 minute between resends

function generateOtp(): string {
  // Cryptographically secure: take 4 random bytes, mod 1_000_000, pad to 6 digits
  const num = crypto.randomBytes(4).readUInt32BE(0) % 1_000_000
  return num.toString().padStart(6, '0')
}

// Shape returned to the client — never include passwordHash or verification tokens
function buildUserResponse(user: {
  id: string
  email: string
  name: string | null
  authProvider: string
  isEmailVerified: boolean
}, profile: Parameters<typeof isProfileComplete>[0]) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    authProvider: user.authProvider,
    isEmailVerified: user.isEmailVerified,
    isProfileComplete: isProfileComplete(profile),
  }
}

export class AuthService {
  constructor(private prisma: PrismaClient) {}

  async register(input: RegisterInput) {
    const existing = await this.prisma.user.findUnique({ where: { email: input.email } })
    if (existing) throw new AppError(409, 'Email is already registered', 'EMAIL_EXISTS')

    const passwordHash = await bcrypt.hash(input.password, BCRYPT_ROUNDS)

    // Generate verification token upfront so we can pass the hash into the DB create call
    let rawVerificationToken: string | null = null
    let emailVerificationToken: string | null = null
    let emailVerificationExpires: Date | null = null

    if (env.REQUIRE_EMAIL_VERIFICATION) {
      rawVerificationToken = generateToken()
      emailVerificationToken = sha256(rawVerificationToken) // only the hash is ever stored
      emailVerificationExpires = new Date(Date.now() + VERIFICATION_EXPIRES_HOURS * 3_600_000)
    }

    const user = await this.prisma.user.create({
      data: {
        email: input.email,
        passwordHash,
        name: input.name ?? null,
        authProvider: 'email',
        isEmailVerified: !env.REQUIRE_EMAIL_VERIFICATION,
        emailVerificationToken,
        emailVerificationExpires,
        profile: {
          create: {
            dietaryRestrictions: [],
            allergies: [],
            customRestrictions: [],
          },
        },
      },
      include: { profile: true },
    })

    if (env.REQUIRE_EMAIL_VERIFICATION && rawVerificationToken) {
      await sendVerificationEmail(user.email, rawVerificationToken)
    }

    const token = signToken({ userId: user.id, email: user.email })

    return {
      user: buildUserResponse(user, user.profile),
      token,
      requiresEmailVerification: env.REQUIRE_EMAIL_VERIFICATION,
    }
  }

  async login(input: LoginInput) {
    const user = await this.prisma.user.findUnique({
      where: { email: input.email },
      include: { profile: true },
    })

    if (!user || !user.passwordHash) {
      throw new AppError(401, 'Invalid email or password', 'INVALID_CREDENTIALS')
    }

    if (!user.isActive) {
      throw new AppError(403, 'Account is deactivated', 'ACCOUNT_INACTIVE')
    }

    const passwordMatch = await bcrypt.compare(input.password, user.passwordHash)
    if (!passwordMatch) {
      throw new AppError(401, 'Invalid email or password', 'INVALID_CREDENTIALS')
    }

    if (env.REQUIRE_EMAIL_VERIFICATION && !user.isEmailVerified) {
      throw new AppError(
        403,
        'Email not verified. Please check your inbox or request a new verification email.',
        'EMAIL_NOT_VERIFIED',
      )
    }

    const token = signToken({ userId: user.id, email: user.email })

    return {
      user: buildUserResponse(user, user.profile),
      token,
    }
  }

  async googleAuth(input: GoogleAuthInput) {
    const googleUser = await verifyGoogleIdToken(input.idToken)

    // Refuse if Google itself says the email is unverified
    if (!googleUser.emailVerified) {
      throw new AppError(400, 'Google account email is not verified', 'GOOGLE_EMAIL_UNVERIFIED')
    }

    // Look up by googleId first, then fall back to email (handles linking)
    let user = await this.prisma.user.findFirst({
      where: {
        OR: [{ googleId: googleUser.googleId }, { email: googleUser.email }],
      },
      include: { profile: true },
    })

    if (user) {
      // Link Google to an existing email-registered account if needed
      if (!user.googleId) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { googleId: googleUser.googleId, isEmailVerified: true },
          include: { profile: true },
        })
      }
    } else {
      // First time: create account + empty profile
      user = await this.prisma.user.create({
        data: {
          email: googleUser.email,
          name: googleUser.name,
          authProvider: 'google',
          googleId: googleUser.googleId,
          isEmailVerified: true,
          profile: {
            create: {
              dietaryRestrictions: [],
              allergies: [],
              customRestrictions: [],
            },
          },
        },
        include: { profile: true },
      })
    }

    const token = signToken({ userId: user.id, email: user.email })

    return {
      user: buildUserResponse(user, user.profile),
      token,
    }
  }

  async verifyEmail(rawToken: string) {
    const tokenHash = sha256(rawToken)

    const user = await this.prisma.user.findFirst({
      where: {
        emailVerificationToken: tokenHash,
        emailVerificationExpires: { gt: new Date() },
        isEmailVerified: false,
      },
    })

    if (!user) {
      throw new AppError(400, 'Verification token is invalid or has expired', 'INVALID_TOKEN')
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        isEmailVerified: true,
        emailVerificationToken: null,
        emailVerificationExpires: null,
      },
    })

    return { message: 'Email verified successfully. You can now log in.' }
  }

  async resendVerification(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } })

    // Do not reveal whether the email is registered
    if (!user || user.isEmailVerified) {
      return {
        message:
          'If this email is registered and unverified, a new verification email has been sent.',
      }
    }

    const rawToken = generateToken()
    const tokenHash = sha256(rawToken)
    const expires = new Date(Date.now() + VERIFICATION_EXPIRES_HOURS * 3_600_000)

    await this.prisma.user.update({
      where: { id: user.id },
      data: { emailVerificationToken: tokenHash, emailVerificationExpires: expires },
    })

    await sendVerificationEmail(email, rawToken)

    return {
      message:
        'If this email is registered and unverified, a new verification email has been sent.',
    }
  }

  async appleAuth(input: AppleAuthInput) {
    const appleUser = await verifyAppleIdToken(input.idToken)

    // Apple may not return an email if the user hid it — require it for account creation
    if (!appleUser.email) {
      throw new AppError(400, 'Apple account did not provide an email address', 'APPLE_NO_EMAIL')
    }

    if (!appleUser.emailVerified) {
      throw new AppError(400, 'Apple account email is not verified', 'APPLE_EMAIL_UNVERIFIED')
    }

    // Look up by appleId first, then fall back to email (handles account linking)
    let user = await this.prisma.user.findFirst({
      where: { OR: [{ appleId: appleUser.appleId }, { email: appleUser.email }] },
      include: { profile: true },
    })

    if (user) {
      if (!user.appleId) {
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { appleId: appleUser.appleId, isEmailVerified: true },
          include: { profile: true },
        })
      }
    } else {
      user = await this.prisma.user.create({
        data: {
          email: appleUser.email,
          // Apple only sends name on the very first login; store if provided
          name: input.name ?? null,
          authProvider: 'apple',
          appleId: appleUser.appleId,
          isEmailVerified: true,
          profile: {
            create: { dietaryRestrictions: [], allergies: [], customRestrictions: [] },
          },
        },
        include: { profile: true },
      })
    }

    const token = signToken({ userId: user.id, email: user.email })

    return {
      user: buildUserResponse(user, user.profile),
      token,
    }
  }

  async sendOtp(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } })

    // Always return the same message — don't reveal whether the email exists
    const okResponse = { message: 'If this email is registered, an OTP has been sent.' }

    if (!user || !user.isActive) return okResponse

    // Enforce 1-minute cooldown between OTP sends
    if (user.otpExpires && user.otpExpires.getTime() - Date.now() > OTP_EXPIRES_MS - OTP_RESEND_COOLDOWN_MS) {
      throw new AppError(429, 'Please wait before requesting a new OTP', 'OTP_RATE_LIMITED')
    }

    const rawOtp = generateOtp()
    const otpHash = sha256(rawOtp)
    const otpExpires = new Date(Date.now() + OTP_EXPIRES_MS)

    await this.prisma.user.update({
      where: { id: user.id },
      data: { otpHash, otpExpires, otpAttempts: 0 },
    })

    await sendOtpEmail(email, rawOtp)

    return okResponse
  }

  async verifyOtp(input: OtpVerifyInput) {
    const user = await this.prisma.user.findUnique({
      where: { email: input.email },
      include: { profile: true },
    })

    // Generic error prevents user enumeration
    const invalidError = new AppError(401, 'Invalid or expired OTP', 'INVALID_OTP')

    if (!user || !user.otpHash || !user.otpExpires) throw invalidError

    if (user.otpExpires < new Date()) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { otpHash: null, otpExpires: null, otpAttempts: 0 },
      })
      throw invalidError
    }

    if (user.otpAttempts >= OTP_MAX_ATTEMPTS) {
      throw new AppError(429, 'Too many incorrect attempts. Request a new OTP.', 'OTP_MAX_ATTEMPTS')
    }

    if (sha256(input.code) !== user.otpHash) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { otpAttempts: { increment: 1 } },
      })
      throw invalidError
    }

    // Success — clear OTP fields
    await this.prisma.user.update({
      where: { id: user.id },
      data: { otpHash: null, otpExpires: null, otpAttempts: 0 },
    })

    const token = signToken({ userId: user.id, email: user.email })

    return {
      user: buildUserResponse(user, user.profile),
      token,
    }
  }
}
