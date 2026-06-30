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
  recipeMatchScore,
  isClearlyUnhealthy,
  healthScore,
  type MoodState,
  type ScorableRecipe,
  type RecipeMatch,
} from './recommendation.scoring'
import { recommendationsTotal } from '../../services/metrics.service'
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
  fatG: number | null
  carbsG: number | null
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

    // Ingredient-availability source — unified to name-based matching:
    //  - photo flow passes explicit ingredient names
    //  - useMyIngredients reads the saved pantry and uses its ingredient names
    // Both are then scored the same way (fuzzy, staple-aware) so a recipe is
    // only "cookable" when most of its real ingredients are on hand.
    const photoNames = opts.availableIngredientNames
    const usePhoto = Array.isArray(photoNames)
    const enrich = usePhoto || input.useMyIngredients

    let availableNames: string[] = []
    if (usePhoto) {
      availableNames = photoNames!.map(n => n.toLowerCase().trim()).filter(Boolean)
    } else if (input.useMyIngredients) {
      const pantry = await this.prisma.userIngredient.findMany({
        where: { userId },
        include: { ingredient: { select: { name: true } } },
      })
      availableNames = pantry.map(p => p.ingredient.name)
    }

    const allScorables: ScorableRecipe[] = eligible.map(toScorable)

    // Healthy-eating guardrail: keep clearly indulgent items out of
    // recommendations, but fall back to the full set if too few remain so we
    // never return an empty list.
    const healthy = allScorables.filter(s => !isClearlyUnhealthy(s))
    const scorables = healthy.length >= 3 ? healthy : allScorables

    // Score every eligible recipe for how much of it the user can actually make.
    const byId = new Map(eligible.map(r => [r.id, r]))
    const matchById = new Map<string, RecipeMatch>()
    if (enrich) {
      for (const row of eligible) {
        matchById.set(
          row.id,
          recipeMatchScore(
            row.recipeIngredients.map(ri => ({
              name: ri.ingredient.name,
              category: ri.ingredient.category,
            })),
            availableNames,
          ),
        )
      }
    }

    // "Cookable" = you have at least 60% of the real (non-staple) ingredients
    // and at least one real match. If fewer than three recipes clear that bar,
    // backfill with the best-matching recipes so we always surface the closest
    // dishes to what was detected — never random ones.
    const MATCH_THRESHOLD = 0.6
    const cookableIds = new Set<string>()
    if (enrich) {
      for (const [id, m] of matchById) {
        if (m.score >= MATCH_THRESHOLD && m.matched >= 1) cookableIds.add(id)
      }
      if (cookableIds.size < 3) {
        const ranked = [...matchById.entries()]
          .filter(([, m]) => m.matched >= 1)
          .sort((a, b) => b[1].score - a[1].score)
        for (const [id] of ranked) {
          cookableIds.add(id)
          if (cookableIds.size >= 3) break
        }
      }
    }
    const isCookable = enrich ? (s: ScorableRecipe) => cookableIds.has(s.id) : undefined
    const matchScoreOf = enrich
      ? (s: ScorableRecipe) => matchById.get(s.id)?.score ?? 0
      : undefined

    const selected = selectThreeOptions(scorables, state, isCookable, matchScoreOf)

    const excludedTerms = getExcludedTermsForUser(userContext)

    // Build the per-option payload (without explanations yet).
    const options = selected.map(opt => {
      const row = byId.get(opt.recipe.id)!
      const base = {
        category: opt.category,
        fitScore: opt.fitScore,
        healthScore: healthScore(opt.recipe),
        recipe: formatRecipe(row),
      }

      if (!enrich) return base

      const m = matchById.get(opt.recipe.id) ?? recipeMatchScore([], availableNames)
      return {
        ...base,
        matchScore: m.score,
        missingIngredients: m.missing,
        substitutions: suggestSubstitutions(m.missing, excludedTerms),
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

    const result = {
      state,
      aiPowered: this.ai.aiEnabled,
      options: options.map(o => ({ ...o, explanation: explanations[o.recipe.id] ?? '' })),
    }
    recommendationsTotal.inc({
      ai_powered: String(this.ai.aiEnabled),
      via_photo: String(usePhoto),
    })
    return result
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
    fatG: row.fatG,
    carbsG: row.carbsG,
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
    fatG: row.fatG,
    carbsG: row.carbsG,
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
