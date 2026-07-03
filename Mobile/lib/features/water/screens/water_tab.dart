import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/water_provider.dart';
import '../../../core/services/water_service.dart';
import '../../../core/theme/app_theme.dart';

/// Epic 6 — the Water tab. Full hydration experience backed by /water:
/// today's progress, quick add, per-drink log, weekly history, goal + reminders.
class WaterTab extends StatefulWidget {
  const WaterTab({super.key});

  @override
  State<WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<WaterTab> {
  static const _blue = Color(0xFF2196F3);
  static const _blueDark = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final water = context.watch<WaterProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: () => context.read<WaterProvider>().loadAll(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              const Text(
                'Water',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const Text(
                'Stay hydrated, stay energized',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              _ProgressCard(water: water),
              const SizedBox(height: 16),

              _QuickAdd(
                busy: water.busy,
                onAdd: (ml) => context.read<WaterProvider>().logAmount(ml),
                onUndo: water.logs.isEmpty
                    ? null
                    : () => context.read<WaterProvider>().removeGlass(),
                onCustom: () => _customAmount(context),
              ),
              const SizedBox(height: 20),

              _SectionTitle('This Week'),
              const SizedBox(height: 10),
              _WeeklyChart(history: water.history),
              const SizedBox(height: 20),

              if (water.logs.isNotEmpty) ...[
                _SectionTitle("Today's Log"),
                const SizedBox(height: 10),
                ...water.logs.map(
                  (l) => _LogRow(
                    log: l,
                    onDelete: () =>
                        context.read<WaterProvider>().deleteLog(l.id),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _SectionTitle('Daily Goal'),
              const SizedBox(height: 10),
              _GoalCard(
                goalMl: water.goalMl,
                onEdit: () => _editGoal(context, water.goalMl),
              ),
              const SizedBox(height: 20),

              _SectionTitle('Reminders'),
              const SizedBox(height: 10),
              _RemindersCard(goal: water.goal),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Custom amount sheet ────────────────────────────────────────────────────
  Future<void> _customAmount(BuildContext context) async {
    final ctrl = TextEditingController();
    final ml = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetScaffold(
        title: 'Add custom amount',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Amount in ml (e.g. 350)',
                suffixText: 'ml',
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryButton(
              label: 'Add',
              color: _blue,
              onTap: () {
                final v = int.tryParse(ctrl.text.trim());
                Navigator.pop(ctx, (v != null && v > 0) ? v.clamp(10, 3000) : null);
              },
            ),
          ],
        ),
      ),
    );
    if (ml != null && context.mounted) {
      context.read<WaterProvider>().logAmount(ml);
    }
  }

  // ─── Goal editor sheet ──────────────────────────────────────────────────────
  Future<void> _editGoal(BuildContext context, int current) async {
    const presets = [1500, 2000, 2500, 3000];
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetScaffold(
        title: 'Set daily goal',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: presets.map((p) {
                final active = p == current;
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? _blue.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? _blue : const Color(0xFFE0E0E0),
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)} L',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: active ? _blueDark : AppTheme.textDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '${presets.first}–${presets.last} ml · a glass is 250 ml',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && context.mounted) {
      context.read<WaterProvider>().setGoal(chosen);
    }
  }
}

// ─── Progress ring card ────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final WaterProvider water;
  const _ProgressCard({required this.water});

  @override
  Widget build(BuildContext context) {
    final pct = (water.progress.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _RingPainter(progress: water.progress.clamp(0.0, 1.0)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💧', style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _WaterTabState._blueDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${water.totalMl} / ${water.goalMl} ml',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${water.glasses} of ${water.goalGlasses} glasses',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: water.goalReached
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : _WaterTabState._blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    water.goalReached
                        ? '🎉 Goal reached!'
                        : '${water.remainingMl} ml to go',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: water.goalReached
                          ? AppTheme.primaryDark
                          : _WaterTabState._blueDark,
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

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    const stroke = 11.0;

    final bg = Paint()
      ..color = const Color(0xFFE3F2FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64B5F6), Color(0xFF1565C0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Quick add ─────────────────────────────────────────────────────────────────

class _QuickAdd extends StatelessWidget {
  final bool busy;
  final void Function(int ml) onAdd;
  final VoidCallback? onUndo;
  final VoidCallback onCustom;

  const _QuickAdd({
    required this.busy,
    required this.onAdd,
    required this.onUndo,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AddButton(
                emoji: '🥛',
                label: 'Glass',
                sub: '250 ml',
                onTap: busy ? null : () => onAdd(250),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AddButton(
                emoji: '🍶',
                label: 'Bottle',
                sub: '500 ml',
                onTap: busy ? null : () => onAdd(500),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AddButton(
                emoji: '✏️',
                label: 'Custom',
                sub: 'ml',
                onTap: busy ? null : onCustom,
              ),
            ),
          ],
        ),
        if (onUndo != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: busy ? null : onUndo,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.undo, size: 16, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Undo last',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final VoidCallback? onTap;

  const _AddButton({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Weekly chart ───────────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  final WaterHistory history;
  const _WeeklyChart({required this.history});

  static const _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final days = history.days;
    final goal = history.goalMl <= 0 ? 2000 : history.goalMl;
    final maxMl = days.isEmpty
        ? goal
        : math.max(goal, days.map((d) => d.totalMl).reduce(math.max));

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: days.isEmpty
          ? const Center(
              child: Text(
                'No data yet — log your first drink!',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final d = days[i];
                final frac = (d.totalMl / maxMl).clamp(0.0, 1.0);
                final reached = d.goalReached;
                final dt = DateTime.tryParse(d.date);
                final label = dt != null ? _dow[dt.weekday - 1] : '';
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        d.totalMl >= 1000
                            ? '${(d.totalMl / 1000).toStringAsFixed(1)}L'
                            : '${d.totalMl}',
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 16,
                        height: (frac * 78).clamp(4.0, 78.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: reached
                                ? [AppTheme.primary, AppTheme.primaryGreenLight]
                                : [
                                    const Color(0xFF1565C0),
                                    const Color(0xFF64B5F6),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}

// ─── Today log row ──────────────────────────────────────────────────────────────

class _LogRow extends StatelessWidget {
  final WaterLog log;
  final VoidCallback onDelete;
  const _LogRow({required this.log, required this.onDelete});

  String get _time {
    final h = log.createdAt.hour.toString().padLeft(2, '0');
    final m = log.createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop,
                  size: 18, color: Color(0xFF2196F3)),
            ),
            const SizedBox(width: 12),
            Text(
              '${log.amountMl} ml',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Text(
              _time,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Goal card ──────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final int goalMl;
  final VoidCallback onEdit;
  const _GoalCard({required this.goalMl, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flag_outlined,
                  size: 20, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(goalMl / 1000).toStringAsFixed(goalMl % 1000 == 0 ? 0 : 1)} L per day',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '$goalMl ml · ${(goalMl / 250).round()} glasses',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Reminders card ─────────────────────────────────────────────────────────────

class _RemindersCard extends StatelessWidget {
  final WaterGoal goal;
  const _RemindersCard({required this.goal});

  static const _intervals = [60, 120, 180, 240];

  String _intervalLabel(int min) =>
      min % 60 == 0 ? '${min ~/ 60}h' : '${min}m';

  Future<void> _pickTime(
    BuildContext context, {
    required bool isWake,
  }) async {
    final parts = (isWake ? goal.wakeTime : goal.sleepTime).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? (isWake ? 8 : 23),
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null && context.mounted) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      context.read<WaterProvider>().setReminders(
            wakeTime: isWake ? '$hh:$mm' : null,
            sleepTime: isWake ? null : '$hh:$mm',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 20, color: Color(0xFF1565C0)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Water reminders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Switch(
                value: goal.waterRemindersOn,
                activeThumbColor: const Color(0xFF2196F3),
                onChanged: (v) =>
                    context.read<WaterProvider>().setReminders(on: v),
              ),
            ],
          ),
          if (goal.waterRemindersOn) ...[
            const Divider(height: 24),
            // Interval
            Row(
              children: [
                const Text(
                  'Every',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.end,
                    children: _intervals.map((m) {
                      final active = m == goal.waterIntervalMin;
                      return GestureDetector(
                        onTap: () => context
                            .read<WaterProvider>()
                            .setReminders(intervalMin: m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2196F3).withValues(alpha: 0.12)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF2196F3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _intervalLabel(m),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? const Color(0xFF1565C0)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Wake / sleep window (custom schedule)
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Wake',
                    value: goal.wakeTime,
                    onTap: () => _pickTime(context, isWake: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(
                    label: 'Sleep',
                    value: goal.sleepTime,
                    onTap: () => _pickTime(context, isWake: false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const Icon(Icons.schedule, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Small shared bits ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
