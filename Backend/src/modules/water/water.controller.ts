import { Request, Response, NextFunction } from 'express'
import { WaterService } from './water.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class WaterController {
  constructor(private service: WaterService) {}

  async log(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(201).json(await this.service.log(userId, req.body))
    } catch (err) {
      next(err)
    }
  }

  async today(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.today(userId))
    } catch (err) {
      next(err)
    }
  }

  async history(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.history(userId, (req.query as any).days))
    } catch (err) {
      next(err)
    }
  }

  async deleteLog(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.deleteLog(userId, req.params.id as string))
    } catch (err) {
      next(err)
    }
  }

  async getGoal(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.getGoal(userId))
    } catch (err) {
      next(err)
    }
  }

  async updateGoal(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.updateGoal(userId, req.body))
    } catch (err) {
      next(err)
    }
  }
}
