import { canonicalizeIngredient, ALIAS_COUNT } from '../src/services/ingredient-knowledge'

describe('canonicalizeIngredient', () => {
  it('resolves British/American spelling differences', () => {
    expect(canonicalizeIngredient('Aubergine')).toBe('eggplant')
    expect(canonicalizeIngredient('courgette')).toBe('zucchini')
    expect(canonicalizeIngredient('Capsicum')).toBe('bell pepper')
    expect(canonicalizeIngredient('coriander')).toBe('cilantro')
    expect(canonicalizeIngredient('rocket')).toBe('arugula')
  })

  it('resolves common transliterations', () => {
    expect(canonicalizeIngredient('tvorog')).toBe('cottage cheese')
    expect(canonicalizeIngredient('Smetana')).toBe('sour cream')
    expect(canonicalizeIngredient('grechka')).toBe('buckwheat')
  })

  it('resolves variants and abbreviations to a canonical name', () => {
    expect(canonicalizeIngredient('scallions')).toBe('green onion')
    expect(canonicalizeIngredient('minced beef')).toBe('ground beef')
    expect(canonicalizeIngredient('chick peas')).toBe('chickpeas')
    expect(canonicalizeIngredient('tinned tuna')).toBe('canned tuna')
    expect(canonicalizeIngredient('oatmeal')).toBe('rolled oats')
  })

  it('lowercases, trims and collapses whitespace', () => {
    expect(canonicalizeIngredient('  Greek   Yoghurt ')).toBe('greek yogurt')
  })

  it('passes unknown ingredients through cleaned', () => {
    expect(canonicalizeIngredient('Quinoa')).toBe('quinoa')
    expect(canonicalizeIngredient('dragon fruit')).toBe('dragon fruit')
  })

  it('handles empty input', () => {
    expect(canonicalizeIngredient('')).toBe('')
    expect(canonicalizeIngredient('   ')).toBe('')
  })

  it('exposes a non-trivial alias table', () => {
    expect(ALIAS_COUNT).toBeGreaterThan(50)
  })
})
