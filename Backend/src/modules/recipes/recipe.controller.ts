import { Request, Response, NextFunction } from 'express'
import { RecipeService } from './recipe.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class RecipeController {
  constructor(private recipeService: RecipeService) {}

  async createRecipe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.recipeService.createRecipe(req.body)
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }

  async getRecipe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.recipeService.getRecipe(req.params.id)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async listRecipes(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.recipeService.listRecipes(req.query as any)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async updateRecipe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.recipeService.updateRecipe(req.params.id, req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async patchRecipe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.recipeService.patchRecipe(req.params.id, req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async deleteRecipe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.recipeService.deleteRecipe(req.params.id)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async getRecommendations(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.recipeService.getRecommendations(userId, req.query as any)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}
