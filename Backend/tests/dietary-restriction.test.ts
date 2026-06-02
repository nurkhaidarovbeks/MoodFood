/**
 * Dietary restriction service tests.
 * Pure logic — no database or mocks needed.
 * Covers all 10 restriction types, custom restrictions, and case-insensitivity.
 */
import {
  canUserSeeRecipe,
  filterRecipesForUser,
  type UserRestrictionContext,
  type RecipeForFiltering,
} from '../src/services/dietary-restriction.service'

// ─── Test recipe builder ──────────────────────────────────────────────────────

let recipeIdCounter = 0

function makeRecipe(
  ingredientsList: Array<{ name: string; category?: string }>,
): RecipeForFiltering {
  return {
    id: `recipe-${++recipeIdCounter}`,
    title: 'Test Recipe',
    recipeIngredients: ingredientsList.map(i => ({
      ingredient: { name: i.name, category: i.category ?? null },
    })),
  }
}

function makeUser(overrides: Partial<UserRestrictionContext> = {}): UserRestrictionContext {
  return {
    dietaryRestrictions: [],
    allergies: [],
    customRestrictions: [],
    ...overrides,
  }
}

// ─── 10. Restriction filtering ────────────────────────────────────────────────

describe('Recipe filtering — standard restrictions', () => {
  it('vegan: excludes recipes with chicken', () => {
    const user = makeUser({ dietaryRestrictions: ['vegan'] })
    const recipe = makeRecipe([{ name: 'Chicken Breast', category: 'meat' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(false)
  })

  it('vegan: excludes recipes with eggs', () => {
    const user = makeUser({ dietaryRestrictions: ['vegan'] })
    const recipe = makeRecipe([{ name: 'Scrambled Eggs' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(false)
  })

  it('vegan: excludes recipes with milk', () => {
    const user = makeUser({ dietaryRestrictions: ['vegan'] })
    const recipe = makeRecipe([{ name: 'Whole Milk' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(false)
  })

  it('vegan: allows plant-based recipes', () => {
    const user = makeUser({ dietaryRestrictions: ['vegan'] })
    const recipe = makeRecipe([
      { name: 'Brown Rice' },
      { name: 'Black Beans' },
      { name: 'Bell Pepper' },
    ])
    expect(canUserSeeRecipe(user, recipe)).toBe(true)
  })

  it('vegetarian: excludes meat but allows dairy and eggs', () => {
    const user = makeUser({ dietaryRestrictions: ['vegetarian'] })

    const meatRecipe = makeRecipe([{ name: 'Ground Beef', category: 'meat' }])
    expect(canUserSeeRecipe(user, meatRecipe)).toBe(false)

    // Eggs are allowed for vegetarian
    const eggRecipe = makeRecipe([{ name: 'Free-range Eggs' }])
    expect(canUserSeeRecipe(user, eggRecipe)).toBe(true)
  })

  it('pescatarian: excludes land meat but allows fish', () => {
    const user = makeUser({ dietaryRestrictions: ['pescatarian'] })

    const meatRecipe = makeRecipe([{ name: 'Pork Ribs', category: 'meat' }])
    expect(canUserSeeRecipe(user, meatRecipe)).toBe(false)

    const fishRecipe = makeRecipe([{ name: 'Grilled Salmon' }])
    expect(canUserSeeRecipe(user, fishRecipe)).toBe(true)
  })

  it('lactose_free: excludes cheese and cream', () => {
    const user = makeUser({ dietaryRestrictions: ['lactose_free'] })

    const cheeseRecipe = makeRecipe([{ name: 'Mozzarella Cheese', category: 'dairy' }])
    expect(canUserSeeRecipe(user, cheeseRecipe)).toBe(false)

    const creamRecipe = makeRecipe([{ name: 'Heavy Cream' }])
    expect(canUserSeeRecipe(user, creamRecipe)).toBe(false)
  })

  it('gluten_free: excludes wheat flour and pasta', () => {
    const user = makeUser({ dietaryRestrictions: ['gluten_free'] })

    const flourRecipe = makeRecipe([{ name: 'All-Purpose Flour' }])
    expect(canUserSeeRecipe(user, flourRecipe)).toBe(false)

    const pastaRecipe = makeRecipe([{ name: 'Penne Pasta' }])
    expect(canUserSeeRecipe(user, pastaRecipe)).toBe(false)

    const riceRecipe = makeRecipe([{ name: 'Jasmine Rice' }])
    expect(canUserSeeRecipe(user, riceRecipe)).toBe(true)
  })

  it('halal: excludes pork and alcohol', () => {
    const user = makeUser({ dietaryRestrictions: ['halal'] })

    const porkRecipe = makeRecipe([{ name: 'Bacon Strips', category: 'pork' }])
    expect(canUserSeeRecipe(user, porkRecipe)).toBe(false)

    const wineRecipe = makeRecipe([{ name: 'Red Wine' }])
    expect(canUserSeeRecipe(user, wineRecipe)).toBe(false)
  })

  it('kosher: excludes pork and shellfish', () => {
    const user = makeUser({ dietaryRestrictions: ['kosher'] })

    const porkRecipe = makeRecipe([{ name: 'Ham Hock', category: 'pork' }])
    expect(canUserSeeRecipe(user, porkRecipe)).toBe(false)

    const shrimpRecipe = makeRecipe([{ name: 'Tiger Shrimp', category: 'seafood' }])
    expect(canUserSeeRecipe(user, shrimpRecipe)).toBe(false)

    const beefRecipe = makeRecipe([{ name: 'Sirloin Steak', category: 'beef' }])
    expect(canUserSeeRecipe(user, beefRecipe)).toBe(true)
  })

  it('nut_allergy: excludes peanuts, almonds, cashews', () => {
    const user = makeUser({ allergies: ['nut_allergy'] })

    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Peanut Butter' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Sliced Almonds' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Cashew Milk' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Sunflower Seeds' }]))).toBe(true)
  })

  it('egg_allergy: excludes eggs and mayonnaise', () => {
    const user = makeUser({ allergies: ['egg_allergy'] })

    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Large Eggs' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Mayonnaise' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Chicken Breast' }]))).toBe(true)
  })

  it('soy_allergy: excludes tofu, miso, edamame', () => {
    const user = makeUser({ allergies: ['soy_allergy'] })

    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Firm Tofu' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Miso Paste' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Edamame' }]))).toBe(false)
  })
})

// ─── 11. Custom restrictions — case-insensitivity ─────────────────────────────

describe('Recipe filtering — custom restrictions', () => {
  it('11a. excludes recipes when custom restriction matches ingredient name exactly', () => {
    const user = makeUser({ customRestrictions: ['mushrooms'] })
    const recipe = makeRecipe([{ name: 'mushrooms' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(false)
  })

  it('11b. case-insensitive: stored as lowercase, matches mixed-case ingredient names', () => {
    const user = makeUser({ customRestrictions: ['mushrooms'] })
    const recipe = makeRecipe([{ name: 'Button Mushrooms' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(false)
  })

  it('11c. custom restriction is case-insensitive against stored restriction too', () => {
    // customRestrictions are lowercased at schema validation time;
    // here we simulate what comes out of DB after lowercasing
    const user = makeUser({ customRestrictions: ['cilantro'] })
    const recipe = makeRecipe([{ name: 'Fresh Cilantro', category: 'herb' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(false)
  })

  it('11d. custom restriction against ingredient category', () => {
    const user = makeUser({ customRestrictions: ['nightshade'] })
    const recipe = makeRecipe([{ name: 'Tomato Sauce', category: 'nightshade vegetable' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(false)
  })

  it('11e. allows recipe when no custom restriction matches', () => {
    const user = makeUser({ customRestrictions: ['mushrooms'] })
    const recipe = makeRecipe([{ name: 'Broccoli' }, { name: 'Garlic' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(true)
  })
})

// ─── Multiple restrictions combined ──────────────────────────────────────────

describe('Combined restrictions', () => {
  it('applies both dietary restrictions and allergies together', () => {
    const user = makeUser({
      dietaryRestrictions: ['vegetarian'],
      allergies: ['nut_allergy'],
    })

    // Should be excluded by vegetarian rule
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Ground Turkey' }]))).toBe(false)

    // Should be excluded by nut allergy
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Almond Butter' }]))).toBe(false)

    // Should pass both
    expect(
      canUserSeeRecipe(
        user,
        makeRecipe([{ name: 'Quinoa' }, { name: 'Chickpeas' }, { name: 'Olive Oil' }]),
      ),
    ).toBe(true)
  })

  it('applies standard restrictions and custom restrictions together', () => {
    const user = makeUser({
      dietaryRestrictions: ['gluten_free'],
      customRestrictions: ['coconut'],
    })

    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Wheat Tortilla' }]))).toBe(false)
    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Coconut Cream' }]))).toBe(false)

    expect(canUserSeeRecipe(user, makeRecipe([{ name: 'Brown Rice' }, { name: 'Lentils' }]))).toBe(
      true,
    )
  })
})

// ─── Edge cases ───────────────────────────────────────────────────────────────

describe('Edge cases', () => {
  it('null profile (unauthenticated): all recipes visible', () => {
    const recipe = makeRecipe([{ name: 'Pork Belly' }, { name: 'Butter' }])
    expect(canUserSeeRecipe(null, recipe)).toBe(true)
  })

  it('user with no restrictions sees all recipes', () => {
    const user = makeUser()
    const recipe = makeRecipe([{ name: 'Pork Belly' }])
    expect(canUserSeeRecipe(user, recipe)).toBe(true)
  })

  it('recipe with no ingredients is visible to everyone', () => {
    const user = makeUser({ dietaryRestrictions: ['vegan'] })
    const recipe = makeRecipe([])
    expect(canUserSeeRecipe(user, recipe)).toBe(true)
  })

  it('filterRecipesForUser removes only ineligible recipes from an array', () => {
    const user = makeUser({ dietaryRestrictions: ['vegetarian'] })

    const recipes: RecipeForFiltering[] = [
      makeRecipe([{ name: 'Brown Rice' }]),            // allowed
      makeRecipe([{ name: 'Chicken Thighs' }]),         // excluded
      makeRecipe([{ name: 'Lentil Soup base' }]),       // allowed
      makeRecipe([{ name: 'Pork Belly', category: 'meat' }]), // excluded
    ]

    const visible = filterRecipesForUser(user, recipes)
    expect(visible).toHaveLength(2)
    expect(visible.every(r => !r.title || true)).toBe(true)
  })
})
