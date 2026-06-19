import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> checkAuthStatus() async {
    final token = await TokenStorage.get();
    if (token == 'demo_token') {
      // Clear stale demo tokens — demo mode is session-only, not persistent
      await TokenStorage.clear();
      _status = AuthStatus.unauthenticated;
    } else {
      _status =
          token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) =>
      _run(() => _service.register(email: email, password: password, name: name));

  Future<bool> login({required String email, required String password}) =>
      _run(() => _service.login(email: email, password: password));

  Future<bool> verifyOtp({required String email, required String code}) =>
      _run(() => _service.verifyOtp(email: email, code: code));

  Future<bool> googleSignIn(String idToken) =>
      _run(() => _service.googleSignIn(idToken));

  Future<bool> _run(Future<AuthResult> Function() call) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await call();
      _user = result.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      await _service.sendOtp(email);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loginAsDemo() async {
    // Demo mode is session-only — no token saved so next launch shows onboarding/welcome
    _user = const UserModel(
      id: 'demo',
      email: 'demo@moodfood.app',
      name: 'Demo User',
      authProvider: 'demo',
      isEmailVerified: true,
      isProfileComplete: true,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    // Reset onboarding flag so it shows again on next cold launch
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
