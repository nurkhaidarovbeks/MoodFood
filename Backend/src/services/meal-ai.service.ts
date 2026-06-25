import OpenAI from 'openai'
import { env } from '../config/env'
import {
  isLowEnergy,
  isStressed,
  isPoorSleep,
  isVeryHungry,
  type MoodState,
  type OptionCategory,
} from '../modules/recommendations/recommendation.scoring'

export interface MealToExplain {
  id: string
  title: string
  category: OptionCategory
  cookingTimeMin: number | null
  estimatedCost: number | null
  calories: number | null
  proteinG: number | null
}

const SYSTEM_PROMPT = `You are MoodFood's nutrition assistant for students and young adults.
For each meal, write ONE short, friendly sentence (max ~20 words) explaining why it fits the
user's current mood, energy, and situation. Be practical and encouraging.
Hard rules:
- NEVER give medical advice, diagnoses, or claims like "this will cure X".
- Respect that this is general healthy-eating guidance, not nutrition therapy.
- No emojis. Plain, warm, student-friendly language.`

interface MealAiOptions {
  apiKey?: string
  model?: string
}

export class MealAiService {
  private client: OpenAI | null
  private model: string

  constructor(opts: MealAiOptions = {}) {
    const apiKey = opts.apiKey ?? env.OPENAI_API_KEY
    this.model = opts.model ?? env.OPENAI_MODEL
    this.client = apiKey ? new OpenAI({ apiKey }) : null
  }

  get aiEnabled(): boolean {
    return this.client !== null
  }

  async explainMeals(
    meals: MealToExplain[],
    state: MoodState,
  ): Promise<Record<string, string>> {
    if (meals.length === 0) return {}

    if (this.client) {
      try {
        const fromAi = await this.explainViaOpenAI(this.client, meals, state)
        return this.withFallback(fromAi, meals, state)
      } catch {
        return this.allFallback(meals, state)
      }
    }

    return this.allFallback(meals, state)
  }

  // ─── OpenAI API path ─────────────────────────────────────────────────────

  private async explainViaOpenAI(
    client: OpenAI,
    meals: MealToExplain[],
    state: MoodState,
  ): Promise<Record<string, string>> {
    const userPrompt = [
      `User's current state: ${describeState(state)}.`,
      '',
      'Meals (each with its role and nutrition):',
      ...meals.map(
        m =>
          `- id=${m.id} | ${m.title} (${m.category}) | ${fmtTime(m.cookingTimeMin)}, ` +
          `${fmtCalories(m.calories)}, ${fmtProtein(m.proteinG)}, ${fmtCost(m.estimatedCost)}`,
      ),
      '',
      'Reply with ONLY a JSON array, no prose, in this exact shape:',
      '[{"id":"<id>","explanation":"<one short sentence>"}]',
    ].join('\n')

    const response = await client.chat.completions.create({
      model: this.model,
      max_tokens: 600,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userPrompt },
      ],
    })

    const text = response.choices[0]?.message?.content?.trim() ?? ''
    return parseExplanationJson(text)
  }

  private withFallback(
    fromAi: Record<string, string>,
    meals: MealToExplain[],
    state: MoodState,
  ): Record<string, string> {
    const out: Record<string, string> = {}
    for (const meal of meals) {
      const ai = fromAi[meal.id]?.trim()
      out[meal.id] = ai && ai.length > 0 ? ai : ruleBasedExplanation(meal, state)
    }
    return out
  }

  private allFallback(meals: MealToExplain[], state: MoodState): Record<string, string> {
    const out: Record<string, string> = {}
    for (const meal of meals) out[meal.id] = ruleBasedExplanation(meal, state)
    return out
  }
}

// ─── Rule-based fallback ──────────────────────────────────────────────────────

export function ruleBasedExplanation(meal: MealToExplain, state: MoodState): string {
  const parts: string[] = []
  const protein = meal.proteinG ?? 0

  if (isLowEnergy(state)) {
    parts.push(
      protein >= 20
        ? `Packed with ${Math.round(protein)}g of protein for a steady energy lift`
        : 'A balanced pick to gently raise your energy',
    )
  } else if (isStressed(state)) {
    parts.push('A simple, balanced meal to help you unwind')
  } else if (isPoorSleep(state)) {
    parts.push('Light but satisfying — easy on the body after poor sleep')
  } else if (isVeryHungry(state)) {
    parts.push('Filling and hearty to properly satisfy your hunger')
  }

  switch (meal.category) {
    case 'fastest':
      parts.push(
        meal.cookingTimeMin != null
          ? `ready in just ${meal.cookingTimeMin} min`
          : 'one of the quickest options',
      )
      break
    case 'cheapest':
      parts.push(
        meal.estimatedCost != null
          ? `budget-friendly at about $${meal.estimatedCost.toFixed(2)}`
          : 'an easy-on-the-wallet choice',
      )
      break
    case 'healthiest':
      parts.push('the most nourishing fit for how you feel right now')
      break
  }

  if (parts.length === 0) {
    return `${meal.title} is a great, balanced choice right now.`
  }

  const sentence = parts.join(', ')
  return sentence.charAt(0).toUpperCase() + sentence.slice(1) + '.'
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function describeState(state: MoodState): string {
  const bits: string[] = []
  if (state.mood) bits.push(`mood: ${state.mood}`)
  if (typeof state.energyLevel === 'number') bits.push(`energy: ${state.energyLevel}/5`)
  if (state.stressLevel) bits.push(`stress: ${state.stressLevel}`)
  if (state.sleepQuality) bits.push(`sleep: ${state.sleepQuality}`)
  if (state.hungerLevel) bits.push(`hunger: ${state.hungerLevel}`)
  return bits.length > 0 ? bits.join(', ') : 'no specific state given'
}

function fmtTime(min: number | null): string {
  return min != null ? `${min} min` : 'time unknown'
}
function fmtCalories(c: number | null): string {
  return c != null ? `${Math.round(c)} kcal` : 'calories unknown'
}
function fmtProtein(p: number | null): string {
  return p != null ? `${Math.round(p)}g protein` : 'protein unknown'
}
function fmtCost(c: number | null): string {
  return c != null ? `~$${c.toFixed(2)}` : 'cost unknown'
}

function parseExplanationJson(text: string): Record<string, string> {
  const start = text.indexOf('[')
  const end = text.lastIndexOf(']')
  if (start === -1 || end === -1 || end < start) return {}

  const parsed = JSON.parse(text.slice(start, end + 1)) as unknown
  if (!Array.isArray(parsed)) return {}

  const out: Record<string, string> = {}
  for (const item of parsed) {
    if (
      item &&
      typeof item === 'object' &&
      typeof (item as any).id === 'string' &&
      typeof (item as any).explanation === 'string'
    ) {
      out[(item as any).id] = (item as any).explanation
    }
  }
  return out
}
