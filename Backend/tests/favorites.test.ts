import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import { FavoritesService } from '../src/modules/favorites/favorites.service'

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const recipeBase = {
  id: 'recipe-1',
  title: 'Grilled Chicken Salad',
  cookingTimeMin: 25,
  difficulty: 'easy',
  estimatedCost: 6,
  calories: 450,
  proteinG: 42,
  fatG: 18,
  carbsG: 10,
  steps: 'Grill and serve.',
  moodTags: ['energetic'],
  recipeIngredients: [
    {
      id: 'ri-1',
      amount: '200',
      unit: 'g',
      ingredient: { id: 'ing-1', name: 'chicken breast', category: 'meat' },
    },
  ],
}

const favoriteBase = {
  id: 'fav-1',
  userId: 'user-1',
  recipeId: 'recipe-1',
  createdAt: new Date('2026-06-25T10:00:00Z'),
  recipe: recipeBase,
}

let service: FavoritesService

beforeEach(() => {
  mockReset(prismaMock)
  service = new FavoritesService(prismaMock as any)
  prismaMock.$transaction.mockImplementation((ops: any) =>
    Array.isArray(ops) ? Promise.all(ops) : ops,
  )
})

// ─── getFavorites ─────────────────────────────────────────────────────────────

describe('getFavorites', () => {
  it('returns paginated list of favorites with recipe data', async () => {
    prismaMock.userFavorite.findMany.mockResolvedValueOnce([favoriteBase] as any)
    prismaMock.userFavorite.count.mockResolvedValueOnce(1)

    const result = await service.getFavorites('user-1', { limit: 20, offset: 0 })

    expect(result.total).toBe(1)
    expect(result.favorites).toHaveLength(1)
    expect(result.favorites[0]!.favoriteId).toBe('fav-1')
    expect(result.favorites[0]!.recipe.title).toBe('Grilled Chicken Salad')
    expect(result.favorites[0]!.recipe.fatG).toBe(18)
    expect(result.favorites[0]!.recipe.carbsG).toBe(10)
  })

  it('returns empty list when user has no favorites', async () => {
    prismaMock.userFavorite.findMany.mockResolvedValueOnce([])
    prismaMock.userFavorite.count.mockResolvedValueOnce(0)

    const result = await service.getFavorites('user-1', { limit: 20, offset: 0 })

    expect(result.total).toBe(0)
    expect(result.favorites).toHaveLength(0)
  })
})

// ─── addFavorite ──────────────────────────────────────────────────────────────

describe('addFavorite', () => {
  it('adds recipe to favorites and returns full recipe data', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce({ id: 'recipe-1' } as any)
    prismaMock.userFavorite.findUnique.mockResolvedValueOnce(null)
    prismaMock.userFavorite.create.mockResolvedValueOnce(favoriteBase as any)

    const result = await service.addFavorite('user-1', { recipeId: 'recipe-1' })

    expect(result.favoriteId).toBe('fav-1')
    expect(result.recipe.id).toBe('recipe-1')
    expect(prismaMock.userFavorite.create).toHaveBeenCalledTimes(1)
  })

  it('throws 404 when recipe does not exist', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce(null)

    await expect(
      service.addFavorite('user-1', { recipeId: 'nonexistent' }),
    ).rejects.toMatchObject({ statusCode: 404, code: 'RECIPE_NOT_FOUND' })
  })

  it('throws 409 when recipe already favorited', async () => {
    prismaMock.recipe.findUnique.mockResolvedValueOnce({ id: 'recipe-1' } as any)
    prismaMock.userFavorite.findUnique.mockResolvedValueOnce(favoriteBase as any)

    await expect(
      service.addFavorite('user-1', { recipeId: 'recipe-1' }),
    ).rejects.toMatchObject({ statusCode: 409, code: 'ALREADY_FAVORITED' })
  })
})

// ─── removeFavorite ───────────────────────────────────────────────────────────

describe('removeFavorite', () => {
  it('removes favorite and returns confirmation message', async () => {
    prismaMock.userFavorite.findFirst.mockResolvedValueOnce(favoriteBase as any)
    prismaMock.userFavorite.delete.mockResolvedValueOnce(favoriteBase as any)

    const result = await service.removeFavorite('user-1', 'fav-1')

    expect(result.message).toBe('Recipe removed from favorites')
    expect(prismaMock.userFavorite.delete).toHaveBeenCalledWith({ where: { id: 'fav-1' } })
  })

  it('throws 404 when favorite not found or belongs to another user', async () => {
    prismaMock.userFavorite.findFirst.mockResolvedValueOnce(null)

    await expect(service.removeFavorite('user-1', 'fav-999')).rejects.toMatchObject({
      statusCode: 404,
      code: 'FAVORITE_NOT_FOUND',
    })
  })
})

// ─── isFavorite ───────────────────────────────────────────────────────────────

describe('isFavorite', () => {
  it('returns true with favoriteId when recipe is favorited', async () => {
    prismaMock.userFavorite.findUnique.mockResolvedValueOnce({ id: 'fav-1' } as any)

    const result = await service.isFavorite('user-1', 'recipe-1')

    expect(result.isFavorite).toBe(true)
    expect(result.favoriteId).toBe('fav-1')
  })

  it('returns false with null favoriteId when not favorited', async () => {
    prismaMock.userFavorite.findUnique.mockResolvedValueOnce(null)

    const result = await service.isFavorite('user-1', 'recipe-1')

    expect(result.isFavorite).toBe(false)
    expect(result.favoriteId).toBeNull()
  })
})
