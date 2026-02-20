import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
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
  String? _error;

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
      if (mounted) {
        setState(() {
          _trackingData = data;
          _isLoading = false;
          _error = null;
        });
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _mapController.move(LatLng(lat, lng), 15);
        }
      }
    } catch (e) {
      debugPrint('Error loading tracking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
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
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.engineering, color: Colors.white, size: 24),
        ),
      ));
    }

    final siteLat = (_trackingData!['complaintLatitude'] as num?)?.toDouble();
    final siteLng = (_trackingData!['complaintLongitude'] as num?)?.toDouble();
    if (siteLat != null && siteLng != null) {
      markers.add(Marker(
        point: LatLng(siteLat, siteLng),
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final techName = _trackingData?['technicianName'] as String? ?? 'Technician';
    final techPhone = _trackingData?['technicianPhone'] as String? ?? '';
    final distanceKm = (_trackingData?['distanceKm'] as num?)?.toDouble();
    final address = _trackingData?['complaintAddress'] as String? ?? '';
    final techLat = (_trackingData?['latitude'] as num?)?.toDouble();
    final techLng = (_trackingData?['longitude'] as num?)?.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking #${widget.ticketNumber}'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTracking,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Technician location unavailable'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadTracking,
                        child: const Text('Retry'),
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
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${AppConstants.mapboxPublicToken}',
                          userAgentPackageName: 'com.indexcare.app',
                          tileSize: 512,
                          zoomOffset: -1,
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF6366F1),
                                    child: Text(
                                      techName.isNotEmpty ? techName[0].toUpperCase() : 'T',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                                      ],
                                    ),
                                  ),
                                  if (distanceKm != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${distanceKm.toStringAsFixed(1)} km away',
                                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(address, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.circle, size: 10, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Live • Updates every 15s',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          _LegendDot(color: const Color(0xFF6366F1), label: 'Technician'),
                          const SizedBox(width: 8),
                          _LegendDot(color: const Color(0xFFEF4444), label: 'Job Site'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
