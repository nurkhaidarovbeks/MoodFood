/**
 * MealAiService tests — focus on the deterministic rule-based fallback that
 * runs whenever no ANTHROPIC_API_KEY is configured (dev / CI / tests).
 */
import { MealAiService, ruleBasedExplanation } from '../src/services/meal-ai.service'
import type { MealToExplain } from '../src/services/meal-ai.service'

const fastestMeal: MealToExplain = {
  id: 'r1',
  title: 'Banana Oat Smoothie',
  category: 'fastest',
  cookingTimeMin: 5,
  estimatedCost: 2.5,
  calories: 320,
  proteinG: 8,
}

const healthiestMeal: MealToExplain = {
  id: 'r2',
  title: 'Salmon with Quinoa',
  category: 'healthiest',
  cookingTimeMin: 30,
  estimatedCost: 9,
  calories: 520,
  proteinG: 48,
}

const cheapestMeal: MealToExplain = {
  id: 'r3',
  title: 'Lentil Dal',
  category: 'cheapest',
  cookingTimeMin: 35,
  estimatedCost: 3,
  calories: 380,
  proteinG: 18,
}

describe('MealAiService (no API key → fallback)', () => {
  const ai = new MealAiService({ apiKey: '' })

  it('reports AI as disabled', () => {
    expect(ai.aiEnabled).toBe(false)
  })

  it('returns a non-empty explanation for every meal', async () => {
    const out = await ai.explainMeals([fastestMeal, healthiestMeal, cheapestMeal], {
      energyLevel: 2,
    })
    expect(Object.keys(out).sort()).toEqual(['r1', 'r2', 'r3'])
    for (const id of Object.keys(out)) {
      expect(out[id]!.length).toBeGreaterThan(0)
    }
  })

  it('returns an empty map for no meals', async () => {
    expect(await ai.explainMeals([], {})).toEqual({})
  })
})

describe('ruleBasedExplanation', () => {
  it('mentions cooking time for the fastest option', () => {
    const text = ruleBasedExplanation(fastestMeal, { energyLevel: 3 })
    expect(text).toContain('5 min')
  })

  it('mentions cost for the cheapest option', () => {
    const text = ruleBasedExplanation(cheapestMeal, {})
    expect(text).toContain('$3.00')
  })

  it('mentions protein when the user has low energy', () => {
    const text = ruleBasedExplanation(healthiestMeal, { energyLevel: 1 })
    expect(text.toLowerCase()).toContain('protein')
  })

  it('produces a clean capitalised sentence ending with a period', () => {
    const text = ruleBasedExplanation(healthiestMeal, { sleepQuality: 'poor' })
    expect(text[0]).toBe(text[0]!.toUpperCase())
    expect(text.endsWith('.')).toBe(true)
  })

  it('is non-medical — never makes cure/treatment claims', () => {
    const claims = ['cure', 'treat', 'diagnos', 'disease', 'medical']
    for (const meal of [fastestMeal, healthiestMeal, cheapestMeal]) {
      const text = ruleBasedExplanation(meal, { energyLevel: 1, stressLevel: 'high' }).toLowerCase()
      for (const c of claims) expect(text).not.toContain(c)
    }
  })
})
