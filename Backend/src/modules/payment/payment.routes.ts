import { Router } from 'express'
import prisma from '../../config/database'
import { PaymentService } from './payment.service'
import { PaymentController } from './payment.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { CheckoutSchema, RefundSchema } from './payment.schema'

const router = Router()
const paymentService = new PaymentService(prisma)
const ctrl = new PaymentController(paymentService)

// ─── Bereke Bank ──────────────────────────────────────────────────────────────

// POST /api/v1/payment/checkout — create order + register with Bereke or PayPal
router.post('/checkout', requireAuth, validate(CheckoutSchema), (req, res, next) =>
  ctrl.checkout(req as any, res, next),
)

// GET /api/v1/payment/success?orderId=... — Bereke redirect after successful payment
router.get('/success', (req, res, next) => ctrl.bereSuccess(req, res, next))

// GET /api/v1/payment/fail?orderId=... — Bereke redirect after failed/cancelled payment
router.get('/fail', (req, res, next) => ctrl.bereFail(req, res, next))

// POST /api/v1/payment/callback — Bereke server-to-server webhook (no auth)
router.post('/callback', (req, res) => ctrl.bereCallback(req, res))

// ─── PayPal ───────────────────────────────────────────────────────────────────

// GET /api/v1/payment/paypal/success?token=... — PayPal redirects here after approval
router.get('/paypal/success', (req, res, next) => ctrl.paypalSuccess(req, res, next))

// GET /api/v1/payment/paypal/cancel — PayPal redirects here on cancel
router.get('/paypal/cancel', (req, res) => ctrl.paypalCancel(req, res))

// ─── Orders ───────────────────────────────────────────────────────────────────

// GET /api/v1/payment/orders — list current user's orders
router.get('/orders', requireAuth, (req, res, next) =>
  ctrl.getUserOrders(req as any, res, next),
)

// GET /api/v1/payment/orders/:id — get single order (owner only)
router.get('/orders/:id', requireAuth, (req, res, next) =>
  ctrl.getOrder(req as any, res, next),
)

// POST /api/v1/payment/orders/:id/refund — admin refund (L2 from slide 10)
router.post('/orders/:id/refund', requireAuth, validate(RefundSchema), (req, res, next) =>
  ctrl.refundOrder(req, res, next),
)

export default router
