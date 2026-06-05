import { Router } from 'express'
import prisma from '../../config/database'
import { RecipeService } from './recipe.service'
import { RecipeController } from './recipe.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { RecipeCreateSchema, RecipePatchSchema, RecipeQuerySchema } from './recipe.schema'

const router = Router()
const recipeService = new RecipeService(prisma)
const recipeController = new RecipeController(recipeService)

// ─── Public routes ─────────────────────────────────────────────────────────────

router.get('/', validate(RecipeQuerySchema, 'query'), (req, res, next) =>
  recipeController.listRecipes(req, res, next),
)

// NOTE: /recommendations must come before /:id — Express matches in order
router.get('/recommendations', requireAuth, validate(RecipeQuerySchema, 'query'), (req, res, next) =>
  recipeController.getRecommendations(req, res, next),
)

router.get('/:id', (req, res, next) =>
  recipeController.getRecipe(req, res, next),
)

// ─── Auth-protected routes ─────────────────────────────────────────────────────

router.post('/', requireAuth, validate(RecipeCreateSchema), (req, res, next) =>
  recipeController.createRecipe(req, res, next),
)

router.put('/:id', requireAuth, validate(RecipeCreateSchema), (req, res, next) =>
  recipeController.updateRecipe(req, res, next),
)

router.patch('/:id', requireAuth, validate(RecipePatchSchema), (req, res, next) =>
  recipeController.patchRecipe(req, res, next),
)

router.delete('/:id', requireAuth, (req, res, next) =>
  recipeController.deleteRecipe(req, res, next),
)

export default router
