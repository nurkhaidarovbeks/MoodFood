/**
 * Recipe service unit tests.
 * Covers CRUD, pagination, and recommendation filtering via DietaryRestrictionService.
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { RecipeService } from '../src/modules/recipes/recipe.service'

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const chickenIngredient = { id: 'ing-1', name: 'chicken breast', category: 'meat' }
const tomatoIngredient = { id: 'ing-2', name: 'cherry tomatoes', category: 'vegetable' }
const tofuIngredient = { id: 'ing-3', name: 'tofu', category: 'soy' }
const lentilIngredient = { id: 'ing-4', name: 'red lentils', category: 'legume' }

const chickenRecipe = {
  id: 'recipe-1',
  title: 'Grilled Chicken Salad',
  cookingTimeMin: 25,
  difficulty: 'easy',
  estimatedCost: 6,
  calories: 450,
  proteinG: 42,
  steps: 'Grill chicken, serve over greens.',
  moodTags: ['energetic'],
  recipeIngredients: [
    { id: 'ri-1', amount: '200', unit: 'g', ingredient: chickenIngredient },
    { id: 'ri-2', amount: '80', unit: 'g', ingredient: tomatoIngredient },
  ],
}

const veganRecipe = {
  id: 'recipe-2',
  title: 'Lentil Dal',
  cookingTimeMin: 35,
  difficulty: 'medium',
  estimatedCost: 3,
  calories: 380,
  proteinG: 18,
  steps: 'Cook lentils with spices.',
  moodTags: ['calm'],
  recipeIngredients: [
    { id: 'ri-3', amount: '150', unit: 'g', ingredient: lentilIngredient },
    { id: 'ri-4', amount: '80', unit: 'g', ingredient: tomatoIngredient },
  ],
}

const tofuRecipe = {
  id: 'recipe-3',
  title: 'Tofu Stir-Fry',
  cookingTimeMin: 20,
  difficulty: 'easy',
  estimatedCost: 4.5,
  calories: 360,
  proteinG: 22,
  steps: 'Stir-fry tofu with veggies.',
  moodTags: ['energetic', 'calm'],
  recipeIngredients: [
    { id: 'ri-5', amount: '200', unit: 'g', ingredient: tofuIngredient },
    { id: 'ri-6', amount: '100', unit: 'g', ingredient: tomatoIngredient },
  ],
}

const baseUserNoRestrictions = {
  id: 'user-1',
  email: 'alice@example.com',
  profile: {
    dietaryRestrictions: [],
    allergies: [],
    customRestrictions: [],
  },
}

const veganUser = {
  id: 'user-2',
  email: 'bob@example.com',
  profile: {
    dietaryRestrictions: ['vegan'],
    allergies: [],
    customRestrictions: [],
  },
}

const soyAllergyUser = {
  id: 'user-3',
  email: 'carol@example.com',
  profile: {
    dietaryRestrictions: [],
    allergies: ['soy_allergy'],
    customRestrictions: [],
  },
}

const customRestrictionUser = {
  id: 'user-4',
  email: 'dave@example.com',
  profile: {
    dietaryRestrictions: [],
    allergies: [],
    customRestrictions: ['lentil'],
  },
}

let recipeService: RecipeService

beforeEach(() => {
  mockReset(prismaMock)
  recipeService = new RecipeService(prismaMock as any)
  // Allow $transaction with array to resolve the underlying promises
  prismaMock.$transaction.mockImplementation((ops: any) =>
    Array.isArray(ops) ? Promise.all(ops) : ops,
  )
})

// ─── createRecipe ─────────────────────────────────────────────────────────────

describe('createRecipe', () => {
  it('creates recipe and upserts ingredients', async () => {
    prismaMock.ingredient.upsert.mockResolvedValueOnce(chickenIngredient)
    prismaMock.recipe.create.mockResolvedValueOnce(chickenRecipe as any)

    const result = await recipeService.createRecipe({
      title: 'Grilled Chicken Salad',
      cookingTimeMin: 25,
      difficulty: 'easy',
      estimatedCost: 6,
      calories: 450,
      proteinG: 42,
      steps: 'Grill chicken, serve over greens.',
      moodTags: ['energetic'],
      ingredients: [{ name: 'chicken breast', category: 'meat', amount: '200', unit: 'g' }],
    })

    expect(result.id).toBe('recipe-1')
    expect(result.title).toBe('Grilled Chicken Salad')
    expect(result.ingredients).toHaveLength(2)
    expect(prismaMock.ingredient.upsert).toHaveBeenCalledTimes(1)
    expect(prismaMock.recipe.create).toHaveBeenCalledTimes(1)
  })

  it('creates recipe with no ingredients', async () => {
    const emptyRecipe = { ...chickenRecipe, recipeIngredients: [] }
    prismaMock.recipe.create.mockResolvedValueOnce(emptyRecipe as any)

    const result = await recipeService.createRecipe({
      title: 'Grilled Chicken Salad',
      moodTags: [],
      ingredients: [],
    })

    expect(result.ingredients).toHaveLength(0)
    expect(prismaMock.ingredient.upsert).not.toHaveBeenCalled()
  })
})

// ─── getRecipe ────────────────────────────────────────────────────────────────

describe('getRecipe', () => {
  it('returns a recipe by id', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(chickenRecipe as any)

    const result = await recipeService.getRecipe('recipe-1')

    expect(result.id).toBe('recipe-1')
    expect(result.title).toBe('Grilled Chicken Salad')
    expect(result.moodTags).toEqual(['energetic'])
    expect(result.ingredients[0]!.name).toBe('chicken breast')
  })

  it('throws 404 for unknown recipe', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(null)

    await expect(recipeService.getRecipe('nonexistent')).rejects.toMatchObject({
      statusCode: 404,
      code: 'RECIPE_NOT_FOUND',
    })
  })
})

// ─── listRecipes ──────────────────────────────────────────────────────────────

describe('listRecipes', () => {
  it('returns paginated recipes with total', async () => {
    prismaMock.recipe.findMany.mockResolvedValueOnce([chickenRecipe, veganRecipe] as any)
    prismaMock.recipe.count.mockResolvedValueOnce(2)

    const result = await recipeService.listRecipes({ limit: 20, offset: 0 })

    expect(result.recipes).toHaveLength(2)
    expect(result.total).toBe(2)
    expect(result.limit).toBe(20)
    expect(result.offset).toBe(0)
  })

  it('passes mood filter to Prisma query', async () => {
    prismaMock.recipe.findMany.mockResolvedValueOnce([veganRecipe] as any)
    prismaMock.recipe.count.mockResolvedValueOnce(1)

    const result = await recipeService.listRecipes({ mood: 'calm', limit: 20, offset: 0 })

    expect(result.total).toBe(1)

    const findManyCall = prismaMock.recipe.findMany.mock.calls[0]![0] as any
    expect(findManyCall.where).toEqual({ moodTags: { array_contains: 'calm' } })
  })

  it('respects limit and offset', async () => {
    prismaMock.recipe.findMany.mockResolvedValueOnce([veganRecipe] as any)
    prismaMock.recipe.count.mockResolvedValueOnce(5)

    const result = await recipeService.listRecipes({ limit: 1, offset: 2 })

    expect(result.recipes).toHaveLength(1)
    expect(result.total).toBe(5)

    const findManyCall = prismaMock.recipe.findMany.mock.calls[0]![0] as any
    expect(findManyCall.skip).toBe(2)
    expect(findManyCall.take).toBe(1)
  })
})

// ─── updateRecipe (full replace) ──────────────────────────────────────────────

describe('updateRecipe', () => {
  it('replaces recipe ingredients and updates fields', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce({ id: 'recipe-1' } as any)
    prismaMock.recipeIngredient.deleteMany.mockResolvedValueOnce({ count: 2 } as any)
    prismaMock.ingredient.upsert.mockResolvedValueOnce(lentilIngredient)
    prismaMock.recipe.update.mockResolvedValueOnce(veganRecipe as any)

    const result = await recipeService.updateRecipe('recipe-1', {
      title: 'Lentil Dal',
      moodTags: ['calm'],
      ingredients: [{ name: 'red lentils', category: 'legume', amount: '150', unit: 'g' }],
    })

    expect(result.title).toBe('Lentil Dal')
    expect(prismaMock.recipeIngredient.deleteMany).toHaveBeenCalledWith({
      where: { recipeId: 'recipe-1' },
    })
  })

  it('throws 404 when recipe does not exist', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(null)

    await expect(
      recipeService.updateRecipe('nonexistent', { title: 'X', moodTags: [], ingredients: [] }),
    ).rejects.toMatchObject({ statusCode: 404, code: 'RECIPE_NOT_FOUND' })
  })
})

// ─── patchRecipe ──────────────────────────────────────────────────────────────

describe('patchRecipe', () => {
  it('updates only provided fields', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(chickenRecipe as any)
    const patched = { ...chickenRecipe, calories: 400 }
    prismaMock.recipe.update.mockResolvedValueOnce(patched as any)

    const result = await recipeService.patchRecipe('recipe-1', { calories: 400 })

    expect(result.calories).toBe(400)
    expect(prismaMock.recipeIngredient.deleteMany).not.toHaveBeenCalled()
  })

  it('replaces ingredients when provided', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(chickenRecipe as any)
    prismaMock.recipeIngredient.deleteMany.mockResolvedValueOnce({ count: 2 } as any)
    prismaMock.ingredient.upsert.mockResolvedValueOnce(tofuIngredient)
    prismaMock.recipe.update.mockResolvedValueOnce(tofuRecipe as any)

    const result = await recipeService.patchRecipe('recipe-1', {
      ingredients: [{ name: 'tofu', category: 'soy' }],
    })

    expect(prismaMock.recipeIngredient.deleteMany).toHaveBeenCalledTimes(1)
    expect(result.title).toBe('Tofu Stir-Fry')
  })

  it('throws 404 when recipe does not exist', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(null)

    await expect(
      recipeService.patchRecipe('nonexistent', { title: 'X' }),
    ).rejects.toMatchObject({ statusCode: 404, code: 'RECIPE_NOT_FOUND' })
  })
})

// ─── deleteRecipe ─────────────────────────────────────────────────────────────

describe('deleteRecipe', () => {
  it('deletes a recipe', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce({ id: 'recipe-1' } as any)
    prismaMock.recipe.delete.mockResolvedValueOnce(chickenRecipe as any)

    const result = await recipeService.deleteRecipe('recipe-1')

    expect(result.message).toBe('Recipe deleted')
    expect(prismaMock.recipe.delete).toHaveBeenCalledWith({ where: { id: 'recipe-1' } })
  })

  it('throws 404 when recipe does not exist', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(null)

    await expect(recipeService.deleteRecipe('nonexistent')).rejects.toMatchObject({
      statusCode: 404,
      code: 'RECIPE_NOT_FOUND',
    })
  })
})

// ─── getRecommendations ───────────────────────────────────────────────────────

describe('getRecommendations', () => {
  it('returns all recipes for user with no restrictions', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUserNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(
      [chickenRecipe, veganRecipe, tofuRecipe] as any,
    )

    const result = await recipeService.getRecommendations('user-1', { limit: 20, offset: 0 })

    expect(result.total).toBe(3)
    expect(result.recipes).toHaveLength(3)
  })

  it('filters out meat recipes for vegan user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(veganUser as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(
      [chickenRecipe, veganRecipe, tofuRecipe] as any,
    )

    const result = await recipeService.getRecommendations('user-2', { limit: 20, offset: 0 })

    // chicken breast is excluded for vegan; tofu is also excluded (vegan excludes eggs/dairy but not tofu)
    // Actually vegan excludes: meat, seafood, eggs, dairy, honey, gelatin, etc.
    // tofu is soy — not excluded for vegan
    // So vegan user gets: veganRecipe + tofuRecipe = 2
    expect(result.total).toBe(2)
    const titles = result.recipes.map((r) => r.title)
    expect(titles).not.toContain('Grilled Chicken Salad')
    expect(titles).toContain('Lentil Dal')
    expect(titles).toContain('Tofu Stir-Fry')
  })

  it('filters out tofu recipe for soy allergy user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(soyAllergyUser as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(
      [chickenRecipe, veganRecipe, tofuRecipe] as any,
    )

    const result = await recipeService.getRecommendations('user-3', { limit: 20, offset: 0 })

    expect(result.total).toBe(2)
    const titles = result.recipes.map((r) => r.title)
    expect(titles).not.toContain('Tofu Stir-Fry')
    expect(titles).toContain('Grilled Chicken Salad')
  })

  it('filters by custom restriction (lentils)', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(customRestrictionUser as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(
      [chickenRecipe, veganRecipe, tofuRecipe] as any,
    )

    const result = await recipeService.getRecommendations('user-4', { limit: 20, offset: 0 })

    const titles = result.recipes.map((r) => r.title)
    expect(titles).not.toContain('Lentil Dal')
    expect(titles).toContain('Grilled Chicken Salad')
    expect(titles).toContain('Tofu Stir-Fry')
  })

  it('paginates filtered results', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUserNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce(
      [chickenRecipe, veganRecipe, tofuRecipe] as any,
    )

    const result = await recipeService.getRecommendations('user-1', { limit: 2, offset: 1 })

    expect(result.total).toBe(3)  // total before pagination
    expect(result.recipes).toHaveLength(2)  // page size
    expect(result.offset).toBe(1)
  })

  it('passes mood filter to Prisma query', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(baseUserNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce([veganRecipe] as any)

    await recipeService.getRecommendations('user-1', { mood: 'calm', limit: 20, offset: 0 })

    const findManyCall = prismaMock.recipe.findMany.mock.calls[0]![0] as any
    expect(findManyCall.where).toEqual({ moodTags: { array_contains: 'calm' } })
  })

  it('returns all recipes when user has no profile', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({ ...baseUserNoRestrictions, profile: null } as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce([chickenRecipe, veganRecipe] as any)

    const result = await recipeService.getRecommendations('user-1', { limit: 20, offset: 0 })

    expect(result.total).toBe(2)
  })

  it('throws 404 for unknown user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)

    await expect(
      recipeService.getRecommendations('nonexistent', { limit: 20, offset: 0 }),
    ).rejects.toMatchObject({ statusCode: 404, code: 'USER_NOT_FOUND' })
  })
})
