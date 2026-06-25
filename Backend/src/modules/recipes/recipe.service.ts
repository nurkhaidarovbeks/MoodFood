import { PrismaClient } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import {
  filterRecipesForUser,
  type UserRestrictionContext,
  type RecipeForFiltering,
} from '../../services/dietary-restriction.service'
import type { RecipeCreateInput, RecipePatchInput, RecipeQueryInput } from './recipe.schema'

// ─── Response shape ────────────────────────────────────────────────────────────

function formatRecipe(recipe: {
  id: string
  title: string
  cookingTimeMin: number | null
  difficulty: string | null
  estimatedCost: number | null
  calories: number | null
  proteinG: number | null
  fatG: number | null
  carbsG: number | null
  steps: string | null
  moodTags: unknown
  recipeIngredients: Array<{
    id: string
    amount: string | null
    unit: string | null
    ingredient: { id: string; name: string; category: string | null }
  }>
}) {
  return {
    id: recipe.id,
    title: recipe.title,
    cookingTimeMin: recipe.cookingTimeMin,
    difficulty: recipe.difficulty,
    estimatedCost: recipe.estimatedCost,
    calories: recipe.calories,
    proteinG: recipe.proteinG,
    fatG: recipe.fatG,
    carbsG: recipe.carbsG,
    steps: recipe.steps,
    moodTags: (recipe.moodTags as string[]) ?? [],
    ingredients: recipe.recipeIngredients.map((ri) => ({
      id: ri.ingredient.id,
      name: ri.ingredient.name,
      category: ri.ingredient.category,
      amount: ri.amount,
      unit: ri.unit,
    })),
  }
}

// ─── Prisma include used everywhere ───────────────────────────────────────────

const RECIPE_INCLUDE = {
  recipeIngredients: {
    include: { ingredient: true },
  },
} as const

// ─── RecipeService ─────────────────────────────────────────────────────────────

export class RecipeService {
  constructor(private prisma: PrismaClient) {}

  async createRecipe(input: RecipeCreateInput) {
    const recipe = await this.prisma.recipe.create({
      data: {
        title: input.title,
        cookingTimeMin: input.cookingTimeMin ?? null,
        difficulty: input.difficulty ?? null,
        estimatedCost: input.estimatedCost ?? null,
        calories: input.calories ?? null,
        proteinG: input.proteinG ?? null,
        fatG: input.fatG ?? null,
        carbsG: input.carbsG ?? null,
        steps: input.steps ?? null,
        moodTags: input.moodTags,
        recipeIngredients: {
          create: await this.buildIngredientCreateData(input.ingredients),
        },
      },
      include: RECIPE_INCLUDE,
    })

    return formatRecipe(recipe)
  }

  async getRecipe(id: string) {
    const recipe = await this.prisma.recipe.findUnique({
      where: { id },
      include: RECIPE_INCLUDE,
    })

    if (!recipe) throw new AppError(404, 'Recipe not found', 'RECIPE_NOT_FOUND')

    return formatRecipe(recipe)
  }

  async listRecipes(query: RecipeQueryInput) {
    const where = query.mood
      ? { moodTags: { array_contains: query.mood } }
      : undefined

    const [recipes, total] = await this.prisma.$transaction([
      this.prisma.recipe.findMany({
        where,
        include: RECIPE_INCLUDE,
        skip: query.offset,
        take: query.limit,
        orderBy: { title: 'asc' },
      }),
      this.prisma.recipe.count({ where }),
    ])

    return {
      recipes: recipes.map(formatRecipe),
      total,
      limit: query.limit,
      offset: query.offset,
    }
  }

  async updateRecipe(id: string, input: RecipeCreateInput) {
    await this.assertExists(id)

    // Delete existing ingredient links, then recreate — simplest full-replace strategy
    await this.prisma.recipeIngredient.deleteMany({ where: { recipeId: id } })

    const recipe = await this.prisma.recipe.update({
      where: { id },
      data: {
        title: input.title,
        cookingTimeMin: input.cookingTimeMin ?? null,
        difficulty: input.difficulty ?? null,
        estimatedCost: input.estimatedCost ?? null,
        calories: input.calories ?? null,
        proteinG: input.proteinG ?? null,
        fatG: input.fatG ?? null,
        carbsG: input.carbsG ?? null,
        steps: input.steps ?? null,
        moodTags: input.moodTags,
        recipeIngredients: {
          create: await this.buildIngredientCreateData(input.ingredients),
        },
      },
      include: RECIPE_INCLUDE,
    })

    return formatRecipe(recipe)
  }

  async patchRecipe(id: string, input: RecipePatchInput) {
    const existing = await this.prisma.recipe.findUnique({
      where: { id },
      include: RECIPE_INCLUDE,
    })
    if (!existing) throw new AppError(404, 'Recipe not found', 'RECIPE_NOT_FOUND')

    const updateData: Record<string, unknown> = {}
    if ('title' in input && input.title !== undefined) updateData.title = input.title
    if ('cookingTimeMin' in input) updateData.cookingTimeMin = input.cookingTimeMin ?? null
    if ('difficulty' in input) updateData.difficulty = input.difficulty ?? null
    if ('estimatedCost' in input) updateData.estimatedCost = input.estimatedCost ?? null
    if ('calories' in input) updateData.calories = input.calories ?? null
    if ('proteinG' in input) updateData.proteinG = input.proteinG ?? null
    if ('fatG' in input) updateData.fatG = input.fatG ?? null
    if ('carbsG' in input) updateData.carbsG = input.carbsG ?? null
    if ('steps' in input) updateData.steps = input.steps ?? null
    if ('moodTags' in input && input.moodTags !== undefined) updateData.moodTags = input.moodTags

    // If ingredients provided, replace them; otherwise leave untouched
    if ('ingredients' in input && input.ingredients !== undefined) {
      await this.prisma.recipeIngredient.deleteMany({ where: { recipeId: id } })
      updateData.recipeIngredients = {
        create: await this.buildIngredientCreateData(input.ingredients),
      }
    }

    const recipe = await this.prisma.recipe.update({
      where: { id },
      data: updateData,
      include: RECIPE_INCLUDE,
    })

    return formatRecipe(recipe)
  }

  async deleteRecipe(id: string) {
    await this.assertExists(id)
    await this.prisma.recipe.delete({ where: { id } })
    return { message: 'Recipe deleted' }
  }

  async getRecommendations(userId: string, query: RecipeQueryInput) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    })

    if (!user) throw new AppError(404, 'User not found', 'USER_NOT_FOUND')

    const where = query.mood
      ? { moodTags: { array_contains: query.mood } }
      : undefined

    // Fetch all candidates (no pagination before filtering — filtering is in-memory)
    const candidates = await this.prisma.recipe.findMany({
      where,
      include: RECIPE_INCLUDE,
      orderBy: { title: 'asc' },
    })

    const userContext: UserRestrictionContext | null = user.profile
      ? {
          dietaryRestrictions: (user.profile.dietaryRestrictions as string[]) ?? [],
          allergies: (user.profile.allergies as string[]) ?? [],
          customRestrictions: (user.profile.customRestrictions as string[]) ?? [],
        }
      : null

    // DietaryRestrictionService is the single source of truth — always filter through it
    const filtered = filterRecipesForUser(
      userContext,
      candidates as unknown as RecipeForFiltering[],
    )

    // ─── Ingredient matching (Epic 3) ─────────────────────────────────────────
    if (query.useMyIngredients) {
      const pantryItems = await this.prisma.userIngredient.findMany({
        where: { userId },
        select: { ingredientId: true },
      })
      const pantryIds = new Set(pantryItems.map(p => p.ingredientId))

      const withScore = filtered.map(recipe => {
        const raw = recipe as unknown as {
          recipeIngredients: Array<{ ingredientId: string; ingredient: { name: string } }>
        } & Parameters<typeof formatRecipe>[0]

        const total = raw.recipeIngredients.length
        const matchedCount = raw.recipeIngredients.filter(ri =>
          pantryIds.has(ri.ingredientId),
        ).length
        const matchScore = total === 0 ? 1 : matchedCount / total
        const missingIngredients = raw.recipeIngredients
          .filter(ri => !pantryIds.has(ri.ingredientId))
          .map(ri => ri.ingredient.name)

        return {
          ...formatRecipe(raw),
          matchScore: Math.round(matchScore * 100) / 100,
          missingIngredients,
        }
      })

      const aboveThreshold = withScore
        .filter(r => r.matchScore >= query.minMatchScore)
        .sort((a, b) => b.matchScore - a.matchScore)

      const totalCount = aboveThreshold.length
      const paginated = aboveThreshold.slice(query.offset, query.offset + query.limit)

      return { recipes: paginated, total: totalCount, limit: query.limit, offset: query.offset }
    }

    // ─── Default: dietary filter only, no ingredient matching ─────────────────
    const total = filtered.length
    const paginated = filtered.slice(query.offset, query.offset + query.limit)

    return {
      recipes: paginated.map(r => formatRecipe(r as Parameters<typeof formatRecipe>[0])),
      total,
      limit: query.limit,
      offset: query.offset,
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private async assertExists(id: string) {
    const exists = await this.prisma.recipe.findUnique({ where: { id }, select: { id: true } })
    if (!exists) throw new AppError(404, 'Recipe not found', 'RECIPE_NOT_FOUND')
  }

  private async buildIngredientCreateData(
    ingredients: RecipeCreateInput['ingredients'],
  ) {
    return Promise.all(
      ingredients.map(async (ing) => {
        // Upsert ingredient by name so shared ingredients are reused
        const ingredient = await this.prisma.ingredient.upsert({
          where: { name: ing.name },
          create: { name: ing.name, category: ing.category ?? null },
          update: {},
        })

        return {
          ingredientId: ingredient.id,
          amount: ing.amount ?? null,
          unit: ing.unit ?? null,
        }
      }),
    )
  }
}
