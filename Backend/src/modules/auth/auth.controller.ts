import { Request, Response, NextFunction } from 'express'
import { AuthService } from './auth.service'

export class AuthController {
  constructor(private authService: AuthService) {}

  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.authService.register(req.body)
      res.status(201).json(result)
    } catch (err) {
      next(err)
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.authService.login(req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async googleAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.authService.googleAuth(req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async verifyEmail(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const token = (req.query['token'] as string) ?? ''
      if (!token) {
        res.status(400).json({ error: { message: 'Verification token is required', code: 'MISSING_TOKEN' } })
        return
      }
      const result = await this.authService.verifyEmail(token)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async resendVerification(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.authService.resendVerification(req.body.email)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async appleAuth(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.authService.appleAuth(req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async sendOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.authService.sendOtp(req.body.email)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }

  async verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.authService.verifyOtp(req.body)
      res.status(200).json(result)
    } catch (err) {
      next(err)
    }
  }
}
