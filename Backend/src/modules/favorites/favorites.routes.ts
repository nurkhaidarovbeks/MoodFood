import { Router } from 'express'
import prisma from '../../config/database'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { FavoritesService } from './favorites.service'
import { FavoritesController } from './favorites.controller'
import { FavoriteAddSchema, FavoritesQuerySchema } from './favorites.schema'

const router = Router()
const service = new FavoritesService(prisma)
const ctrl = new FavoritesController(service)

// All favorites routes require authentication
router.use(requireAuth)

// GET  /api/v1/favorites              — list user's favorites (paginated)
router.get('/', validate(FavoritesQuerySchema, 'query'), (req, res, next) => ctrl.getFavorites(req as any, res, next))

// POST /api/v1/favorites              — add recipe to favorites
router.post('/', validate(FavoriteAddSchema), (req, res, next) => ctrl.addFavorite(req as any, res, next))

// DELETE /api/v1/favorites/:id        — remove by favoriteId
router.delete('/:id', (req, res, next) => ctrl.removeFavorite(req as any, res, next))

// GET  /api/v1/favorites/check/:recipeId — check if recipe is favorited
router.get('/check/:recipeId', (req, res, next) => ctrl.isFavorite(req as any, res, next))

export default router
