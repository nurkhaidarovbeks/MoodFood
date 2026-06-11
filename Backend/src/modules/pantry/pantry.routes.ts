import { Router } from 'express'
import prisma from '../../config/database'
import { PantryService } from './pantry.service'
import { PantryController } from './pantry.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { AddIngredientsSchema } from './pantry.schema'

const router = Router()
const pantryService = new PantryService(prisma)
const pantryController = new PantryController(pantryService)

router.use(requireAuth)

// GET /api/v1/pantry — list user's pantry ingredients
router.get('/', (req, res, next) =>
  pantryController.getIngredients(req as any, res, next),
)

// POST /api/v1/pantry — add ingredients to pantry
router.post('/', validate(AddIngredientsSchema), (req, res, next) =>
  pantryController.addIngredients(req as any, res, next),
)

// DELETE /api/v1/pantry/clear — remove all ingredients
router.delete('/clear', (req, res, next) =>
  pantryController.clearPantry(req as any, res, next),
)

// DELETE /api/v1/pantry/:id — remove one ingredient
router.delete('/:id', (req, res, next) =>
  pantryController.removeIngredient(req as any, res, next),
)

export default router
