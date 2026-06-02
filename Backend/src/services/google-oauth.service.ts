import { OAuth2Client } from 'google-auth-library'
import { env } from '../config/env'
import { AppError } from '../middleware/errorHandler'

export interface GoogleUserInfo {
  googleId: string
  email: string
  name: string | null
  emailVerified: boolean
}

// Instantiate once at module level; client is stateless
const client = new OAuth2Client(env.GOOGLE_CLIENT_ID || undefined)

/**
 * Verifies a Google ID token server-side using Google's public keys.
 * Never trust raw frontend data — always verify through this function.
 */
export async function verifyGoogleIdToken(idToken: string): Promise<GoogleUserInfo> {
  if (!env.GOOGLE_CLIENT_ID) {
    throw new AppError(501, 'Google OAuth is not configured on this server', 'GOOGLE_NOT_CONFIGURED')
  }

  let ticket
  try {
    ticket = await client.verifyIdToken({
      idToken,
      audience: env.GOOGLE_CLIENT_ID,
    })
  } catch {
    throw new AppError(401, 'Invalid Google ID token', 'INVALID_GOOGLE_TOKEN')
  }

  const payload = ticket.getPayload()
  if (!payload || !payload.email) {
    throw new AppError(401, 'Google token is missing required fields', 'INVALID_GOOGLE_TOKEN')
  }

  return {
    googleId: payload.sub,
    email: payload.email,
    name: payload.name ?? null,
    emailVerified: payload.email_verified ?? false,
  }
}
