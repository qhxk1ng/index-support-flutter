import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/mapbox_theme_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class AdminTrackingPage extends StatefulWidget {
  final String complaintId;
  final String ticketNumber;

  const AdminTrackingPage({
    super.key,
    required this.complaintId,
    required this.ticketNumber,
  });

  @override
  State<AdminTrackingPage> createState() => _AdminTrackingPageState();
}

class _AdminTrackingPageState extends State<AdminTrackingPage> {
  late MapboxMapController _mapController;
  Timer? _locationTimer;

  double? _technicianLat;
  double? _technicianLng;
  double? _jobSiteLat;
  double? _jobSiteLng;
  String? _technicianName;
  String? _technicianPhone;
  double? _distanceKm;
  String? _status;
  bool _journeyStarted = false;
  bool _isLoading = true;
  String? _error;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = MapboxThemeService.isDarkMode();
    _fetchTrackingData();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchTrackingData(),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrackingData() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(
        '/admin/complaint/${widget.complaintId}/track',
      );
      final data = response.data['data'];

      if (mounted) {
        setState(() {
          _technicianLat = (data['latitude'] as num).toDouble();
          _technicianLng = (data['longitude'] as num).toDouble();
          _jobSiteLat = (data['complaintLatitude'] as num).toDouble();
          _jobSiteLng = (data['complaintLongitude'] as num).toDouble();
          _technicianName = data['technicianName'] as String?;
          _technicianPhone = data['technicianPhone'] as String?;
          _distanceKm = (data['distanceKm'] as num?)?.toDouble();
          _status = data['status'] as String?;
          _journeyStarted = data['journeyStarted'] == true;
          _isLoading = false;
          _error = null;
        });

        _fitMapToBounds();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_technicianLat == null) {
            _error = 'Technician location not available yet';
          }
        });
      }
    }
  }

  Future<void> _fitMapToBounds() async {
    if (_technicianLat == null || _jobSiteLat == null) return;
    try {
      await _mapController.animateCamera(
        CameraUpdateOptions(
          bounds: CameraUpdateOptions(
            bounds: LatLngBounds(
              southwest: LatLng(_technicianLat!, _technicianLng!),
              northeast: LatLng(_jobSiteLat!, _jobSiteLng!),
            ),
            padding: const EdgeInsets.all(100),
          ),
        ),
      );
    } catch (_) {}
  }

  String _getETA() {
    if (_distanceKm == null) return 'Calculating...';
    final minutes = (_distanceKm! / 30 * 60).round();
    if (minutes < 1) return 'At location';
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _technicianLat == null
              ? _buildErrorState()
              : Stack(
                  children: [
                    _buildMap(),
                    _buildTopBar(),
                    _buildBottomSheet(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              _error ?? 'Unable to track technician',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchTrackingData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return MapboxMap(
      accessToken: AppConstants.mapboxAccessToken,
      styleString: MapboxThemeService.getMapboxStyleUrl(),
      initialCameraPosition: CameraPosition(
        target: LatLng(_technicianLat ?? 0, _technicianLng ?? 0),
        zoom: 14,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _fitMapToBounds();
      },
      myLocationEnabled: false,
      annotations: _buildAnnotations(),
    );
  }

  List<Annotation> _buildAnnotations() {
    final annotations = <Annotation>[];

    if (_technicianLat != null && _technicianLng != null) {
      annotations.add(
        CircleAnnotation(
          geometry: Point(coordinates: Position(_technicianLng!, _technicianLat!)),
          circleRadius: 12,
          circleColor: const Color(0xFF10B981),
          circleStrokeColor: Colors.white,
          circleStrokeWidth: 3,
        ),
      );
    }

    if (_jobSiteLat != null && _jobSiteLng != null) {
      annotations.add(
        CircleAnnotation(
          geometry: Point(coordinates: Position(_jobSiteLng!, _jobSiteLat!)),
          circleRadius: 12,
          circleColor: const Color(0xFFEF4444),
          circleStrokeColor: Colors.white,
          circleStrokeWidth: 3,
        ),
      );
    }

    if (_technicianLat != null && _jobSiteLat != null) {
      annotations.add(
        LineAnnotation(
          geometry: LineString(coordinates: [
            Position(_technicianLng!, _technicianLat!),
            Position(_jobSiteLng!, _jobSiteLat!),
          ]),
          lineColor: const Color(0xFF6366F1),
          lineWidth: 3,
        ),
      );
    }

    return annotations;
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white.withOpacity(0)],
          ),
        ),
        child: Row(
          children: [
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _journeyStarted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ticket #${widget.ticketNumber} - ${_journeyStarted ? "En route" : _status ?? "Assigned"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _fitMapToBounds,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.center_focus_strong,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Status + ETA Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _journeyStarted
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _journeyStarted ? Icons.directions_car : Icons.assignment,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _journeyStarted ? 'Estimated Arrival' : 'Status',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          _journeyStarted ? _getETA() : (_status ?? 'ASSIGNED'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_distanceKm != null)
                    Column(
                      children: [
                        Text(
                          _distanceKm!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'km away',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Technician Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.engineering,
                      color: Color(0xFF6366F1),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _technicianName ?? 'Technician',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Assigned technician',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (_technicianPhone != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final uri = Uri.parse('tel:$_technicianPhone');
                          launchUrl(uri);
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Color(0xFF3B82F6),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Live indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live tracking • Updates every 5s',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
