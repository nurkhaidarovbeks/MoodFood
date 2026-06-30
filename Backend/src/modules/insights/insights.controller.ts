import { Request, Response, NextFunction } from 'express'
import { InsightsService } from './insights.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class InsightsController {
  constructor(private service: InsightsService) {}

  async weekly(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.weekly(userId, (req.query as any).days))
    } catch (err) {
      next(err)
    }
  }

  async tips(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.tips(userId, (req.query as any).days))
    } catch (err) {
      next(err)
    }
  }
}
