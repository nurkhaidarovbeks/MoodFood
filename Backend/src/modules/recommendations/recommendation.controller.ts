import { Request, Response, NextFunction } from 'express'
import { RecommendationService } from './recommendation.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class RecommendationController {
  constructor(private service: RecommendationService) {}

  async recommend(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.service.recommend(userId, req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}
