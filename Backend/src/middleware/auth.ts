import { Request, Response, NextFunction } from 'express'
import { verifyToken } from '../utils/jwt'
import { AppError } from './errorHandler'

export interface AuthenticatedRequest extends Request {
  userId: string
  userEmail: string
}

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization
  if (!authHeader?.startsWith('Bearer ')) {
    next(new AppError(401, 'Authentication required', 'UNAUTHORIZED'))
    return
  }

  const token = authHeader.slice(7)
  try {
    const payload = verifyToken(token)
    ;(req as AuthenticatedRequest).userId = payload.userId
    ;(req as AuthenticatedRequest).userEmail = payload.email
    next()
  } catch {
    next(new AppError(401, 'Invalid or expired token', 'INVALID_TOKEN'))
  }
}
