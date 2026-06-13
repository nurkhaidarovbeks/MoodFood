import { mockDeep, mockReset } from 'jest-mock-extended'
import { PrismaClient } from '@prisma/client'
import { PantryService } from '../src/modules/pantry/pantry.service'

const mockPrisma = mockDeep<PrismaClient>()
const service = new PantryService(mockPrisma as unknown as PrismaClient)

beforeEach(() => mockReset(mockPrisma))

// ─── Helpers ──────────────────────────────────────────────────────────────────

const userId = 'user-1'

function makeIngredient(id: string, name: string, category: string | null = null) {
  return { id, name, category }
}

function makePantryItem(id: string, ingredientId: string, name: string) {
  return {
    id,
    userId,
    ingredientId,
    createdAt: new Date(),
    ingredient: makeIngredient(ingredientId, name),
  }
}

// ─── getIngredients ───────────────────────────────────────────────────────────

describe('getIngredients', () => {
  it('P1. returns formatted pantry list', async () => {
    mockPrisma.userIngredient.findMany.mockResolvedValue([
      makePantryItem('pi-1', 'ing-1', 'eggs') as any,
      makePantryItem('pi-2', 'ing-2', 'rice') as any,
    ])

    const result = await service.getIngredients(userId)

    expect(result).toEqual([
      { id: 'pi-1', ingredientId: 'ing-1', name: 'eggs', category: null },
      { id: 'pi-2', ingredientId: 'ing-2', name: 'rice', category: null },
    ])
  })

  it('P2. returns empty array when pantry is empty', async () => {
    mockPrisma.userIngredient.findMany.mockResolvedValue([])
    const result = await service.getIngredients(userId)
    expect(result).toEqual([])
  })
})

// ─── addIngredients ───────────────────────────────────────────────────────────

describe('addIngredients', () => {
  it('P3. upserts ingredient and creates pantry link', async () => {
    mockPrisma.ingredient.upsert.mockResolvedValue(makeIngredient('ing-1', 'eggs') as any)
    mockPrisma.userIngredient.upsert.mockResolvedValue({} as any)

    const result = await service.addIngredients(userId, { ingredients: ['eggs'] })

    expect(mockPrisma.ingredient.upsert).toHaveBeenCalledWith({
      where: { name: 'eggs' },
      create: { name: 'eggs' },
      update: {},
    })
    expect(mockPrisma.userIngredient.upsert).toHaveBeenCalledWith({
      where: { userId_ingredientId: { userId, ingredientId: 'ing-1' } },
      create: { userId, ingredientId: 'ing-1' },
      update: {},
    })
    expect(result.added).toHaveLength(1)
    expect(result.added[0].name).toBe('eggs')
  })

  it('P4. adds multiple ingredients at once', async () => {
    mockPrisma.ingredient.upsert
      .mockResolvedValueOnce(makeIngredient('ing-1', 'eggs') as any)
      .mockResolvedValueOnce(makeIngredient('ing-2', 'rice') as any)
    mockPrisma.userIngredient.upsert.mockResolvedValue({} as any)

    const result = await service.addIngredients(userId, { ingredients: ['eggs', 'rice'] })

    expect(result.added).toHaveLength(2)
    expect(result.added.map(i => i.name)).toEqual(['eggs', 'rice'])
  })
})

// ─── removeIngredient ─────────────────────────────────────────────────────────

describe('removeIngredient', () => {
  it('P5. removes pantry item by id', async () => {
    mockPrisma.userIngredient.findFirst.mockResolvedValue(
      makePantryItem('pi-1', 'ing-1', 'eggs') as any,
    )
    mockPrisma.userIngredient.delete.mockResolvedValue({} as any)

    const result = await service.removeIngredient(userId, 'pi-1')

    expect(mockPrisma.userIngredient.delete).toHaveBeenCalledWith({ where: { id: 'pi-1' } })
    expect(result.message).toBe('Ingredient removed from pantry')
  })

  it('P6. throws 404 when pantry item not found', async () => {
    mockPrisma.userIngredient.findFirst.mockResolvedValue(null)

    await expect(service.removeIngredient(userId, 'nonexistent')).rejects.toMatchObject({
      statusCode: 404,
      code: 'PANTRY_ITEM_NOT_FOUND',
    })
  })
})

// ─── clearPantry ──────────────────────────────────────────────────────────────

describe('clearPantry', () => {
  it('P7. deletes all pantry items and returns count', async () => {
    mockPrisma.userIngredient.deleteMany.mockResolvedValue({ count: 3 })

    const result = await service.clearPantry(userId)

    expect(mockPrisma.userIngredient.deleteMany).toHaveBeenCalledWith({ where: { userId } })
    expect(result.removed).toBe(3)
  })
})
