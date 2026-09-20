import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_environment.dart';
import '../storage/token_store.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'api_response.dart';

abstract interface class HttpClient {
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(Object?) decode,
  });
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  });
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  });
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  });
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  });
}

final class DioApiClient implements HttpClient {
  DioApiClient(this._tokens, [Dio? dio])
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)) {
    AppConfig.validate();
    _dio.options
      ..connectTimeout = const Duration(seconds: 12)
      ..receiveTimeout = const Duration(seconds: 20)
      ..headers = const {'Accept': 'application/json'};
    _dio.interceptors.add(_BearerInterceptor(_dio, _tokens));
  }
  final Dio _dio;
  final TokenStore _tokens;
  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(Object?) decode,
  }) => _request('GET', path, query: query, decode: decode);
  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  }) => _request('POST', path, body: body, decode: decode);
  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  }) => _request('PUT', path, body: body, decode: decode);
  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  }) => _request('PATCH', path, body: body, decode: decode);
  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    required T Function(Object?) decode,
  }) => _request('DELETE', path, body: body, decode: decode);

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(Object?) decode,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, contentType: Headers.jsonContentType),
      );
      final raw = response.data;
      if (raw is! Map)
        throw const ServerException('Resposta inválida do servidor.', null);
      final result = ApiResponse<T>.fromJson(
        Map<String, dynamic>.from(raw),
        decode,
      );
      if (result.status >= 400)
        throw ServerException(result.message, result.status);
      return result;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  AppException _mapError(DioException error) {
    final code = error.response?.statusCode, payload = error.response?.data;
    final json = payload is Map ? Map<String, dynamic>.from(payload) : null;
    final message =
        (json?['mensagem'] ??
                json?['message'] ??
                'Não foi possível concluir a solicitação.')
            .toString();
    if (code == 401) return UnauthorizedException(message);
    if (code == 422)
      return ValidationException(
        message,
        Map<String, dynamic>.from(json?['errors'] as Map? ?? const {}),
      );
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout)
      return const NetworkException('Sem conexão com o servidor.');
    return ServerException(message, code);
  }
}

final class _BearerInterceptor extends Interceptor {
  _BearerInterceptor(this._dio, this._tokens);
  final Dio _dio;
  final TokenStore _tokens;
  Future<String?>? _refreshing;
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.read();
    if (token != null && token.isNotEmpty)
      options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final authRoute =
        request.path == ApiEndpoints.login ||
        request.path == ApiEndpoints.register ||
        request.path == ApiEndpoints.refresh;
    if (error.response?.statusCode != 401 ||
        authRoute ||
        request.extra['retried'] == true) {
      handler.next(error);
      return;
    }
    try {
      final token = await (_refreshing ??= _refreshToken());
      _refreshing = null;
      if (token == null) throw const UnauthorizedException();
      request.headers['Authorization'] = 'Bearer $token';
      request.extra['retried'] = true;
      handler.resolve(await _dio.fetch<Object?>(request));
    } catch (_) {
      _refreshing = null;
      await _tokens.clear();
      handler.next(error);
    }
  }

  Future<String?> _refreshToken() async {
    final current = await _tokens.read();
    if (current == null) return null;
    final client = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $current',
        },
      ),
    );
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.refresh,
      data: {'device_name': 'fitness_app'},
    );
    final token = ((response.data?['data'] as Map?)?['token'])?.toString();
    if (token != null && token.isNotEmpty) await _tokens.write(token);
    return token;
  }
}
