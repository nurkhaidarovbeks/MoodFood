import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import { env } from './config/env'
import { errorHandler } from './middleware/errorHandler'
import prisma from './config/database'
import authRoutes from './modules/auth/auth.routes'
import profileRoutes from './modules/profile/profile.routes'
import recipeRoutes from './modules/recipes/recipe.routes'
import pantryRoutes from './modules/pantry/pantry.routes'
import paymentRoutes from './modules/payment/payment.routes'
import walletRoutes from './modules/wallet/wallet.routes'
import subscriptionRoutes from './modules/subscription/subscription.routes'
import recommendationRoutes from './modules/recommendations/recommendation.routes'
import moodCheckRoutes from './modules/moodcheck/moodcheck.routes'
import favoritesRoutes from './modules/favorites/favorites.routes'

const app = express()

// ─── Security headers ────────────────────────────────────────────────────────
app.use(helmet())

// ─── CORS ────────────────────────────────────────────────────────────────────
app.use(
  cors({
    origin: env.FRONTEND_URL,
    credentials: true,
  }),
)

// ─── Body parsing ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }))

// ─── Health check ────────────────────────────────────────────────────────────
app.get('/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`
    res.json({ status: 'ok', db: 'connected', version: env.APP_VERSION })
  } catch {
    res.status(503).json({ status: 'error', db: 'disconnected', version: env.APP_VERSION })
  }
})

// ─── API routes ───────────────────────────────────────────────────────────────
app.use('/api/v1/auth', authRoutes)
app.use('/api/v1/profile', profileRoutes)
app.use('/api/v1/recipes', recipeRoutes)
app.use('/api/v1/pantry', pantryRoutes)
app.use('/api/v1/payment', paymentRoutes)
app.use('/api/v1/wallet', walletRoutes)
app.use('/api/v1/subscriptions', subscriptionRoutes)
app.use('/api/v1/recommendations', recommendationRoutes)
app.use('/api/v1/mood-checks', moodCheckRoutes)
app.use('/api/v1/favorites', favoritesRoutes)

// ─── 404 handler ─────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: { message: 'Route not found', code: 'NOT_FOUND' } })
})

// ─── Global error handler ────────────────────────────────────────────────────
app.use(errorHandler)

export default app
