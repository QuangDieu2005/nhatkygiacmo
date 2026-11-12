import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthOperations? authService})
    : _authService = authService ?? AuthService.instance;

  final AuthOperations _authService;

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  Future<void> checkAuthStatus() async {
    await _authService.init();
    if (_authService.isAuthenticated) {
      _user = _authService.currentUser;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    if (_status == AuthStatus.loading) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    if (_status == AuthStatus.loading) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(email: email, password: password, name: name);
      // Registration success is not equivalent to an authenticated,
      // email-verified session. The current service only provides mock data.
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    if (_status == AuthStatus.loading) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateSleepGoal(int hours) async {
    if (_user == null) return;
    final updated = _user!.copyWith(sleepGoalHours: hours);
    await _authService.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> updateNotifications(bool enabled) async {
    if (_user == null) return;
    final updated = _user!.copyWith(notificationsEnabled: enabled);
    await _authService.updateUser(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
