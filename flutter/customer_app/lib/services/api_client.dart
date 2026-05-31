import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
  late final Dio _dio;
  String? _token;
  final String baseUrl;

  ApiClient({required this.baseUrl, String? token}) : _token = token {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    ));

    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback = (cert, host, port) =>
          false; // production: validate
      return client;
    };

    _dio.interceptors.addAll([
      _AuthInterceptor(() => _token),
      _RetryInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  void setToken(String? token) => _token = token;

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get(path, queryParameters: query);
    return ApiResponse.fromDio(response);
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _dio.post(path, data: body);
    return ApiResponse.fromDio(response);
  }

  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await _dio.patch(path, data: body);
    return ApiResponse.fromDio(response);
  }

  Future<ApiResponse> delete(String path) async {
    final response = await _dio.delete(path);
    return ApiResponse.fromDio(response);
  }
}

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic>? data;
  final String? error;

  ApiResponse({
    required this.statusCode,
    this.data,
    this.error,
  });

  factory ApiResponse.fromDio(Response response) {
    final body = response.data is Map
        ? response.data as Map<String, dynamic>
        : jsonDecode(response.data as String) as Map<String, dynamic>;

    return ApiResponse(
      statusCode: response.statusCode ?? 500,
      data: body['data'] as Map<String, dynamic>?,
      error: body['error']?.toString(),
    );
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get hasError => error != null;

  T? as<T>(T Function(Map<String, dynamic>) fromJson) {
    if (data == null) return null;
    return fromJson(data!);
  }
}

class _AuthInterceptor extends Interceptor {
  final String? Function() getToken;

  _AuthInterceptor(this.getToken);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — trigger refresh or logout
    }
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final response = await err.requestOptions.extra['retry'] = true;
        handler.resolve(await Dio().fetch(err.requestOptions));
      } catch (retryError) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response != null && err.response!.statusCode! >= 500) &&
            err.requestOptions.extra['retry'] != true;
  }
}
