/// Maps a recipe title to an appetising, on-topic food photo.
///
/// The backend does not ship an image for a recipe, so the frontend derives
/// one from the title. Matching is **priority-ordered** (not just longest
/// keyword) so proteins / signature dishes win over generic sides — e.g.
/// "Chicken Vegetable Soup" resolves to soup, not broccoli. Every entry below
/// is a verified Unsplash photo (HTTP 200), and the fallback is still a real
/// food photo, so no recipe ever shows a bare placeholder.
class RecipePhoto {
  RecipePhoto._();

  static const _base = 'https://images.unsplash.com/';
  static String _u(String id) => '$_base$id?w=800&q=80&fit=crop';

  // ─── Verified photos ──────────────────────────────────────────────────────
  static final _smoothie = _u('photo-1553530666-ba11a7da3888');
  static final _egg = _u('photo-1482049016688-2d3e1b311543');
  static final _oats = _u('photo-1571748982800-fa51082c2224');
  static final _blueberry = _u('photo-1498557850523-fd3d118b962e');
  static final _strawberry = _u('photo-1464965911861-746a04b4bca6');
  static final _berry = _u('photo-1498557850523-fd3d118b962e');
  static final _avocado = _u('photo-1523049673857-eb18f1d7b578');
  static final _quinoa = _u('photo-1646842762133-0e9e2c0038a0');
  static final _chicken = _u('photo-1604908176997-125f25cc6f3d');
  static final _salmon = _u('photo-1519708227418-c8fd9a32b7a2');
  static final _salmon2 = _u('photo-1467003909585-2f8a72700288');
  static final _cod = _u('photo-1519996529931-28324d5a630e');
  static final _tuna = _u('photo-1567188040759-fb8a883dc6d8');
  static final _shrimp = _u('photo-1607532941433-304659e8198a');
  static final _fish = _u('photo-1519708227418-c8fd9a32b7a2');
  static final _lentilSoup = _u('photo-1547592166-23ac45744acd');
  static final _soup = _u('photo-1547592180-85f173990554');
  static final _tomatoSoup = _u('photo-1476124369491-e7addf5db371');
  static final _curry = _u('photo-1631292784640-2b24be784d5d');
  static final _curry2 = _u('photo-1600335895229-6e75511892c8');
  static final _noodle = _u('photo-1569718212165-3a8278d5f624');
  static final _yogurt = _u('photo-1488477181946-6428a0291777');
  static final _turkey = _u('photo-1574672280600-4accfa5b6f98');
  static final _steak = _u('photo-1546964124-0cce460f38ef');
  static final _grilledMeat = _u('photo-1544025162-d76694265947');
  static final _burger = _u('photo-1568901346375-23c9450c58cd');
  static final _pasta = _u('photo-1555949258-eb67b1ef0ceb');
  static final _pasta2 = _u('photo-1473093295043-cdd812d0e601');
  static final _salad = _u('photo-1512621776951-a57141f2eefd');
  static final _greekSalad = _u('photo-1626645738196-c2a7c87a8f58');
  static final _toast = _u('photo-1484723091739-30a097e8f929');
  static final _stir = _u('photo-1512058564366-18510be2db19');
  static final _wrap = _u('photo-1552332386-f8dd00dc2f85');
  static final _rice = _u('photo-1536304993881-ff6e9eefa2a6');
  static final _coconutRice = _u('photo-1626074353765-517a681e40be');
  static final _beef = _u('photo-1432139509613-5c4255815697');
  static final _tofu = _u('photo-1546069901-ba9599a7e63c');
  static final _bean = _u('photo-1515543904379-3d757afe72e4');
  static final _chickpea = _u('photo-1610970881699-44a5587cabec');
  static final _bread = _u('photo-1504982998983-a6c6a876cc97');
  static final _banana = _u('photo-1587132137056-bfbf0166836e');
  static final _fruit = _u('photo-1568702846914-96b305d2aaeb');
  static final _pancakes = _u('photo-1567620905732-2d1ec7ab7445');
  static final _granola = _u('photo-1512852939750-1305098529bf');
  static final _pudding = _u('photo-1547496502-affa22d38842');
  static final _tacos = _u('photo-1551504734-5ee1c4a1479b');
  static final _burrito = _u('photo-1626700051175-6818013e1d4f');
  static final _quesadilla = _u('photo-1607330289024-1535c6b4e1c1');
  static final _potato = _u('photo-1518977676601-b53f82aba655');
  static final _sweetPotato = _u('photo-1476718406336-bb5a9690ee2a');
  static final _mushroom = _u('photo-1504545102780-26774c1bb073');
  static final _broccoli = _u('photo-1584270354949-c26b0d5b4a0c');
  static final _cauliflower = _u('photo-1466637574441-749b8f19452f');
  static final _stuffedPepper = _u('photo-1585032226651-759b368d7246');
  static final _buddhaBowl = _u('photo-1490474418585-ba9bad8fd0ea');
  static final _bowl = _u('photo-1512621776951-a57141f2eefd');
  static final _pizza = _u('photo-1513104890138-7c749659a591');

  /// Ordered rules — first title substring hit wins. Proteins & signature
  /// dishes come before generic sides on purpose.
  static final List<(List<String>, String)> _rules = [
    (['smoothie'], _smoothie),
    (['buddha bowl'], _buddhaBowl),
    (['burrito bowl'], _burrito),
    (['sweet potato'], _sweetPotato),
    (['black bean'], _bean),
    (['avocado'], _avocado),
    (['pancake', 'waffle'], _pancakes),
    (['quesadilla'], _quesadilla),
    (['burrito'], _burrito),
    (['taco', 'fajita', 'nachos'], _tacos),
    (['curry', 'chana', 'tikka', 'masala'], _curry),
    (['chili'], _curry2),
    (['stew'], _soup),
    (['chowder'], _tomatoSoup),
    (['tomato soup'], _tomatoSoup),
    (['soup'], _soup),
    (['chickpea', 'hummus'], _chickpea),
    (['lentil', 'dal', 'daal'], _lentilSoup),
    (['salmon'], _salmon),
    (['trout', 'mackerel', 'sardine'], _salmon2),
    (['cod', 'white fish', 'tilapia', 'haddock'], _cod),
    (['tuna'], _tuna),
    (['shrimp', 'prawn'], _shrimp),
    (['fish'], _fish),
    (['chicken'], _chicken),
    (['turkey'], _turkey),
    (['steak'], _steak),
    (['burger'], _burger),
    (['beef'], _beef),
    (['meatball', 'pork', 'lamb', 'sausage'], _grilledMeat),
    (['tofu', 'edamame', 'tempeh'], _tofu),
    (['pesto'], _pasta2),
    (['pasta', 'spaghetti', 'penne', 'macaroni', ' mac ', 'lasagna', 'fettuccine'], _pasta),
    (['noodle', 'ramen'], _noodle),
    (['omelette', 'omelet', 'scrambled', 'frittata', 'shakshuka', 'egg'], _egg),
    (['quinoa'], _quinoa),
    (['coconut'], _coconutRice),
    (['couscous', 'bulgur', 'buckwheat', 'barley', 'rice'], _rice),
    (['caprese', 'tabbouleh', 'greek salad', 'greek'], _greekSalad),
    (['coleslaw', 'slaw', 'caesar', 'salad'], _salad),
    (['mushroom'], _mushroom),
    (['cauliflower'], _cauliflower),
    (['broccoli', 'cabbage', 'carrot', 'zucchini', 'kale'], _broccoli),
    (['bell pepper', 'stuffed pepper', 'pepper'], _stuffedPepper),
    (['potato'], _potato),
    (['wrap', 'roll-up', 'rollup'], _wrap),
    (['pizza', 'flatbread'], _pizza),
    (['stir', 'stir-fry', 'stir fry'], _stir),
    (['oatmeal', 'porridge', 'overnight oat', 'oats', 'oat'], _oats),
    (['granola', 'muesli', 'cereal'], _granola),
    (['chia', 'pudding'], _pudding),
    (['yogurt', 'cottage cheese', 'parfait'], _yogurt),
    (['muffin'], _bread),
    (['french toast', 'toast'], _toast),
    (['bread', 'bagel', 'sandwich'], _bread),
    (['banana'], _banana),
    (['blueberry'], _blueberry),
    (['strawberry'], _strawberry),
    (['berry'], _berry),
    (['apple', 'pear', 'peach', 'mango', 'fruit'], _fruit),
    (['veggie', 'vegetable', 'greens', 'spinach'], _broccoli),
    (['bean', 'burrito'], _bean),
    (['bowl'], _bowl),
    (['protein'], _chicken),
  ];

  // Real-food fallbacks so an unmatched title still looks appetising.
  static final List<String> _fallbacks = [
    _bowl,
    _buddhaBowl,
    _salad,
    _greekSalad,
    _grilledMeat,
  ];

  /// Photo URL for a recipe title. [seed] (e.g. recipe id) varies the fallback.
  static String forTitle(String title, {String? seed}) {
    final t = ' ${title.toLowerCase()} ';
    for (final (keys, url) in _rules) {
      for (final k in keys) {
        if (t.contains(k)) return url;
      }
    }
    final idx = (seed ?? title).hashCode.abs() % _fallbacks.length;
    return _fallbacks[idx];
  }

  /// Food emoji for the graceful fallback (when a photo fails to load).
  static const List<(List<String>, String)> _emojiRules = [
    (['smoothie', 'shake'], '🥤'),
    (['soup', 'stew', 'chowder', 'broth'], '🍲'),
    (['salad', 'slaw', 'greens'], '🥗'),
    (['salmon', 'tuna', 'cod', 'fish', 'trout', 'shrimp', 'prawn'], '🐟'),
    (['chicken', 'turkey'], '🍗'),
    (['beef', 'steak', 'burger', 'meatball', 'pork', 'lamb'], '🥩'),
    (['egg', 'omelet', 'omelette', 'frittata', 'shakshuka'], '🍳'),
    (['pasta', 'spaghetti', 'noodle', 'ramen', 'lasagna'], '🍝'),
    (['rice', 'quinoa', 'couscous', 'bowl', 'buddha'], '🍚'),
    (['taco', 'burrito', 'quesadilla', 'fajita', 'wrap'], '🌯'),
    (['pizza', 'flatbread'], '🍕'),
    (['oat', 'oatmeal', 'porridge', 'granola', 'cereal'], '🥣'),
    (['toast', 'bread', 'bagel', 'sandwich', 'muffin'], '🍞'),
    (['pancake', 'waffle'], '🥞'),
    (['yogurt', 'parfait', 'pudding', 'chia'], '🥛'),
    (['banana'], '🍌'),
    (['apple', 'pear'], '🍎'),
    (['berry', 'blueberry', 'strawberry'], '🍓'),
    (['avocado'], '🥑'),
    (['bean', 'lentil', 'chickpea', 'tofu', 'hummus'], '🫘'),
    (['potato', 'sweet potato'], '🥔'),
    (['broccoli', 'cauliflower', 'veggie', 'vegetable', 'mushroom', 'pepper'], '🥦'),
    (['fruit', 'mango', 'peach'], '🍽️'),
  ];

  static String emojiForTitle(String title) {
    final t = ' ${title.toLowerCase()} ';
    for (final (keys, emoji) in _emojiRules) {
      for (final k in keys) {
        if (t.contains(k)) return emoji;
      }
    }
    return '🍽️';
  }
}
