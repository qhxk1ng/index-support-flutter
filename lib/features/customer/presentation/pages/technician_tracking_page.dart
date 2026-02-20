import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class TechnicianTrackingPage extends StatefulWidget {
  final String complaintId;
  final String ticketNumber;

  const TechnicianTrackingPage({
    super.key,
    required this.complaintId,
    required this.ticketNumber,
  });

  @override
  State<TechnicianTrackingPage> createState() => _TechnicianTrackingPageState();
}

class _TechnicianTrackingPageState extends State<TechnicianTrackingPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _locationTimer;
  
  LatLng? _technicianLocation;
  LatLng? _customerLocation;
  String? _technicianName;
  String? _technicianPhone;
  double? _distanceKm;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTechnicianLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchTechnicianLocation());
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTechnicianLocation() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/complaints/${widget.complaintId}/track');
      final data = response.data['data'];

      if (mounted) {
        setState(() {
          _technicianLocation = LatLng(
            (data['latitude'] as num).toDouble(),
            (data['longitude'] as num).toDouble(),
          );
          _customerLocation = LatLng(
            (data['complaintLatitude'] as num).toDouble(),
            (data['complaintLongitude'] as num).toDouble(),
          );
          _technicianName = data['technicianName'] as String?;
          _technicianPhone = data['technicianPhone'] as String?;
          _distanceKm = (data['distanceKm'] as num?)?.toDouble();
          _isLoading = false;
          _error = null;
        });

        _fitMapToBounds();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_technicianLocation == null) {
            _error = 'Technician location not available yet';
          }
        });
      }
    }
  }

  void _fitMapToBounds() {
    if (_technicianLocation == null || _customerLocation == null) return;
    try {
      final bounds = LatLngBounds(_technicianLocation!, _customerLocation!);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
      );
    } catch (_) {}
  }

  String _getETA() {
    if (_distanceKm == null) return 'Calculating...';
    // Rough estimate: 30 km/h average speed in city
    final minutes = (_distanceKm! / 30 * 60).round();
    if (minutes < 1) return 'Arriving now';
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _technicianLocation == null
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
                _fetchTechnicianLocation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
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
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _technicianLocation ?? const LatLng(0, 0),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.indexcare.app',
        ),
        if (_technicianLocation != null && _customerLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [_technicianLocation!, _customerLocation!],
                color: const Color(0xFF3B82F6),
                strokeWidth: 3,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_technicianLocation != null)
              Marker(
                point: _technicianLocation!,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.engineering, color: Colors.white, size: 24),
                ),
              ),
            if (_customerLocation != null)
              Marker(
                point: _customerLocation!,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.home, color: Colors.white, size: 24),
                ),
              ),
          ],
        ),
      ],
    );
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
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ticket #${widget.ticketNumber} - Technician en route',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.center_focus_strong, size: 20, color: Color(0xFF3B82F6)),
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
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            // ETA Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
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
                    child: const Icon(Icons.access_time, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Arrival', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        Text(
                          _getETA(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (_distanceKm != null)
                    Column(
                      children: [
                        Text(
                          '${_distanceKm!.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Text('km away', style: TextStyle(fontSize: 11, color: Colors.white70)),
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
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.engineering, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _technicianName ?? 'Technician',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        Text(
                          'Your assigned technician',
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
                          child: const Icon(Icons.phone, color: Color(0xFF3B82F6), size: 22),
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
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
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
