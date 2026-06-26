import { PrismaClient } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import type { FavoriteAddInput, FavoritesQueryInput } from './favorites.schema'
import { favoritesTotal } from '../../services/metrics.service'

const RECIPE_INCLUDE = {
  recipeIngredients: {
    include: { ingredient: true },
  },
} as const

export class FavoritesService {
  constructor(private prisma: PrismaClient) {}

  async getFavorites(userId: string, query: FavoritesQueryInput) {
    const [items, total] = await this.prisma.$transaction([
      this.prisma.userFavorite.findMany({
        where: { userId },
        include: { recipe: { include: RECIPE_INCLUDE } },
        orderBy: { createdAt: 'desc' },
        skip: query.offset,
        take: query.limit,
      }),
      this.prisma.userFavorite.count({ where: { userId } }),
    ])

    return {
      favorites: items.map((f) => ({
        favoriteId: f.id,
        savedAt: f.createdAt,
        recipe: this.formatRecipe(f.recipe),
      })),
      total,
      limit: query.limit,
      offset: query.offset,
    }
  }

  async addFavorite(userId: string, input: FavoriteAddInput) {
    const recipe = await this.prisma.recipe.findUnique({
      where: { id: input.recipeId },
      select: { id: true },
    })
    if (!recipe) throw new AppError(404, 'Recipe not found', 'RECIPE_NOT_FOUND')

    const existing = await this.prisma.userFavorite.findUnique({
      where: { userId_recipeId: { userId, recipeId: input.recipeId } },
    })
    if (existing) throw new AppError(409, 'Recipe already in favorites', 'ALREADY_FAVORITED')

    favoritesTotal.inc({ action: 'add' })
    const favorite = await this.prisma.userFavorite.create({
      data: { userId, recipeId: input.recipeId },
      include: { recipe: { include: RECIPE_INCLUDE } },
    })

    return {
      favoriteId: favorite.id,
      savedAt: favorite.createdAt,
      recipe: this.formatRecipe(favorite.recipe),
    }
  }

  async removeFavorite(userId: string, favoriteId: string) {
    const item = await this.prisma.userFavorite.findFirst({
      where: { id: favoriteId, userId },
    })
    if (!item) throw new AppError(404, 'Favorite not found', 'FAVORITE_NOT_FOUND')

    await this.prisma.userFavorite.delete({ where: { id: favoriteId } })
    favoritesTotal.inc({ action: 'remove' })
    return { message: 'Recipe removed from favorites' }
  }

  async isFavorite(userId: string, recipeId: string) {
    const item = await this.prisma.userFavorite.findUnique({
      where: { userId_recipeId: { userId, recipeId } },
      select: { id: true },
    })
    return { isFavorite: item !== null, favoriteId: item?.id ?? null }
  }

  private formatRecipe(recipe: {
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
}
