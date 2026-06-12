import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/ingredients_provider.dart';
import '../../../core/theme/app_theme.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: IngredientsProvider.categories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedCategoryIndex = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngredientsProvider>().load();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addCustom() async {
    final name = _textController.text.trim();
    if (name.isEmpty) return;
    await context.read<IngredientsProvider>().add(name);
    _textController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Fridge'),
        backgroundColor: AppTheme.surface,
        actions: [
          Consumer<IngredientsProvider>(
            builder: (_, prov, _) => prov.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _showClearDialog(context, prov),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPantrySection(),
          const Divider(height: 1, color: AppTheme.divider),
          _buildAddSection(),
          const Divider(height: 1, color: AppTheme.divider),
          _buildCategoryTabs(),
          Expanded(child: _buildIngredientGrid()),
        ],
      ),
    );
  }

  Widget _buildPantrySection() {
    return Consumer<IngredientsProvider>(
      builder: (_, prov, _) {
        if (prov.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: AppTheme.surface,
            child: const Row(
              children: [
                Text('🧊', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your fridge is empty',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add ingredients to get matching recipes',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🧊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '${prov.ingredients.length} ingredient${prov.ingredients.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: prov.ingredients
                    .map((name) => _PantryChip(
                          name: name,
                          onRemove: () => prov.remove(name),
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddSection() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Add ingredient manually…',
                prefixIcon: Icon(Icons.add, color: AppTheme.textMedium),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _addCustom(),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _addCustom,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(56, 48),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Icon(Icons.add, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textMedium,
        indicatorColor: AppTheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: IngredientsProvider.categories
            .map((c) => Tab(text: '${c.emoji} ${c.label}'))
            .toList(),
      ),
    );
  }

  Widget _buildIngredientGrid() {
    final category =
        IngredientsProvider.categories[_selectedCategoryIndex];
    return Consumer<IngredientsProvider>(
      builder: (_, prov, _) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
          ),
          itemCount: category.items.length,
          itemBuilder: (_, i) {
            final name = category.items[i];
            final selected = prov.has(name);
            return _IngredientTile(
              name: name,
              selected: selected,
              onTap: () => prov.toggle(name),
            );
          },
        );
      },
    );
  }

  void _showClearDialog(BuildContext context, IngredientsProvider prov) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear fridge?'),
        content: const Text('This will remove all your saved ingredients.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              prov.clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _PantryChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _IngredientTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : AppTheme.divider,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
