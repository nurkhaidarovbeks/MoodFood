import { Request, Response, NextFunction } from 'express'

export class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code?: string,
  ) {
    super(message)
    this.name = 'AppError'
  }
}

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: {
        message: err.message,
        code: err.code ?? 'ERROR',
      },
    })
    return
  }

  // Prisma unique constraint violation
  if ((err as NodeJS.ErrnoException & { code?: string }).code === 'P2002') {
    res.status(409).json({
      error: {
        message: 'A record with this value already exists.',
        code: 'CONFLICT',
      },
    })
    return
  }

  // Prisma record not found
  if ((err as NodeJS.ErrnoException & { code?: string }).code === 'P2025') {
    res.status(404).json({
      error: {
        message: 'Record not found.',
        code: 'NOT_FOUND',
      },
    })
    return
  }

  console.error('[Unhandled error]', err)
  res.status(500).json({
    error: {
      message: 'Internal server error',
      code: 'INTERNAL_ERROR',
    },
  })
}
