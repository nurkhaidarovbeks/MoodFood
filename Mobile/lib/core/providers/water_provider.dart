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
  bool _loading = false;
  bool _busy = false; // a log/delete request is in flight

  WaterToday get today => _today;
  bool get loading => _loading;

  int get totalMl => _today.totalMl;
  int get goalMl => _today.goalMl;
  double get progress => _today.progress;
  bool get goalReached => _today.goalReached;

  /// Whole glasses consumed / target, derived from millilitres.
  int get glasses => (_today.totalMl / glassMl).round();
  int get goalGlasses => (_today.goalMl / glassMl).round().clamp(1, 99);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final t = await _service.today();
    if (t != null) _today = t;
    _loading = false;
    notifyListeners();
  }

  /// Log one glass (250 ml).
  Future<void> addGlass() async {
    if (_busy) return;
    _busy = true;
    final t = await _service.log(glassMl);
    if (t != null) _today = t;
    _busy = false;
    notifyListeners();
  }

  /// Remove the most recent drink log (undo the last glass).
  Future<void> removeGlass() async {
    if (_busy || _today.logs.isEmpty) return;
    _busy = true;
    // logs come newest-first from the backend
    final lastId = _today.logs.first.id;
    final t = await _service.deleteLog(lastId);
    if (t != null) _today = t;
    _busy = false;
    notifyListeners();
  }
}
