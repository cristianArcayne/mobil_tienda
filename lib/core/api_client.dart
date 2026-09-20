import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiClient {
  static const Duration timeoutDuration = Duration(seconds: 25);

  // Headers base
  static Future<Map<String, String>> _getHeaders({bool requireAuth = true, String? url}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Excluir googleapis.com de headers de autenticación local
    if (url != null && url.contains('googleapis.com')) {
      return headers;
    }

    if (requireAuth) {
      final token = await StorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET
  static Future<dynamic> get(String url, {bool requireAuth = true, Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders(requireAuth: requireAuth, url: url);
      final response = await http.get(uri, headers: headers).timeout(timeoutDuration);

      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // POST
  static Future<dynamic> post(String url, dynamic body, {bool requireAuth = true}) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _getHeaders(requireAuth: requireAuth, url: url);
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);

      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // PUT
  static Future<dynamic> put(String url, dynamic body, {bool requireAuth = true}) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _getHeaders(requireAuth: requireAuth, url: url);
      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeoutDuration);

      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE
  static Future<dynamic> delete(String url, {bool requireAuth = true}) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _getHeaders(requireAuth: requireAuth, url: url);
      final response = await http.delete(uri, headers: headers).timeout(timeoutDuration);

      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      String errorMessage = 'Error ${response.statusCode}';
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorData is Map && errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        } else if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

