import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import 'api_service.dart';

enum RegistrationOutcome { authenticated, emailConfirmationRequired }

class AuthRegistrationResult {
  const AuthRegistrationResult.authenticated(this.user)
    : outcome = RegistrationOutcome.authenticated;

  const AuthRegistrationResult.emailConfirmationRequired()
    : outcome = RegistrationOutcome.emailConfirmationRequired,
      user = null;

  final RegistrationOutcome outcome;
  final UserModel? user;

  bool get requiresEmailConfirmation =>
      outcome == RegistrationOutcome.emailConfirmationRequired;
}

abstract interface class AuthTokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();
}

class SecureAuthTokenStorage implements AuthTokenStorage {
  SecureAuthTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      await clearTokens();
      rethrow;
    }
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

abstract interface class AuthOperations {
  UserModel? get currentUser;
  String? get token;
  DateTime? get expiresAt;
  bool get isAuthenticated;
  void setSessionExpiredHandler(FutureOr<void> Function()? handler);
  Future<void> init();
  Future<UserModel> login({required String email, required String password});
  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
    required String name,
  });
  Future<void> forgotPassword(String email);
  Future<void> updateUser(UserModel updatedUser);
  Future<void> logout();
}

class AuthService implements AuthOperations {
  AuthService._()
    : _api = ApiService.instance,
      _tokenStorage = SecureAuthTokenStorage() {
    ApiClient.instance.setAccessTokenProvider(() => _accessToken);
    ApiClient.instance.setRefreshAccessTokenHandler(refreshAccessToken);
  }

  AuthService.forTesting({
    required AuthApiOperations api,
    required AuthTokenStorage tokenStorage,
    SharedPreferences? preferences,
  }) : _api = api,
       _tokenStorage = tokenStorage,
       _preferences = preferences {
    ApiClient.instance.setAccessTokenProvider(() => _accessToken);
    ApiClient.instance.setRefreshAccessTokenHandler(refreshAccessToken);
  }

  static final AuthService instance = AuthService._();

  final AuthApiOperations _api;
  final AuthTokenStorage _tokenStorage;
  SharedPreferences? _preferences;

  UserModel? _currentUser;
  String? _accessToken;
  DateTime? _expiresAt;
  Future<String?>? _refreshInFlight;
  FutureOr<void> Function()? _sessionExpiredHandler;

  @override
  UserModel? get currentUser => _currentUser;
  @override
  String? get token => _accessToken;
  @override
  DateTime? get expiresAt => _expiresAt;
  @override
  bool get isAuthenticated => _currentUser != null && _accessToken != null;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  @override
  void setSessionExpiredHandler(FutureOr<void> Function()? handler) {
    _sessionExpiredHandler = handler;
  }

  @override
  Future<void> init() async {
    final prefs = await _prefs;
    // Remove the legacy mock token without ever loading or logging its value.
    await prefs.remove(AppConstants.prefAuthToken);
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    _currentUser = null;
    _accessToken = null;
    _expiresAt = null;

    await refreshAccessToken();
  }

  Future<String?> refreshAccessToken() {
    final pending = _refreshInFlight;
    if (pending != null) return pending;

    late final Future<String?> current;
    current = _refreshStoredSession().whenComplete(() {
      if (identical(_refreshInFlight, current)) _refreshInFlight = null;
    });
    _refreshInFlight = current;
    return current;
  }

  Future<String?> _refreshStoredSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireLocalSession();
      return null;
    }

    try {
      final response = await _api.refresh(refreshToken);
      final user = await _acceptSessionResponse(
        response,
        prefs: await _prefs,
        fallbackRefreshToken: refreshToken,
      );
      _currentUser = user;
      return _accessToken;
    } catch (error) {
      if (_isRejectedRefresh(error)) {
        await _expireLocalSession();
        return null;
      }
      await _expireLocalSession();
      rethrow;
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.login(email, password);
    return _acceptSessionResponse(response, prefs: await _prefs);
  }

  @override
  Future<AuthRegistrationResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _api.register(email, password, name);
    final session = response['session'];
    if (session == null) {
      if (response['confirmation_required'] != true) {
        throw const FormatException(
          'Phản hồi đăng ký thiếu thông tin xác nhận email.',
        );
      }
      await _clearLocalSession(removeUser: false);
      return const AuthRegistrationResult.emailConfirmationRequired();
    }

    final user = await _acceptSessionResponse(response, prefs: await _prefs);
    return AuthRegistrationResult.authenticated(user);
  }

  Future<UserModel> _acceptSessionResponse(
    Map<String, dynamic> response, {
    required SharedPreferences prefs,
    String? fallbackRefreshToken,
  }) async {
    final sessionValue = response['session'];
    final userValue = response['user'];
    if (sessionValue is! Map || userValue is! Map) {
      throw const FormatException('Phản hồi phiên đăng nhập không hợp lệ.');
    }
    final session = Map<String, dynamic>.from(sessionValue);
    final userJson = Map<String, dynamic>.from(userValue);
    final accessToken = _requiredToken(session['access_token'], 'access_token');
    final responseRefreshToken = session['refresh_token'];
    final refreshToken =
        responseRefreshToken is String && responseRefreshToken.isNotEmpty
        ? responseRefreshToken
        : fallbackRefreshToken ??
              _requiredToken(responseRefreshToken, 'refresh_token');
    final expiresAt = _parseExpiry(session);
    final previousUser = _readPreviousUser(prefs);
    final user = UserModel.fromAuthJson(
      userJson,
      localSettings: previousUser?.id == userJson['id'] ? previousUser : null,
    );

    try {
      await _tokenStorage.writeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      if (!await prefs.setString(
        AppConstants.prefUser,
        jsonEncode(user.toJson()),
      )) {
        throw StateError('Không thể lưu hồ sơ cục bộ.');
      }
      if (!await prefs.setBool(AppConstants.prefIsLoggedIn, true)) {
        throw StateError('Không thể lưu trạng thái cục bộ.');
      }
    } catch (_) {
      await _clearLocalSession(removeUser: true);
      rethrow;
    }

    _currentUser = user;
    _accessToken = accessToken;
    _expiresAt = expiresAt;
    return user;
  }

  UserModel? _readPreviousUser(SharedPreferences prefs) {
    final value = prefs.getString(AppConstants.prefUser);
    if (value == null) return null;
    try {
      return UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  String _requiredToken(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FormatException('Phiên xác thực thiếu $field.');
    }
    return value;
  }

  DateTime? _parseExpiry(Map<String, dynamic> session) {
    final expiresAt = session['expires_at'];
    if (expiresAt is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        expiresAt.toInt() * 1000,
        isUtc: true,
      );
    }
    if (expiresAt is String) {
      final epoch = int.tryParse(expiresAt);
      if (epoch != null) {
        return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
      }
      return DateTime.tryParse(expiresAt)?.toUtc();
    }
    final expiresIn = session['expires_in'];
    if (expiresIn is num && expiresIn > 0) {
      return DateTime.now().toUtc().add(Duration(seconds: expiresIn.toInt()));
    }
    return null;
  }

  bool _isRejectedRefresh(Object error) {
    final appError = _appError(error);
    return appError?.code == '400' || appError?.code == '401';
  }

  Future<void> _expireLocalSession() async {
    try {
      await _clearLocalSession(removeUser: true);
    } finally {
      await _sessionExpiredHandler?.call();
    }
  }

  AppException? _appError(Object error) {
    if (error is AppException) return error;
    // ApiClient wraps the typed app exception in DioException.error.
    if (error is DioException && error.error is AppException) {
      return error.error as AppException;
    }
    return null;
  }

  Future<void> _clearLocalSession({required bool removeUser}) async {
    final prefs = await _prefs;
    Object? clearError;
    try {
      await _tokenStorage.clearTokens();
    } catch (error) {
      clearError = error;
    }
    _currentUser = null;
    _accessToken = null;
    _expiresAt = null;
    await prefs.remove(AppConstants.prefAuthToken);
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    if (removeUser) await prefs.remove(AppConstants.prefUser);
    if (clearError != null)
      throw StateError('Không thể xóa phiên lưu an toàn.');
  }

  @override
  Future<void> forgotPassword(String email) async {
    throw AuthException(
      'Chức năng gửi email khôi phục mật khẩu chưa được hỗ trợ.',
      code: 'NOT_SUPPORTED',
    );
  }

  @override
  Future<void> updateUser(UserModel updatedUser) async {
    _currentUser = updatedUser;
    final prefs = await _prefs;
    await prefs.setString(
      AppConstants.prefUser,
      jsonEncode(updatedUser.toJson()),
    );
  }

  @override
  Future<void> logout() async {
    try {
      if (_accessToken != null) await _api.logout();
    } catch (_) {
      // A failed remote logout must not keep the local device signed in.
    } finally {
      await _clearLocalSession(removeUser: true);
    }
  }
}
