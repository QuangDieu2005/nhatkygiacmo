import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/constants/app_constants.dart';
import 'package:my_app/core/errors/app_exception.dart';
import 'package:my_app/core/network/api_client.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _userId = 'fbb80b6f-c830-41f3-99fb-075d8d23d989';
const _access = 'access-test-value';
const _refresh = 'refresh-test-value';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('login stores API tokens through secure storage abstraction', () async {
    final storage = _MemoryTokenStorage();
    final service = await _service(storage: storage);
    final user = await service.login(
      email: 'dream@example.com',
      password: 'correct-horse',
    );

    expect(user.name, 'Dreamer');
    expect(storage.accessToken, _access);
    expect(storage.refreshToken, _refresh);
    expect(service.isAuthenticated, isTrue);
    expect(service.expiresAt, isNotNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefAuthToken), isNull);
  });

  test('login API failure creates no local session', () async {
    final storage = _MemoryTokenStorage();
    final api = _FakeAuthApi()
      ..loginError = AuthException('Denied', code: '401');
    final service = await _service(storage: storage, api: api);

    await expectLater(
      service.login(email: 'dream@example.com', password: 'bad'),
      throwsA(isA<AuthException>()),
    );
    expect(service.isAuthenticated, isFalse);
    expect(storage.accessToken, isNull);
  });

  test(
    'startup removes legacy SharedPreferences token without reading it',
    () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefAuthToken: 'legacy-mock-token',
      });
      final storage = _MemoryTokenStorage();
      final service = await _service(storage: storage);

      await service.init();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefAuthToken), isNull);
      expect(service.isAuthenticated, isFalse);
      expect(storage.refreshToken, isNull);
    },
  );

  test('register with session creates authenticated session', () async {
    final storage = _MemoryTokenStorage();
    final api = _FakeAuthApi()..registrationResponse = _sessionResponse();
    final service = await _service(storage: storage, api: api);

    final result = await service.register(
      email: 'dream@example.com',
      password: 'correct-horse',
      name: 'Dreamer',
    );

    expect(result.requiresEmailConfirmation, isFalse);
    expect(service.isAuthenticated, isTrue);
    expect(storage.refreshToken, _refresh);
  });

  test(
    'register requiring confirmation does not authenticate or store tokens',
    () async {
      final storage = _MemoryTokenStorage();
      final api = _FakeAuthApi()
        ..registrationResponse = {
          'user': null,
          'session': null,
          'confirmation_required': true,
        };
      final service = await _service(storage: storage, api: api);

      final result = await service.register(
        email: 'dream@example.com',
        password: 'correct-horse',
        name: 'Dreamer',
      );

      expect(result.requiresEmailConfirmation, isTrue);
      expect(service.isAuthenticated, isFalse);
      expect(storage.refreshToken, isNull);
    },
  );

  test(
    'startup restores user and rotates tokens through refresh endpoint',
    () async {
      final storage = _MemoryTokenStorage()..refreshToken = 'old-refresh';
      final api = _FakeAuthApi();
      final service = await _service(storage: storage, api: api);
      await service.init();

      expect(api.refreshCalls, 1);
      expect(api.lastRefreshToken, 'old-refresh');
      expect(service.isAuthenticated, isTrue);
      expect(storage.accessToken, _access);
      expect(storage.refreshToken, _refresh);
    },
  );

  test('rejected refresh clears both stored tokens', () async {
    final storage = _MemoryTokenStorage()..refreshToken = 'expired-refresh';
    final api = _FakeAuthApi()
      ..refreshError = AuthException('Expired', code: '401');
    final service = await _service(storage: storage, api: api);
    await service.init();

    expect(service.isAuthenticated, isFalse);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('refresh failure during restore clears local session', () async {
    final storage = _MemoryTokenStorage()..refreshToken = 'retry-refresh';
    final api = _FakeAuthApi()..refreshError = NetworkException('offline');
    final service = await _service(storage: storage, api: api);

    await expectLater(service.init(), throwsA(isA<NetworkException>()));
    expect(service.isAuthenticated, isFalse);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('logout success clears local session', () async {
    final storage = _MemoryTokenStorage();
    final service = await _service(storage: storage);
    await service.login(email: 'dream@example.com', password: 'secret');
    await service.logout();

    expect(service.isAuthenticated, isFalse);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('logout network failure still clears local session', () async {
    final storage = _MemoryTokenStorage();
    final api = _FakeAuthApi();
    final service = await _service(storage: storage, api: api);
    await service.login(email: 'dream@example.com', password: 'secret');
    api.logoutError = NetworkException('offline');
    await service.logout();

    expect(api.logoutCalls, 1);
    expect(service.isAuthenticated, isFalse);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('auth user name falls back to user_metadata then email prefix', () {
    final metadataUser = UserModel.fromAuthJson({
      'id': _userId,
      'email': 'dream@example.com',
      'user_metadata': {'name': 'Metadata Name'},
      'created_at': '2025-01-01T00:00:00Z',
    });
    final fallbackUser = UserModel.fromAuthJson({
      'id': _userId,
      'email': 'dream@example.com',
    });

    expect(metadataUser.name, 'Metadata Name');
    expect(fallbackUser.name, 'dream');
  });

  test('ApiClient attaches bearer only when request requires auth', () async {
    final adapter = _RecordingAdapter();
    final client = ApiClient.instance;
    client.setAccessTokenProvider(() => _access);
    client.init(baseUrl: 'https://unit.test');
    client.dio.httpClientAdapter = adapter;
    await client.get<Map<String, dynamic>>('/private');
    await client.get<Map<String, dynamic>>(
      '/public',
      options: Options(extra: {'requiresAuth': false}),
    );
    expect(adapter.authorizationHeaders, ['Bearer $_access', null]);
  });

  test(
    '401 refreshes once and retries original request with rotated token',
    () async {
      final adapter = _RetryAdapter();
      final storage = _MemoryTokenStorage();
      final api = _FakeAuthApi()
        ..refreshResponse = _sessionResponseWithTokens(
          'rotated-access',
          'rotated-refresh',
        );
      final service = await _service(storage: storage, api: api);
      await service.login(email: 'dream@example.com', password: 'secret');
      _useAdapter(adapter);

      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        '/dreams',
        data: {'title': 'kept body'},
        queryParameters: {'filter': 'kept query'},
      );

      expect(response.statusCode, 200);
      expect(api.refreshCalls, 1);
      expect(storage.accessToken, 'rotated-access');
      expect(storage.refreshToken, 'rotated-refresh');
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].method, 'POST');
      expect(adapter.requests[1].method, 'POST');
      expect(adapter.requests[1].uri.path, adapter.requests[0].uri.path);
      expect(adapter.requests[1].queryParameters, {'filter': 'kept query'});
      expect(adapter.requests[1].data, {'title': 'kept body'});
      expect(adapter.authorizationHeaders, [
        'Bearer $_access',
        'Bearer rotated-access',
      ]);
    },
  );

  test('a retry that still returns 401 is not refreshed again', () async {
    final adapter = _RetryAdapter()..retryUnauthorized = true;
    final storage = _MemoryTokenStorage();
    final api = _FakeAuthApi()
      ..refreshResponse = _sessionResponseWithTokens(
        'rotated-access',
        'rotated-refresh',
      );
    final service = await _service(storage: storage, api: api);
    await service.login(email: 'dream@example.com', password: 'secret');
    _useAdapter(adapter);

    await expectLater(
      ApiClient.instance.get<Map<String, dynamic>>('/private'),
      throwsA(isA<DioException>()),
    );

    expect(api.refreshCalls, 1);
    expect(adapter.requests, hasLength(2));
    expect(adapter.authorizationHeaders.last, 'Bearer rotated-access');
  });

  test(
    'rejected refresh clears local tokens and notifies AuthProvider',
    () async {
      final adapter = _RetryAdapter();
      final storage = _MemoryTokenStorage();
      final api = _FakeAuthApi()
        ..refreshError = AuthException('Rejected', code: '401');
      final service = await _service(storage: storage, api: api);
      final provider = AuthProvider(authService: service);
      addTearDown(provider.dispose);
      await provider.login(email: 'dream@example.com', password: 'secret');
      _useAdapter(adapter);

      await expectLater(
        ApiClient.instance.get<Map<String, dynamic>>('/private'),
        throwsA(isA<DioException>()),
      );

      expect(provider.isAuthenticated, isFalse);
      expect(provider.status, AuthStatus.unauthenticated);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(api.refreshCalls, 1);
    },
  );

  test('public auth endpoints do not trigger refresh interception', () async {
    final adapter = _RetryAdapter()..unauthorizedWithoutToken = true;
    final storage = _MemoryTokenStorage();
    final api = _FakeAuthApi();
    final service = await _service(storage: storage, api: api);
    await service.login(email: 'dream@example.com', password: 'secret');
    _useAdapter(adapter);

    for (final path in ['/auth/login', '/auth/register', '/auth/refresh']) {
      await expectLater(
        ApiClient.instance.post<Map<String, dynamic>>(
          path,
          data: const {},
          options: Options(extra: {'requiresAuth': false}),
        ),
        throwsA(isA<DioException>()),
      );
    }

    expect(api.refreshCalls, 0);
    expect(adapter.requests, hasLength(3));
    expect(adapter.authorizationHeaders, everyElement(isNull));
  });

  test('simultaneous 401 responses share one refresh and both retry', () async {
    final adapter = _RetryAdapter();
    final storage = _MemoryTokenStorage();
    final api = _FakeAuthApi()
      ..refreshGate = Completer<void>()
      ..refreshStarted = Completer<void>()
      ..refreshResponse = _sessionResponseWithTokens(
        'rotated-access',
        'rotated-refresh',
      );
    final service = await _service(storage: storage, api: api);
    await service.login(email: 'dream@example.com', password: 'secret');
    _useAdapter(adapter);

    final first = ApiClient.instance.get<Map<String, dynamic>>(
      '/private',
      queryParameters: {'request': 'one'},
    );
    final second = ApiClient.instance.get<Map<String, dynamic>>(
      '/private',
      queryParameters: {'request': 'two'},
    );
    await api.refreshStarted!.future;
    expect(api.refreshCalls, 1);
    api.refreshGate!.complete();

    final responses = await Future.wait([first, second]);
    expect(responses, hasLength(2));
    expect(responses.every((response) => response.statusCode == 200), isTrue);
    expect(api.refreshCalls, 1);
    expect(adapter.requests, hasLength(4));
    expect(
      adapter.authorizationHeaders.where(
        (value) => value == 'Bearer rotated-access',
      ),
      hasLength(2),
    );
  });

  test(
    'missing refresh token does not call refresh endpoint and ends session',
    () async {
      final adapter = _RetryAdapter();
      final storage = _MemoryTokenStorage();
      final api = _FakeAuthApi();
      final service = await _service(storage: storage, api: api);
      final provider = AuthProvider(authService: service);
      addTearDown(provider.dispose);
      await provider.login(email: 'dream@example.com', password: 'secret');
      storage.refreshToken = null;
      _useAdapter(adapter);

      await expectLater(
        ApiClient.instance.get<Map<String, dynamic>>('/private'),
        throwsA(isA<DioException>()),
      );

      expect(api.refreshCalls, 0);
      expect(provider.isAuthenticated, isFalse);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    },
  );

  test(
    'refresh network failure completes request and expires local session',
    () async {
      final adapter = _RetryAdapter();
      final storage = _MemoryTokenStorage();
      final api = _FakeAuthApi()..refreshError = NetworkException('offline');
      final service = await _service(storage: storage, api: api);
      final provider = AuthProvider(authService: service);
      addTearDown(provider.dispose);
      await provider.login(email: 'dream@example.com', password: 'secret');
      _useAdapter(adapter);

      await expectLater(
        ApiClient.instance
            .get<Map<String, dynamic>>('/private')
            .timeout(const Duration(seconds: 2)),
        throwsA(isA<DioException>()),
      );

      expect(api.refreshCalls, 1);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.status, AuthStatus.unauthenticated);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    },
  );
}

Future<AuthService> _service({
  required _MemoryTokenStorage storage,
  _FakeAuthApi? api,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return AuthService.forTesting(
    api: api ?? _FakeAuthApi(),
    tokenStorage: storage,
    preferences: prefs,
  );
}

Map<String, dynamic> _sessionResponse() => {
  'user': {
    'id': _userId,
    'email': 'dream@example.com',
    'user_metadata': {'name': 'Dreamer'},
    'created_at': '2025-01-01T00:00:00Z',
  },
  'session': {
    'access_token': _access,
    'refresh_token': _refresh,
    'expires_in': 3600,
    'expires_at': 1924992000,
  },
};

Map<String, dynamic> _sessionResponseWithTokens(
  String accessToken,
  String refreshToken,
) => {
  ..._sessionResponse(),
  'session': {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': 3600,
    'expires_at': 1924992000,
  },
};

void _useAdapter(_RetryAdapter adapter) {
  final client = ApiClient.instance;
  client.init(baseUrl: 'https://unit.test/api');
  client.dio.httpClientAdapter = adapter;
}

class _MemoryTokenStorage implements AuthTokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;
  @override
  Future<String?> readRefreshToken() async => refreshToken;
  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _FakeAuthApi implements AuthApiOperations {
  Map<String, dynamic> registrationResponse = {
    ..._sessionResponse(),
    'confirmation_required': false,
  };
  Object? loginError;
  Object? refreshError;
  Object? logoutError;
  int refreshCalls = 0;
  int logoutCalls = 0;
  String? lastRefreshToken;
  Completer<void>? refreshGate;
  Completer<void>? refreshStarted;
  Map<String, dynamic> refreshResponse = _sessionResponse();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (loginError case final error?) throw error;
    return _sessionResponse();
  }

  @override
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async => registrationResponse;

  @override
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    refreshCalls++;
    lastRefreshToken = refreshToken;
    if (refreshStarted != null && !refreshStarted!.isCompleted) {
      refreshStarted!.complete();
    }
    if (refreshGate != null) await refreshGate!.future;
    if (refreshError case final error?) throw error;
    return refreshResponse;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError case final error?) throw error;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  final authorizationHeaders = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorizationHeaders.add(options.headers['Authorization'] as String?);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RetryAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool retryUnauthorized = false;
  bool unauthorizedWithoutToken = false;

  List<String?> get authorizationHeaders => requests
      .map((request) => request.headers['Authorization'] as String?)
      .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final accessHeader = options.headers['Authorization'];
    if (accessHeader == 'Bearer $_access' ||
        (unauthorizedWithoutToken && accessHeader == null) ||
        (retryUnauthorized && accessHeader == 'Bearer rotated-access')) {
      return ResponseBody.fromString(
        '{"message":"expired"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
