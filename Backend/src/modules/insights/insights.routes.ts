import { Router } from 'express'
import prisma from '../../config/database'
import { InsightsService } from './insights.service'
import { InsightsController } from './insights.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { InsightsQuerySchema } from './insights.schema'

const router = Router()
const controller = new InsightsController(new InsightsService(prisma))

router.use(requireAuth)

// GET /api/v1/insights/weekly — habit summary + tips (?days=7)
router.get('/weekly', validate(InsightsQuerySchema, 'query'), (req, res, next) =>
  controller.weekly(req, res, next),
)

// GET /api/v1/insights/tips — just the actionable tips (?days=7)
router.get('/tips', validate(InsightsQuerySchema, 'query'), (req, res, next) =>
  controller.tips(req, res, next),
)

export default router
