import { Request, Response, NextFunction } from 'express'
import { ProfileService } from './profile.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class ProfileController {
  constructor(private profileService: ProfileService) {}

  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.profileService.getProfile(userId)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async upsertProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.profileService.upsertProfile(userId, req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async patchProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const result = await this.profileService.patchProfile(userId, req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}
