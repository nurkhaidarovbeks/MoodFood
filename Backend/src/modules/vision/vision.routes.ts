import { Router } from 'express'
import express from 'express'
import rateLimit from 'express-rate-limit'
import prisma from '../../config/database'
import { requireAuth, type AuthenticatedRequest } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { VisionAiService } from '../../services/vision-ai.service'
import { MealAiService } from '../../services/meal-ai.service'
import { RecommendationService } from '../recommendations/recommendation.service'
import { VisionService } from './vision.service'
import { VisionController } from './vision.controller'
import { VisionExtractSchema, VisionRecommendSchema } from './vision.schema'

const router = Router()

const visionAi = new VisionAiService()
const recommendationService = new RecommendationService(prisma, new MealAiService())
const service = new VisionService(visionAi, recommendationService)
const ctrl = new VisionController(service)

// Photos are large — raise the body limit for this router only (the global
// parser skips /vision; see app.ts). 14mb of base64 ≈ ~10mb decoded image.
router.use(express.json({ limit: '14mb' }))

// Vision calls cost money and latency — cap usage per user.
const visionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  keyGenerator: (req) =>
    (req as AuthenticatedRequest).userId ??
    (req.socket.remoteAddress ?? 'unknown').replace(/^::ffff:/, ''),
  message: {
    error: { message: 'Too many photo requests. Try again in 15 minutes.', code: 'RATE_LIMITED' },
  },
  standardHeaders: true,
  legacyHeaders: false,
})

router.use(requireAuth)
router.use(visionLimiter)

// POST /api/v1/vision/ingredients — photo → extracted ingredients (+confidence).
router.post('/ingredients', validate(VisionExtractSchema), (req, res, next) =>
  ctrl.extract(req as AuthenticatedRequest, res, next),
)

// POST /api/v1/vision/recommendations — photo → 3 dish recommendations (one-shot).
router.post('/recommendations', validate(VisionRecommendSchema), (req, res, next) =>
  ctrl.recommend(req as AuthenticatedRequest, res, next),
)

export default router
