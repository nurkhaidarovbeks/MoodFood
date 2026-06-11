import { Response, NextFunction } from 'express'
import { PantryService } from './pantry.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class PantryController {
  constructor(private pantryService: PantryService) {}

  async getIngredients(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.pantryService.getIngredients(req.userId)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async addIngredients(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.pantryService.addIngredients(req.userId, req.body)
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }

  async removeIngredient(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.pantryService.removeIngredient(
        req.userId,
        req.params['id'] as string,
      )
      res.json(result)
    } catch (err) {
      next(err)
    }
  }

  async clearPantry(req: AuthenticatedRequest, res: Response, next: NextFunction) {
    try {
      const result = await this.pantryService.clearPantry(req.userId)
      res.json(result)
    } catch (err) {
      next(err)
    }
  }
}
