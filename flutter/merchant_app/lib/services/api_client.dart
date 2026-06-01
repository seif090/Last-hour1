import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lasthour_shared/src/services/connectivity_service.dart';
import 'package:lasthour_shared/src/exceptions/network_exception.dart';

class ApiResponse {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;
  final int statusCode;

  const ApiResponse({
    required this.isSuccess,
    this.data,
    this.error,
    required this.statusCode,
  });
}

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ConnectivityService _connectivity;

  ApiClient({required String baseUrl, required ConnectivityService connectivity})
      : _connectivity = connectivity,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.headers['Authorization'] == null) {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.receiveTimeout) {
          for (var i = 0; i < 2; i++) {
            try {
              await Future.delayed(Duration(seconds: 1 << i));
              final response = await err.requestOptions.copyWith().execute();
              handler.resolve(response);
              return;
            } catch (_) {}
          }
        }
        handler.next(err);
      },
    ));
  }

  void setToken(String? token) {
    _dio.options.headers['Authorization'] = token != null ? 'Bearer $token' : null;
  }

  Future<ApiResponse> get(String path, {Map<String, dynamic>? queryParams}) async {
    if (!_connectivity.isConnected) throw const NetworkException();
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return _process(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) throw const NetworkException();
      return _error(e);
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    if (!_connectivity.isConnected) throw const NetworkException();
    try {
      final response = await _dio.post(path, data: body);
      return _process(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) throw const NetworkException();
      return _error(e);
    }
  }

  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    if (!_connectivity.isConnected) throw const NetworkException();
    try {
      final response = await _dio.patch(path, data: body);
      return _process(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) throw const NetworkException();
      return _error(e);
    }
  }

  Future<ApiResponse> delete(String path) async {
    if (!_connectivity.isConnected) throw const NetworkException();
    try {
      final response = await _dio.delete(path);
      return _process(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) throw const NetworkException();
      return _error(e);
    }
  }

  ApiResponse _process(Response response) {
    return ApiResponse(
      isSuccess: response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300,
      data: response.data is Map ? response.data as Map<String, dynamic> : {'result': response.data},
      statusCode: response.statusCode ?? 500,
    );
  }

  ApiResponse _error(DioException e) {
    final data = e.response?.data;
    String message = 'Something went wrong';
    if (data is Map) {
      message = data['message'] ?? data['error'] ?? message;
    } else if (data is String) {
      message = data;
    }
    return ApiResponse(
      isSuccess: false,
      error: message,
      statusCode: e.response?.statusCode ?? 500,
    );
  }
}
