import { Request, Response, NextFunction } from 'express'
import { ZodSchema } from 'zod'

export function validate(schema: ZodSchema, source: 'body' | 'query' = 'body') {
  return (req: Request, res: Response, next: NextFunction): void => {
    const result = schema.safeParse(source === 'query' ? req.query : req.body)
    if (!result.success) {
      res.status(400).json({
        error: {
          message: 'Validation failed',
          code: 'VALIDATION_ERROR',
          details: result.error.errors.map(e => ({
            field: e.path.join('.'),
            message: e.message,
          })),
        },
      })
      return
    }
    if (source === 'query') {
      req.query = result.data
    } else {
      req.body = result.data
    }
    next()
  }
}
