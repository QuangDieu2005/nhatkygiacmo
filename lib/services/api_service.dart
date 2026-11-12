import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/dream_model.dart';
import '../models/sleep_session_model.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final ApiClient _client = ApiClient.instance;

  ApiClient get client => _client;

  // Authentication API endpoints (cho Node.js backend)
  Future<Map<String, dynamic>> login(String email, String password) async {
    // TODO: Khi nối Backend Node.js thực tế:
    // final response = await _client.post('/auth/login', data: {'email': email, 'password': password});
    // return response.data;
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': UserModel(
        id: 'usr_${email.hashCode.abs()}',
        email: email,
        name: email.split('@').first,
        createdAt: DateTime.now(),
      ).toJson(),
    };
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    // TODO: Khi nối Backend Node.js thực tế:
    // final response = await _client.post('/auth/register', data: {'email': email, 'password': password, 'name': name});
    // return response.data;
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': UserModel(
        id: 'usr_${email.hashCode.abs()}',
        email: email,
        name: name,
        createdAt: DateTime.now(),
      ).toJson(),
    };
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
