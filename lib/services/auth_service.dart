import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

abstract interface class AuthOperations {
  UserModel? get currentUser;
  String? get token;
  bool get isAuthenticated;
  Future<void> init();
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  });
  Future<void> forgotPassword(String email);
  Future<void> updateUser(UserModel updatedUser);
  Future<void> logout();
}

class AuthService implements AuthOperations {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserModel? _currentUser;
  String? _token;

  @override
  UserModel? get currentUser => _currentUser;
  @override
  String? get token => _token;
  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.prefUser);
    _token = prefs.getString(AppConstants.prefAuthToken);

    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // The API service currently returns a local mock response.
    final result = await ApiService.instance.login(email, password);
    final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
    final token = result['token'] as String;

    _currentUser = user;
    _token = token;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUser, jsonEncode(user.toJson()));
    await prefs.setString(AppConstants.prefAuthToken, token);
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);

    return user;
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // Registration is mocked. A mock response is not proof that an account
    // was created or that its email was verified, so do not create a session.
    final result = await ApiService.instance.register(email, password, name);
    return UserModel.fromJson(result['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Simulates request latency only; it does not send an email.
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> updateUser(UserModel updatedUser) async {
    _currentUser = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefUser,
      jsonEncode(updatedUser.toJson()),
    );
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUser);
    await prefs.remove(AppConstants.prefAuthToken);
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
  }
}
