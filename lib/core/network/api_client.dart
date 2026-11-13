import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late Dio dio;
  String? Function()? _accessTokenProvider;
  Future<String?> Function()? _refreshAccessToken;

  static const _authRetryExtraKey = 'authRetryAttempted';

  void setAccessTokenProvider(String? Function() provider) {
    _accessTokenProvider = provider;
  }

  void setRefreshAccessTokenHandler(Future<String?> Function() handler) {
    _refreshAccessToken = handler;
  }

  void init({String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final requiresAuth = options.extra['requiresAuth'] != false;
          final token = requiresAuth ? _accessTokenProvider?.call() : null;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (_shouldRefresh(e)) {
            final request = e.requestOptions;
            final currentToken = _accessTokenProvider?.call();
            final requestAuthorization =
                request.headers['Authorization'] as String?;
            final staleRequestToken =
                currentToken != null &&
                currentToken.isNotEmpty &&
                requestAuthorization != 'Bearer $currentToken';
            String? accessToken = staleRequestToken ? currentToken : null;

            if (!staleRequestToken) {
              final refresh = _refreshAccessToken;
              if (refresh != null) {
                try {
                  accessToken = await refresh();
                } catch (_) {
                  // Preserve the original request error. Refresh failures are
                  // handled by AuthService and are never logged here.
                }
              }
            }

            if (accessToken != null && accessToken.isNotEmpty) {
              final retryOptions = request.copyWith(
                headers: {
                  ...request.headers,
                  'Authorization': 'Bearer $accessToken',
                },
                extra: {...request.extra, _authRetryExtraKey: true},
              );
              try {
                final response = await dio.fetch<dynamic>(retryOptions);
                handler.resolve(response);
                return;
              } on DioException catch (retryError) {
                // The retry passes through this interceptor with its retry
                // marker, so a second 401 is returned without refreshing.
                handler.next(retryError);
                return;
              } catch (_) {
                handler.next(_toHandledDioError(e));
                return;
              }
            }
          }

          handler.next(_toHandledDioError(e));
        },
      ),
    );
  }

  bool _shouldRefresh(DioException error) {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.extra['requiresAuth'] == false ||
        request.extra[_authRetryExtraKey] == true) {
      return false;
    }

    final path = request.uri.path;
    return !path.endsWith('/auth/login') &&
        !path.endsWith('/auth/register') &&
        !path.endsWith('/auth/refresh');
  }

  DioException _toHandledDioError(DioException error) {
    final appException = _handleDioError(error);
    return DioException(
      requestOptions: error.requestOptions,
      error: appException,
      type: error.type,
      response: error.response,
    );
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final message = data is Map
            ? (data['message'] ?? 'Lỗi từ máy chủ')
            : 'Lỗi từ máy chủ ($statusCode)';

        if (statusCode == 401 || statusCode == 403) {
          return AuthException(message, code: '$statusCode');
        } else if (statusCode == 404) {
          return NotFoundException(message, code: '404');
        } else if (statusCode == 422 || statusCode == 400) {
          return ValidationException(message, code: '$statusCode');
        } else {
          return ServerException(message, code: '$statusCode');
        }
      case DioExceptionType.cancel:
        return AppException('Yêu cầu đã bị hủy');
      default:
        return AppException('Đã xảy ra lỗi không xác định');
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
