import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/errors/app_exception.dart';
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
    : _authService = authService ?? AuthService.instance {
    _authService.setSessionExpiredHandler(_handleSessionExpired);
  }

  final AuthOperations _authService;

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _errorMessage;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;
  bool _emailConfirmationRequired = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get emailConfirmationRequired => _emailConfirmationRequired;

  Future<void> checkAuthStatus() {
    if (_isInitialized) return Future<void>.value();
    return _initializationFuture ??= _restoreAuthStatus();
  }

  Future<void> retryRestoreSession() {
    _initializationFuture = _restoreAuthStatus();
    return _initializationFuture!;
  }

  Future<void> _restoreAuthStatus() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.init();
      _user = _authService.isAuthenticated ? _authService.currentUser : null;
      _status = _user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } catch (error) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = _friendlyError(error);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    if (_status == AuthStatus.loading) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    _emailConfirmationRequired = false;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _status = AuthStatus.error;
      _errorMessage = _friendlyError(e, loginAttempt: true);
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
    _emailConfirmationRequired = false;
    notifyListeners();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );
      _emailConfirmationRequired = result.requiresEmailConfirmation;
      _user = result.user;
      _status = result.user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _status = AuthStatus.error;
      _errorMessage = _friendlyError(e);
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
      _errorMessage = _friendlyError(e);
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
    try {
      await _authService.logout();
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _emailConfirmationRequired = false;
      notifyListeners();
    }
  }

  void _handleSessionExpired() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _emailConfirmationRequired = false;
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.setSessionExpiredHandler(null);
    super.dispose();
  }

  String _friendlyError(Object error, {bool loginAttempt = false}) {
    if (error is DioException && error.error is AppException) {
      return _friendlyError(
        error.error as AppException,
        loginAttempt: loginAttempt,
      );
    }
    if (error is NetworkException) {
      return 'Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại.';
    }
    if (error is AppException) {
      if (error.code == '401' || (loginAttempt && error.code == '400')) {
        return 'Email hoặc mật khẩu không chính xác.';
      }
      return error.message;
    }
    if (error is FormatException) {
      return 'Máy chủ trả về dữ liệu xác thực không hợp lệ.';
    }
    return 'Đã xảy ra lỗi xác thực. Vui lòng thử lại.';
  }
}
