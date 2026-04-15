import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../network/api_client.dart';

class LocationTrackingService {
  final ApiClient _apiClient;
  Timer? _locationTimer;
  Timer? _heartbeatTimer;
  bool _isTracking = false;
  Position? _lastKnownPosition;

  LocationTrackingService(this._apiClient);

  Future<bool> requestLocationPermissions() async {
    final status = await Permission.locationAlways.request();
    
    if (status.isDenied) {
      final whenInUse = await Permission.locationWhenInUse.request();
      return whenInUse.isGranted;
    }
    
    return status.isGranted;
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        print('Location permission denied');
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      _isTracking = true;
      
      await _updateLocation();
      
      // Send initial heartbeat
      await _sendHeartbeat();
      
      // Location update every 3 seconds for denser GPS traces
      _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        await _updateLocation();
      });
      
      // Heartbeat every 30 seconds to mark technician as online
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        await _sendHeartbeat();
      });
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Filter out low-accuracy GPS readings (indoor, tunnel, cold start)
      if (position.accuracy > 50) {
        print('Skipping inaccurate GPS point (accuracy: ${position.accuracy}m)');
        return;
      }

      _lastKnownPosition = position;
      await _sendLocationToServer(position);
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _sendLocationToServer(Position position) async {
    try {
      await _apiClient.post(
        '/field-personnel/location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'speed': position.speed >= 0 ? position.speed : null,
          'heading': position.heading >= 0 ? position.heading : null,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error sending location to server: $e');
    }
  }

  Future<void> _sendHeartbeat() async {
    try {
      final data = <String, dynamic>{};
      
      // Include last known location if available
      if (_lastKnownPosition != null) {
        data['latitude'] = _lastKnownPosition!.latitude;
        data['longitude'] = _lastKnownPosition!.longitude;
        data['accuracy'] = _lastKnownPosition!.accuracy;
        if (_lastKnownPosition!.speed >= 0) data['speed'] = _lastKnownPosition!.speed;
        if (_lastKnownPosition!.heading >= 0) data['heading'] = _lastKnownPosition!.heading;
      }
      
      await _apiClient.post(
        '/field-personnel/heartbeat',
        data: data,
      );
      print('Heartbeat sent successfully');
    } catch (e) {
      print('Error sending heartbeat: $e');
    }
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isTracking = false;
  }

  bool get isTracking => _isTracking;

  void dispose() {
    stopTracking();
  }
}
