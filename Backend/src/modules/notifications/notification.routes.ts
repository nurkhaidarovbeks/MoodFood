import { Router } from 'express'
import prisma from '../../config/database'
import { NotificationService } from './notification.service'
import { NotificationController } from './notification.controller'
import { PushService } from '../../services/push.service'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import {
  RegisterDeviceSchema,
  UpdatePreferencesSchema,
  NotificationHistoryQuerySchema,
} from './notification.schema'

const router = Router()
const service = new NotificationService(prisma, new PushService())
const controller = new NotificationController(service)

router.use(requireAuth)

// Device tokens
router.post('/devices', validate(RegisterDeviceSchema), (req, res, next) =>
  controller.registerDevice(req, res, next),
)
router.delete('/devices/:token', (req, res, next) => controller.removeDevice(req, res, next))

// Preferences
router.get('/preferences', (req, res, next) => controller.getPreferences(req, res, next))
router.put('/preferences', validate(UpdatePreferencesSchema), (req, res, next) =>
  controller.updatePreferences(req, res, next),
)

// Reminders due right now (client polling) + delivery history + test push
router.get('/due', (req, res, next) => controller.due(req, res, next))
router.get('/history', validate(NotificationHistoryQuerySchema, 'query'), (req, res, next) =>
  controller.history(req, res, next),
)
router.post('/test', (req, res, next) => controller.test(req, res, next))

export default router
