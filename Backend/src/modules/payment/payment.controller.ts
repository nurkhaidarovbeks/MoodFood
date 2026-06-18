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

  async bereSuccess(req: Request, res: Response, next: NextFunction) {
    try {
      const orderId = req.query['orderId'] as string
      const result = await this.paymentService.handleBereSuccess(orderId)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async bereFail(req: Request, res: Response, next: NextFunction) {
    try {
      const orderId = req.query['orderId'] as string
      const result = await this.paymentService.handleBereFail(orderId)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async bereCallback(req: Request, res: Response) {
    try {
      const result = await this.paymentService.handleBereCallback(req.body)
      res.json(result)
    } catch {
      // Always return 200 — Bereke retries if we don't respond OK
      res.json({ status: 'ok' })
    }
  }

  async paypalSuccess(req: Request, res: Response, next: NextFunction) {
    try {
      const token = req.query['token'] as string
      const result = await this.paymentService.handlePaypalSuccess(token)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  paypalCancel(_req: Request, res: Response) {
    res.json({ success: false, message: 'Payment cancelled by user' })
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
