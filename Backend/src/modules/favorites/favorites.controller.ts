import { Response, NextFunction } from 'express'
import { FavoritesService } from './favorites.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class FavoritesController {
  constructor(private favoritesService: FavoritesService) {}

  async getFavorites(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.favoritesService.getFavorites(req.userId, req.query as any)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async addFavorite(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.favoritesService.addFavorite(req.userId, req.body)
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }

  async removeFavorite(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.favoritesService.removeFavorite(req.userId, req.params['id'] as string)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async isFavorite(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.favoritesService.isFavorite(req.userId, req.params['recipeId'] as string)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}
