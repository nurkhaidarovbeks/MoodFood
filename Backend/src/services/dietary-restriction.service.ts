/**
 * DietaryRestrictionService
 *
 * Central place for all dietary restriction logic.
 * Any backend endpoint that returns recipes MUST filter through canUserSeeRecipe()
 * or filterRecipesForUser() — never rely on the frontend to filter.
 */

// ─── Restriction keys (canonical values stored in DB) ────────────────────────

export const DIETARY_RESTRICTION_KEYS = [
  'vegan',
  'vegetarian',
  'pescatarian',
  'lactose_free',
  'gluten_free',
  'halal',
  'kosher',
  'nut_allergy',
  'egg_allergy',
  'soy_allergy',
] as const

export type DietaryRestrictionKey = typeof DIETARY_RESTRICTION_KEYS[number]

// ─── Ingredient term exclusions per restriction ───────────────────────────────
//
// Matching: an ingredient is excluded if its name or category CONTAINS any term
// (case-insensitive substring match). This catches "chicken breast", "whole milk",
// "all-purpose flour", etc.

export const RESTRICTION_EXCLUSIONS: Record<DietaryRestrictionKey, string[]> = {
  vegan: [
    // Meat
    'meat', 'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'veal', 'venison', 'bison', 'goat',
    // Seafood
    'fish', 'salmon', 'tuna', 'cod', 'tilapia', 'bass', 'trout', 'halibut', 'snapper', 'sardine', 'herring',
    'seafood', 'shrimp', 'prawn', 'lobster', 'crab', 'oyster', 'clam', 'mussel', 'scallop', 'squid', 'octopus',
    // Eggs & Dairy
    'egg', 'eggs',
    'milk', 'cheese', 'yogurt', 'butter', 'cream', 'whey', 'casein', 'lactose',
    'mozzarella', 'parmesan', 'cheddar', 'brie', 'ricotta', 'ghee',
    // Other animal products
    'honey', 'gelatin', 'lard', 'anchovy', 'anchovies', 'worcestershire', 'suet', 'tallow',
  ],
  vegetarian: [
    // Meat
    'meat', 'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'veal', 'venison', 'bison', 'goat',
    // Seafood
    'fish', 'salmon', 'tuna', 'cod', 'tilapia', 'bass', 'trout', 'halibut', 'snapper', 'sardine', 'herring',
    'seafood', 'shrimp', 'prawn', 'lobster', 'crab', 'oyster', 'clam', 'mussel', 'scallop', 'squid', 'octopus',
    // Animal-derived
    'gelatin', 'lard', 'anchovy', 'anchovies', 'suet', 'tallow',
  ],
  pescatarian: [
    // Land meat only (fish/seafood is allowed)
    'meat', 'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'veal', 'venison', 'bison', 'goat',
    'lard', 'suet', 'tallow',
  ],
  lactose_free: [
    'milk', 'cheese', 'yogurt', 'butter', 'cream', 'whey', 'casein', 'lactose',
    'dairy', 'mozzarella', 'parmesan', 'cheddar', 'brie', 'ricotta', 'ghee',
    'buttermilk', 'sour cream', 'half-and-half', 'kefir',
  ],
  gluten_free: [
    'wheat', 'flour', 'bread', 'pasta', 'barley', 'rye', 'gluten',
    'semolina', 'spelt', 'couscous', 'bulgur', 'farro', 'malt', 'triticale',
    'breadcrumbs', 'croutons',
    // Traditional soy sauce contains wheat; specifically excluded here
    'soy sauce',
  ],
  halal: [
    'pork', 'bacon', 'ham', 'lard', 'prosciutto', 'pancetta', 'salami',
    'alcohol', 'wine', 'beer', 'rum', 'vodka', 'whiskey', 'brandy', 'liqueur', 'sake', 'mirin',
  ],
  kosher: [
    // Forbidden meats
    'pork', 'bacon', 'ham', 'lard', 'prosciutto',
    // Shellfish
    'shellfish', 'shrimp', 'prawn', 'lobster', 'crab', 'oyster', 'clam', 'mussel', 'scallop',
  ],
  nut_allergy: [
    'nuts', 'nut',
    'peanut', 'peanuts', 'peanut butter',
    'almond', 'almonds', 'almond milk', 'almond flour',
    'walnut', 'walnuts',
    'cashew', 'cashews',
    'hazelnut', 'hazelnuts', 'nutella',
    'pistachio', 'pistachios',
    'pecan', 'pecans',
    'macadamia',
    'brazil nut', 'pine nut', 'pine nuts',
    'marzipan', 'praline', 'gianduja',
  ],
  egg_allergy: [
    'egg', 'eggs', 'mayonnaise', 'mayo', 'meringue', 'albumin', 'albumen',
  ],
  soy_allergy: [
    'soy', 'tofu', 'soy sauce', 'edamame', 'miso', 'tempeh', 'soya',
    'soymilk', 'soy milk', 'textured vegetable protein', 'tvp', 'natto',
    'yuba', 'okara',
  ],
}

// ─── Types ────────────────────────────────────────────────────────────────────

export interface RecipeIngredientEntry {
  ingredient: {
    name: string
    category: string | null
  }
}

export interface RecipeForFiltering {
  id: string
  title: string
  recipeIngredients: RecipeIngredientEntry[]
}

export interface UserRestrictionContext {
  dietaryRestrictions: string[]
  allergies: string[]
  customRestrictions: string[]
}

// ─── Core matching logic ──────────────────────────────────────────────────────

function ingredientMatchesTerm(
  ingredientName: string,
  category: string | null,
  term: string,
): boolean {
  const nameLower = ingredientName.toLowerCase()
  const catLower = (category ?? '').toLowerCase()
  const termLower = term.toLowerCase()
  return nameLower.includes(termLower) || catLower.includes(termLower)
}

function buildExcludedTerms(restrictions: string[], allergies: string[]): string[] {
  const terms = new Set<string>()
  for (const key of [...restrictions, ...allergies]) {
    const exclusions = RESTRICTION_EXCLUSIONS[key as DietaryRestrictionKey]
    if (exclusions) {
      exclusions.forEach(t => terms.add(t.toLowerCase()))
    }
  }
  return Array.from(terms)
}

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * Returns true if the user is allowed to see this recipe given their restrictions.
 *
 * This is the single source of truth for recipe eligibility.
 * All recommendation/search endpoints MUST call this (or filterRecipesForUser).
 */
export function canUserSeeRecipe(
  userProfile: UserRestrictionContext | null,
  recipe: RecipeForFiltering,
): boolean {
  if (!userProfile) return true
  if (!recipe.recipeIngredients.length) return true

  const { dietaryRestrictions, allergies, customRestrictions } = userProfile

  if (!dietaryRestrictions.length && !allergies.length && !customRestrictions.length) {
    return true
  }

  const excludedTerms = buildExcludedTerms(dietaryRestrictions, allergies)
  const normalizedCustom = customRestrictions
    .map(r => r.toLowerCase().trim())
    .filter(Boolean)

  for (const ri of recipe.recipeIngredients) {
    const { name, category } = ri.ingredient

    // Check standard restriction exclusions
    for (const term of excludedTerms) {
      if (ingredientMatchesTerm(name, category, term)) return false
    }

    // Check custom free-text restrictions (case-insensitive substring match)
    for (const custom of normalizedCustom) {
      if (
        name.toLowerCase().includes(custom) ||
        (category ?? '').toLowerCase().includes(custom)
      ) {
        return false
      }
    }
  }

  return true
}

/**
 * Returns the lowercased exclusion terms implied by a user's restrictions and
 * allergies (plus their custom free-text restrictions). Used by the
 * recommendation engine to avoid suggesting unsafe ingredient substitutions.
 */
export function getExcludedTermsForUser(userProfile: UserRestrictionContext | null): string[] {
  if (!userProfile) return []
  const terms = buildExcludedTerms(userProfile.dietaryRestrictions, userProfile.allergies)
  const custom = userProfile.customRestrictions
    .map(r => r.toLowerCase().trim())
    .filter(Boolean)
  return Array.from(new Set([...terms, ...custom]))
}

/**
 * Filters an array of recipes, removing any the user cannot see.
 * Drop-in helper for recommendation / search endpoints.
 */
export function filterRecipesForUser<T extends RecipeForFiltering>(
  userProfile: UserRestrictionContext | null,
  recipes: T[],
): T[] {
  return recipes.filter(recipe => canUserSeeRecipe(userProfile, recipe))
}
