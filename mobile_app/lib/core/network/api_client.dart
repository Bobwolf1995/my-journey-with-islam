import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'http://192.168.1.105:8000';

  final http.Client _client;
  final String baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      return _decode(response);
    } on TimeoutException {
      return _connectionError('انتهت مهلة الاتصال بالسيرفر');
    } catch (error) {
      return _connectionError('تعذر الاتصال بالسيرفر', error: error);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 20));

      return _decode(response);
    } on TimeoutException {
      return _connectionError('انتهت مهلة الاتصال بالسيرفر');
    } catch (error) {
      return _connectionError('تعذر الاتصال بالسيرفر', error: error);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 20));

      return _decode(response);
    } on TimeoutException {
      return _connectionError('انتهت مهلة الاتصال بالسيرفر');
    } catch (error) {
      return _connectionError('تعذر الاتصال بالسيرفر', error: error);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: _headers(token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 20));

      return _decode(response);
    } on TimeoutException {
      return _connectionError('انتهت مهلة الاتصال بالسيرفر');
    } catch (error) {
      return _connectionError('تعذر الاتصال بالسيرفر', error: error);
    }
  }

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.trim();

    dynamic decoded;

    try {
      decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{
        'success': false,
        'statusCode': response.statusCode,
        'message': 'استجابة غير مفهومة من السيرفر',
        'raw': body,
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{
        'success': true,
        'data': decoded,
      };
    }

    return <String, dynamic>{
      'success': false,
      'statusCode': response.statusCode,
      'message': decoded is Map<String, dynamic>
          ? decoded['message'] ?? 'حدث خطأ غير متوقع'
          : 'حدث خطأ غير متوقع',
      'errors': decoded is Map<String, dynamic> ? decoded['errors'] : null,
    };
  }

  Map<String, dynamic> _connectionError(
    String message, {
    Object? error,
  }) {
    return <String, dynamic>{
      'success': false,
      'message': message,
      'error': error?.toString(),
    };
  }
}
