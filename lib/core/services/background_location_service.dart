import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';

class BackgroundLocationService {
  static Timer? _timer;
  static bool _running = false;
  static Position? _lastKnownPosition;

  static Future<void> initialize() async {
    // No-op
  }

  static Future<void> start() async {
    if (_running) return;
    _running = true;
    // Send immediately, then every 30s
    await _sendLocation();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _sendLocation());
  }

  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  static Future<bool> isRunning() async => _running;

  static Future<void> _sendLocation() async {
    try {
      // Check permission first
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('BackgroundLocationService: permission denied, skipping');
        return;
      }

      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('BackgroundLocationService: location service disabled');
        return;
      }

      // Try last known position first (fast, no timeout risk)
      Position? position = await Geolocator.getLastKnownPosition();

      // If last known is stale (>2 min) or null, get fresh position
      final now = DateTime.now();
      if (position == null ||
          now.difference(position.timestamp).inMinutes >= 2) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
        } catch (e) {
          // Fall back to last known if fresh fetch fails
          debugPrint('BackgroundLocationService: getCurrentPosition failed: $e');
          if (position == null && _lastKnownPosition != null) {
            position = _lastKnownPosition;
          }
        }
      }

      if (position == null) {
        debugPrint('BackgroundLocationService: no position available');
        return;
      }

      _lastKnownPosition = position;

      // Read auth token
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.tokenKey);
      if (token == null) {
        debugPrint('BackgroundLocationService: no auth token, skipping');
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.fullBaseUrl,
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final response = await dio.post('/field-personnel/heartbeat', data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      debugPrint('BackgroundLocationService: heartbeat sent '
          '(${position.latitude}, ${position.longitude}) → ${response.statusCode}');
    } catch (e) {
      debugPrint('BackgroundLocationService: error: $e');
    }
  }
}
