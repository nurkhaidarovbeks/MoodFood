import { Router } from 'express'
import prisma from '../../config/database'
import { WaterService } from './water.service'
import { WaterController } from './water.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { LogWaterSchema, WaterHistoryQuerySchema, UpdateWaterGoalSchema } from './water.schema'

const router = Router()
const controller = new WaterController(new WaterService(prisma))

router.use(requireAuth)

// GET  /api/v1/water/today    — today's total, goal and progress
router.get('/today', (req, res, next) => controller.today(req, res, next))

// GET  /api/v1/water/history  — per-day totals (?days=7)
router.get('/history', validate(WaterHistoryQuerySchema, 'query'), (req, res, next) =>
  controller.history(req, res, next),
)

// GET  /api/v1/water/goal     — hydration goal + reminder cadence
router.get('/goal', (req, res, next) => controller.getGoal(req, res, next))

// PUT  /api/v1/water/goal     — update goal / reminder cadence
router.put('/goal', validate(UpdateWaterGoalSchema), (req, res, next) =>
  controller.updateGoal(req, res, next),
)

// POST /api/v1/water          — log an intake
router.post('/', validate(LogWaterSchema), (req, res, next) => controller.log(req, res, next))

// DELETE /api/v1/water/:id    — remove a logged intake
router.delete('/:id', (req, res, next) => controller.deleteLog(req, res, next))

export default router
