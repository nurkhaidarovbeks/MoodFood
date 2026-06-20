import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionProvider extends ChangeNotifier {
  static const _key = 'is_premium';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> upgradeToPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    _isPremium = true;
    notifyListeners();
  }

  Future<void> cancelPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _isPremium = false;
    notifyListeners();
  }
}
