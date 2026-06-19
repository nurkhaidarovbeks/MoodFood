import { Router } from 'express'
import prisma from '../../config/database'
import { RecommendationService } from './recommendation.service'
import { RecommendationController } from './recommendation.controller'
import { MealAiService } from '../../services/meal-ai.service'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { RecommendationRequestSchema } from './recommendation.schema'

const router = Router()
const aiService = new MealAiService()
const recommendationService = new RecommendationService(prisma, aiService)
const recommendationController = new RecommendationController(recommendationService)

// POST /api/v1/recommendations — AI meal recommendations from a mood-check.
// Body: { mood?, energyLevel?, stressLevel?, sleepQuality?, hungerLevel?,
//         budgetLevel?, maxCookingTime?, useMyIngredients? }
router.post('/', requireAuth, validate(RecommendationRequestSchema), (req, res, next) =>
  recommendationController.recommend(req, res, next),
)

export default router
