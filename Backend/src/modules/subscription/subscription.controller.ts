import { Request, Response, NextFunction } from 'express'
import { SubscriptionService } from './subscription.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class SubscriptionController {
  constructor(private subscriptionService: SubscriptionService) {}

  async getPlans(_req: Request, res: Response, next: NextFunction) {
    try {
      const plans = await this.subscriptionService.getPlans()
      res.json({ plans })
    } catch (err) {
      next(err)
    }
  }

  async subscribe(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.subscriptionService.subscribe(req.userId, req.body)
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }

  async getMySubscription(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const subscription = await this.subscriptionService.getMySubscription(req.userId)
      res.json({ subscription })
    } catch (err) {
      next(err)
    }
  }

  async cancelSubscription(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.subscriptionService.cancelSubscription(req.userId)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }
}
