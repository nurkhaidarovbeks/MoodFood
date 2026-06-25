import 'package:flutter/material.dart';
import '../../../core/models/mood_entry_model.dart';
import '../../../core/services/recommendation_service.dart';
import '../../../core/theme/app_theme.dart';

class RecommendationsScreen extends StatefulWidget {
  final MoodEntry? moodEntry;

  const RecommendationsScreen({super.key, this.moodEntry});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _service = RecommendationService();
  RecommendationResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.moodEntry == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.recommend(entry: widget.moodEntry!);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
      if (result == null) _error = 'Could not load recommendations';
    });
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.moodEntry?.mood ?? 'happy';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.textDark),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your\nRecommendations',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Based on your ${widget.moodEntry?.moodLabel ?? 'mood'} ${widget.moodEntry?.moodEmoji ?? ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (_result?.aiPowered == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'AI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primary),
                      SizedBox(height: 16),
                      Text(
                        'Finding the perfect meals for you…',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ErrorCard(
                      message: _error!,
                      onRetry: _load,
                      mood: mood,
                    ),
                    const SizedBox(height: 24),
                    _BottomButtons(context: context),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_result != null && _result!.options.isNotEmpty) ...[
                      ..._result!.options.map(
                        (opt) => _RecommendationCard(option: opt),
                      ),
                    ] else ...[
                      _EmptyCard(mood: mood),
                    ],
                    const SizedBox(height: 24),
                    _BottomButtons(context: context),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final RecommendationOption option;

  const _RecommendationCard({required this.option});

  static const _categoryColors = {
    'energizing': Color(0xFFFFF3E0),
    'calming': Color(0xFFE8F5E9),
    'comforting': Color(0xFFFCE4EC),
    'light': Color(0xFFE3F2FD),
    'nourishing': Color(0xFFF3E5F5),
  };

  static const _categoryIcons = {
    'energizing': '⚡',
    'calming': '🌿',
    'comforting': '🍲',
    'light': '🥗',
    'nourishing': '💪',
  };

  Color get _cardColor =>
      _categoryColors[option.category] ?? const Color(0xFFF5F5F5);
  String get _icon => _categoryIcons[option.category] ?? '🍽️';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category colour
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(_icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.recipe.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.category[0].toUpperCase() +
                            option.category.substring(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fit score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${option.fitScore}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                if (option.recipe.cookingTimeMin != null) ...[
                  const Icon(Icons.timer_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${option.recipe.cookingTimeMin} min',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 14),
                ],
                if (option.recipe.calories != null) ...[
                  const Icon(Icons.local_fire_department_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${option.recipe.calories} kcal',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 14),
                ],
                if (option.recipe.difficulty != null) ...[
                  const Icon(Icons.signal_cellular_alt,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    option.recipe.difficulty!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          // AI explanation
          if (option.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.explanation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Missing ingredients (pantry mode)
          if (option.missingIngredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const Text(
                    'Missing: ',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  ...option.missingIngredients.map(
                    (i) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        i,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.deepOrange),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Error Card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String mood;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEEEE)),
      ),
      child: Column(
        children: [
          const Text('😕', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text(
            'Couldn\'t reach the server',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String mood;
  const _EmptyCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Text('🍽️', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'No recipes found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The database may be empty. Try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Buttons ───────────────────────────────────────────────────────────

class _BottomButtons extends StatelessWidget {
  final BuildContext context;
  const _BottomButtons({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (_) => false,
              arguments: {'tab': 1},
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  'Explore More Recipes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.popUntil(
              context,
              ModalRoute.withName('/home'),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
