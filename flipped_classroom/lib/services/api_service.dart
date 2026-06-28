import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5001/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:5001/api/v1';
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: _getHeaders());
    return _handleResponse(response, 'GET', path);
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, 'POST', path);
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.put(
      url,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, 'PUT', path);
  }

  Future<http.Response> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.delete(url, headers: _getHeaders());
    return _handleResponse(response, 'DELETE', path);
  }

  http.Response _handleResponse(
    http.Response response,
    String method,
    String path,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    try {
      final body = jsonDecode(response.body);
      final message = body['message']?.toString() ?? 'Da xay ra loi he thong';
      debugPrint(
        'API $method $path failed: status=${response.statusCode}, code=${body['code']}, message=$message',
      );
      throw ApiException(message, response.statusCode);
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      debugPrint(
        'API $method $path failed: status=${response.statusCode}, raw=${response.body}',
      );
      throw ApiException(
        'Loi ket noi may chu (${response.statusCode})',
        response.statusCode,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
