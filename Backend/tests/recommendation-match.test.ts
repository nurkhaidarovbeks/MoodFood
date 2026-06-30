/**
 * Recipe match-scoring tests — the staple-aware "how much of this can I cook"
 * logic that replaced the old "shares ≥1 ingredient" rule, plus an end-to-end
 * check that the photo flow surfaces a fully-matched recipe.
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { recipeMatchScore, isStaple } from '../src/modules/recommendations/recommendation.scoring'
import { RecommendationService } from '../src/modules/recommendations/recommendation.service'
import { MealAiService } from '../src/services/meal-ai.service'

describe('isStaple', () => {
  it('treats spices, oils and condiments (and salt/pepper/water) as staples', () => {
    expect(isStaple('olive oil', 'oil')).toBe(true)
    expect(isStaple('cumin', 'spice')).toBe(true)
    expect(isStaple('soy sauce', 'condiment')).toBe(true)
    expect(isStaple('salt', null)).toBe(true)
    expect(isStaple('chicken breast', 'meat')).toBe(false)
    expect(isStaple('tomato', 'vegetable')).toBe(false)
  })
})

describe('recipeMatchScore', () => {
  const ings = [
    { name: 'eggs', category: 'dairy' },
    { name: 'cheese', category: 'dairy' },
    { name: 'bell pepper', category: 'vegetable' },
    { name: 'olive oil', category: 'oil' }, // staple — excluded from denominator
  ]

  it('ignores staples in the denominator', () => {
    const m = recipeMatchScore(ings, ['eggs', 'cheese', 'bell pepper'])
    expect(m.countable).toBe(3) // oil excluded
    expect(m.matched).toBe(3)
    expect(m.score).toBe(1)
    expect(m.missing).toEqual([])
  })

  it('scores partial matches and lists the missing items', () => {
    const m = recipeMatchScore(ings, ['eggs'])
    expect(m.countable).toBe(3)
    expect(m.matched).toBe(1)
    expect(m.score).toBeCloseTo(0.33, 2)
    expect(m.missing).toEqual(['cheese', 'bell pepper'])
  })

  it('matches fuzzy singular/plural and synonyms', () => {
    const m = recipeMatchScore(
      [{ name: 'eggs', category: 'dairy' }, { name: 'green onion', category: 'vegetable' }],
      ['egg', 'scallion'], // egg→eggs, scallion→green onion
    )
    expect(m.matched).toBe(2)
    expect(m.score).toBe(1)
  })

  it('returns score 1 for an all-staple recipe', () => {
    const m = recipeMatchScore([{ name: 'salt', category: null }], [])
    expect(m.score).toBe(1)
  })
})

// ─── Photo flow surfaces a cookable recipe ────────────────────────────────────

const ri = (id: string, name: string, category: string) => ({
  ingredientId: id,
  amount: '1',
  unit: 'pc',
  ingredient: { id, name, category },
})

const omelette = {
  id: 'r-omelette',
  title: 'Veggie Cheese Omelette',
  cookingTimeMin: 10,
  difficulty: 'easy',
  estimatedCost: 3,
  calories: 330,
  proteinG: 24,
  steps: 'Beat and cook.',
  moodTags: ['energetic'],
  recipeIngredients: [
    ri('i-egg', 'eggs', 'dairy'),
    ri('i-cheese', 'cheese', 'dairy'),
    ri('i-pepper', 'bell pepper', 'vegetable'),
    ri('i-oil', 'olive oil', 'oil'),
  ],
}

const salmon = {
  id: 'r-salmon',
  title: 'Salmon with Quinoa',
  cookingTimeMin: 30,
  difficulty: 'medium',
  estimatedCost: 9,
  calories: 520,
  proteinG: 48,
  steps: 'Sear.',
  moodTags: ['focused'],
  recipeIngredients: [ri('i-salmon', 'salmon', 'fish'), ri('i-quinoa', 'quinoa', 'grain')],
}

const user = {
  id: 'user-1',
  email: 'a@x.com',
  profile: { dietaryRestrictions: [], allergies: [], customRestrictions: [], budgetLevel: 'medium' },
}

describe('recommend — photo ingredients', () => {
  it('marks the fully-available recipe as cookable with matchScore 1 and no missing items', async () => {
    mockReset(prismaMock)
    const service = new RecommendationService(prismaMock as any, new MealAiService({ apiKey: '' }))
    prismaMock.user.findUnique.mockResolvedValueOnce(user as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce([omelette, salmon] as any)

    const result = await service.recommend(
      'user-1',
      { useMyIngredients: false },
      { availableIngredientNames: ['eggs', 'cheese', 'bell pepper'] },
    )

    const opt = (result.options as any[]).find(o => o.recipe.id === 'r-omelette')
    expect(opt).toBeDefined()
    expect(opt.matchScore).toBe(1)
    expect(opt.missingIngredients).toEqual([])

    // Salmon (nothing matched) should not crowd out the cookable omelette as healthiest.
    const healthiest = (result.options as any[]).find(o => o.category === 'healthiest')
    expect(healthiest.recipe.id).toBe('r-omelette')
  })
})
