import { Request, Response, NextFunction } from 'express'
import { MoodCheckService } from './moodcheck.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class MoodCheckController {
  constructor(private service: MoodCheckService) {}

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.service.create(userId, req.body)
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }

  async history(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.service.history(userId, req.query as any)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async latest(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.service.latest(userId)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}
