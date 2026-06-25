import { Response, NextFunction } from 'express'
import { VisionService } from './vision.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class VisionController {
  constructor(private service: VisionService) {}

  async extract(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.service.extract(req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async recommend(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.service.recommendFromPhoto(req.userId, req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}
