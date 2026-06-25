import { Request, Response, NextFunction } from 'express'
import { PaymentService } from './payment.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class PaymentController {
  constructor(private paymentService: PaymentService) {}

  async checkout(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.paymentService.checkout(req.userId, req.body)
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }

  async paypalSuccess(req: Request, res: Response, next: NextFunction) {
    try {
      const token  = req.query['token'] as string
      const result = await this.paymentService.handlePaypalSuccess(token)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async paypalCancel(req: Request, res: Response, next: NextFunction) {
    try {
      const token  = req.query['token'] as string
      const result = await this.paymentService.handlePaypalCancel(token)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async getUserOrders(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const orders = await this.paymentService.getUserOrders(req.userId)
      res.json({ orders })
    } catch (err) {
      next(err)
    }
  }

  async getOrder(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const order = await this.paymentService.getOrder(req.userId, req.params['id'] as string)
      res.json(order)
    } catch (err) {
      next(err)
    }
  }

  async refundOrder(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await this.paymentService.refundOrder(req.params['id'] as string, req.body)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }
}
