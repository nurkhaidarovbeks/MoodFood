/**
 * Vision feature tests — fully offline. The OpenAI client is faked/injected, so
 * no network calls are made. Covers image validation, JSON parsing, output
 * normalisation, hallucination/non-food handling, the extract service split,
 * and the photo → recommendation one-shot (name-based ingredient matching).
 */
import { mockReset } from 'jest-mock-extended'
import prismaMock from './__mocks__/database'
import {
  VisionAiService,
  buildDataUrl,
  parseVisionJson,
  normalizeVisionResult,
  normalizeName,
  type VisionClient,
} from '../src/services/vision-ai.service'
import { VisionService } from '../src/modules/vision/vision.service'
import { RecommendationService } from '../src/modules/recommendations/recommendation.service'
import { MealAiService } from '../src/services/meal-ai.service'

// A base64 string long enough to pass the "looks like a photo" guard.
const FAKE_B64 = 'iVBORw0KGgoAAAANSUhEUg' + 'A'.repeat(300)

const fakeClient = (content: string): VisionClient => ({
  chat: {
    completions: {
      create: async () => ({ choices: [{ message: { content } }] }),
    },
  },
})

const throwingClient = (): VisionClient => ({
  chat: {
    completions: {
      create: async () => {
        throw new Error('network down')
      },
    },
  },
})

// ─── buildDataUrl (image validation) ───────────────────────────────────────────

describe('buildDataUrl', () => {
  it('accepts raw base64 with a supported mimeType', () => {
    const url = buildDataUrl({ imageBase64: FAKE_B64, mimeType: 'image/jpeg' })
    expect(url).toBe(`data:image/jpeg;base64,${FAKE_B64}`)
  })

  it('accepts and passes through a data URL', () => {
    const dataUrl = `data:image/png;base64,${FAKE_B64}`
    expect(buildDataUrl({ imageBase64: dataUrl })).toBe(dataUrl)
  })

  it('requires mimeType when given raw base64', () => {
    expect(() => buildDataUrl({ imageBase64: FAKE_B64 })).toThrow(
      expect.objectContaining({ code: 'IMAGE_MIME_REQUIRED' }),
    )
  })

  it('rejects HEIC and other unsupported formats', () => {
    expect(() =>
      buildDataUrl({ imageBase64: FAKE_B64, mimeType: 'image/heic' as any }),
    ).toThrow(expect.objectContaining({ code: 'UNSUPPORTED_IMAGE_FORMAT' }))
  })

  it('rejects non-base64 garbage', () => {
    expect(() =>
      buildDataUrl({ imageBase64: 'not valid !!!! base64 @@@', mimeType: 'image/jpeg' }),
    ).toThrow(expect.objectContaining({ code: 'INVALID_IMAGE_DATA' }))
  })

  it('rejects images larger than 10 MB', () => {
    const huge = 'A'.repeat(14 * 1024 * 1024) // ~10.5 MB decoded
    expect(() => buildDataUrl({ imageBase64: huge, mimeType: 'image/jpeg' })).toThrow(
      expect.objectContaining({ code: 'IMAGE_TOO_LARGE' }),
    )
  })
})

// ─── parseVisionJson ───────────────────────────────────────────────────────────

describe('parseVisionJson', () => {
  it('parses clean JSON', () => {
    const out = parseVisionJson('{"detectedSource":"fridge","ingredients":[]}')
    expect(out?.detectedSource).toBe('fridge')
  })

  it('strips markdown code fences', () => {
    const out = parseVisionJson('```json\n{"detectedSource":"receipt","ingredients":[]}\n```')
    expect(out?.detectedSource).toBe('receipt')
  })

  it('extracts the object from surrounding prose', () => {
    const out = parseVisionJson('Here you go: {"detectedSource":"unknown","ingredients":[]} thanks')
    expect(out?.detectedSource).toBe('unknown')
  })

  it('returns null for non-JSON garbage', () => {
    expect(parseVisionJson('totally not json')).toBeNull()
    expect(parseVisionJson('')).toBeNull()
  })
})

// ─── normalizeName ──────────────────────────────────────────────────────────────

describe('normalizeName', () => {
  it('lowercases, trims, and strips punctuation', () => {
    expect(normalizeName('  Chicken Breast!! ')).toBe('chicken breast')
    expect(normalizeName('Eggs (large)')).toBe('eggs large')
  })

  it('keeps unicode letters (cyrillic) intact', () => {
    expect(normalizeName('Молоко')).toBe('молоко')
  })
})

// ─── normalizeVisionResult ──────────────────────────────────────────────────────

describe('normalizeVisionResult', () => {
  it('clamps confidence, dedupes by name keeping highest, sorts desc', () => {
    const result = normalizeVisionResult({
      detectedSource: 'fridge',
      nonFoodDetected: false,
      ingredients: [
        { name: 'eggs', normalizedName: 'eggs', confidence: 0.4, quantity: null },
        { name: 'Eggs', normalizedName: 'eggs', confidence: 0.9, quantity: '6' }, // dup, higher
        { name: 'rice', normalizedName: 'rice', confidence: 1.5, quantity: null }, // clamp to 1
      ],
      warnings: [],
    })

    expect(result.ingredients).toHaveLength(2) // eggs deduped
    expect(result.ingredients[0]!.name).toBe('rice')
    expect(result.ingredients[0]!.confidence).toBe(1) // clamped
    const eggs = result.ingredients.find(i => i.name === 'eggs')!
    expect(eggs.confidence).toBe(0.9) // kept the higher-confidence duplicate
    expect(eggs.quantity).toBe('6')
  })

  it('flags non-food when the model says so', () => {
    const result = normalizeVisionResult({
      detectedSource: 'unknown',
      nonFoodDetected: true,
      ingredients: [],
      warnings: ['not a food photo'],
    })
    expect(result.nonFoodDetected).toBe(true)
    expect(result.ingredients).toHaveLength(0)
  })

  it('treats an empty ingredient list as non-food even if not flagged', () => {
    const result = normalizeVisionResult({
      detectedSource: 'fridge',
      nonFoodDetected: false,
      ingredients: [],
      warnings: [],
    })
    expect(result.nonFoodDetected).toBe(true)
  })

  it('falls back to "unknown" for an invalid source value', () => {
    const result = normalizeVisionResult({
      detectedSource: 'banana-stand',
      ingredients: [{ name: 'x', normalizedName: 'x', confidence: 0.5, quantity: null }],
    } as any)
    expect(result.detectedSource).toBe('unknown')
  })
})

// ─── VisionAiService.extractIngredients ─────────────────────────────────────────

describe('VisionAiService.extractIngredients', () => {
  const validJson = JSON.stringify({
    detectedSource: 'receipt',
    nonFoodDetected: false,
    ingredients: [
      { name: 'куриная грудка', normalizedName: 'chicken breast', confidence: 0.92, quantity: '500 g' },
      { name: 'Рис', normalizedName: 'white rice', confidence: 0.8, quantity: null },
    ],
    warnings: ['receipt slightly blurry'],
  })

  it('throws VISION_NOT_CONFIGURED when no API key / client', async () => {
    const svc = new VisionAiService({ apiKey: '' })
    expect(svc.enabled).toBe(false)
    await expect(
      svc.extractIngredients({ imageBase64: FAKE_B64, mimeType: 'image/jpeg' }),
    ).rejects.toMatchObject({ statusCode: 503, code: 'VISION_NOT_CONFIGURED' })
  })

  it('maps a valid model response into a normalised result', async () => {
    const svc = new VisionAiService({ client: fakeClient(validJson) })
    const res = await svc.extractIngredients({ imageBase64: FAKE_B64, mimeType: 'image/jpeg' })

    expect(res.detectedSource).toBe('receipt')
    expect(res.nonFoodDetected).toBe(false)
    expect(res.ingredients.map(i => i.name)).toEqual(['chicken breast', 'white rice'])
    expect(res.ingredients[0]!.raw).toBe('куриная грудка') // original text preserved
    expect(res.warnings).toContain('receipt slightly blurry')
  })

  it('throws VISION_PARSE_ERROR when the model returns garbage', async () => {
    const svc = new VisionAiService({ client: fakeClient('I cannot help with that') })
    await expect(
      svc.extractIngredients({ imageBase64: FAKE_B64, mimeType: 'image/jpeg' }),
    ).rejects.toMatchObject({ statusCode: 502, code: 'VISION_PARSE_ERROR' })
  })

  it('throws VISION_UPSTREAM_ERROR when the client call fails', async () => {
    const svc = new VisionAiService({ client: throwingClient() })
    await expect(
      svc.extractIngredients({ imageBase64: FAKE_B64, mimeType: 'image/jpeg' }),
    ).rejects.toMatchObject({ statusCode: 502, code: 'VISION_UPSTREAM_ERROR' })
  })

  it('validates the image before calling the model (bad format → 400)', async () => {
    const create = jest.fn()
    const svc = new VisionAiService({
      client: { chat: { completions: { create } } } as any,
    })
    await expect(
      svc.extractIngredients({ imageBase64: FAKE_B64, mimeType: 'image/heic' as any }),
    ).rejects.toMatchObject({ code: 'UNSUPPORTED_IMAGE_FORMAT' })
    expect(create).not.toHaveBeenCalled() // never reached the network
  })
})

// ─── VisionService (module orchestration) ───────────────────────────────────────

describe('VisionService.extract', () => {
  it('splits confident and low-confidence items by threshold', async () => {
    const json = JSON.stringify({
      detectedSource: 'fridge',
      nonFoodDetected: false,
      ingredients: [
        { name: 'eggs', normalizedName: 'eggs', confidence: 0.9, quantity: null },
        { name: 'maybe parsley', normalizedName: 'parsley', confidence: 0.2, quantity: null },
      ],
      warnings: [],
    })
    const visionAi = new VisionAiService({ client: fakeClient(json) })
    const svc = new VisionService(visionAi, {} as any)

    const res = await svc.extract({ imageBase64: FAKE_B64, mimeType: 'image/jpeg', minConfidence: 0.4 })

    expect(res.confident.map(i => i.name)).toEqual(['eggs'])
    expect(res.lowConfidence.map(i => i.name)).toEqual(['parsley'])
  })
})

// ─── Photo → recommendation one-shot (name-based matching) ──────────────────────

const ri = (name: string, category: string) => ({
  ingredientId: `ing-${name}`,
  amount: '1',
  unit: 'pc',
  ingredient: { id: `ing-${name}`, name, category },
})

const chickenRow = {
  id: 'r-chicken',
  title: 'Grilled Chicken Salad',
  cookingTimeMin: 25,
  difficulty: 'easy',
  estimatedCost: 6,
  calories: 450,
  proteinG: 42,
  steps: 'Grill.',
  moodTags: ['energetic'],
  recipeIngredients: [ri('chicken breast', 'meat'), ri('lettuce', 'vegetable')],
}

const riceRow = {
  id: 'r-rice',
  title: 'Egg Fried Rice',
  cookingTimeMin: 15,
  difficulty: 'easy',
  estimatedCost: 3,
  calories: 420,
  proteinG: 16,
  steps: 'Fry.',
  moodTags: ['cozy'],
  recipeIngredients: [ri('white rice', 'grain'), ri('eggs', 'dairy')],
}

const userNoRestrictions = {
  id: 'user-1',
  email: 'a@x.com',
  profile: { dietaryRestrictions: [], allergies: [], customRestrictions: [], budgetLevel: 'medium' },
}

describe('VisionService.recommendFromPhoto', () => {
  beforeEach(() => mockReset(prismaMock))

  const photoJson = JSON.stringify({
    detectedSource: 'fridge',
    nonFoodDetected: false,
    ingredients: [
      { name: 'куриная грудка', normalizedName: 'chicken breast', confidence: 0.9, quantity: null },
      { name: 'рис', normalizedName: 'white rice', confidence: 0.85, quantity: null },
      { name: 'blurry thing', normalizedName: 'mystery item', confidence: 0.2, quantity: null },
    ],
    warnings: [],
  })

  function buildService(modelJson: string) {
    const visionAi = new VisionAiService({ client: fakeClient(modelJson) })
    const rec = new RecommendationService(prismaMock as any, new MealAiService({ apiKey: '' }))
    return new VisionService(visionAi, rec)
  }

  it('extracts confident ingredients and returns dish recommendations', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)
    prismaMock.recipe.findMany.mockResolvedValueOnce([chickenRow, riceRow] as any)

    const svc = buildService(photoJson)
    const res = await svc.recommendFromPhoto('user-1', {
      imageBase64: FAKE_B64,
      mimeType: 'image/jpeg',
      minConfidence: 0.4,
    })

    // Low-confidence "mystery item" excluded from the confident set.
    expect(res.vision.confident.map(i => i.name)).toEqual(['chicken breast', 'white rice'])
    expect(res.vision.lowConfidence.map(i => i.name)).toEqual(['mystery item'])

    // Recommendations come back with name-based matchScore.
    expect(res.recommendation.options.length).toBeGreaterThan(0)
    const rice = res.recommendation.options.find(o => o.recipe.id === 'r-rice') as any
    // Egg Fried Rice needs white rice (have) + eggs (missing) → 0.5 match.
    expect(rice.matchScore).toBe(0.5)
    expect(rice.missingIngredients).toContain('eggs')
    // Never queries the saved pantry in the photo flow.
    expect(prismaMock.userIngredient.findMany).not.toHaveBeenCalled()
  })

  it('throws 422 NO_INGREDIENTS_DETECTED when nothing is confident', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)

    const lowJson = JSON.stringify({
      detectedSource: 'fridge',
      nonFoodDetected: false,
      ingredients: [{ name: 'blur', normalizedName: 'blur', confidence: 0.1, quantity: null }],
      warnings: ['very blurry'],
    })
    const svc = buildService(lowJson)

    await expect(
      svc.recommendFromPhoto('user-1', { imageBase64: FAKE_B64, mimeType: 'image/jpeg', minConfidence: 0.4 }),
    ).rejects.toMatchObject({ statusCode: 422, code: 'NO_INGREDIENTS_DETECTED' })
  })

  it('throws 422 for a non-food photo', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(userNoRestrictions as any)

    const nonFoodJson = JSON.stringify({
      detectedSource: 'unknown',
      nonFoodDetected: true,
      ingredients: [],
      warnings: ['not a food photo'],
    })
    const svc = buildService(nonFoodJson)

    await expect(
      svc.recommendFromPhoto('user-1', { imageBase64: FAKE_B64, mimeType: 'image/jpeg', minConfidence: 0.4 }),
    ).rejects.toMatchObject({ statusCode: 422, code: 'NO_INGREDIENTS_DETECTED' })
  })
})
