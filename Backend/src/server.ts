import { env } from './config/env'
import app from './app'
import prisma from './config/database'

async function main() {
  try {
    await prisma.$connect()
    console.log('[DB] Connected to PostgreSQL')
  } catch (err) {
    console.error('[DB] Failed to connect:', err)
    process.exit(1)
  }

  const server = app.listen(env.PORT, () => {
    console.log(`[Server] MoodFood API running on port ${env.PORT} (${env.NODE_ENV})`)
  })

  const shutdown = async (signal: string) => {
    console.log(`[Server] ${signal} received — shutting down gracefully`)
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
