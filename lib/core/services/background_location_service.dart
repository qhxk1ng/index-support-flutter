import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';

// Top-level callback required by flutter_foreground_task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_LocationTaskHandler());
}

class _LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('LocationTaskHandler: started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _sendHeartbeat();
  } 

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('LocationTaskHandler: destroyed');
  }

  Future<void> _sendHeartbeat() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Position? position = await Geolocator.getLastKnownPosition();
      final now = DateTime.now();
      if (position == null || now.difference(position.timestamp).inMinutes >= 2) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
          );
        } catch (_) {}
      }
      if (position == null) return;

      // Skip low-accuracy GPS readings
      if (position.accuracy > 50) {
        debugPrint('Background: skipping inaccurate GPS (${position.accuracy}m)');
        return;
      }

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.tokenKey);
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.fullBaseUrl,
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final body = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
      if (position.speed >= 0) body['speed'] = position.speed;
      if (position.heading >= 0) body['heading'] = position.heading;
      try {
        await dio.post('/location/heartbeat', data: body);
      } catch (_) {
        await dio.post('/field-personnel/heartbeat', data: body);
      }
      debugPrint('Heartbeat sent: ${position.latitude}, ${position.longitude} (acc: ${position.accuracy}m)');
    } catch (e) {
      debugPrint('Heartbeat error: $e');
    }
  }
}

class BackgroundLocationService {
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_tracking',
        channelName: 'Location Tracking',
        channelDescription: 'Sharing your location with the team',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> start() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) return;

    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Index Care',
      notificationText: 'Sharing your location...',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<bool> isRunning() async {
    return FlutterForegroundTask.isRunningService;
  }
}
