import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();

  factory MonitoringService() {
    return _instance;
  }

  MonitoringService._internal();

  late StreamController<MonitoringState> _stateController;
  Stream<MonitoringState> get statusStream => _stateController.stream;

  Timer? _pollTimer;
  bool _isMonitoring = false;
  DateTime? _lastUpdate;
  MonitoringStatus _currentStatus = MonitoringStatus.inactive;

  bool get isMonitoring => _isMonitoring;

  void initialize() {
    _stateController = StreamController<MonitoringState>.broadcast();
  }

  void dispose() {
    _pollTimer?.cancel();
    _stateController.close();
  }

  /// Start monitoring in background (polls every 60 seconds)
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    final hasLocationPermission = await _requestLocationPermission();
    if (!hasLocationPermission) {
      _updateState(MonitoringStatus.paused, 'Location permission denied');
      return;
    }

    _isMonitoring = true;
    _currentStatus = MonitoringStatus.active;
    _updateState(MonitoringStatus.active, 'Monitoring started');

    // Poll every 60 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _collectAndLogSensorData();
    });

    // Collect immediately on start
    await _collectAndLogSensorData();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _pollTimer?.cancel();
    _isMonitoring = false;
    _currentStatus = MonitoringStatus.inactive;
    _updateState(MonitoringStatus.inactive, 'Monitoring stopped');
  }

  /// Pause monitoring
  void pauseMonitoring() {
    _pollTimer?.cancel();
    _isMonitoring = false;
    _currentStatus = MonitoringStatus.paused;
    _updateState(MonitoringStatus.paused, 'Monitoring paused');
  }

  /// Resume monitoring
  Future<void> resumeMonitoring() async {
    if (_isMonitoring) return;
    await startMonitoring();
  }

  /// Collect GPS and sensor data
  Future<SensorData?> _collectAndLogSensorData() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      // Get battery level (mock - in real app, battery_info package)
      final battery = 75.0; // Mock battery level

      // Get motion data from accelerometer
      bool isMoving = await _isDeviceMoving();

      // Get weather condition (mock)
      final weatherCondition = _getMockWeatherCondition();

      final sensorData = SensorData(
        lat: position.latitude,
        lng: position.longitude,
        speedKmh: position.speed * 3.6, // Convert m/s to km/h
        battery: battery,
        isMoving: isMoving,
        weatherCondition: weatherCondition,
        timestamp: DateTime.now(),
      );

      _lastUpdate = DateTime.now();

      // Check for extreme conditions
      if (_hasExtremeCondition(sensorData)) {
        _updateState(
          MonitoringStatus.alert,
          'Extreme condition detected: $weatherCondition',
        );
      } else if (_currentStatus != MonitoringStatus.alert) {
        _updateState(MonitoringStatus.active);
      }

      return sensorData;
    } catch (e) {
      print('Error collecting sensor data: $e');
      return null;
    }
  }

  Future<bool> _requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<bool> _isDeviceMoving() async {
    // Mock device movement detection
    // In production, integrate sensors_plus or device_motion package
    try {
      final position = await Geolocator.getCurrentPosition();
      // If device has significant speed, it's moving
      return position.speed > 0.5; // > 0.5 m/s = ~1.8 km/h
    } catch (e) {
      return false;
    }
  }

  String _getMockWeatherCondition() {
    // Mock weather conditions - in production, call actual weather API
    final conditions = [
      'Clear',
      'Rainy',
      'Stormy',
      'Foggy',
      'Hail',
      'Extreme Heat',
    ];
    final random = DateTime.now().millisecond % conditions.length;
    return conditions[random];
  }

  bool _hasExtremeCondition(SensorData data) {
    final extremeWeather = [
      'Stormy',
      'Hail',
      'Extreme Heat',
    ];
    return extremeWeather.contains(data.weatherCondition);
  }

  void _updateState(MonitoringStatus status, [String? message]) {
    _currentStatus = status;
    _stateController.add(
      MonitoringState(
        status: status,
        lastUpdate: _lastUpdate ?? DateTime.now(),
        alertMessage: message,
      ),
    );
  }
}
