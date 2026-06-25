import { PrismaClient } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import {
  filterRecipesForUser,
  getExcludedTermsForUser,
  type UserRestrictionContext,
  type RecipeForFiltering,
} from '../../services/dietary-restriction.service'
import { MealAiService, type MealToExplain } from '../../services/meal-ai.service'
import {
  selectThreeOptions,
  suggestSubstitutions,
  type MoodState,
  type ScorableRecipe,
} from './recommendation.scoring'
import type { RecommendationRequestInput } from './recommendation.schema'

// Prisma row shape we fetch (recipe + ingredients).
type RecipeRow = {
  id: string
  title: string
  cookingTimeMin: number | null
  difficulty: string | null
  estimatedCost: number | null
  calories: number | null
  proteinG: number | null
  steps: string | null
  moodTags: unknown
  recipeIngredients: Array<{
    ingredientId: string
    amount: string | null
    unit: string | null
    ingredient: { id: string; name: string; category: string | null }
  }>
}

const RECIPE_INCLUDE = {
  recipeIngredients: { include: { ingredient: true } },
} as const

export class RecommendationService {
  constructor(
    private prisma: PrismaClient,
    private ai: MealAiService,
  ) {}

  async recommend(
    userId: string,
    input: RecommendationRequestInput,
    opts: { availableIngredientNames?: string[] } = {},
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    })
    if (!user) throw new AppError(404, 'User not found', 'USER_NOT_FOUND')

    const userContext: UserRestrictionContext | null = user.profile
      ? {
          dietaryRestrictions: (user.profile.dietaryRestrictions as string[]) ?? [],
          allergies: (user.profile.allergies as string[]) ?? [],
          customRestrictions: (user.profile.customRestrictions as string[]) ?? [],
        }
      : null

    // Budget comes from the request, falling back to the profile.
    const state: MoodState = {
      mood: input.mood,
      energyLevel: input.energyLevel,
      stressLevel: input.stressLevel,
      sleepQuality: input.sleepQuality,
      hungerLevel: input.hungerLevel,
      budgetLevel: input.budgetLevel ?? (user.profile?.budgetLevel as MoodState['budgetLevel']),
    }

    // Only quick recipes when maxCookingTime is set (excludes unknown-time recipes).
    const where = input.maxCookingTime
      ? { cookingTimeMin: { lte: input.maxCookingTime } }
      : undefined

    const candidates = (await this.prisma.recipe.findMany({
      where,
      include: RECIPE_INCLUDE,
      orderBy: { title: 'asc' },
    })) as RecipeRow[]

    // Dietary restrictions are a HARD constraint — always filter through the service.
    const eligible = filterRecipesForUser(
      userContext,
      candidates as unknown as RecipeForFiltering[],
    ) as unknown as RecipeRow[]

    // Ingredient-availability source:
    //  - photo flow passes explicit ingredient names → matched BY NAME
    //  - otherwise useMyIngredients reads the saved pantry → matched BY ID
    const photoNames = opts.availableIngredientNames
    const usePhoto = Array.isArray(photoNames)
    const enrich = usePhoto || input.useMyIngredients

    let pantryIds = new Set<string>()
    if (input.useMyIngredients && !usePhoto) {
      const pantry = await this.prisma.userIngredient.findMany({
        where: { userId },
        select: { ingredientId: true },
      })
      pantryIds = new Set(pantry.map(p => p.ingredientId))
    }
    const nameSet = usePhoto
      ? new Set(photoNames!.map(n => n.toLowerCase().trim()).filter(Boolean))
      : null

    const hasIngredient = (ri: {
      ingredientId: string
      ingredient: { name: string }
    }): boolean =>
      usePhoto
        ? nameSet!.has(ri.ingredient.name.toLowerCase().trim())
        : pantryIds.has(ri.ingredientId)

    const scorables: ScorableRecipe[] = eligible.map(toScorable)
    const selected = selectThreeOptions(scorables, state)

    const byId = new Map(eligible.map(r => [r.id, r]))
    const excludedTerms = getExcludedTermsForUser(userContext)

    // Build the per-option payload (without explanations yet).
    const options = selected.map(opt => {
      const row = byId.get(opt.recipe.id)!
      const base = {
        category: opt.category,
        fitScore: opt.fitScore,
        recipe: formatRecipe(row),
      }

      if (!enrich) return base

      const total = row.recipeIngredients.length
      const matched = row.recipeIngredients.filter(hasIngredient).length
      const missing = row.recipeIngredients
        .filter(ri => !hasIngredient(ri))
        .map(ri => ri.ingredient.name)

      return {
        ...base,
        matchScore: total === 0 ? 1 : Math.round((matched / total) * 100) / 100,
        missingIngredients: missing,
        substitutions: suggestSubstitutions(missing, excludedTerms),
      }
    })

    // One batched AI call (or rule-based fallback) for all selected meals.
    const mealsToExplain: MealToExplain[] = selected.map(opt => ({
      id: opt.recipe.id,
      title: opt.recipe.title,
      category: opt.category,
      cookingTimeMin: opt.recipe.cookingTimeMin,
      estimatedCost: opt.recipe.estimatedCost,
      calories: opt.recipe.calories,
      proteinG: opt.recipe.proteinG,
    }))
    const explanations = await this.ai.explainMeals(mealsToExplain, state)

    return {
      state,
      aiPowered: this.ai.aiEnabled,
      options: options.map(o => ({ ...o, explanation: explanations[o.recipe.id] ?? '' })),
    }
  }
}

// ─── Mapping helpers ──────────────────────────────────────────────────────────

function toScorable(row: RecipeRow): ScorableRecipe {
  return {
    id: row.id,
    title: row.title,
    cookingTimeMin: row.cookingTimeMin,
    difficulty: row.difficulty,
    estimatedCost: row.estimatedCost,
    calories: row.calories,
    proteinG: row.proteinG,
    moodTags: (row.moodTags as string[]) ?? [],
    categories: row.recipeIngredients
      .map(ri => ri.ingredient.category?.toLowerCase())
      .filter((c): c is string => !!c),
  }
}

function formatRecipe(row: RecipeRow) {
  return {
    id: row.id,
    title: row.title,
    cookingTimeMin: row.cookingTimeMin,
    difficulty: row.difficulty,
    estimatedCost: row.estimatedCost,
    calories: row.calories,
    proteinG: row.proteinG,
    steps: row.steps,
    moodTags: (row.moodTags as string[]) ?? [],
    ingredients: row.recipeIngredients.map(ri => ({
      id: ri.ingredient.id,
      name: ri.ingredient.name,
      category: ri.ingredient.category,
      amount: ri.amount,
      unit: ri.unit,
    })),
  }
}
