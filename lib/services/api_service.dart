import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/dream_model.dart';
import '../models/sleep_session_model.dart';

abstract interface class AuthApiOperations {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  );
  Future<Map<String, dynamic>> refresh(String refreshToken);
  Future<void> logout();
}

class ApiService implements AuthApiOperations {
  ApiService._();
  static final ApiService instance = ApiService._();

  final ApiClient _client = ApiClient.instance;

  ApiClient get client => _client;

  // Authentication API endpoints (cho Node.js backend)
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: Options(extra: {'requiresAuth': false}),
    );
    return _mapResponse(response.data);
  }

  @override
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
      options: Options(extra: {'requiresAuth': false}),
    );
    return _mapResponse(response.data);
  }

  @override
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'requiresAuth': false}),
    );
    return _mapResponse(response.data);
  }

  @override
  Future<void> logout() async {
    await _client.post<void>('/auth/logout');
  }

  Map<String, dynamic> _mapResponse(Object? value) {
    if (value is! Map) {
      throw const FormatException('Phản hồi xác thực không hợp lệ.');
    }
    return Map<String, dynamic>.from(value);
  }

  // Dreams API endpoints
  Future<List<DreamModel>> fetchDreams() async {
    // TODO: Gọi API REST khi backend sẵn sàng:
    // final response = await _client.get('/dreams');
    // return (response.data as List).map((e) => DreamModel.fromApiJson(e)).toList();
    return [];
  }

  Future<DreamModel> createDream(DreamModel dream) async {
    // TODO: POST /dreams with dream.toApiWriteJson(), then parse
    // DreamModel.fromApiJson(response.data). This remains a local stub.
    return dream;
  }

  // Sleep record API endpoint stubs. Local tracking snapshots keep toJson().
  Future<List<SleepSessionModel>> fetchSleepSessions() async {
    // TODO: GET /sleep-records and parse with SleepSessionModel.fromApiJson.
    return [];
  }

  Future<SleepSessionModel> syncSleepSession(SleepSessionModel session) async {
    // TODO: POST /sleep-records with session.toApiWriteJson(), then parse
    // SleepSessionModel.fromApiJson(response.data). Do not send local JSON.
    return session;
  }
}
