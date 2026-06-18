import { Response, NextFunction } from 'express'
import { WalletService } from './wallet.service'
import { PaymentService } from '../payment/payment.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class WalletController {
  constructor(
    private walletService: WalletService,
    private paymentService: PaymentService,
  ) {}

  async getWallet(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.walletService.getWallet(req.userId)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async getTransactions(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { limit, offset } = req.query as unknown as { limit: number; offset: number }
      const result = await this.walletService.getTransactions(req.userId, limit, offset)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async topup(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const { amount, gateway } = req.body
      const result = await this.paymentService.checkout(req.userId, {
        amount,
        gateway,
        orderType: 'topup',
        description: 'Wallet top-up',
      })
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }
}
