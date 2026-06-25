/**
 * Pure unit tests for the recommendation scoring engine (no DB, no network).
 */
import {
  isLowEnergy,
  isStressed,
  isPoorSleep,
  isVeryHungry,
  isBudgetConscious,
  stateFitScore,
  selectThreeOptions,
  suggestSubstitutions,
  ingredientMatches,
  isIngredientAvailable,
  healthScore,
  isClearlyUnhealthy,
  type ScorableRecipe,
  type MoodState,
} from '../src/modules/recommendations/recommendation.scoring'

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const smoothie: ScorableRecipe = {
  id: 'r-smoothie',
  title: 'Banana Oat Smoothie',
  cookingTimeMin: 5,
  difficulty: 'easy',
  estimatedCost: 2.5,
  calories: 320,
  proteinG: 8,
  moodTags: ['happy'],
  categories: ['fruit', 'grain', 'sweetener'],
}

const chicken: ScorableRecipe = {
  id: 'r-chicken',
  title: 'Grilled Chicken Salad',
  cookingTimeMin: 25,
  difficulty: 'easy',
  estimatedCost: 6,
  calories: 450,
  proteinG: 42,
  moodTags: ['energetic'],
  categories: ['meat', 'vegetable'],
}

const lentil: ScorableRecipe = {
  id: 'r-lentil',
  title: 'Lentil Dal',
  cookingTimeMin: 35,
  difficulty: 'medium',
  estimatedCost: 3,
  calories: 380,
  proteinG: 18,
  moodTags: ['calm'],
  categories: ['legume', 'vegetable', 'spice'],
}

const salmon: ScorableRecipe = {
  id: 'r-salmon',
  title: 'Salmon with Quinoa',
  cookingTimeMin: 30,
  difficulty: 'medium',
  estimatedCost: 9,
  calories: 520,
  proteinG: 48,
  moodTags: ['focused'],
  categories: ['fish', 'grain', 'vegetable'],
}

const ALL = [smoothie, chicken, lentil, salmon]

// ─── State detection ──────────────────────────────────────────────────────────

describe('state detection helpers', () => {
  it('detects low energy from energyLevel and mood', () => {
    expect(isLowEnergy({ energyLevel: 2 })).toBe(true)
    expect(isLowEnergy({ energyLevel: 4 })).toBe(false)
    expect(isLowEnergy({ mood: 'tired' })).toBe(true)
    expect(isLowEnergy({ mood: 'low_energy' })).toBe(true)
    expect(isLowEnergy({ mood: 'happy' })).toBe(false)
  })

  it('detects stress, poor sleep, and high hunger', () => {
    expect(isStressed({ stressLevel: 'high' })).toBe(true)
    expect(isStressed({ mood: 'stressed' })).toBe(true)
    expect(isStressed({ stressLevel: 'low' })).toBe(false)
    expect(isPoorSleep({ sleepQuality: 'poor' })).toBe(true)
    expect(isPoorSleep({ sleepQuality: 'good' })).toBe(false)
    expect(isVeryHungry({ hungerLevel: 'high' })).toBe(true)
    expect(isVeryHungry({ hungerLevel: 'low' })).toBe(false)
  })

  it('detects budget-conscious state only for low budget', () => {
    expect(isBudgetConscious({ budgetLevel: 'low' })).toBe(true)
    expect(isBudgetConscious({ budgetLevel: 'medium' })).toBe(false)
    expect(isBudgetConscious({ budgetLevel: 'high' })).toBe(false)
    expect(isBudgetConscious({})).toBe(false)
  })
})

// ─── Fit scoring ──────────────────────────────────────────────────────────────

describe('stateFitScore', () => {
  it('returns the 0.5 baseline when no state is provided', () => {
    // smoothie has no big protein, so only baseline applies
    expect(stateFitScore(smoothie, {})).toBeCloseTo(0.5)
  })

  it('rewards protein + complex carbs and penalises sugar when low energy', () => {
    const state: MoodState = { energyLevel: 1 }
    // salmon: +0.2 protein, +0.12 grain, +0.05 high-protein bonus
    expect(stateFitScore(salmon, state)).toBeGreaterThan(stateFitScore(lentil, state))
    // smoothie loses points for the sweetener
    expect(stateFitScore(smoothie, state)).toBeLessThan(0.5)
  })

  it('rewards lighter meals and penalises heavy ones after poor sleep', () => {
    const state: MoodState = { sleepQuality: 'poor' }
    expect(stateFitScore(smoothie, state)).toBeGreaterThan(0.5) // 320 kcal, light
    // A genuinely heavy meal (>600 kcal) is penalised below baseline.
    const heavy: ScorableRecipe = { ...salmon, calories: 700, proteinG: 10 }
    expect(stateFitScore(heavy, state)).toBeLessThan(0.5)
    // Light smoothie should still rank above the heavier salmon (520 kcal).
    expect(stateFitScore(smoothie, state)).toBeGreaterThan(stateFitScore(salmon, state))
  })

  it('rewards cheap meals and penalises pricey ones for low-budget users', () => {
    const state: MoodState = { budgetLevel: 'low' }
    // smoothie ($2.50) and lentil ($3) are cheap → boosted above baseline
    expect(stateFitScore(smoothie, state)).toBeGreaterThan(0.5)
    expect(stateFitScore(lentil, state)).toBeGreaterThan(0.5)
    // salmon ($9) is pricey → penalised below baseline
    expect(stateFitScore(salmon, state)).toBeLessThan(0.5)
    // cheap lentil should rank above pricey salmon for a budget student
    expect(stateFitScore(lentil, state)).toBeGreaterThan(stateFitScore(salmon, state))
  })

  it('does not apply the budget rule for medium/high budget', () => {
    // chicken ($6) sits between thresholds — unaffected even at low budget,
    // and pricey salmon is only penalised when budget is explicitly low.
    expect(stateFitScore(salmon, { budgetLevel: 'high' })).toBeCloseTo(stateFitScore(salmon, {}))
    expect(stateFitScore(smoothie, { budgetLevel: 'medium' })).toBeCloseTo(stateFitScore(smoothie, {}))
  })

  it('never returns a value outside 0..1', () => {
    for (const r of ALL) {
      const s = stateFitScore(r, { energyLevel: 1, hungerLevel: 'high', sleepQuality: 'poor', budgetLevel: 'low' })
      expect(s).toBeGreaterThanOrEqual(0)
      expect(s).toBeLessThanOrEqual(1)
    }
  })
})

// ─── Selection ────────────────────────────────────────────────────────────────

describe('selectThreeOptions', () => {
  it('returns three distinct recipes labelled fastest / healthiest / cheapest', () => {
    const opts = selectThreeOptions(ALL, { energyLevel: 2 })
    expect(opts).toHaveLength(3)

    const categories = opts.map(o => o.category).sort()
    expect(categories).toEqual(['cheapest', 'fastest', 'healthiest'])

    const ids = new Set(opts.map(o => o.recipe.id))
    expect(ids.size).toBe(3) // all distinct
  })

  it('picks the lowest cooking time as fastest and lowest cost as cheapest', () => {
    const opts = selectThreeOptions(ALL, { energyLevel: 2 })
    const fastest = opts.find(o => o.category === 'fastest')!
    expect(fastest.recipe.id).toBe('r-smoothie') // 5 min

    // healthiest (best low-energy fit) is the high-protein salmon
    const healthiest = opts.find(o => o.category === 'healthiest')!
    expect(healthiest.recipe.id).toBe('r-salmon')

    // cheapest of what's left (chicken $6, lentil $3) is lentil
    const cheapest = opts.find(o => o.category === 'cheapest')!
    expect(cheapest.recipe.id).toBe('r-lentil')
  })

  it('returns fewer options when fewer than three recipes are eligible', () => {
    expect(selectThreeOptions([lentil, smoothie], {})).toHaveLength(2)
    expect(selectThreeOptions([lentil], {})).toHaveLength(1)
    expect(selectThreeOptions([], {})).toHaveLength(0)
  })

  it('treats recipes with unknown time/cost as last for fastest/cheapest', () => {
    const noTime: ScorableRecipe = { ...smoothie, id: 'no-time', cookingTimeMin: null, estimatedCost: null }
    const opts = selectThreeOptions([chicken, noTime, lentil], {})
    const fastest = opts.find(o => o.category === 'fastest')!
    expect(fastest.recipe.id).not.toBe('no-time')
  })
})

// ─── Ingredient name matching (fuzzy) ──────────────────────────────────────────

describe('ingredientMatches', () => {
  it('matches singular vs plural', () => {
    expect(ingredientMatches('egg', 'eggs')).toBe(true)
    expect(ingredientMatches('tomatoes', 'tomato')).toBe(true)
    expect(ingredientMatches('berries', 'berry')).toBe(true)
  })

  it('matches a generic word inside a specific recipe ingredient', () => {
    expect(ingredientMatches('cheese', 'cheddar cheese')).toBe(true)
    expect(ingredientMatches('milk', 'almond milk')).toBe(true)
    expect(ingredientMatches('rice', 'white rice')).toBe(true)
  })

  it('matches multi-word names exactly', () => {
    expect(ingredientMatches('sour cream', 'sour cream')).toBe(true)
    expect(ingredientMatches('bell pepper', 'bell pepper')).toBe(true)
  })

  it('does not match unrelated ingredients', () => {
    expect(ingredientMatches('egg', 'eggplant')).toBe(false) // eggplant tokenises to "eggplant"
    expect(ingredientMatches('milk', 'chicken breast')).toBe(false)
    expect(ingredientMatches('cheese', 'cherry tomatoes')).toBe(false)
  })

  it('does not match a compound noun to its bare head (butter ≠ peanut butter)', () => {
    expect(ingredientMatches('butter', 'peanut butter')).toBe(false)
    expect(ingredientMatches('peanut butter', 'butter')).toBe(false)
    expect(ingredientMatches('cream', 'ice cream')).toBe(false)
    // but the same compound still matches itself
    expect(ingredientMatches('peanut butter', 'peanut butter')).toBe(true)
    expect(ingredientMatches('butter', 'butter')).toBe(true)
  })

  it('isIngredientAvailable checks a list', () => {
    const fridge = ['egg', 'cheese', 'milk', 'bread']
    expect(isIngredientAvailable('eggs', fridge)).toBe(true)
    expect(isIngredientAvailable('cheddar cheese', fridge)).toBe(true)
    expect(isIngredientAvailable('canned tuna', fridge)).toBe(false)
  })

  it('matches across synonyms / spellings / transliterations', () => {
    expect(ingredientMatches('aubergine', 'eggplant')).toBe(true)
    expect(ingredientMatches('scallion', 'spring onion')).toBe(true) // both → green onion
    expect(ingredientMatches('tvorog', 'cottage cheese')).toBe(true)
    expect(ingredientMatches('minced beef', 'ground beef')).toBe(true)
    expect(ingredientMatches('capsicum', 'red bell pepper')).toBe(true)
  })
})

// ─── Nutrition / health scoring ─────────────────────────────────────────────────

const healthyChicken: ScorableRecipe = {
  id: 'h-chicken', title: 'Chicken Veggie Bowl', cookingTimeMin: 20, difficulty: 'easy',
  estimatedCost: 5, calories: 470, proteinG: 40, fatG: 12, carbsG: 48,
  moodTags: [], categories: ['meat', 'grain', 'vegetable'],
}
const sugaryDessert: ScorableRecipe = {
  id: 'd-cake', title: 'Sugar Bomb', cookingTimeMin: 10, difficulty: 'easy',
  estimatedCost: 3, calories: 520, proteinG: 5, fatG: 22, carbsG: 80,
  moodTags: [], categories: ['sweetener', 'grain'],
}
const hugePortion: ScorableRecipe = {
  ...healthyChicken, id: 'big', calories: 850,
}

describe('healthScore', () => {
  it('rates a balanced high-protein veg meal higher than a sugary one', () => {
    expect(healthScore(healthyChicken)).toBeGreaterThan(healthScore(sugaryDessert))
  })

  it('rewards protein and whole-food categories', () => {
    const lean: ScorableRecipe = { ...healthyChicken, categories: ['legume', 'vegetable', 'fruit'] }
    expect(healthScore(lean)).toBeGreaterThanOrEqual(70)
  })

  it('always returns 0..100', () => {
    for (const r of [healthyChicken, sugaryDessert, hugePortion]) {
      const s = healthScore(r)
      expect(s).toBeGreaterThanOrEqual(0)
      expect(s).toBeLessThanOrEqual(100)
    }
  })
})

describe('isClearlyUnhealthy', () => {
  it('flags sugary low-protein calorie-dense items', () => {
    expect(isClearlyUnhealthy(sugaryDessert)).toBe(true)
  })

  it('flags very large portions', () => {
    expect(isClearlyUnhealthy(hugePortion)).toBe(true)
  })

  it('does not flag balanced meals', () => {
    expect(isClearlyUnhealthy(healthyChicken)).toBe(false)
  })
})

// ─── Selection prefers cookable recipes ─────────────────────────────────────────

describe('selectThreeOptions with isCookable', () => {
  it('draws every option from the cookable subset when enough exist', () => {
    // smoothie, chicken, lentil are cookable; salmon is not.
    const cookableIds = new Set(['r-smoothie', 'r-chicken', 'r-lentil'])
    const opts = selectThreeOptions(ALL, { energyLevel: 2 }, r => cookableIds.has(r.id))
    expect(opts).toHaveLength(3)
    expect(opts.map(o => o.recipe.id)).not.toContain('r-salmon')
  })

  it('falls back to non-cookable only after cookable are exhausted', () => {
    const cookableIds = new Set(['r-smoothie']) // only one cookable
    const opts = selectThreeOptions(ALL, {}, r => cookableIds.has(r.id))
    expect(opts).toHaveLength(3) // still returns three
    // The single cookable recipe is among the picks.
    expect(opts.map(o => o.recipe.id)).toContain('r-smoothie')
  })
})

// ─── Substitutions ──────────────────────────────────────────────────────────

describe('suggestSubstitutions', () => {
  it('suggests alternatives for known missing ingredients', () => {
    const subs = suggestSubstitutions(['chicken breast', 'whole milk'])
    expect(subs['chicken breast']).toBeDefined()
    expect(subs['chicken breast']!.length).toBeGreaterThan(0)
    expect(subs['whole milk']).toBeDefined()
  })

  it('omits ingredients with no known substitute', () => {
    const subs = suggestSubstitutions(['dragon fruit'])
    expect(subs['dragon fruit']).toBeUndefined()
  })

  it('drops alternatives that conflict with the user restrictions', () => {
    // A vegan should not be offered eggs/tofu... but should still get plant subs.
    const subs = suggestSubstitutions(['chicken breast'], ['egg', 'tofu'])
    const alts = subs['chicken breast'] ?? []
    expect(alts).not.toContain('eggs')
    expect(alts).not.toContain('tofu')
  })

  it('caps alternatives at two per ingredient', () => {
    const subs = suggestSubstitutions(['chicken breast'])
    expect(subs['chicken breast']!.length).toBeLessThanOrEqual(2)
  })
})
