import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;

  ApiResponse({required this.isSuccess, this.data, this.error});
}

class ApiClient {
  final Dio _dio;
  String? _token;

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://10.0.2.2:3000/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ));

  void setToken(String? token) {
    _token = token;
  }

  Map<String, dynamic> get _headers {
    final h = <String, dynamic>{};
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
  }

  Future<ApiResponse> get(String path) async {
    try {
      final res = await _dio.get(path, options: Options(headers: _headers));
      return ApiResponse(isSuccess: true, data: res.data as Map<String, dynamic>?);
    } on DioException catch (e) {
      return ApiResponse(isSuccess: false, error: e.response?.data?['message']?.toString() ?? e.message);
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await _dio.post(path, data: body, options: Options(headers: _headers));
      return ApiResponse(isSuccess: true, data: res.data as Map<String, dynamic>?);
    } on DioException catch (e) {
      return ApiResponse(isSuccess: false, error: e.response?.data?['message']?.toString() ?? e.message);
    }
  }

  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await _dio.patch(path, data: body, options: Options(headers: _headers));
      return ApiResponse(isSuccess: true, data: res.data as Map<String, dynamic>?);
    } on DioException catch (e) {
      return ApiResponse(isSuccess: false, error: e.response?.data?['message']?.toString() ?? e.message);
    }
  }

  Future<ApiResponse> delete(String path) async {
    try {
      final res = await _dio.delete(path, options: Options(headers: _headers));
      return ApiResponse(isSuccess: true, data: res.data as Map<String, dynamic>?);
    } on DioException catch (e) {
      return ApiResponse(isSuccess: false, error: e.response?.data?['message']?.toString() ?? e.message);
    }
  }
}
