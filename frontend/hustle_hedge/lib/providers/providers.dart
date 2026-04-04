import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  AuthProvider() {
    _initToken();
  }

  Future<void> _initToken() async {
    _token = await ApiClient.getStoredToken();
    notifyListeners();
  }

  Future<bool> sendOtp(String mobile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.sendOtp(mobile);
      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to send OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.verifyOtp(mobile, otp).timeout(
        const Duration(seconds: 10),
        onTimeout: () => {'success': false, 'message': 'Request timeout'},
      );
      
      if (result['success'] == true) {
        // Handle response format - data can be directly in result or in result['data']
        final data = result['data'] ?? result;
        _token = data['access_token'] ?? data['token'] ?? 'test_token_$mobile';
        _user = User(
          id: data['user_id'] ?? data['id'] ?? mobile,
          fullName: data['full_name'] ?? data['fullName'] ?? 'User',
          mobile: mobile,
          mobileVerified: true,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to verify OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await ApiClient.logout();
    _token = null;
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void setMockUser(String mobile) {
    // Mock authentication for testing - skip OTP verification
    _token = 'mock_token_$mobile';
    _user = User(
      id: 'user_$mobile',
      fullName: 'Test User',
      mobile: mobile,
      mobileVerified: true,
    );
    _error = null;
    notifyListeners();
  }

  Future<String?> getStoredToken() async {
    return await ApiClient.getStoredToken();
  }
}

class PolicyProvider extends ChangeNotifier {
  Policy? _policy;
  List<Plan> _plans = [];
  Plan? _recommendedPlan;
  bool _isLoading = false;
  String? _error;

  Policy? get policy => _policy;
  List<Plan> get plans => _plans;
  Plan? get recommendedPlan => _recommendedPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActivePolicy => _policy != null && _policy!.status == 'ACTIVE';

  Future<bool> fetchPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.getPlansList();
      if (result['success'] == true && result['data'] is List) {
        _plans = (result['data'] as List).map((p) => Plan.fromJson(p)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to fetch plans';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchRecommendedPlan() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.getRecommendedPlan();
      if (result['success'] == true && result['data'] != null) {
        _recommendedPlan = Plan.fromJson(result['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to fetch recommended plan';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchActivePolicy() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.getActivePolicy();
      if (result['success'] == true && result['data'] != null) {
        _policy = Policy.fromJson(result['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _policy = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> selectPlan(String planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.selectPlan(planId);
      if (result['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to select plan';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmPolicy() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.confirmPolicy();
      if (result['success'] == true && result['data'] != null) {
        _policy = Policy.fromJson(result['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to confirm policy';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> upgradePlan(String planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.upgradePlan(planId);
      if (result['success'] == true && result['data'] != null) {
        _policy = Policy.fromJson(result['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to upgrade plan';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelPolicy() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.cancelPolicy();
      if (result['success'] == true) {
        _policy = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to cancel policy';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

class ClaimsProvider extends ChangeNotifier {
  List<Claim> _claims = [];
  bool _isLoading = false;
  String? _error;

  List<Claim> get claims => _claims;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> fetchClaimsHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.getClaimHistory();
      if (result['success'] == true && result['data'] is List) {
        _claims = (result['data'] as List).map((c) => Claim.fromJson(c)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to fetch claims';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> submitClaim({
    required String type,
    required String description,
    required DateTime incidentDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiClient.submitClaim({
        'type': type,
        'description': description,
        'incident_date': incidentDate.toIso8601String(),
      });

      if (result['success'] == true && result['data'] != null) {
        final claim = Claim.fromJson(result['data']);
        _claims.insert(0, claim);
        _isLoading = false;
        notifyListeners();
        return result['data'];
      } else {
        _error = result['message'] ?? 'Failed to submit claim';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Claim?> getClaimStatus(String claimId) async {
    try {
      final result = await ApiClient.getClaimStatus(claimId);
      if (result['success'] == true && result['data'] != null) {
        return Claim.fromJson(result['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class MonitoringProvider extends ChangeNotifier {
  MonitoringStatus _status = MonitoringStatus.inactive;
  DateTime? _lastUpdate;
  String? _alertMessage;

  MonitoringStatus get status => _status;
  DateTime? get lastUpdate => _lastUpdate;
  String? get alertMessage => _alertMessage;
  bool get isActive => _status == MonitoringStatus.active;

  void setStatus(MonitoringStatus newStatus) {
    _status = newStatus;
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  void setAlert(String message) {
    _alertMessage = message;
    _status = MonitoringStatus.alert;
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  void clearAlert() {
    _alertMessage = null;
    _status = MonitoringStatus.active;
    notifyListeners();
  }

  Future<bool> logSensorData(SensorData data) async {
    try {
      final result = await ApiClient.logSensorData(data.toJson());
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
