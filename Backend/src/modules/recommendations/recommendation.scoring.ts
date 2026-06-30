/**
 * Recommendation scoring — pure, deterministic, dependency-free.
 *
 * Encodes the product rules from the MoodFood plan (§12.4 "AI Recommendation
 * Rule Logic"): given a user's current mood-check state, score how well each
 * recipe fits, then pick the three classic options — fastest, healthiest,
 * cheapest. No DB, no network — everything here is unit-tested in isolation.
 */

import { canonicalizeIngredient } from '../../services/ingredient-knowledge'

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
  fatG?: number | null
  carbsG?: number | null
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

// ─── Ingredient name matching (singular/plural + substring aware) ─────────────
//
// Photo/pantry ingredient names rarely match recipe names exactly: the vision
// model normalises to singular ("eggs" -> "egg") and uses generic words
// ("cheese") while the recipe DB stores "eggs", "cheddar cheese", "almond milk".
// We tokenise both, singularise each token, and match when one name's tokens are
// a subset of the other's (sharing at least one ≥3-char token). This makes
// egg↔eggs, cheese⊆cheddar cheese, milk⊆almond milk, rice⊆white rice all match.

function singularize(word: string): string {
  if (word.length > 4 && word.endsWith('ies')) return word.slice(0, -3) + 'y' // berries→berry
  if (word.length > 4 && word.endsWith('oes')) return word.slice(0, -2) // tomatoes→tomato
  if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) return word.slice(0, -1) // eggs→egg
  return word
}

function tokenize(name: string): string[] {
  return (name ?? '')
    .toLowerCase()
    .trim()
    .split(/[\s-]+/)
    .map(singularize)
    .filter(t => t.length >= 2)
}

// Compound ingredients whose qualifier makes them a DIFFERENT product, so the
// bare head noun must not match the compound (e.g. "butter" ≠ "peanut butter").
const INCOMPATIBLE_QUALIFIERS: Record<string, string[]> = {
  butter: ['peanut', 'almond', 'cashew', 'nut', 'cocoa', 'apple', 'shea', 'body'],
  cream: ['ice'],
}

function hasIncompatibleQualifier(aSet: Set<string>, bSet: Set<string>): boolean {
  for (const [head, bad] of Object.entries(INCOMPATIBLE_QUALIFIERS)) {
    if (!aSet.has(head) || !bSet.has(head)) continue
    const aBad = bad.some(q => aSet.has(q))
    const bBad = bad.some(q => bSet.has(q))
    // One side is "<qualifier> X" and the other is plain "X" → not the same thing.
    if (aBad !== bBad) return true
  }
  return false
}

/** True when two ingredient names refer to the same thing (fuzzy, see above). */
export function ingredientMatches(a: string, b: string): boolean {
  // Resolve synonyms/spellings/transliterations first (scallion→green onion,
  // aubergine→eggplant, tvorog→cottage cheese), then compare by tokens.
  const at = tokenize(canonicalizeIngredient(a))
  const bt = tokenize(canonicalizeIngredient(b))
  if (at.length === 0 || bt.length === 0) return false

  const aSet = new Set(at)
  const bSet = new Set(bt)

  // Need at least one meaningful shared token to avoid trivial collisions.
  const shared = [...aSet].filter(t => bSet.has(t) && t.length >= 3)
  if (shared.length === 0) return false

  // Guard against compound nouns like "peanut butter" matching plain "butter".
  if (hasIncompatibleQualifier(aSet, bSet)) return false

  const subset = (small: Set<string>, big: Set<string>) => [...small].every(t => big.has(t))
  return subset(aSet, bSet) || subset(bSet, aSet)
}

/** True when any available ingredient matches the given recipe ingredient name. */
export function isIngredientAvailable(recipeIngredientName: string, available: string[]): boolean {
  return available.some(a => ingredientMatches(a, recipeIngredientName))
}

// ─── Recipe-level match scoring (staple-aware) ────────────────────────────────
//
// The old "cookable = shares ≥1 ingredient" rule surfaced recipes where only 1
// of 8 ingredients was on hand. Instead we score how much of a recipe the user
// can actually make: matched non-staple ingredients ÷ total non-staple
// ingredients. Pantry staples (salt, oil, common spices/condiments) are assumed
// to be on hand and never count against a recipe — nobody photographs the salt.

const STAPLE_CATEGORIES = new Set(['spice', 'oil', 'condiment'])
const STAPLE_NAMES = new Set(['salt', 'pepper', 'black pepper', 'water'])

/** Pantry staple → assumed always available, excluded from match denominator. */
export function isStaple(name: string, category?: string | null): boolean {
  if (category && STAPLE_CATEGORIES.has(category.toLowerCase())) return true
  return STAPLE_NAMES.has(canonicalizeIngredient(name))
}

export interface RecipeMatch {
  /** Non-staple ingredients the user has. */
  matched: number
  /** Non-staple ingredients total (the denominator). */
  countable: number
  /** matched / countable, 0–1, rounded to 2dp. 1.0 when a recipe is all staples. */
  score: number
  /** Non-staple ingredient names the user is missing. */
  missing: string[]
}

/**
 * Scores how cookable a recipe is given the available ingredient names.
 * Staples are skipped (assumed on hand); everything else must be matched.
 */
export function recipeMatchScore(
  ingredients: Array<{ name: string; category?: string | null }>,
  available: string[],
): RecipeMatch {
  let matched = 0
  let countable = 0
  const missing: string[] = []

  for (const ing of ingredients) {
    if (isStaple(ing.name, ing.category)) continue
    countable++
    if (isIngredientAvailable(ing.name, available)) matched++
    else missing.push(ing.name)
  }

  const score = countable === 0 ? 1 : matched / countable
  return { matched, countable, score: Math.round(score * 100) / 100, missing }
}

// ─── Selection ────────────────────────────────────────────────────────────────

/**
 * Picks up to three DISTINCT recipes labelled fastest / healthiest / cheapest.
 * Healthiest is resolved first (it's the core product value), then fastest,
 * then cheapest, each from the remaining pool. Returns fewer than three options
 * only when fewer than three eligible recipes exist.
 *
 * When `isCookable` is provided (photo/pantry flows), each category prefers a
 * recipe the user can actually make: as long as any cookable recipe remains, the
 * pick is drawn from the cookable subset, falling back to the rest only once
 * cookable options are exhausted. This keeps "use what I have" front and centre.
 */
export function selectThreeOptions(
  recipes: ScorableRecipe[],
  state: MoodState,
  isCookable?: (recipe: ScorableRecipe) => boolean,
  matchScore?: (recipe: ScorableRecipe) => number,
): SelectedOption[] {
  if (recipes.length === 0) return []

  const remaining = [...recipes]
  const options: SelectedOption[] = []
  // Match score is a tie-breaker so the best-matching cookable recipe wins
  // within each category (0 when ingredients are unknown — no effect).
  const ms = matchScore ?? (() => 0)

  const take = (category: OptionCategory, picker: (rs: ScorableRecipe[]) => ScorableRecipe) => {
    if (remaining.length === 0) return
    // Prefer cookable recipes while any remain.
    let pool = remaining
    if (isCookable) {
      const cookable = remaining.filter(isCookable)
      if (cookable.length > 0) pool = cookable
    }
    const chosen = picker(pool)
    options.push({ category, recipe: chosen, fitScore: stateFitScore(chosen, state) })
    remaining.splice(remaining.indexOf(chosen), 1)
  }

  // Healthiest = best fit; tie-break by match, then protein desc.
  take('healthiest', rs =>
    [...rs].sort(
      (a, b) =>
        stateFitScore(b, state) - stateFitScore(a, state) ||
        ms(b) - ms(a) ||
        (b.proteinG ?? 0) - (a.proteinG ?? 0),
    )[0]!,
  )

  // Fastest = lowest cooking time (unknown time sorts last); tie-break by match, then fit.
  take('fastest', rs =>
    [...rs].sort(
      (a, b) =>
        timeOrInfinity(a) - timeOrInfinity(b) ||
        ms(b) - ms(a) ||
        stateFitScore(b, state) - stateFitScore(a, state),
    )[0]!,
  )

  // Cheapest = lowest estimated cost (unknown cost sorts last); tie-break by match, then fit.
  take('cheapest', rs =>
    [...rs].sort(
      (a, b) =>
        costOrInfinity(a) - costOrInfinity(b) ||
        ms(b) - ms(a) ||
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

// ─── Nutrition / health scoring ────────────────────────────────────────────────
//
// MoodFood is a healthy-eating app, so every recommendation should lean
// nutritious. healthScore() rates a recipe 0–100 from its macros and ingredient
// categories (protein, vegetables, legumes, fruit, whole grains are good; added
// sugar, very high calories/fat, alcohol are penalised). isClearlyUnhealthy() is
// a conservative guardrail that keeps obviously indulgent items (sugar bombs,
// huge portions) out of recommendations entirely.

const GOOD_CATEGORIES = new Set(['vegetable', 'legume', 'fruit'])

export function healthScore(recipe: ScorableRecipe): number {
  let score = 50

  const protein = recipe.proteinG ?? 0
  const calories = recipe.calories ?? 0
  const fat = recipe.fatG ?? 0
  const carbs = recipe.carbsG ?? 0
  const cats = new Set(recipe.categories)

  // Protein density — up to +20.
  score += Math.min(protein * 0.5, 20)

  // Whole-food categories — vegetables / legumes / fruit (+7 each, capped +18).
  let plantBonus = 0
  for (const c of GOOD_CATEGORIES) if (cats.has(c)) plantBonus += 7
  score += Math.min(plantBonus, 18)

  // Whole grains / seeds — modest fibre bonus.
  if (cats.has('grain')) score += 4
  if (cats.has('seeds')) score += 3

  // Penalties.
  if (cats.has('sweetener')) score -= 12 // added sugar
  if (cats.has('alcohol')) score -= 12
  if (calories > 700) score -= 15
  else if (calories > 600) score -= 8
  if (fat > 30) score -= 8
  if (carbs > 90) score -= 6

  return clamp(Math.round(score), 0, 100)
}

/**
 * Conservative "this is not healthy food" gate. Excludes only clearly indulgent
 * recipes so balanced meals are never wrongly dropped:
 *  - very large portions (≥ 800 kcal), or
 *  - sugary, low-protein, calorie-dense items (dessert-like), or
 *  - a very low overall health score.
 */
export function isClearlyUnhealthy(recipe: ScorableRecipe): boolean {
  const protein = recipe.proteinG ?? 0
  const calories = recipe.calories ?? 0
  const cats = new Set(recipe.categories)

  if (calories >= 800) return true
  if (cats.has('sweetener') && calories >= 450 && protein < 8) return true
  if (healthScore(recipe) < 35) return true
  return false
}

function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n))
}
