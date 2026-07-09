/// Maps a recipe title to an appetising, on-topic food photo.
///
/// The backend ships no image for a recipe, so the frontend derives one from
/// the title. Each category holds a **pool** of photos; a recipe deterministically
/// picks one from the pool by its id, so two "Black Bean …" recipes get
/// different photos instead of the same one. Matching is priority-ordered
/// (specific dishes / proteins before generic sides). The fallback (see
/// RecipeImage) is always a real gradient + food emoji, so nothing looks broken.
class RecipePhoto {
  RecipePhoto._();

  static const _base = 'https://images.unsplash.com/';
  static String _u(String id) => '$_base$id?w=800&q=80&fit=crop';

  // ─── Photo pools (verified against on-device screenshots where possible) ────
  static final _smoothie = [
    _u('photo-1553530666-ba11a7da3888'), // red berry smoothie ✓
    _u('photo-1610970881699-44a5587cabec'), // green smoothie ✓
    _u('photo-1502741224143-90386d7f8c82'),
    _u('photo-1600271886742-f049cd451bba'),
  ];
  static final _egg = [
    _u('photo-1482049016688-2d3e1b311543'), // egg + avocado toast ✓
    _u('photo-1525351484163-7529414344d8'),
    _u('photo-1600335895229-6e75511892c8'),
  ];
  static final _oats = [
    _u('photo-1571748982800-fa51082c2224'),
    _u('photo-1517673400267-0251440c45dc'),
    _u('photo-1494597564530-871f2b93ac55'),
  ];
  static final _yogurt = [
    _u('photo-1488477181946-6428a0291777'), // parfait ✓
    _u('photo-1550583724-b2692b85b150'),
    _u('photo-1490474418585-ba9bad8fd0ea'),
  ];
  static final _berry = [
    _u('photo-1464965911861-746a04b4bca6'), // strawberries ✓
    _u('photo-1498557850523-fd3d118b962e'),
    _u('photo-1587049352846-4a222e784d38'),
  ];
  static final _avocadoToast = [
    _u('photo-1482049016688-2d3e1b311543'), // egg + avocado toast ✓
    _u('photo-1588137378633-dea1336ce1e2'),
    _u('photo-1541519227354-08fa5d50c44d'),
  ];
  static final _chickpea = [
    _u('photo-1515543904379-3d757afe72e4'), // chickpea bowl ✓
    _u('photo-1604497181015-76590d828b78'),
    _u('photo-1512058564366-18510be2db19'),
  ];
  static final _bean = [
    _u('photo-1515543904379-3d757afe72e4'),
    _u('photo-1607013251379-e6eecfffe234'),
    _u('photo-1584479898061-15742e14f57f'),
    _u('photo-1512058564366-18510be2db19'),
  ];
  static final _lentil = [
    _u('photo-1547592166-23ac45744acd'),
    _u('photo-1476124369491-e7addf5db371'),
    _u('photo-1614777986387-015c2a89b696'),
  ];
  static final _rice = [
    _u('photo-1536304993881-ff6e9eefa2a6'), // steamed rice ✓
    _u('photo-1516684732162-798a0062be99'),
    _u('photo-1603133872878-684f208fb84b'),
    _u('photo-1596797038530-2c107229654b'),
  ];
  static final _chicken = [
    _u('photo-1604908176997-125f25cc6f3d'),
    _u('photo-1598515214211-89d3c73ae83b'),
    _u('photo-1532550907401-a500c9a57435'),
    _u('photo-1610057099431-d73a1c9d2f2f'),
  ];
  static final _salmon = [
    _u('photo-1519708227418-c8fd9a32b7a2'),
    _u('photo-1467003909585-2f8a72700288'),
    _u('photo-1580476262798-bddd9f4b7369'),
  ];
  static final _fish = [
    _u('photo-1519708227418-c8fd9a32b7a2'),
    _u('photo-1535140728325-a4d3707eee61'),
  ];
  static final _tuna = [
    _u('photo-1567188040759-fb8a883dc6d8'),
    _u('photo-1603073163308-9654c3fb70b5'),
  ];
  static final _shrimp = [
    _u('photo-1607532941433-304659e8198a'),
    _u('photo-1565680018434-b513d5e5fd47'),
  ];
  static final _beef = [
    _u('photo-1432139509613-5c4255815697'),
    _u('photo-1546964124-0cce460f38ef'),
    _u('photo-1544025162-d76694265947'),
  ];
  static final _pasta = [
    _u('photo-1555949258-eb67b1ef0ceb'),
    _u('photo-1473093295043-cdd812d0e601'),
    _u('photo-1621996346565-e3dbc646d9a9'),
    _u('photo-1563379926898-05f4575a45d8'),
  ];
  static final _noodle = [
    _u('photo-1569718212165-3a8278d5f624'),
    _u('photo-1585032226651-759b368d7246'),
  ];
  static final _salad = [
    _u('photo-1512621776951-a57141f2eefd'),
    _u('photo-1546069901-ba9599a7e63c'),
    _u('photo-1607532941433-304659e8198a'),
    _u('photo-1540420773420-3366772f4999'),
  ];
  static final _soup = [
    _u('photo-1547592180-85f173990554'),
    _u('photo-1476124369491-e7addf5db371'),
    _u('photo-1604152135912-04a022e23696'),
  ];
  static final _veg = [
    _u('photo-1584270354949-c26b0d5b4a0c'), // broccoli bowl ✓
    _u('photo-1512621776951-a57141f2eefd'),
    _u('photo-1466637574441-749b8f19452f'),
    _u('photo-1540420773420-3366772f4999'),
  ];
  static final _potato = [
    _u('photo-1518977676601-b53f82aba655'),
    _u('photo-1476718406336-bb5a9690ee2a'),
  ];
  static final _mushroom = [
    _u('photo-1504545102780-26774c1bb073'),
    _u('photo-1552825896-a1e0a3e35fc7'),
  ];
  static final _toast = [
    _u('photo-1484723091739-30a097e8f929'),
    _u('photo-1525351484163-7529414344d8'),
  ];
  static final _bread = [
    _u('photo-1509440159596-0249088772ff'),
    _u('photo-1586444248902-2f64eddc13df'),
  ];
  static final _wrap = [
    _u('photo-1626700051175-6818013e1d4f'), // wrap ✓
    _u('photo-1552332386-f8dd00dc2f85'),
    _u('photo-1600850056064-a8b380df8395'),
  ];
  static final _taco = [
    _u('photo-1551504734-5ee1c4a1479b'),
    _u('photo-1565299585323-38d6b0865b47'),
  ];
  static final _pizza = [
    _u('photo-1513104890138-7c749659a591'),
    _u('photo-1574071318508-1cdbab80d002'),
  ];
  static final _pancakes = [
    _u('photo-1567620905732-2d1ec7ab7445'),
    _u('photo-1528207776546-365bb710ee93'),
  ];
  static final _pudding = [
    _u('photo-1517673132405-a56a62b18caf'),
    _u('photo-1490474418585-ba9bad8fd0ea'),
  ];
  static final _banana = [
    _u('photo-1571771894821-ce9b6c11b08e'),
    _u('photo-1587132137056-bfbf0166836e'),
  ];
  static final _fruit = [
    _u('photo-1568702846914-96b305d2aaeb'),
    _u('photo-1490474418585-ba9bad8fd0ea'),
    _u('photo-1519996529931-28324d5a630e'),
  ];
  static final _tofu = [
    _u('photo-1546069901-ba9599a7e63c'),
    _u('photo-1512058564366-18510be2db19'),
  ];
  static final _bowl = [
    _u('photo-1490474418585-ba9bad8fd0ea'),
    _u('photo-1512621776951-a57141f2eefd'),
    _u('photo-1546069901-ba9599a7e63c'),
    _u('photo-1543339308-43e59d6b73a6'),
  ];
  static final _curry = [
    _u('photo-1631292784640-2b24be784d5d'),
    _u('photo-1585937421612-70a008356fbe'),
  ];

  /// Ordered rules — first title substring hit wins.
  static final List<(List<String>, List<String>)> _rules = [
    (['smoothie', 'shake'], _smoothie),
    (['avocado toast', 'avo toast'], _avocadoToast),
    (['buddha bowl'], _bowl),
    (['taco', 'fajita', 'nachos'], _taco),
    (['burrito', 'quesadilla', 'wrap', 'roll-up'], _wrap),
    (['curry', 'tikka', 'masala', 'chana', 'chili'], _curry),
    (['chowder', 'tomato soup'], _soup),
    (['stew', 'soup'], _soup),
    (['chickpea', 'hummus'], _chickpea),
    (['black bean', 'kidney bean', 'pinto', 'refried', ' bean'], _bean),
    (['lentil', 'dal', 'daal'], _lentil),
    (['salmon'], _salmon),
    (['tuna'], _tuna),
    (['shrimp', 'prawn'], _shrimp),
    (['cod', 'tilapia', 'haddock', 'trout', 'mackerel', 'white fish', 'fish'], _fish),
    (['chicken'], _chicken),
    (['turkey'], _chicken),
    (['steak', 'beef', 'meatball', 'burger', 'pork', 'lamb', 'sausage'], _beef),
    (['tofu', 'tempeh', 'edamame'], _tofu),
    (['pasta', 'spaghetti', 'penne', 'macaroni', 'lasagna', 'fettuccine', 'pesto'], _pasta),
    (['noodle', 'ramen'], _noodle),
    (['omelette', 'omelet', 'scrambled', 'frittata', 'shakshuka', 'egg'], _egg),
    (['pancake', 'waffle'], _pancakes),
    (['oatmeal', 'porridge', 'overnight oat', 'oats', 'oat'], _oats),
    (['chia', 'pudding'], _pudding),
    (['granola', 'muesli', 'cereal', 'parfait', 'yogurt', 'cottage cheese'], _yogurt),
    (['pizza', 'flatbread'], _pizza),
    (['mushroom'], _mushroom),
    (['potato'], _potato),
    (['cabbage', 'coleslaw', 'slaw'], _salad),
    (['broccoli', 'cauliflower', 'zucchini', 'carrot', 'kale', 'spinach', 'greens', 'veggie', 'vegetable', 'stir'], _veg),
    (['caprese', 'greek', 'tabbouleh', 'caesar', 'salad'], _salad),
    (['quinoa', 'couscous', 'bulgur', 'buckwheat', 'barley', 'rice'], _rice),
    (['muffin', 'bagel', 'sandwich', 'bread'], _bread),
    (['french toast', 'toast'], _toast),
    (['avocado'], _avocadoToast),
    (['banana'], _banana),
    (['berry', 'blueberry', 'strawberry'], _berry),
    (['apple', 'pear', 'peach', 'mango', 'fruit', 'coconut'], _fruit),
    (['bowl'], _bowl),
    (['protein'], _chicken),
  ];

  static final List<String> _fallbacks = [
    ..._bowl,
    ..._salad,
    ..._veg,
  ];

  /// Photo URL for a recipe title. [seed] (recipe id) picks within the pool so
  /// recipes sharing a keyword get different photos.
  static String forTitle(String title, {String? seed}) {
    final t = ' ${title.toLowerCase()} ';
    final h = (seed ?? title).hashCode.abs();
    for (final (keys, pool) in _rules) {
      for (final k in keys) {
        if (t.contains(k)) return pool[h % pool.length];
      }
    }
    return _fallbacks[h % _fallbacks.length];
  }

  // ─── Emoji for the graceful fallback ───────────────────────────────────────
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
