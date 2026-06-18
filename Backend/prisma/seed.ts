import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

const recipes = [
  {
    title: 'Banana Oat Smoothie',
    cookingTimeMin: 5,
    difficulty: 'easy',
    estimatedCost: 2.5,
    calories: 320,
    proteinG: 8,
    steps: 'Blend banana, oats, almond milk, and honey until smooth. Serve cold.',
    moodTags: ['happy', 'energetic', 'calm'],
    ingredients: [
      { name: 'banana', category: 'fruit', amount: '1', unit: 'pc' },
      { name: 'rolled oats', category: 'grain', amount: '50', unit: 'g' },
      { name: 'almond milk', category: 'dairy-free', amount: '200', unit: 'ml' },
      { name: 'honey', category: 'sweetener', amount: '1', unit: 'tbsp' },
    ],
  },
  {
    title: 'Grilled Chicken Salad',
    cookingTimeMin: 25,
    difficulty: 'easy',
    estimatedCost: 6.0,
    calories: 450,
    proteinG: 42,
    steps: 'Grill chicken breast, slice and serve over mixed greens with olive oil and lemon dressing.',
    moodTags: ['energetic', 'focused'],
    ingredients: [
      { name: 'chicken breast', category: 'meat', amount: '200', unit: 'g' },
      { name: 'mixed greens', category: 'vegetable', amount: '100', unit: 'g' },
      { name: 'olive oil', category: 'oil', amount: '2', unit: 'tbsp' },
      { name: 'lemon', category: 'fruit', amount: '1', unit: 'pc' },
      { name: 'cherry tomatoes', category: 'vegetable', amount: '80', unit: 'g' },
    ],
  },
  {
    title: 'Lentil Dal',
    cookingTimeMin: 35,
    difficulty: 'medium',
    estimatedCost: 3.0,
    calories: 380,
    proteinG: 18,
    steps: 'Sauté onion and garlic, add lentils, tomatoes, cumin and turmeric. Simmer 25 minutes.',
    moodTags: ['calm', 'cozy', 'happy'],
    ingredients: [
      { name: 'red lentils', category: 'legume', amount: '150', unit: 'g' },
      { name: 'onion', category: 'vegetable', amount: '1', unit: 'pc' },
      { name: 'garlic', category: 'vegetable', amount: '3', unit: 'cloves' },
      { name: 'canned tomatoes', category: 'vegetable', amount: '200', unit: 'g' },
      { name: 'cumin', category: 'spice', amount: '1', unit: 'tsp' },
      { name: 'turmeric', category: 'spice', amount: '0.5', unit: 'tsp' },
      { name: 'olive oil', category: 'oil', amount: '2', unit: 'tbsp' },
    ],
  },
  {
    title: 'Avocado Toast with Egg',
    cookingTimeMin: 10,
    difficulty: 'easy',
    estimatedCost: 4.0,
    calories: 410,
    proteinG: 16,
    steps: 'Toast bread, mash avocado with salt and lemon, top with a fried egg.',
    moodTags: ['energetic', 'focused', 'happy'],
    ingredients: [
      { name: 'whole wheat bread', category: 'grain', amount: '2', unit: 'slices' },
      { name: 'avocado', category: 'fruit', amount: '1', unit: 'pc' },
      { name: 'eggs', category: 'dairy', amount: '2', unit: 'pcs' },
      { name: 'lemon', category: 'fruit', amount: '0.5', unit: 'pc' },
    ],
  },
  {
    title: 'Salmon with Quinoa',
    cookingTimeMin: 30,
    difficulty: 'medium',
    estimatedCost: 9.0,
    calories: 520,
    proteinG: 48,
    steps: 'Cook quinoa per package. Pan-sear salmon fillet 4 min each side. Serve with steamed broccoli.',
    moodTags: ['focused', 'energetic'],
    ingredients: [
      { name: 'salmon', category: 'fish', amount: '200', unit: 'g' },
      { name: 'quinoa', category: 'grain', amount: '80', unit: 'g' },
      { name: 'broccoli', category: 'vegetable', amount: '150', unit: 'g' },
      { name: 'olive oil', category: 'oil', amount: '1', unit: 'tbsp' },
      { name: 'garlic', category: 'vegetable', amount: '2', unit: 'cloves' },
    ],
  },
  {
    title: 'Vegetable Stir-Fry with Tofu',
    cookingTimeMin: 20,
    difficulty: 'easy',
    estimatedCost: 4.5,
    calories: 360,
    proteinG: 22,
    steps: 'Press and cube tofu, stir-fry with mixed vegetables and soy sauce over high heat.',
    moodTags: ['energetic', 'calm'],
    ingredients: [
      { name: 'tofu', category: 'soy', amount: '200', unit: 'g' },
      { name: 'bell pepper', category: 'vegetable', amount: '1', unit: 'pc' },
      { name: 'broccoli', category: 'vegetable', amount: '100', unit: 'g' },
      { name: 'carrot', category: 'vegetable', amount: '1', unit: 'pc' },
      { name: 'soy sauce', category: 'condiment', amount: '3', unit: 'tbsp' },
      { name: 'sesame oil', category: 'oil', amount: '1', unit: 'tbsp' },
    ],
  },
  {
    title: 'Greek Yogurt Parfait',
    cookingTimeMin: 5,
    difficulty: 'easy',
    estimatedCost: 3.5,
    calories: 280,
    proteinG: 20,
    steps: 'Layer Greek yogurt, granola and fresh berries in a glass. Drizzle honey on top.',
    moodTags: ['happy', 'calm', 'cozy'],
    ingredients: [
      { name: 'greek yogurt', category: 'dairy', amount: '200', unit: 'g' },
      { name: 'granola', category: 'grain', amount: '50', unit: 'g' },
      { name: 'blueberries', category: 'fruit', amount: '80', unit: 'g' },
      { name: 'strawberries', category: 'fruit', amount: '80', unit: 'g' },
      { name: 'honey', category: 'sweetener', amount: '1', unit: 'tbsp' },
    ],
  },
  {
    title: 'Beef Tacos',
    cookingTimeMin: 25,
    difficulty: 'easy',
    estimatedCost: 7.0,
    calories: 580,
    proteinG: 35,
    steps: 'Brown ground beef with taco seasoning. Serve in tortillas with salsa, cheese and sour cream.',
    moodTags: ['happy', 'cozy'],
    ingredients: [
      { name: 'ground beef', category: 'meat', amount: '300', unit: 'g' },
      { name: 'corn tortillas', category: 'grain', amount: '4', unit: 'pcs' },
      { name: 'cheddar cheese', category: 'dairy', amount: '60', unit: 'g' },
      { name: 'sour cream', category: 'dairy', amount: '50', unit: 'g' },
      { name: 'salsa', category: 'condiment', amount: '80', unit: 'g' },
      { name: 'lettuce', category: 'vegetable', amount: '50', unit: 'g' },
    ],
  },
  {
    title: 'Mushroom Risotto',
    cookingTimeMin: 40,
    difficulty: 'hard',
    estimatedCost: 5.5,
    calories: 490,
    proteinG: 12,
    steps: 'Sauté mushrooms, add arborio rice, ladle warm broth gradually, finish with parmesan.',
    moodTags: ['cozy', 'calm'],
    ingredients: [
      { name: 'arborio rice', category: 'grain', amount: '180', unit: 'g' },
      { name: 'mushrooms', category: 'vegetable', amount: '200', unit: 'g' },
      { name: 'parmesan', category: 'dairy', amount: '50', unit: 'g' },
      { name: 'butter', category: 'dairy', amount: '30', unit: 'g' },
      { name: 'onion', category: 'vegetable', amount: '1', unit: 'pc' },
      { name: 'vegetable broth', category: 'liquid', amount: '600', unit: 'ml' },
      { name: 'white wine', category: 'alcohol', amount: '100', unit: 'ml' },
    ],
  },
  {
    title: 'Chickpea Buddha Bowl',
    cookingTimeMin: 30,
    difficulty: 'easy',
    estimatedCost: 4.0,
    calories: 430,
    proteinG: 20,
    steps: 'Roast chickpeas with spices. Serve over rice with roasted sweet potato, spinach and tahini.',
    moodTags: ['calm', 'happy', 'energetic'],
    ingredients: [
      { name: 'chickpeas', category: 'legume', amount: '200', unit: 'g' },
      { name: 'sweet potato', category: 'vegetable', amount: '1', unit: 'pc' },
      { name: 'brown rice', category: 'grain', amount: '80', unit: 'g' },
      { name: 'spinach', category: 'vegetable', amount: '60', unit: 'g' },
      { name: 'tahini', category: 'condiment', amount: '2', unit: 'tbsp' },
      { name: 'olive oil', category: 'oil', amount: '1', unit: 'tbsp' },
      { name: 'cumin', category: 'spice', amount: '1', unit: 'tsp' },
    ],
  },
]

async function main() {
  // ─── Subscription plans ──────────────────────────────────────────────────
  console.log('Seeding subscription plans...')

  await prisma.subscriptionPlan.upsert({
    where:  { type: 'monthly' },
    create: { type: 'monthly', name: 'Monthly', priceKzt: 2990, priceUsd: 9.99, durationDays: 30,  description: 'Full access for 1 month' },
    update: { name: 'Monthly', priceKzt: 2990, priceUsd: 9.99, durationDays: 30,  description: 'Full access for 1 month', isActive: true },
  })

  await prisma.subscriptionPlan.upsert({
    where:  { type: 'annual' },
    create: { type: 'annual', name: 'Annual', priceKzt: 24990, priceUsd: 79.99, durationDays: 365, description: 'Full access for 1 year — save 30%' },
    update: { name: 'Annual', priceKzt: 24990, priceUsd: 79.99, durationDays: 365, description: 'Full access for 1 year — save 30%', isActive: true },
  })

  console.log('  ✓ Monthly (2,990 KZT / $9.99 / 30 days)')
  console.log('  ✓ Annual  (24,990 KZT / $79.99 / 365 days)')

  // ─── Recipes ─────────────────────────────────────────────────────────────
  console.log('\nSeeding recipes...')

  for (const r of recipes) {
    const recipe = await prisma.recipe.create({
      data: {
        title: r.title,
        cookingTimeMin: r.cookingTimeMin,
        difficulty: r.difficulty,
        estimatedCost: r.estimatedCost,
        calories: r.calories,
        proteinG: r.proteinG,
        steps: r.steps,
        moodTags: r.moodTags,
      },
    })

    for (const ing of r.ingredients) {
      const ingredient = await prisma.ingredient.upsert({
        where: { name: ing.name },
        create: { name: ing.name, category: ing.category },
        update: {},
      })

      await prisma.recipeIngredient.create({
        data: {
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          amount: ing.amount,
          unit: ing.unit,
        },
      })
    }

    console.log(`  ✓ ${recipe.title}`)
  }

  console.log(`\nDone — 2 plans + ${recipes.length} recipes seeded.`)
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(() => prisma.$disconnect())
