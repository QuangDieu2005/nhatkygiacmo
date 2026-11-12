import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserModel? _currentUser;
  String? _token;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.prefUser);
    _token = prefs.getString(AppConstants.prefAuthToken);

    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<UserModel> login({required String email, required String password}) async {
    // Gọi ApiService hoặc Supabase
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

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await ApiService.instance.register(email, password, name);
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

  Future<void> forgotPassword(String email) async {
    // Mock gửi email reset
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> updateUser(UserModel updatedUser) async {
    _currentUser = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefUser, jsonEncode(updatedUser.toJson()));
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUser);
    await prefs.remove(AppConstants.prefAuthToken);
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
  }
}
