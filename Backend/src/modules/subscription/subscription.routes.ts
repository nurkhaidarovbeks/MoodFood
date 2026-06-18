import { Router } from 'express'
import prisma from '../../config/database'
import { PaymentService } from '../payment/payment.service'
import { SubscriptionService } from './subscription.service'
import { SubscriptionController } from './subscription.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { SubscribeSchema } from './subscription.schema'

const router = Router()
const paymentService      = new PaymentService(prisma)
const subscriptionService = new SubscriptionService(prisma, paymentService)
const ctrl                = new SubscriptionController(subscriptionService)

// GET /api/v1/subscriptions/plans — available plans (public)
router.get('/plans', (req, res, next) => ctrl.getPlans(req, res, next))

// GET /api/v1/subscriptions/me — current user's subscription
router.get('/me', requireAuth, (req, res, next) =>
  ctrl.getMySubscription(req as any, res, next),
)

// POST /api/v1/subscriptions/subscribe — subscribe to a plan
router.post('/subscribe', requireAuth, validate(SubscribeSchema), (req, res, next) =>
  ctrl.subscribe(req as any, res, next),
)

// DELETE /api/v1/subscriptions/me — cancel active subscription
router.delete('/me', requireAuth, (req, res, next) =>
  ctrl.cancelSubscription(req as any, res, next),
)

export default router
