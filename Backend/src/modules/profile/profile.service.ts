import { PrismaClient, Lifestyle, BudgetLevel } from '@prisma/client'
import { isProfileComplete } from '../../utils/profile-completion'
import { AppError } from '../../middleware/errorHandler'
import type { ProfileUpsertInput, ProfilePatchInput } from './profile.schema'

// ─── Response helpers ─────────────────────────────────────────────────────────

function formatProfile(profile: {
  age: number | null
  goal: string | null
  lifestyle: string | null
  budgetLevel: string | null
  dietaryRestrictions: unknown
  allergies: unknown
  customRestrictions: unknown
}) {
  return {
    age: profile.age,
    goal: profile.goal,
    lifestyle: profile.lifestyle,
    budgetLevel: profile.budgetLevel,
    dietaryRestrictions: (profile.dietaryRestrictions as string[]) ?? [],
    allergies: (profile.allergies as string[]) ?? [],
    customRestrictions: (profile.customRestrictions as string[]) ?? [],
  }
}

// ─── ProfileService ───────────────────────────────────────────────────────────

export class ProfileService {
  constructor(private prisma: PrismaClient) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        authProvider: true,
        isEmailVerified: true,
        profile: true,
      },
    })

    if (!user) throw new AppError(404, 'User not found', 'USER_NOT_FOUND')

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        authProvider: user.authProvider,
        isEmailVerified: user.isEmailVerified,
        isProfileComplete: isProfileComplete(user.profile),
      },
      profile: user.profile ? formatProfile(user.profile as any) : null,
    }
  }

  async upsertProfile(userId: string, input: ProfileUpsertInput) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } })
    if (!user) throw new AppError(404, 'User not found', 'USER_NOT_FOUND')

    const data = {
      age: input.age ?? null,
      goal: input.goal ?? null,
      lifestyle: (input.lifestyle ?? null) as Lifestyle | null,
      budgetLevel: (input.budgetLevel ?? null) as BudgetLevel | null,
      dietaryRestrictions: input.dietaryRestrictions ?? [],
      allergies: input.allergies ?? [],
      customRestrictions: input.customRestrictions ?? [],
    }

    const completed = isProfileComplete(data)

    const profile = await this.prisma.userProfile.upsert({
      where: { userId },
      create: {
        userId,
        ...data,
        onboardingCompleted: completed,
        profileCompletedAt: completed ? new Date() : null,
      },
      update: {
        ...data,
        onboardingCompleted: completed,
        // Only set profileCompletedAt when first completing; don't overwrite it on edits
        ...(completed ? { profileCompletedAt: new Date() } : {}),
      },
    })

    return {
      profile: formatProfile(profile as any),
      isProfileComplete: isProfileComplete(profile as any),
    }
  }

  async patchProfile(userId: string, input: ProfilePatchInput) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    })
    if (!user) throw new AppError(404, 'User not found', 'USER_NOT_FOUND')

    // Start from existing values and overlay only the provided fields
    const existing = user.profile
    const merged = {
      age: 'age' in input ? (input.age ?? null) : (existing?.age ?? null),
      goal: 'goal' in input ? (input.goal ?? null) : (existing?.goal ?? null),
      lifestyle: (
        'lifestyle' in input
          ? (input.lifestyle ?? null)
          : ((existing?.lifestyle as string | null) ?? null)
      ) as Lifestyle | null,
      budgetLevel: (
        'budgetLevel' in input
          ? (input.budgetLevel ?? null)
          : ((existing?.budgetLevel as string | null) ?? null)
      ) as BudgetLevel | null,
      dietaryRestrictions:
        'dietaryRestrictions' in input
          ? (input.dietaryRestrictions ?? [])
          : ((existing?.dietaryRestrictions as string[]) ?? []),
      allergies:
        'allergies' in input
          ? (input.allergies ?? [])
          : ((existing?.allergies as string[]) ?? []),
      customRestrictions:
        'customRestrictions' in input
          ? (input.customRestrictions ?? [])
          : ((existing?.customRestrictions as string[]) ?? []),
    }

    const completed = isProfileComplete(merged)

    const profile = await this.prisma.userProfile.upsert({
      where: { userId },
      create: {
        userId,
        ...merged,
        onboardingCompleted: completed,
        profileCompletedAt: completed ? new Date() : null,
      },
      update: {
        ...merged,
        onboardingCompleted: completed,
        ...(completed && !existing?.onboardingCompleted ? { profileCompletedAt: new Date() } : {}),
      },
    })

    return {
      profile: formatProfile(profile as any),
      isProfileComplete: isProfileComplete(profile as any),
    }
  }
}
