import 'package:flutter/foundation.dart';
import '../services/water_service.dart';

/// Epic 6 — hydration tracking backed by /water.
///
/// The UI thinks in "glasses"; the backend stores millilitres. One glass =
/// [glassMl]. A "+1 glass" logs a drink, "−1 glass" removes the most recent
/// log. Optimistic where cheap, always reconciled with the server response.
class WaterProvider extends ChangeNotifier {
  static const int glassMl = 250;

  final _service = WaterService();

  WaterToday _today = WaterToday.empty;
  WaterHistory _history = WaterHistory.empty;
  WaterGoal _goal = WaterGoal.defaults;
  bool _loading = false;
  bool _busy = false; // a log/delete request is in flight

  WaterToday get today => _today;
  WaterHistory get history => _history;
  WaterGoal get goal => _goal;
  bool get loading => _loading;
  bool get busy => _busy;

  int get totalMl => _today.totalMl;
  int get goalMl => _today.goalMl;
  int get remainingMl => _today.remainingMl;
  double get progress => _today.progress;
  bool get goalReached => _today.goalReached;
  List<WaterLog> get logs => _today.logs;

  /// Whole glasses consumed / target, derived from millilitres.
  int get glasses => (_today.totalMl / glassMl).round();
  int get goalGlasses => (_today.goalMl / glassMl).round().clamp(1, 99);

  /// Lightweight refresh — just today's total (used by the Home card).
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final t = await _service.today();
    if (t != null) _today = t;
    _loading = false;
    notifyListeners();
  }

  /// Full refresh for the Water tab — today + history + goal/reminders.
  Future<void> loadAll({int historyDays = 7}) async {
    _loading = true;
    notifyListeners();
    final results = await Future.wait([
      _service.today(),
      _service.history(days: historyDays),
      _service.getGoal(),
    ]);
    final t = results[0] as WaterToday?;
    final h = results[1] as WaterHistory?;
    final g = results[2] as WaterGoal?;
    if (t != null) _today = t;
    if (h != null) _history = h;
    if (g != null) _goal = g;
    _loading = false;
    notifyListeners();
  }

  /// Log one glass (250 ml).
  Future<void> addGlass() => logAmount(glassMl);

  /// Log an arbitrary amount (ml). Refreshes history so the chart stays in sync.
  Future<void> logAmount(int amountMl) async {
    if (_busy || amountMl <= 0) return;
    _busy = true;
    notifyListeners();
    final t = await _service.log(amountMl);
    if (t != null) _today = t;
    _busy = false;
    notifyListeners();
    _refreshHistory();
  }

  /// Remove the most recent drink log (undo the last glass).
  Future<void> removeGlass() async {
    if (_today.logs.isEmpty) return;
    await deleteLog(_today.logs.first.id);
  }

  /// Delete a specific log (from the today list).
  Future<void> deleteLog(String id) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    final t = await _service.deleteLog(id);
    if (t != null) _today = t;
    _busy = false;
    notifyListeners();
    _refreshHistory();
  }

  /// Change the daily goal (ml).
  Future<void> setGoal(int ml) async {
    final g = await _service.updateGoal(waterGoalMl: ml);
    if (g != null) _goal = g;
    // reflect the new goal in today's summary immediately
    await load();
  }

  /// Update reminder settings (on/off, cadence, wake/sleep window).
  Future<void> setReminders({
    bool? on,
    int? intervalMin,
    String? wakeTime,
    String? sleepTime,
  }) async {
    final g = await _service.updateGoal(
      waterRemindersOn: on,
      waterIntervalMin: intervalMin,
      wakeTime: wakeTime,
      sleepTime: sleepTime,
    );
    if (g != null) {
      _goal = g;
      notifyListeners();
    }
  }

  Future<void> _refreshHistory() async {
    final h = await _service.history(days: 7);
    if (h != null) {
      _history = h;
      notifyListeners();
    }
  }
}
