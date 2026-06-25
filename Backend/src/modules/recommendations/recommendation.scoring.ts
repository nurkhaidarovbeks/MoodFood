/**
 * Recommendation scoring — pure, deterministic, dependency-free.
 *
 * Encodes the product rules from the MoodFood plan (§12.4 "AI Recommendation
 * Rule Logic"): given a user's current mood-check state, score how well each
 * recipe fits, then pick the three classic options — fastest, healthiest,
 * cheapest. No DB, no network — everything here is unit-tested in isolation.
 */

// ─── Types ──────────────────────────────────────────────────────────────────

export type StressLevel = 'low' | 'medium' | 'high'
export type SleepQuality = 'poor' | 'normal' | 'good'
export type HungerLevel = 'low' | 'medium' | 'high'
export type BudgetLevel = 'low' | 'medium' | 'high'

export interface MoodState {
  mood?: string
  energyLevel?: number // 1–5
  stressLevel?: StressLevel
  sleepQuality?: SleepQuality
  hungerLevel?: HungerLevel
  budgetLevel?: BudgetLevel
}

/** Flat recipe shape the scorer works on (decoupled from Prisma rows). */
export interface ScorableRecipe {
  id: string
  title: string
  cookingTimeMin: number | null
  difficulty: string | null
  estimatedCost: number | null
  calories: number | null
  proteinG: number | null
  moodTags: string[]
  categories: string[] // ingredient categories, lowercased
}

export type OptionCategory = 'fastest' | 'healthiest' | 'cheapest'

export interface SelectedOption {
  category: OptionCategory
  recipe: ScorableRecipe
  fitScore: number
}

// ─── State helpers ────────────────────────────────────────────────────────────

const LOW_ENERGY_MOODS = ['tired', 'low_energy', 'low energy', 'exhausted', 'sluggish']
const STRESSED_MOODS = ['stressed', 'anxious', 'overwhelmed']

export function isLowEnergy(state: MoodState): boolean {
  if (typeof state.energyLevel === 'number' && state.energyLevel <= 2) return true
  const mood = (state.mood ?? '').toLowerCase()
  return LOW_ENERGY_MOODS.some(m => mood.includes(m))
}

export function isStressed(state: MoodState): boolean {
  if (state.stressLevel === 'high') return true
  const mood = (state.mood ?? '').toLowerCase()
  return STRESSED_MOODS.some(m => mood.includes(m))
}

export function isPoorSleep(state: MoodState): boolean {
  return state.sleepQuality === 'poor'
}

export function isVeryHungry(state: MoodState): boolean {
  return state.hungerLevel === 'high'
}

export function isBudgetConscious(state: MoodState): boolean {
  return state.budgetLevel === 'low'
}

// ─── Fit scoring ──────────────────────────────────────────────────────────────

const COMPLEX_CARB_CATEGORIES = ['grain', 'legume']
const SWEETENER_CATEGORIES = ['sweetener']

// Budget thresholds (estimatedCost, USD per serving). Student-friendly meals sit
// at or below CHEAP; anything above PRICEY is penalised for low-budget users.
const BUDGET_CHEAP = 4
const BUDGET_PRICEY = 7

/**
 * Returns a 0–1 score for how well a recipe fits the user's current state.
 * 0.5 is the neutral baseline; rules nudge it up or down. Always clamped.
 */
export function stateFitScore(recipe: ScorableRecipe, state: MoodState): number {
  let score = 0.5

  const protein = recipe.proteinG ?? 0
  const calories = recipe.calories ?? 0
  const hasComplexCarbs = recipe.categories.some(c => COMPLEX_CARB_CATEGORIES.includes(c))
  const hasSweetener = recipe.categories.some(c => SWEETENER_CATEGORIES.includes(c))

  // Low energy → protein + complex carbs, avoid sugar-heavy quick fixes.
  if (isLowEnergy(state)) {
    if (protein >= 20) score += 0.2
    else if (protein >= 12) score += 0.1
    if (hasComplexCarbs) score += 0.12
    if (hasSweetener) score -= 0.15
  }

  // High stress → simple, balanced, warm meals.
  if (isStressed(state)) {
    if (protein >= 12 && protein <= 35) score += 0.12
    if (hasComplexCarbs) score += 0.1
    if (calories > 650) score -= 0.1 // avoid heavy meals when stressed
  }

  // Poor sleep → light but filling, avoid heavy/greasy.
  if (isPoorSleep(state)) {
    if (calories > 0 && calories <= 450) score += 0.15
    if (calories > 600) score -= 0.18
  }

  // Very hungry → filling: protein + fibre + carbs.
  if (isVeryHungry(state)) {
    if (calories >= 450) score += 0.12
    if (protein >= 20) score += 0.1
  }

  // Limited budget → reward cheap student-friendly meals, penalise pricey ones
  // (Epic 4: "Budget-based recommendations — low-cost meals for students").
  if (isBudgetConscious(state)) {
    const cost = recipe.estimatedCost
    if (cost !== null) {
      if (cost <= BUDGET_CHEAP) score += 0.15
      else if (cost > BUDGET_PRICEY) score -= 0.15
    }
  }

  // Generic protein-density nudge so scores aren't all 0.5 with no state.
  if (protein >= 30) score += 0.05

  return clamp01(Math.round(score * 100) / 100)
}

function clamp01(n: number): number {
  return Math.max(0, Math.min(1, n))
}

// ─── Selection ────────────────────────────────────────────────────────────────

/**
 * Picks up to three DISTINCT recipes labelled fastest / healthiest / cheapest.
 * Healthiest is resolved first (it's the core product value), then fastest,
 * then cheapest, each from the remaining pool. Returns fewer than three options
 * only when fewer than three eligible recipes exist.
 */
export function selectThreeOptions(
  recipes: ScorableRecipe[],
  state: MoodState,
): SelectedOption[] {
  if (recipes.length === 0) return []

  const remaining = [...recipes]
  const options: SelectedOption[] = []

  const take = (category: OptionCategory, picker: (rs: ScorableRecipe[]) => ScorableRecipe) => {
    if (remaining.length === 0) return
    const chosen = picker(remaining)
    options.push({ category, recipe: chosen, fitScore: stateFitScore(chosen, state) })
    remaining.splice(remaining.indexOf(chosen), 1)
  }

  // Healthiest = best fit; tie-break by protein desc.
  take('healthiest', rs =>
    [...rs].sort(
      (a, b) =>
        stateFitScore(b, state) - stateFitScore(a, state) ||
        (b.proteinG ?? 0) - (a.proteinG ?? 0),
    )[0]!,
  )

  // Fastest = lowest cooking time (unknown time sorts last); tie-break by fit.
  take('fastest', rs =>
    [...rs].sort(
      (a, b) =>
        timeOrInfinity(a) - timeOrInfinity(b) ||
        stateFitScore(b, state) - stateFitScore(a, state),
    )[0]!,
  )

  // Cheapest = lowest estimated cost (unknown cost sorts last); tie-break by fit.
  take('cheapest', rs =>
    [...rs].sort(
      (a, b) =>
        costOrInfinity(a) - costOrInfinity(b) ||
        stateFitScore(b, state) - stateFitScore(a, state),
    )[0]!,
  )

  return options
}

function timeOrInfinity(r: ScorableRecipe): number {
  return r.cookingTimeMin ?? Number.POSITIVE_INFINITY
}

function costOrInfinity(r: ScorableRecipe): number {
  return r.estimatedCost ?? Number.POSITIVE_INFINITY
}

// ─── Ingredient substitutions ───────────────────────────────────────────────
//
// "Suggest eggs, beans, or cottage cheese if chicken is unavailable" (Epic 4).
// Keyed by a substring of the missing ingredient name. Alternatives are
// filtered against the user's excluded restriction terms so we never suggest
// something they can't eat.

const SUBSTITUTIONS: Array<{ match: string; alternatives: string[] }> = [
  { match: 'chicken', alternatives: ['eggs', 'beans', 'tofu', 'chickpeas'] },
  { match: 'beef', alternatives: ['lentils', 'mushrooms', 'turkey', 'beans'] },
  { match: 'pork', alternatives: ['chicken', 'beans', 'tofu'] },
  { match: 'fish', alternatives: ['tofu', 'chickpeas', 'eggs'] },
  { match: 'salmon', alternatives: ['tuna', 'tofu', 'chickpeas'] },
  { match: 'milk', alternatives: ['almond milk', 'oat milk', 'soy milk'] },
  { match: 'butter', alternatives: ['olive oil', 'coconut oil'] },
  { match: 'cream', alternatives: ['greek yogurt', 'coconut milk'] },
  { match: 'cheese', alternatives: ['nutritional yeast', 'tofu'] },
  { match: 'rice', alternatives: ['quinoa', 'couscous', 'bulgur'] },
  { match: 'pasta', alternatives: ['rice', 'noodles', 'quinoa'] },
  { match: 'egg', alternatives: ['tofu', 'chickpea flour', 'banana'] },
  { match: 'yogurt', alternatives: ['greek yogurt', 'coconut yogurt'] },
  { match: 'honey', alternatives: ['maple syrup', 'mashed banana'] },
]

/**
 * For each missing ingredient, returns up to two safe alternatives.
 * `excludedTerms` are the user's restriction substrings (lowercased) — any
 * alternative containing one is dropped. Ingredients with no known
 * substitute are omitted entirely.
 */
export function suggestSubstitutions(
  missingIngredients: string[],
  excludedTerms: string[] = [],
): Record<string, string[]> {
  const result: Record<string, string[]> = {}

  for (const missing of missingIngredients) {
    const lower = missing.toLowerCase()
    const entry = SUBSTITUTIONS.find(s => lower.includes(s.match))
    if (!entry) continue

    const safe = entry.alternatives
      .filter(alt => !excludedTerms.some(term => alt.toLowerCase().includes(term)))
      .slice(0, 2)

    if (safe.length > 0) result[missing] = safe
  }

  return result
}
