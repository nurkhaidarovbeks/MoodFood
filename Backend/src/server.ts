import { env } from './config/env'
import app from './app'
import prisma from './config/database'
import { startGrafanaCloudPush } from './services/metrics.service'
import { startReminderSweep } from './services/reminder-sweep'

async function main() {
  try {
    await prisma.$connect()
    console.log('[DB] Connected to PostgreSQL')
  } catch (err) {
    console.error('[DB] Failed to connect:', err)
    process.exit(1)
  }

  // Start Grafana Cloud push if configured (production on Render)
  startGrafanaCloudPush(
    env.GRAFANA_REMOTE_WRITE_URL,
    env.GRAFANA_REMOTE_WRITE_USER,
    env.GRAFANA_REMOTE_WRITE_PASSWORD,
  )

  // Start the background reminder sweep (water / meal push notifications)
  const sweep = startReminderSweep(prisma, env.REMINDER_SWEEP_MINUTES)

  const server = app.listen(env.PORT, () => {
    console.log(`[Server] MoodFood API running on port ${env.PORT} (${env.NODE_ENV})`)
  })

  const shutdown = async (signal: string) => {
    console.log(`[Server] ${signal} received — shutting down gracefully`)
    sweep.stop()
    server.close(async () => {
      await prisma.$disconnect()
      console.log('[Server] Shutdown complete')
      process.exit(0)
    })
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'))
  process.on('SIGINT', () => shutdown('SIGINT'))
}

main()
