import appleSignin from 'apple-signin-auth'
import { env } from '../config/env'
import { AppError } from '../middleware/errorHandler'

export interface AppleUser {
  appleId: string
  email: string | null
  emailVerified: boolean
}

export async function verifyAppleIdToken(idToken: string): Promise<AppleUser> {
  try {
    const claims = await appleSignin.verifyIdToken(idToken, {
      audience: env.APPLE_CLIENT_ID,
      ignoreExpiration: false,
    })

    return {
      appleId: claims.sub,
      email: claims.email ?? null,
      // Apple returns boolean or string "true"/"false"
      emailVerified: claims.email_verified === true || claims.email_verified === 'true',
    }
  } catch {
    throw new AppError(401, 'Invalid Apple ID token', 'INVALID_APPLE_TOKEN')
  }
}
