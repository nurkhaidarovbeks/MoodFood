/**
 * Profile service unit tests.
 * Covers create/update, restrictions saving, partial PATCH, and completion logic.
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { ProfileService } from '../src/modules/profile/profile.service'

const baseUser = {
  id: 'user-1',
  email: 'alice@example.com',
  name: 'Alice',
  authProvider: 'email',
  isEmailVerified: true,
}

const emptyProfile = {
  id: 'profile-1',
  userId: 'user-1',
  age: null,
  goal: null,
  lifestyle: null,
  budgetLevel: null,
  dietaryRestrictions: [],
  allergies: [],
  customRestrictions: [],
  onboardingCompleted: false,
  profileCompletedAt: null,
}

let profileService: ProfileService

beforeEach(() => {
  mockReset(prismaMock)
  profileService = new ProfileService(prismaMock as any)
})

// ─── Profile creation / update ────────────────────────────────────────────────

describe('Profile upsert', () => {
  it('7. saves dietary restrictions and allergies', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUser as any)

    const savedProfile = {
      ...emptyProfile,
      age: 25,
      goal: 'Eat healthier',
      lifestyle: 'student',
      budgetLevel: 'low',
      dietaryRestrictions: ['vegan', 'gluten_free'],
      allergies: ['nut_allergy'],
      customRestrictions: [],
      onboardingCompleted: true,
    }

    prismaMock.userProfile.upsert.mockResolvedValueOnce(savedProfile as any)

    const result = await profileService.upsertProfile('user-1', {
      age: 25,
      goal: 'Eat healthier',
      lifestyle: 'student',
      budgetLevel: 'low',
      dietaryRestrictions: ['vegan', 'gluten_free'],
      allergies: ['nut_allergy'],
      customRestrictions: [],
    })

    expect(result.profile.dietaryRestrictions).toEqual(['vegan', 'gluten_free'])
    expect(result.profile.allergies).toEqual(['nut_allergy'])
    expect(result.isProfileComplete).toBe(true)
  })

  it('8. saves custom restrictions', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUser as any)

    const savedProfile = {
      ...emptyProfile,
      age: 22,
      goal: 'Build muscle',
      lifestyle: 'professional',
      budgetLevel: 'medium',
      customRestrictions: ['mushrooms', 'cilantro'],
      onboardingCompleted: true,
    }

    prismaMock.userProfile.upsert.mockResolvedValueOnce(savedProfile as any)

    const result = await profileService.upsertProfile('user-1', {
      age: 22,
      goal: 'Build muscle',
      lifestyle: 'professional',
      budgetLevel: 'medium',
      dietaryRestrictions: [],
      allergies: [],
      customRestrictions: ['Mushrooms', 'CILANTRO'], // intentional mixed case — should be lowercased
    })

    expect(result.profile.customRestrictions).toEqual(['mushrooms', 'cilantro'])
  })

  it('returns isProfileComplete=false when required fields missing', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUser as any)

    const incompleteProfile = {
      ...emptyProfile,
      age: 25,
      // goal, lifestyle, budgetLevel all null
    }

    prismaMock.userProfile.upsert.mockResolvedValueOnce(incompleteProfile as any)

    const result = await profileService.upsertProfile('user-1', {
      age: 25,
      goal: null,
      lifestyle: null,
      budgetLevel: null,
      dietaryRestrictions: [],
      allergies: [],
      customRestrictions: [],
    })

    expect(result.isProfileComplete).toBe(false)
  })
})

// ─── Partial PATCH ────────────────────────────────────────────────────────────

describe('Profile patch', () => {
  it('9. partial update preserves unspecified fields', async () => {
    const existingProfile = {
      ...emptyProfile,
      age: 25,
      goal: 'Eat healthier',
      lifestyle: 'student',
      budgetLevel: 'low',
      dietaryRestrictions: ['vegan'],
      allergies: ['nut_allergy'],
      customRestrictions: ['mushrooms'],
      onboardingCompleted: true,
    }

    prismaMock.user.findUnique.mockResolvedValueOnce({
      ...baseUser,
      profile: existingProfile,
    } as any)

    // PATCH only changes goal — everything else should be preserved
    const updatedProfile = { ...existingProfile, goal: 'Stay fit' }
    prismaMock.userProfile.upsert.mockResolvedValueOnce(updatedProfile as any)

    const result = await profileService.patchProfile('user-1', { goal: 'Stay fit' })

    // Verify the upsert was called with merged data (preserved fields)
    const upsertCall = prismaMock.userProfile.upsert.mock.calls[0]![0]
    const updateData = upsertCall.update as Record<string, unknown>

    expect(updateData['age']).toBe(25)
    expect(updateData['lifestyle']).toBe('student')
    expect(updateData['budgetLevel']).toBe('low')
    expect(updateData['goal']).toBe('Stay fit')
    expect(updateData['dietaryRestrictions']).toEqual(['vegan'])
    expect(updateData['customRestrictions']).toEqual(['mushrooms'])

    // Result uses the mock-returned updated profile
    expect(result.profile.goal).toBe('Stay fit')
    expect(result.profile.age).toBe(25)
    expect(result.profile.dietaryRestrictions).toEqual(['vegan'])
  })

  it('patch with null on a field explicitly clears it', async () => {
    const existingProfile = {
      ...emptyProfile,
      age: 30,
      goal: 'Old goal',
      lifestyle: 'student',
      budgetLevel: 'low',
    }

    prismaMock.user.findUnique.mockResolvedValueOnce({
      ...baseUser,
      profile: existingProfile,
    } as any)

    prismaMock.userProfile.upsert.mockResolvedValueOnce({
      ...existingProfile,
      goal: null,
      onboardingCompleted: false,
    } as any)

    const result = await profileService.patchProfile('user-1', { goal: null })

    const upsertCall = prismaMock.userProfile.upsert.mock.calls[0]![0]
    const updateData = upsertCall.update as Record<string, unknown>
    expect(updateData['goal']).toBeNull()
    expect(result.isProfileComplete).toBe(false)
  })
})

// ─── GET profile ──────────────────────────────────────────────────────────────

describe('Get profile', () => {
  it('returns user info and profile with isProfileComplete', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      ...baseUser,
      profile: {
        ...emptyProfile,
        age: 25,
        goal: 'Eat well',
        lifestyle: 'student',
        budgetLevel: 'low',
        onboardingCompleted: true,
      },
    } as any)

    const result = await profileService.getProfile('user-1')

    expect(result.user.id).toBe('user-1')
    expect(result.user.isProfileComplete).toBe(true)
    expect(result.profile?.age).toBe(25)
  })

  it('returns isProfileComplete=false for empty profile', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      ...baseUser,
      profile: emptyProfile,
    } as any)

    const result = await profileService.getProfile('user-1')

    expect(result.user.isProfileComplete).toBe(false)
  })

  it('throws 404 for unknown user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)

    await expect(profileService.getProfile('nonexistent')).rejects.toMatchObject({
      statusCode: 404,
      code: 'USER_NOT_FOUND',
    })
  })
})
