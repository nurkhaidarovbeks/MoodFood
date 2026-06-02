import { z } from 'zod'
import { DIETARY_RESTRICTION_KEYS, DietaryRestrictionKey } from '../../services/dietary-restriction.service'

// ─── Shared sub-schemas ───────────────────────────────────────────────────────

const restrictionItem = z.string().refine(
  (val): val is DietaryRestrictionKey =>
    (DIETARY_RESTRICTION_KEYS as readonly string[]).includes(val),
  {
    message: `Must be one of: ${DIETARY_RESTRICTION_KEYS.join(', ')}`,
  },
)

const restrictionArray = z
  .array(restrictionItem)
  .transform(arr => [...new Set(arr)])

const customRestrictionArray = z
  .array(z.string().min(1, 'Restriction cannot be empty').max(100).trim())
  .transform(arr => [...new Set(arr.map(s => s.toLowerCase().trim()).filter(Boolean))])

// ─── Full upsert schema (PUT) ─────────────────────────────────────────────────

export const ProfileUpsertSchema = z.object({
  age: z.number({ invalid_type_error: 'Age must be a number' }).int().min(1).max(120).nullable().optional(),
  goal: z.string().min(1).max(500).trim().nullable().optional(),
  lifestyle: z.enum(['student', 'professional', 'other']).nullable().optional(),
  budgetLevel: z.enum(['low', 'medium', 'high']).nullable().optional(),
  dietaryRestrictions: restrictionArray.optional().default([]),
  allergies: restrictionArray.optional().default([]),
  customRestrictions: customRestrictionArray.optional().default([]),
})

// ─── Partial update schema (PATCH) ───────────────────────────────────────────
// Same fields but all optional, no defaults — unspecified fields are preserved.

export const ProfilePatchSchema = z.object({
  age: z.number({ invalid_type_error: 'Age must be a number' }).int().min(1).max(120).nullable().optional(),
  goal: z.string().min(1).max(500).trim().nullable().optional(),
  lifestyle: z.enum(['student', 'professional', 'other']).nullable().optional(),
  budgetLevel: z.enum(['low', 'medium', 'high']).nullable().optional(),
  dietaryRestrictions: restrictionArray.optional(),
  allergies: restrictionArray.optional(),
  customRestrictions: customRestrictionArray.optional(),
})

export type ProfileUpsertInput = z.infer<typeof ProfileUpsertSchema>
export type ProfilePatchInput = z.infer<typeof ProfilePatchSchema>
