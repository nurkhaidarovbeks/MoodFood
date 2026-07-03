import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import { env } from './config/env'
import { errorHandler } from './middleware/errorHandler'
import prisma from './config/database'
import {
  registry,
  httpRequestsTotal,
  httpRequestDurationSeconds,
  normalizeRoute,
} from './services/metrics.service'
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
import visionRoutes from './modules/vision/vision.routes'
import waterRoutes from './modules/water/water.routes'
import notificationRoutes from './modules/notifications/notification.routes'
import insightsRoutes from './modules/insights/insights.routes'

const app = express()

// Render (and most PaaS) sit behind one reverse proxy hop that sets
// X-Forwarded-For with the real client IP. Trust only that first hop so
// express-rate-limit can key by the actual client IP — trusting `true`
// (all hops) would let a client spoof its own IP via the header.
app.set('trust proxy', 1)

// ─── Security headers ────────────────────────────────────────────────────────
app.use(helmet())

// ─── CORS ────────────────────────────────────────────────────────────────────
app.use(
  cors({
    origin: env.FRONTEND_URL,
    credentials: true,
  }),
)

// ─── Prometheus metrics endpoint ─────────────────────────────────────────────
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', registry.contentType)
  res.end(await registry.metrics())
})

// ─── HTTP request metrics middleware ─────────────────────────────────────────
app.use((req, res, next) => {
  const start = process.hrtime.bigint()
  res.on('finish', () => {
    const route = normalizeRoute(req.path)
    const labels = {
      method: req.method,
      route,
      status_code: String(res.statusCode),
    }
    httpRequestsTotal.inc(labels)
    const durationMs = Number(process.hrtime.bigint() - start) / 1e9
    httpRequestDurationSeconds.observe(labels, durationMs)
  })
  next()
})

// ─── Body parsing ─────────────────────────────────────────────────────────────
// Global 1mb limit for normal JSON. /vision handles large base64 photos and
// mounts its own higher-limit parser, so we skip the global one for that path.
const jsonParser = express.json({ limit: '1mb' })
app.use((req, res, next) => {
  if (req.path.startsWith('/api/v1/vision')) return next()
  jsonParser(req, res, next)
})

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
app.use('/api/v1/vision', visionRoutes)
app.use('/api/v1/water', waterRoutes)
app.use('/api/v1/notifications', notificationRoutes)
app.use('/api/v1/insights', insightsRoutes)

// ─── 404 handler ─────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: { message: 'Route not found', code: 'NOT_FOUND' } })
})

// ─── Global error handler ────────────────────────────────────────────────────
app.use(errorHandler)

export default app
