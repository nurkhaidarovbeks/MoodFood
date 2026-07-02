import 'package:flutter/foundation.dart';
import '../services/insights_service.dart';

/// Epic 7 — habit analytics for the Tracker tab.
class InsightsProvider extends ChangeNotifier {
  final _service = InsightsService();

  WeeklyInsights? _weekly;
  bool _loading = false;
  bool _loadedOnce = false;

  WeeklyInsights? get weekly => _weekly;
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  List<String> get tips => _weekly?.tips ?? const [];

  Future<void> load({int days = 7, bool force = false}) async {
    if (_loading) return;
    if (_loadedOnce && !force) return;
    _loading = true;
    notifyListeners();
    _weekly = await _service.weekly(days: days);
    _loading = false;
    _loadedOnce = true;
    notifyListeners();
  }
}
