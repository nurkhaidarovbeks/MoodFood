/**
 * Auth service unit tests.
 * The Prisma client is replaced by the deep mock via jest.config.ts moduleNameMapper.
 * No real database connection is made.
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { AuthService } from '../src/modules/auth/auth.service'
import { AppError } from '../src/middleware/errorHandler'
import * as emailService from '../src/services/email.service'
import * as googleOauthService from '../src/services/google-oauth.service'
import * as appleAuthService from '../src/services/apple-auth.service'

// Silence email console output in tests
jest.mock('../src/services/email.service', () => ({
  sendEmail: jest.fn(),
  sendVerificationEmail: jest.fn(),
  sendOtpEmail: jest.fn(),
  sendPasswordResetEmail: jest.fn(),
}))

jest.mock('../src/services/google-oauth.service', () => ({
  verifyGoogleIdToken: jest.fn(),
}))

jest.mock('../src/services/apple-auth.service', () => ({
  verifyAppleIdToken: jest.fn(),
}))

const mockSendVerificationEmail = emailService.sendVerificationEmail as jest.Mock
const mockSendOtpEmail = emailService.sendOtpEmail as jest.Mock
const mockSendPasswordResetEmail = emailService.sendPasswordResetEmail as jest.Mock
const mockVerifyGoogleIdToken = googleOauthService.verifyGoogleIdToken as jest.Mock
const mockVerifyAppleIdToken = appleAuthService.verifyAppleIdToken as jest.Mock

// ─── Shared test fixtures ─────────────────────────────────────────────────────

const baseUser = {
  id: 'user-1',
  email: 'alice@example.com',
  name: 'Alice',
  passwordHash: '$2b$12$hashed',
  authProvider: 'email' as const,
  googleId: null,
  isActive: true,
  isEmailVerified: true,
  emailVerificationToken: null,
  emailVerificationExpires: null,
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
}

const emptyProfile = {
  id: 'profile-1',
  userId: 'user-1',
  age: null,
  goal: null,
  lifestyle: null,
  budgetLevel: null,
  dietaryRestrictions: [],
  allergies: [],
  customRestrictions: [],
  onboardingCompleted: false,
  profileCompletedAt: null,
}

// ─── Setup ────────────────────────────────────────────────────────────────────

let authService: AuthService

beforeEach(() => {
  mockReset(prismaMock)
  mockSendVerificationEmail.mockReset()
  mockSendVerificationEmail.mockResolvedValue(undefined)
  mockSendOtpEmail.mockReset()
  mockSendOtpEmail.mockResolvedValue(undefined)
  mockSendPasswordResetEmail.mockReset()
  mockSendPasswordResetEmail.mockResolvedValue(undefined)
  authService = new AuthService(prismaMock as any)
})

// ─── Registration ─────────────────────────────────────────────────────────────

describe('Registration', () => {
  it('1. registers a new user and returns token + incomplete profile status', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)
    prismaMock.user.create.mockResolvedValueOnce({ ...baseUser, profile: emptyProfile } as any)

    const result = await authService.register({
      email: 'alice@example.com',
      password: 'SecurePass123!',
      name: 'Alice',
    })

    expect(result.user.email).toBe('alice@example.com')
    expect(result.user.isProfileComplete).toBe(false)
    expect(result.token).toBeDefined()
    expect(typeof result.token).toBe('string')
    expect(result.requiresEmailVerification).toBe(false)
  })

  it('2. rejects registration with a duplicate email (409)', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUser as any)

    await expect(
      authService.register({ email: 'alice@example.com', password: 'SecurePass123!' }),
    ).rejects.toMatchObject({ statusCode: 409, code: 'EMAIL_EXISTS' })
  })

  it('sends a verification email when REQUIRE_EMAIL_VERIFICATION=true', async () => {
    const originalEnv = process.env['REQUIRE_EMAIL_VERIFICATION']
    process.env['REQUIRE_EMAIL_VERIFICATION'] = 'true'

    // Re-require env so the flag is re-read (env is evaluated at import time, so we patch the module)
    // We test this by checking that sendVerificationEmail is called.
    prismaMock.user.findUnique.mockResolvedValueOnce(null)
    prismaMock.user.create.mockResolvedValueOnce({
      ...baseUser,
      isEmailVerified: false,
      profile: emptyProfile,
    } as any)
    prismaMock.user.update.mockResolvedValueOnce(baseUser as any)

    // Import env module directly and patch it for this test
    const envModule = await import('../src/config/env')
    const originalRequire = envModule.env.REQUIRE_EMAIL_VERIFICATION
    ;(envModule.env as any).REQUIRE_EMAIL_VERIFICATION = true

    const svc = new AuthService(prismaMock as any)
    await svc.register({ email: 'alice@example.com', password: 'SecurePass123!' })

    expect(mockSendVerificationEmail).toHaveBeenCalledWith(
      'alice@example.com',
      expect.any(String),
    )

    // Restore
    ;(envModule.env as any).REQUIRE_EMAIL_VERIFICATION = originalRequire
    process.env['REQUIRE_EMAIL_VERIFICATION'] = originalEnv
  })
})

// ─── Login ────────────────────────────────────────────────────────────────────

describe('Login', () => {
  it('3. logs in with correct credentials and returns token', async () => {
    const bcrypt = await import('bcrypt')
    const hash = await bcrypt.hash('correctPassword', 12)

    prismaMock.user.findUnique.mockResolvedValueOnce({
      ...baseUser,
      passwordHash: hash,
      profile: emptyProfile,
    } as any)

    const result = await authService.login({
      email: 'alice@example.com',
      password: 'correctPassword',
    })

    expect(result.user.email).toBe('alice@example.com')
    expect(result.token).toBeDefined()
  })

  it('4. rejects login with wrong password (401)', async () => {
    const bcrypt = await import('bcrypt')
    const hash = await bcrypt.hash('correctPassword', 12)

    prismaMock.user.findUnique.mockResolvedValueOnce({
      ...baseUser,
      passwordHash: hash,
      profile: emptyProfile,
    } as any)

    await expect(
      authService.login({ email: 'alice@example.com', password: 'wrongPassword' }),
    ).rejects.toMatchObject({ statusCode: 401, code: 'INVALID_CREDENTIALS' })
  })

  it('rejects login for unknown email (401)', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)

    await expect(
      authService.login({ email: 'nobody@example.com', password: 'anything' }),
    ).rejects.toMatchObject({ statusCode: 401, code: 'INVALID_CREDENTIALS' })
  })

  it('rejects login for deactivated accounts (403)', async () => {
    const bcrypt = await import('bcrypt')
    const hash = await bcrypt.hash('pass', 12)

    prismaMock.user.findUnique.mockResolvedValueOnce({
      ...baseUser,
      isActive: false,
      passwordHash: hash,
      profile: emptyProfile,
    } as any)

    await expect(
      authService.login({ email: 'alice@example.com', password: 'pass' }),
    ).rejects.toMatchObject({ statusCode: 403, code: 'ACCOUNT_INACTIVE' })
  })
})

// ─── Google OAuth ─────────────────────────────────────────────────────────────

describe('Google OAuth', () => {
  const googleUser = {
    googleId: 'google-sub-123',
    email: 'alice@gmail.com',
    name: 'Alice G',
    emailVerified: true,
  }

  it('5a. creates a new user on first Google login', async () => {
    mockVerifyGoogleIdToken.mockResolvedValueOnce(googleUser)
    prismaMock.user.findFirst.mockResolvedValueOnce(null)
    prismaMock.user.create.mockResolvedValueOnce({
      ...baseUser,
      email: 'alice@gmail.com',
      authProvider: 'google',
      googleId: 'google-sub-123',
      isEmailVerified: true,
      profile: emptyProfile,
    } as any)

    const result = await authService.googleAuth({ idToken: 'valid-id-token' })

    expect(result.user.email).toBe('alice@gmail.com')
    expect(result.user.authProvider).toBe('google')
    expect(result.user.isEmailVerified).toBe(true)
    expect(result.user.isProfileComplete).toBe(false)
    expect(result.token).toBeDefined()
    expect(prismaMock.user.create).toHaveBeenCalledTimes(1)
  })

  it('5b. logs in an existing Google user without creating a duplicate', async () => {
    mockVerifyGoogleIdToken.mockResolvedValueOnce(googleUser)
    prismaMock.user.findFirst.mockResolvedValueOnce({
      ...baseUser,
      email: 'alice@gmail.com',
      googleId: 'google-sub-123',
      authProvider: 'google',
      profile: emptyProfile,
    } as any)

    const result = await authService.googleAuth({ idToken: 'valid-id-token' })

    expect(result.user.email).toBe('alice@gmail.com')
    expect(prismaMock.user.create).not.toHaveBeenCalled()
  })

  it('5c. links Google to an existing email account', async () => {
    mockVerifyGoogleIdToken.mockResolvedValueOnce(googleUser)
    // Found by email, no googleId yet
    prismaMock.user.findFirst.mockResolvedValueOnce({
      ...baseUser,
      email: 'alice@gmail.com',
      googleId: null,
      authProvider: 'email',
      profile: emptyProfile,
    } as any)
    prismaMock.user.update.mockResolvedValueOnce({
      ...baseUser,
      email: 'alice@gmail.com',
      googleId: 'google-sub-123',
      isEmailVerified: true,
      authProvider: 'email',
      profile: emptyProfile,
    } as any)

    const result = await authService.googleAuth({ idToken: 'valid-id-token' })

    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({ googleId: 'google-sub-123', isEmailVerified: true }),
      }),
    )
    expect(result.token).toBeDefined()
  })

  it('5d. rejects Google tokens where email_verified is false', async () => {
    mockVerifyGoogleIdToken.mockResolvedValueOnce({ ...googleUser, emailVerified: false })

    await expect(authService.googleAuth({ idToken: 'bad-token' })).rejects.toMatchObject({
      statusCode: 400,
      code: 'GOOGLE_EMAIL_UNVERIFIED',
    })
  })
})

// ─── New user profile status ──────────────────────────────────────────────────

describe('Profile completion after registration', () => {
  it('6. newly registered user always has isProfileComplete = false', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)
    prismaMock.user.create.mockResolvedValueOnce({
      ...baseUser,
      profile: emptyProfile,
    } as any)

    const result = await authService.register({
      email: 'new@example.com',
      password: 'SecurePass123!',
    })

    expect(result.user.isProfileComplete).toBe(false)
  })
})

// ─── Apple OAuth ──────────────────────────────────────────────────────────────

describe('Apple OAuth', () => {
  const appleUser = {
    appleId: 'apple-sub-123',
    email: 'alice@privaterelay.appleid.com',
    emailVerified: true,
  }

  it('A1. creates a new user on first Apple login', async () => {
    mockVerifyAppleIdToken.mockResolvedValueOnce(appleUser)
    prismaMock.user.findFirst.mockResolvedValueOnce(null)
    prismaMock.user.create.mockResolvedValueOnce({
      ...baseUser,
      email: appleUser.email,
      authProvider: 'apple',
      appleId: appleUser.appleId,
      isEmailVerified: true,
      profile: emptyProfile,
    } as any)

    const result = await authService.appleAuth({ idToken: 'valid-apple-token', name: 'Alice' })

    expect(result.user.authProvider).toBe('apple')
    expect(result.user.isEmailVerified).toBe(true)
    expect(result.token).toBeDefined()
    expect(prismaMock.user.create).toHaveBeenCalledTimes(1)
  })

  it('A2. logs in existing Apple user without creating a duplicate', async () => {
    mockVerifyAppleIdToken.mockResolvedValueOnce(appleUser)
    prismaMock.user.findFirst.mockResolvedValueOnce({
      ...baseUser,
      email: appleUser.email,
      appleId: appleUser.appleId,
      authProvider: 'apple',
      profile: emptyProfile,
    } as any)

    const result = await authService.appleAuth({ idToken: 'valid-apple-token' })

    expect(result.token).toBeDefined()
    expect(prismaMock.user.create).not.toHaveBeenCalled()
  })

  it('A3. links Apple to an existing email account', async () => {
    mockVerifyAppleIdToken.mockResolvedValueOnce(appleUser)
    prismaMock.user.findFirst.mockResolvedValueOnce({
      ...baseUser,
      email: appleUser.email,
      appleId: null,
      authProvider: 'email',
      profile: emptyProfile,
    } as any)
    prismaMock.user.update.mockResolvedValueOnce({
      ...baseUser,
      email: appleUser.email,
      appleId: appleUser.appleId,
      isEmailVerified: true,
      authProvider: 'email',
      profile: emptyProfile,
    } as any)

    await authService.appleAuth({ idToken: 'valid-apple-token' })

    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ appleId: appleUser.appleId, isEmailVerified: true }),
      }),
    )
  })

  it('A4. rejects token with unverified email', async () => {
    mockVerifyAppleIdToken.mockResolvedValueOnce({ ...appleUser, emailVerified: false })

    await expect(authService.appleAuth({ idToken: 'bad-token' })).rejects.toMatchObject({
      statusCode: 400,
      code: 'APPLE_EMAIL_UNVERIFIED',
    })
  })

  it('A5. rejects token when Apple returns no email', async () => {
    mockVerifyAppleIdToken.mockResolvedValueOnce({ ...appleUser, email: null })

    await expect(authService.appleAuth({ idToken: 'no-email-token' })).rejects.toMatchObject({
      statusCode: 400,
      code: 'APPLE_NO_EMAIL',
    })
  })
})

// ─── OTP ─────────────────────────────────────────────────────────────────────

describe('OTP authentication', () => {
  const otpUser = {
    ...baseUser,
    otpHash: null,
    otpExpires: null,
    otpAttempts: 0,
  }

  it('O1. sends OTP email for existing user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(otpUser as any)
    prismaMock.user.update.mockResolvedValueOnce(otpUser as any)

    const result = await authService.sendOtp('alice@example.com')

    expect(result.message).toContain('OTP has been sent')
    expect(mockSendOtpEmail).toHaveBeenCalledWith('alice@example.com', expect.stringMatching(/^\d{6}$/))
  })

  it('O2. returns same message for unknown email (no user enumeration)', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)

    const result = await authService.sendOtp('nobody@example.com')

    expect(result.message).toContain('OTP has been sent')
    expect(mockSendOtpEmail).not.toHaveBeenCalled()
  })

  it('O3. verifyOtp returns token for correct code', async () => {
    const { sha256 } = await import('../src/utils/hash')
    const rawOtp = '123456'
    const userWithOtp = {
      ...otpUser,
      otpHash: sha256(rawOtp),
      otpExpires: new Date(Date.now() + 4 * 60 * 1000), // 4 min from now
      otpAttempts: 0,
      profile: emptyProfile,
    }

    prismaMock.user.findUnique.mockResolvedValueOnce(userWithOtp as any)
    prismaMock.user.update.mockResolvedValueOnce(userWithOtp as any)

    const result = await authService.verifyOtp({ email: 'alice@example.com', code: rawOtp })

    expect(result.token).toBeDefined()
    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ otpHash: null, otpExpires: null, otpAttempts: 0 }),
      }),
    )
  })

  it('O4. rejects expired OTP', async () => {
    const { sha256 } = await import('../src/utils/hash')
    const userWithExpiredOtp = {
      ...otpUser,
      otpHash: sha256('123456'),
      otpExpires: new Date(Date.now() - 1000), // expired 1 second ago
      otpAttempts: 0,
      profile: emptyProfile,
    }

    prismaMock.user.findUnique.mockResolvedValueOnce(userWithExpiredOtp as any)
    prismaMock.user.update.mockResolvedValueOnce(userWithExpiredOtp as any)

    await expect(
      authService.verifyOtp({ email: 'alice@example.com', code: '123456' }),
    ).rejects.toMatchObject({ statusCode: 401, code: 'INVALID_OTP' })
  })

  it('O5. rejects wrong code and increments attempt counter', async () => {
    const { sha256 } = await import('../src/utils/hash')
    const userWithOtp = {
      ...otpUser,
      otpHash: sha256('999999'),
      otpExpires: new Date(Date.now() + 4 * 60 * 1000),
      otpAttempts: 0,
      profile: emptyProfile,
    }

    prismaMock.user.findUnique.mockResolvedValueOnce(userWithOtp as any)
    prismaMock.user.update.mockResolvedValueOnce(userWithOtp as any)

    await expect(
      authService.verifyOtp({ email: 'alice@example.com', code: '000000' }),
    ).rejects.toMatchObject({ statusCode: 401, code: 'INVALID_OTP' })

    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ otpAttempts: { increment: 1 } }),
      }),
    )
  })

  it('O6. blocks after 3 failed attempts', async () => {
    const { sha256 } = await import('../src/utils/hash')
    const userMaxAttempts = {
      ...otpUser,
      otpHash: sha256('999999'),
      otpExpires: new Date(Date.now() + 4 * 60 * 1000),
      otpAttempts: 3, // already at max
      profile: emptyProfile,
    }

    prismaMock.user.findUnique.mockResolvedValueOnce(userMaxAttempts as any)

    await expect(
      authService.verifyOtp({ email: 'alice@example.com', code: '000000' }),
    ).rejects.toMatchObject({ statusCode: 429, code: 'OTP_MAX_ATTEMPTS' })
  })
})

// ─── Password reset ─────────────────────────────────────────────────────────────

describe('forgotPassword', () => {
  it('issues a reset token and emails the link for a registered email account', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUser as any)
    prismaMock.user.update.mockResolvedValueOnce(baseUser as any)

    const result = await authService.forgotPassword('alice@example.com')

    expect(mockSendPasswordResetEmail).toHaveBeenCalledWith('alice@example.com', expect.any(String))
    const arg = prismaMock.user.update.mock.calls[0]![0] as any
    expect(arg.data.passwordResetToken).toEqual(expect.any(String))
    expect(arg.data.passwordResetExpires).toBeInstanceOf(Date)
    expect(result.message).toMatch(/reset link has been sent/i)
  })

  it('returns the same message but sends nothing for an unknown email', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)

    const result = await authService.forgotPassword('ghost@example.com')

    expect(mockSendPasswordResetEmail).not.toHaveBeenCalled()
    expect(result.message).toMatch(/reset link has been sent/i)
  })

  it('does not send a reset link to an OAuth-only account (no password)', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({ ...baseUser, passwordHash: null } as any)

    await authService.forgotPassword('alice@example.com')
    expect(mockSendPasswordResetEmail).not.toHaveBeenCalled()
  })
})

describe('resetPassword', () => {
  it('sets a new password when the token is valid and clears it', async () => {
    prismaMock.user.findFirst.mockResolvedValueOnce(baseUser as any)
    prismaMock.user.update.mockResolvedValueOnce(baseUser as any)

    const result = await authService.resetPassword('raw-token', 'newpassword123')

    const arg = prismaMock.user.update.mock.calls[0]![0] as any
    expect(arg.data.passwordHash).toEqual(expect.any(String))
    expect(arg.data.passwordResetToken).toBeNull()
    expect(arg.data.passwordResetExpires).toBeNull()
    expect(result.message).toMatch(/password has been reset/i)
  })

  it('rejects an invalid or expired token', async () => {
    prismaMock.user.findFirst.mockResolvedValueOnce(null)

    await expect(authService.resetPassword('bad-token', 'newpassword123')).rejects.toMatchObject({
      statusCode: 400,
      code: 'INVALID_RESET_TOKEN',
    })
  })
})
