import { Router } from 'express'
import prisma from '../../config/database'
import { PaymentService } from './payment.service'
import { PaymentController } from './payment.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { CheckoutSchema, RefundSchema } from './payment.schema'

const router = Router()
const paymentService = new PaymentService(prisma)
const ctrl           = new PaymentController(paymentService)

// POST /api/v1/payment/checkout — create order, returns PayPal approval URL
router.post('/checkout', requireAuth, validate(CheckoutSchema), (req, res, next) =>
  ctrl.checkout(req as any, res, next),
)

// GET /api/v1/payment/paypal/success?token=... — PayPal redirects here after approval
router.get('/paypal/success', (req, res, next) => ctrl.paypalSuccess(req, res, next))

// GET /api/v1/payment/paypal/cancel?token=... — PayPal redirects here on cancel
router.get('/paypal/cancel', (req, res, next) => ctrl.paypalCancel(req, res, next))

// GET /api/v1/payment/orders — list current user's orders
router.get('/orders', requireAuth, (req, res, next) =>
  ctrl.getUserOrders(req as any, res, next),
)

// GET /api/v1/payment/orders/:id — get single order (owner only)
router.get('/orders/:id', requireAuth, (req, res, next) =>
  ctrl.getOrder(req as any, res, next),
)

// POST /api/v1/payment/orders/:id/refund — refund order
router.post('/orders/:id/refund', requireAuth, validate(RefundSchema), (req, res, next) =>
  ctrl.refundOrder(req, res, next),
)

export default router
