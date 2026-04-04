import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // For Android Emulator: use 10.0.2.2 instead of localhost
  // For physical device: replace with your machine IP (e.g., http://192.168.x.x:5000)
  // For web/iOS: use localhost
  static const String _baseUrl = 'http://10.0.2.2:5000/api/v1';
  static const _secureStorage = FlutterSecureStorage();

  static String? _jwtToken;

  // ────────────────────────────────────────────────────────────────────────
  // Authentication
  // ────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String mobile,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      ).timeout(const Duration(seconds: 10));
      
      final result = _handleResponse(response);
      if (result['success']) {
        // Try to extract token from various possible response formats
        final data = result['data'] ?? result;
        final token = data['access_token'] ?? data['token'] ?? 'mock_token_$mobile';
        if (token.isNotEmpty) {
          await _secureStorage.write(key: 'jwt_token', value: token);
          _jwtToken = token;
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
    _jwtToken = null;
    return true;
  }

  static Future<String?> getStoredToken() async {
    if (_jwtToken == null) {
      _jwtToken = await _secureStorage.read(key: 'jwt_token');
    }
    return _jwtToken;
  }

  // ────────────────────────────────────────────────────────────────────────
  // Registration
  // ────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitRegistration(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/worker/profile'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getWorkerProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/worker/profile'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Plans
  // ────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPlansList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/plans/list'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getRecommendedPlan() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/plans/recommend'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPlanDetails(String planId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/plans/$planId/details'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Policy
  // ────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> selectPlan(String planId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/policy/select-plan'),
        headers: _getHeaders(),
        body: jsonEncode({'plan_id': planId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> confirmPolicy() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/policy/confirm'),
        headers: _getHeaders(),
        body: jsonEncode({}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getActivePolicy() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/policy/me'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPolicyDetails(String policyId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/policy/$policyId'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> upgradePlan(String planId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/policy/upgrade-plan'),
        headers: _getHeaders(),
        body: jsonEncode({'plan_id': planId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> cancelPolicy() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/policy/cancel'),
        headers: _getHeaders(),
        body: jsonEncode({}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Claims
  // ────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitClaim(
    Map<String, dynamic> claimData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/claims/submit'),
        headers: _getHeaders(),
        body: jsonEncode(claimData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getClaimHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/claims/history'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getClaimStatus(String claimId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/claims/$claimId/status'),
        headers: _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Monitoring
  // ────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> logSensorData(
    Map<String, dynamic> sensorData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/monitoring/log'),
        headers: _getHeaders(),
        body: jsonEncode(sensorData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Utilities
  // ────────────────────────────────────────────────────────────────────────

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid response format',
        'status_code': response.statusCode,
      };
    }
  }
}
