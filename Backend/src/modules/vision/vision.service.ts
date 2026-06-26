import { AppError } from '../../middleware/errorHandler'
import {
  visionRequestsTotal,
  visionSourceTotal,
  visionIngredientsExtracted,
} from '../../services/metrics.service'
import {
  VisionAiService,
  type VisionResult,
  type ExtractedIngredient,
  type ImageInput,
} from '../../services/vision-ai.service'
import { RecommendationService } from '../recommendations/recommendation.service'
import type { VisionExtractInput, VisionRecommendInput } from './vision.schema'

export interface ExtractResponse extends VisionResult {
  /** Confident ingredients only (confidence >= minConfidence). */
  confident: ExtractedIngredient[]
  /** Items below the threshold the user may want to confirm manually. */
  lowConfidence: ExtractedIngredient[]
  minConfidence: number
}

export class VisionService {
  constructor(
    private vision: VisionAiService,
    private recommendations: RecommendationService,
  ) {}

  /** Photo → structured ingredient list (no recommendation, no DB writes). */
  async extract(input: VisionExtractInput): Promise<ExtractResponse> {
    visionRequestsTotal.inc({ endpoint: 'ingredients' })
    const result = await this.vision.extractIngredients(toImageInput(input))
    visionSourceTotal.inc({ source: result.detectedSource })
    visionIngredientsExtracted.observe(result.ingredients.length)
    return this.split(result, input.minConfidence)
  }

  /**
   * Photo → confident ingredients → 3 dish recommendations (one-shot).
   * Reuses the full recommendation pipeline, so dietary restrictions remain a
   * hard constraint and substitutions are filtered to what the user can eat.
   */
  async recommendFromPhoto(userId: string, input: VisionRecommendInput) {
    visionRequestsTotal.inc({ endpoint: 'recommendations' })
    const visionResult = await this.vision.extractIngredients(toImageInput(input))
    visionSourceTotal.inc({ source: visionResult.detectedSource })
    visionIngredientsExtracted.observe(visionResult.ingredients.length)
    const split = this.split(visionResult, input.minConfidence)

    if (split.confident.length === 0) {
      // Nothing usable — surface what we saw so the frontend can ask for a retake.
      throw new AppError(
        422,
        visionResult.nonFoodDetected
          ? 'No food ingredients were found in the photo. Try a clearer photo of your fridge, a receipt, or a food list.'
          : 'Could not read any ingredients confidently. Try a clearer, well-lit photo.',
        'NO_INGREDIENTS_DETECTED',
      )
    }

    const availableIngredientNames = split.confident.map(i => i.name)

    const recommendation = await this.recommendations.recommend(
      userId,
      {
        mood: input.mood,
        energyLevel: input.energyLevel,
        stressLevel: input.stressLevel,
        sleepQuality: input.sleepQuality,
        hungerLevel: input.hungerLevel,
        budgetLevel: input.budgetLevel,
        maxCookingTime: input.maxCookingTime,
        useMyIngredients: false, // photo names are the ingredient source instead
      },
      { availableIngredientNames },
    )

    return {
      vision: split,
      recommendation,
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private split(result: VisionResult, minConfidence: number): ExtractResponse {
    const confident = result.ingredients.filter(i => i.confidence >= minConfidence)
    const lowConfidence = result.ingredients.filter(i => i.confidence < minConfidence)

    const warnings = [...result.warnings]
    if (confident.length === 0 && lowConfidence.length > 0) {
      warnings.push('All detected items were low-confidence; please review them.')
    }

    return {
      ...result,
      warnings,
      confident,
      lowConfidence,
      minConfidence,
    }
  }
}

function toImageInput(input: { imageBase64: string; mimeType?: string }): ImageInput {
  return input.mimeType
    ? { imageBase64: input.imageBase64, mimeType: input.mimeType }
    : { imageBase64: input.imageBase64 }
}
