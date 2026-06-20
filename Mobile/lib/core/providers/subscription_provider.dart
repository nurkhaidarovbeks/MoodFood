import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const _key = 'is_premium';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  final _service = SubscriptionService();

  // Load from SharedPrefs (fast, offline-safe)
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  // Sync from backend — call after login
  Future<void> syncFromBackend() async {
    try {
      final sub = await _service.getMySubscription();
      final isActive = sub != null && sub['status'] == 'active';
      if (isActive != _isPremium) {
        _isPremium = isActive;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_key, isActive);
        notifyListeners();
      }
    } catch (_) {
      // Network error — keep local value
    }
  }

  Future<void> upgradeToPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    _isPremium = true;
    notifyListeners();
  }

  Future<void> cancelPremium() async {
    try {
      await _service.cancel();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _isPremium = false;
    notifyListeners();
  }
}
