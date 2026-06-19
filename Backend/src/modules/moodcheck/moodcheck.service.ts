import { PrismaClient } from '@prisma/client'
import type { CreateMoodCheckInput, MoodCheckHistoryQuery } from './moodcheck.schema'

/**
 * MoodCheckService — Epic 2. Persists the user's daily state check-ins and
 * exposes their history (the "Mood history" backlog item). The current state
 * captured here is what feeds the Epic 4 recommendation engine.
 */
export class MoodCheckService {
  constructor(private prisma: PrismaClient) {}

  async create(userId: string, input: CreateMoodCheckInput) {
    return this.prisma.moodCheck.create({
      data: {
        userId,
        mood: input.mood ?? null,
        energyLevel: input.energyLevel ?? null,
        stressLevel: input.stressLevel ?? null,
        sleepQuality: input.sleepQuality ?? null,
        hungerLevel: input.hungerLevel ?? null,
      },
    })
  }

  async history(userId: string, query: MoodCheckHistoryQuery) {
    const [moodChecks, total] = await this.prisma.$transaction([
      this.prisma.moodCheck.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip: query.offset,
        take: query.limit,
      }),
      this.prisma.moodCheck.count({ where: { userId } }),
    ])

    return { moodChecks, total, limit: query.limit, offset: query.offset }
  }

  async latest(userId: string) {
    return this.prisma.moodCheck.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    })
  }
}
