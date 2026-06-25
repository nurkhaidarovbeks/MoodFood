/**
 * Ingredient knowledge base — makes product understanding robust "under any
 * circumstances": British/American spellings, common transliterations the vision
 * model may emit, plurals, and brand-ish variants all resolve to one canonical
 * English name. Used by:
 *   - recommendation matching (recommendation.scoring.ingredientMatches)
 *   - photo extraction (vision-ai normalizeVisionResult)
 * so the same product is recognised whatever form it arrives in.
 */

// alias (lowercase) → canonical English ingredient name (lowercase, singular-ish)
const INGREDIENT_ALIASES: Record<string, string> = {
  // ─── Vegetables (British/American + variants) ─────────────────────────────
  aubergine: 'eggplant',
  courgette: 'zucchini',
  capsicum: 'bell pepper',
  'sweet pepper': 'bell pepper',
  'green pepper': 'bell pepper',
  'red pepper': 'bell pepper',
  'yellow pepper': 'bell pepper',
  pepper: 'bell pepper',
  rocket: 'arugula',
  coriander: 'cilantro',
  'spring onion': 'green onion',
  'spring onions': 'green onion',
  scallion: 'green onion',
  scallions: 'green onion',
  'green onions': 'green onion',
  'mangetout': 'snow peas',
  beetroot: 'beet',
  'swede': 'rutabaga',
  rocketsalad: 'arugula',
  'cherry tomato': 'cherry tomatoes',
  'plum tomato': 'tomato',
  'tinned tomatoes': 'canned tomatoes',
  'tinned tomato': 'canned tomatoes',
  'chili': 'chili pepper',
  'chilli': 'chili pepper',
  'chile': 'chili pepper',

  // ─── Dairy & eggs ─────────────────────────────────────────────────────────
  curd: 'cottage cheese',
  'cottage cheese': 'cottage cheese',
  tvorog: 'cottage cheese',
  'quark': 'cottage cheese',
  smetana: 'sour cream',
  'soured cream': 'sour cream',
  'natural yogurt': 'yogurt',
  'natural yoghurt': 'yogurt',
  yoghurt: 'yogurt',
  'greek yoghurt': 'greek yogurt',
  'plain yogurt': 'yogurt',
  ryazhenka: 'yogurt',
  'whole milk': 'milk',
  'skim milk': 'milk',
  'skimmed milk': 'milk',
  'semi-skimmed milk': 'milk',
  'dairy milk': 'milk',
  'cows milk': 'milk',
  'soured milk': 'kefir',
  'hard cheese': 'cheese',
  'cheddar': 'cheddar cheese',
  'parmesan cheese': 'parmesan',
  'feta cheese': 'feta',
  'mozzarella cheese': 'mozzarella',
  egg: 'eggs',
  'chicken egg': 'eggs',
  'hen egg': 'eggs',

  // ─── Meat, poultry, fish ──────────────────────────────────────────────────
  'chicken fillet': 'chicken breast',
  'chicken filet': 'chicken breast',
  'chicken breast fillet': 'chicken breast',
  'minced beef': 'ground beef',
  'beef mince': 'ground beef',
  'minced meat': 'ground beef',
  'minced turkey': 'ground turkey',
  'turkey mince': 'ground turkey',
  'minced chicken': 'ground chicken',
  'pork mince': 'ground pork',
  'sausages': 'sausage',
  'wiener': 'sausage',
  'frankfurter': 'sausage',
  'tinned tuna': 'canned tuna',
  'tuna': 'canned tuna',
  'prawns': 'shrimp',
  'prawn': 'shrimp',

  // ─── Grains, bread, pasta ─────────────────────────────────────────────────
  'wholewheat bread': 'whole wheat bread',
  'wholemeal bread': 'whole wheat bread',
  'brown bread': 'whole wheat bread',
  'white bread': 'bread',
  'loaf': 'bread',
  'baton': 'bread',
  'oats': 'rolled oats',
  'oatmeal': 'rolled oats',
  'porridge oats': 'rolled oats',
  grechka: 'buckwheat',
  'buckwheat groats': 'buckwheat',
  'pasta': 'pasta',
  'spaghetti': 'pasta',
  'macaroni': 'pasta',
  'penne': 'pasta',
  'noodles': 'noodles',
  'tortillas': 'flour tortilla',
  'tortilla': 'flour tortilla',
  'wrap': 'flour tortilla',
  'basmati rice': 'white rice',
  'jasmine rice': 'white rice',
  'long grain rice': 'white rice',

  // ─── Legumes, nuts, seeds ─────────────────────────────────────────────────
  'chick peas': 'chickpeas',
  'garbanzo beans': 'chickpeas',
  'garbanzo': 'chickpeas',
  'red lentil': 'red lentils',
  'lentil': 'red lentils',
  'lentils': 'red lentils',
  'kidney beans': 'beans',
  'black beans': 'black beans',
  'white beans': 'beans',
  'cannellini beans': 'beans',
  'peanuts': 'peanut',
  'groundnut': 'peanut',
  'peanut paste': 'peanut butter',

  // ─── Fruit ────────────────────────────────────────────────────────────────
  'banana': 'banana',
  'bananas': 'banana',
  'avocados': 'avocado',
  'blueberry': 'blueberries',
  'strawberry': 'strawberries',
  'mixed berries': 'berries',
  'berry': 'berries',

  // ─── Oils, condiments, misc ───────────────────────────────────────────────
  'olive oil extra virgin': 'olive oil',
  'extra virgin olive oil': 'olive oil',
  'veg oil': 'vegetable oil',
  'sunflower oil': 'vegetable oil',
  'soy sauce': 'soy sauce',
  'soya sauce': 'soy sauce',
  'tomato paste': 'tomato paste',
  'tomato puree': 'tomato paste',
}

/**
 * Resolves any ingredient name to its canonical English form. Lowercases,
 * trims, collapses whitespace, then looks up the alias table. Unknown names
 * pass through cleaned but otherwise unchanged.
 */
export function canonicalizeIngredient(name: string): string {
  const cleaned = (name ?? '').toLowerCase().trim().replace(/\s+/g, ' ')
  if (!cleaned) return ''
  return INGREDIENT_ALIASES[cleaned] ?? cleaned
}

/** Number of known aliases — handy for tests / diagnostics. */
export const ALIAS_COUNT = Object.keys(INGREDIENT_ALIASES).length
