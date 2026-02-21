import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/admin_remote_data_source.dart';

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
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  Map<String, dynamic>? _trackingData;
  bool _isLoading = true;
  bool _waitingForLocation = false;
  String _lastError = '';
  bool _mapReady = false;
  bool _useMapbox = false;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadTracking();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadTracking());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadTracking() async {
    try {
      final adminRemoteDataSource = sl<AdminRemoteDataSource>();
      final data = await adminRemoteDataSource.getComplaintTracking(widget.complaintId);
      if (!mounted) return;
      setState(() {
        _trackingData = data;
        _isLoading = false;
        _waitingForLocation = false;
        _lastError = '';
      });
      final techLat = (data['latitude'] as num?)?.toDouble();
      final techLng = (data['longitude'] as num?)?.toDouble();
      final siteLat = (data['complaintLatitude'] as num?)?.toDouble();
      final siteLng = (data['complaintLongitude'] as num?)?.toDouble();
      if (techLat != null && techLng != null) {
        if (_mapReady) {
          _mapController.move(LatLng(techLat, techLng), 15);
        }
        if (siteLat != null && siteLng != null) {
          _fetchRoute(techLat, techLng, siteLat, siteLng);
        }
      }
    } catch (e) {
      debugPrint('Tracking fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _waitingForLocation = true;
          _lastError = e.toString();
        });
      }
    }
  }

  Future<void> _fetchRoute(double fromLat, double fromLng, double toLat, double toLng) async {
    try {
      final dio = Dio();
      final url =
          'https://router.project-osrm.org/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat'
          '?overview=full&geometries=geojson';
      final response = await dio.get(url);
      final routes = response.data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final coords = routes[0]['geometry']['coordinates'] as List;
      final points = coords.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
      if (mounted) {
        setState(() => _routePoints = points);
      }
    } catch (e) {
      debugPrint('Route fetch error: $e');
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
      return 'Updated ${DateFormat('h:mm a').format(dt)}';
    } catch (_) {
      return '';
    }
  }

  List<Marker> _buildMarkers() {
    if (_trackingData == null) return [];
    final markers = <Marker>[];

    final techLat = (_trackingData!['latitude'] as num?)?.toDouble();
    final techLng = (_trackingData!['longitude'] as num?)?.toDouble();
    if (techLat != null && techLng != null) {
      markers.add(Marker(
        point: LatLng(techLat, techLng),
        width: 56,
        height: 56,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.engineering, color: Colors.white, size: 26),
        ),
      ));
    }

    final siteLat = (_trackingData!['complaintLatitude'] as num?)?.toDouble();
    final siteLng = (_trackingData!['complaintLongitude'] as num?)?.toDouble();
    if (siteLat != null && siteLng != null) {
      markers.add(Marker(
        point: LatLng(siteLat, siteLng),
        width: 56,
        height: 56,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.home_repair_service, color: Colors.white, size: 20),
            ),
            Container(width: 2, height: 10, color: const Color(0xFFEF4444)),
          ],
        ),
      ));
    }

    return markers;
  }

  String _getTileUrl() {
    if (_useMapbox) {
      final token = AppConstants.mapboxPublicToken;
      if (token.isNotEmpty) {
        return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$token';
      }
    }
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  @override
  Widget build(BuildContext context) {
    final techName = _trackingData?['technicianName'] as String? ?? 'Technician';
    final techPhone = _trackingData?['technicianPhone'] as String? ?? '';
    final distanceKm = (_trackingData?['distanceKm'] as num?)?.toDouble();
    final address = _trackingData?['complaintAddress'] as String? ?? '';
    final techLat = (_trackingData?['latitude'] as num?)?.toDouble();
    final techLng = (_trackingData?['longitude'] as num?)?.toDouble();
    final timestamp = _trackingData?['timestamp'];
    final updatedText = _formatTimestamp(timestamp);

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Track #${widget.ticketNumber}'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          // Beta: Mapbox toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: () => setState(() => _useMapbox = !_useMapbox),
              icon: Icon(
                _useMapbox ? Icons.map : Icons.layers,
                color: Colors.white70,
                size: 18,
              ),
              label: Text(
                _useMapbox ? 'OSM' : 'Mapbox',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTracking,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _waitingForLocation
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      const Icon(Icons.location_searching, size: 64, color: Color(0xFF6366F1)),
                      const SizedBox(height: 16),
                      const Text(
                        'Waiting for technician location...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Auto-refreshing every 15 seconds',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      if (_lastError.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            _lastError,
                            style: TextStyle(fontSize: 11, color: Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _loadTracking,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Now'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: techLat != null && techLng != null
                            ? LatLng(techLat, techLng)
                            : const LatLng(0, 0),
                        initialZoom: 15,
                        onMapReady: () => setState(() => _mapReady = true),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _getTileUrl(),
                          userAgentPackageName: 'com.indexcare.app',
                          tileSize: _useMapbox ? 512 : 256,
                          zoomOffset: _useMapbox ? -1 : 0,
                        ),
                        if (_routePoints.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 5,
                                color: const Color(0xFF6366F1),
                                borderStrokeWidth: 2,
                                borderColor: Colors.white,
                              ),
                            ],
                          ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    // Bottom info card
                    Positioned(
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
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Drag handle
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF6366F1),
                                    child: Text(
                                      techName.isNotEmpty ? techName[0].toUpperCase() : 'T',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(techName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (techPhone.isNotEmpty)
                                          Text(techPhone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                        if (updatedText.isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                                              const SizedBox(width: 4),
                                              Text(
                                                updatedText,
                                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (distanceKm != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '${distanceKm.toStringAsFixed(1)}',
                                            style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                          const Text('km away', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          address,
                                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top legend
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          _LegendChip(color: const Color(0xFF6366F1), label: 'Technician'),
                          const SizedBox(width: 8),
                          _LegendChip(color: const Color(0xFFEF4444), label: 'Job Site'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
