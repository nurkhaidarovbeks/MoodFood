import { PrismaClient } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import type { AddIngredientsInput } from './pantry.schema'

export class PantryService {
  constructor(private prisma: PrismaClient) {}

  async getIngredients(userId: string) {
    const items = await this.prisma.userIngredient.findMany({
      where: { userId },
      include: { ingredient: true },
      orderBy: { ingredient: { name: 'asc' } },
    })

    return items.map(item => ({
      id: item.id,
      ingredientId: item.ingredientId,
      name: item.ingredient.name,
      category: item.ingredient.category,
    }))
  }

  async addIngredients(userId: string, input: AddIngredientsInput) {
    const added = await Promise.all(
      input.ingredients.map(async name => {
        const ingredient = await this.prisma.ingredient.upsert({
          where: { name },
          create: { name },
          update: {},
        })

        await this.prisma.userIngredient.upsert({
          where: { userId_ingredientId: { userId, ingredientId: ingredient.id } },
          create: { userId, ingredientId: ingredient.id },
          update: {},
        })

        return { ingredientId: ingredient.id, name: ingredient.name }
      }),
    )

    return { added }
  }

  async removeIngredient(userId: string, id: string) {
    const item = await this.prisma.userIngredient.findFirst({
      where: { id, userId },
    })

    if (!item) throw new AppError(404, 'Ingredient not found in pantry', 'PANTRY_ITEM_NOT_FOUND')

    await this.prisma.userIngredient.delete({ where: { id } })
    return { message: 'Ingredient removed from pantry' }
  }

  async clearPantry(userId: string) {
    const { count } = await this.prisma.userIngredient.deleteMany({ where: { userId } })
    return { message: 'Pantry cleared', removed: count }
  }
}
