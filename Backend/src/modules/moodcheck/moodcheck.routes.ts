import { Router } from 'express'
import prisma from '../../config/database'
import { MoodCheckService } from './moodcheck.service'
import { MoodCheckController } from './moodcheck.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { CreateMoodCheckSchema, MoodCheckHistoryQuerySchema } from './moodcheck.schema'

const router = Router()
const service = new MoodCheckService(prisma)
const controller = new MoodCheckController(service)

router.use(requireAuth)

// POST /api/v1/mood-checks — record a state check-in
router.post('/', validate(CreateMoodCheckSchema), (req, res, next) =>
  controller.create(req, res, next),
)

// GET /api/v1/mood-checks/latest — most recent check-in (or null)
router.get('/latest', (req, res, next) => controller.latest(req, res, next))

// GET /api/v1/mood-checks — paginated history (newest first)
router.get('/', validate(MoodCheckHistoryQuerySchema, 'query'), (req, res, next) =>
  controller.history(req, res, next),
)

export default router
