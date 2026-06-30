import { Request, Response, NextFunction } from 'express'
import { NotificationService } from './notification.service'
import type { AuthenticatedRequest } from '../../middleware/auth'

export class NotificationController {
  constructor(private service: NotificationService) {}

  async registerDevice(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(201).json(await this.service.registerDevice(userId, req.body))
    } catch (err) {
      next(err)
    }
  }

  async removeDevice(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.removeDevice(userId, req.params.token as string))
    } catch (err) {
      next(err)
    }
  }

  async getPreferences(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.getPreferences(userId))
    } catch (err) {
      next(err)
    }
  }

  async updatePreferences(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.updatePreferences(userId, req.body))
    } catch (err) {
      next(err)
    }
  }

  async due(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      const reminders = await this.service.computeDueReminders(userId)
      res.status(200).json({ reminders, count: reminders.length })
    } catch (err) {
      next(err)
    }
  }

  async test(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.sendTest(userId))
    } catch (err) {
      next(err)
    }
  }

  async history(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req as AuthenticatedRequest
      res.status(200).json(await this.service.history(userId, (req.query as any).limit))
    } catch (err) {
      next(err)
    }
  }
}
