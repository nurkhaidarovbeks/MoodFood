/**
 * RecommendationService tests — pipeline, dietary filtering, pantry matching,
 * and rule-based AI fallback (no ANTHROPIC_API_KEY in the test env).
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { RecommendationService } from '../src/modules/recommendations/recommendation.service'
import { MealAiService } from '../src/services/meal-ai.service'

// ─── Recipe fixtures (RecipeRow shape with ingredient joins) ──────────────────

const ing = (id: string, name: string, category: string) => ({ id, name, category })
const ri = (ingredientId: string, ingredient: { id: string; name: string; category: string }) => ({
  ingredientId,
  amount: '1',
  unit: 'pc',
  ingredient,
})

const chickenRow = {
  id: 'r-chicken',
  title: 'Grilled Chicken Salad',
  cookingTimeMin: 25,
  difficulty: 'easy',
  estimatedCost: 6,
  calories: 450,
  proteinG: 42,
  steps: 'Grill and serve.',
  moodTags: ['energetic'],
  recipeIngredients: [
    ri('ing-chicken', ing('ing-chicken', 'chicken breast', 'meat')),
    ri('ing-lettuce', ing('ing-lettuce', 'lettuce', 'vegetable')),
  ],
}

const lentilRow = {
  id: 'r-lentil',
  title: 'Lentil Dal',
  cookingTimeMin: 35,
  difficulty: 'medium',
  estimatedCost: 3,
  calories: 380,
  proteinG: 18,
  steps: 'Simmer lentils.',
  moodTags: ['calm'],
  recipeIngredients: [
    ri('ing-lentil', ing('ing-lentil', 'red lentils', 'legume')),
    ri('ing-onion', ing('ing-onion', 'onion', 'vegetable')),
  ],
}

const smoothieRow = {
  id: 'r-smoothie',
  title: 'Banana Oat Smoothie',
  cookingTimeMin: 5,
  difficulty: 'easy',
  estimatedCost: 2.5,
  calories: 320,
  proteinG: 8,
  steps: 'Blend.',
  moodTags: ['happy'],
  recipeIngredients: [
    ri('ing-banana', ing('ing-banana', 'banana', 'fruit')),
    ri('ing-oats', ing('ing-oats', 'rolled oats', 'grain')),
    ri('ing-maple', ing('ing-maple', 'maple syrup', 'sweetener')),
  ],
}

const salmonRow = {
  id: 'r-salmon',
  title: 'Salmon with Quinoa',
  cookingTimeMin: 30,
  difficulty: 'medium',
  estimatedCost: 9,
  calories: 520,
  proteinG: 48,
  steps: 'Sear salmon.',
  moodTags: ['focused'],
  recipeIngredients: [
    ri('ing-salmon', ing('ing-salmon', 'salmon', 'fish')),
    ri('ing-quinoa', ing('ing-quinoa', 'quinoa', 'grain')),
  ],
}

const ALL_ROWS = [chickenRow, lentilRow, smoothieRow, salmonRow]

const userNoRestrictions = {
  id: 'user-1',
  email: 'a@x.com',
  profile: { dietaryRestrictions: [], allergies: [], customRestrictions: [], budgetLevel: 'low' },
}

const veganUser = {
  id: 'user-2',
  email: 'b@x.com',
  profile: { dietaryRestrictions: ['vegan'], allergies: [], customRestrictions: [], budgetLevel: 'low' },
}

let service: RecommendationService

beforeEach(() => {
  mockReset(prismaMock)
  // Explicitly key-less AI service → deterministic rule-based fallback.
  service = new RecommendationService(prismaMock as any, new MealAiService({ apiKey: '' }))
})

// ─── Happy path ───────────────────────────────────────────────────────────────

describe('recommend — happy path', () => {
  it('returns three labelled options each with a non-empty explanation', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(ALL_ROWS as any)

    const result = await service.recommend('user-1', { energyLevel: 2, useMyIngredients: false })

    expect(result.options).toHaveLength(3)
    expect(result.aiPowered).toBe(false) // no API key in tests
    expect(result.options.map(o => o.category).sort()).toEqual([
      'cheapest',
      'fastest',
      'healthiest',
    ])
    for (const opt of result.options) {
      expect(typeof opt.explanation).toBe('string')
      expect(opt.explanation.length).toBeGreaterThan(0)
      expect(opt.recipe.id).toBeDefined()
      expect(typeof opt.fitScore).toBe('number')
    }
  })

  it('selects the high-protein meal as healthiest when low energy', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(ALL_ROWS as any)

    // budgetLevel:'high' neutralises the profile's 'low' budget so this test
    // isolates the low-energy → high-protein rule (salmon) from the budget rule.
    const result = await service.recommend('user-1', { energyLevel: 1, budgetLevel: 'high', useMyIngredients: false })

    const healthiest = result.options.find(o => o.category === 'healthiest')!
    expect(healthiest.recipe.id).toBe('r-salmon')
    const fastest = result.options.find(o => o.category === 'fastest')!
    expect(fastest.recipe.id).toBe('r-smoothie')
  })
})

// ─── Dietary filtering (hard constraint) ──────────────────────────────────────

describe('recommend — dietary restrictions', () => {
  it('never recommends meat or fish to a vegan user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(veganUser as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(ALL_ROWS as any)

    const result = await service.recommend('user-2', { useMyIngredients: false })

    const ids = result.options.map(o => o.recipe.id)
    expect(ids).not.toContain('r-chicken')
    expect(ids).not.toContain('r-salmon')
    expect(ids).toContain('r-lentil')
    expect(result.options.length).toBe(2) // only lentil + smoothie are vegan-safe
  })
})

// ─── Cooking-time filter ──────────────────────────────────────────────────────

describe('recommend — maxCookingTime', () => {
  it('pushes a cookingTimeMin <= N filter into the recipe query', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce([smoothieRow] as any)

    await service.recommend('user-1', { maxCookingTime: 10, useMyIngredients: false })

    const call = prismaMock.recipe.findMany.mock.calls[0]![0] as any
    expect(call.where).toEqual({ cookingTimeMin: { lte: 10 } })
  })
})

// ─── Budget-based recommendation ──────────────────────────────────────────────

describe('recommend — budget', () => {
  it('favours cheaper meals as healthiest for a low-budget profile', async () => {
    // userNoRestrictions has budgetLevel:'low'. At low energy, pricey salmon ($9)
    // is penalised so the cheap, protein-decent lentil ($3) wins as healthiest.
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(ALL_ROWS as any)

    const result = await service.recommend('user-1', { energyLevel: 1, useMyIngredients: false })

    const healthiest = result.options.find(o => o.category === 'healthiest')!
    expect(healthiest.recipe.id).toBe('r-lentil')
    // The pricey salmon should not be the healthiest pick on a tight budget.
    expect(healthiest.recipe.id).not.toBe('r-salmon')
  })
})

// ─── Pantry matching + substitutions ──────────────────────────────────────────

describe('recommend — useMyIngredients', () => {
  it('adds matchScore, missingIngredients, and substitutions to each option', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(ALL_ROWS as any)
    prismaMock.userIngredient.findMany.mockResolvedValueOnce([]) // empty pantry

    // budgetLevel:'high' keeps pricey salmon in the running as healthiest so we
    // can assert its substitutions (the profile's 'low' budget would drop it).
    const result = await service.recommend('user-1', { energyLevel: 1, budgetLevel: 'high', useMyIngredients: true })

    for (const opt of result.options as any[]) {
      expect(typeof opt.matchScore).toBe('number')
      expect(Array.isArray(opt.missingIngredients)).toBe(true)
      expect(typeof opt.substitutions).toBe('object')
    }

    // Salmon is the healthiest pick; with an empty pantry "salmon" is missing
    // and has a known substitute.
    const salmon = (result.options as any[]).find(o => o.recipe.id === 'r-salmon')
    expect(salmon.matchScore).toBe(0)
    expect(salmon.missingIngredients).toContain('salmon')
    expect(salmon.substitutions['salmon']).toBeDefined()
  })

  it('does not query the pantry when useMyIngredients is false', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(ALL_ROWS as any)

    await service.recommend('user-1', { useMyIngredients: false })

    expect(prismaMock.userIngredient.findMany).not.toHaveBeenCalled()
  })
})

// ─── Errors ─────────────────────────────────────────────────────────────────

describe('recommend — errors', () => {
  it('throws 404 for an unknown user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)

    await expect(
      service.recommend('nope', { useMyIngredients: false }),
    ).rejects.toMatchObject({ statusCode: 404, code: 'USER_NOT_FOUND' })
  })

  it('works for a user with no profile (no restrictions applied)', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({ ...userNoRestrictions, profile: null } as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(ALL_ROWS as any)

    const result = await service.recommend('user-1', { useMyIngredients: false })
    expect(result.options.length).toBe(3)
  })
})
