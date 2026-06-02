interface ProfileFields {
  age?: number | null
  goal?: string | null
  lifestyle?: string | null
  budgetLevel?: string | null
}

/**
 * A profile is "complete" when the four required nutrition fields are all filled.
 * Dietary restrictions and allergies are optional bonus data, not required for completion.
 */
export function isProfileComplete(profile: ProfileFields | null): boolean {
  if (!profile) return false
  return (
    profile.age !== null &&
    profile.age !== undefined &&
    typeof profile.age === 'number' &&
    Boolean(profile.goal?.trim()) &&
    profile.lifestyle !== null &&
    profile.lifestyle !== undefined &&
    profile.budgetLevel !== null &&
    profile.budgetLevel !== undefined
  )
}
