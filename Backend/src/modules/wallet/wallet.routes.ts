import { Router } from 'express'
import prisma from '../../config/database'
import { WalletService } from './wallet.service'
import { PaymentService } from '../payment/payment.service'
import { WalletController } from './wallet.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { TopupSchema, WalletTransactionsQuerySchema } from './wallet.schema'

const router = Router()
const walletService  = new WalletService(prisma)
const paymentService = new PaymentService(prisma)
const ctrl = new WalletController(walletService, paymentService)

router.use(requireAuth)

// GET /api/v1/wallet — current balance + last 20 transactions
router.get('/', (req, res, next) => ctrl.getWallet(req as any, res, next))

// GET /api/v1/wallet/transactions?limit=20&offset=0 — paginated transaction history
router.get(
  '/transactions',
  validate(WalletTransactionsQuerySchema, 'query'),
  (req, res, next) => ctrl.getTransactions(req as any, res, next),
)

// POST /api/v1/wallet/topup — create top-up order, returns payment URL
router.post('/topup', validate(TopupSchema), (req, res, next) =>
  ctrl.topup(req as any, res, next),
)

export default router
