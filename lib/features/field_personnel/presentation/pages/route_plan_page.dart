import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/valhalla_service.dart';

class RoutePlanPage extends StatefulWidget {
  const RoutePlanPage({super.key});

  @override
  State<RoutePlanPage> createState() => _RoutePlanPageState();
}

class _RoutePlanPageState extends State<RoutePlanPage> {
  bool _isLoading = true;
  bool _isSnapping = false;
  Map<String, dynamic>? _routePlan;
  String? _error;

  // Road-snapped route from Valhalla
  List<LatLng> _routePoints = [];
  List<double> _legKm = [];
  double _roadTotalKm = 0;
  double _roadReturnKm = 0;
  double _roadGrandTotalKm = 0;

  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadRoutePlan();
  }

  Future<void> _loadRoutePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _routePoints = [];
      _legKm = [];
      _roadTotalKm = 0;
      _roadReturnKm = 0;
      _roadGrandTotalKm = 0;
    });
    try {
      final api = sl<ApiClient>();
      final res = await api.get('/field-personnel/route-plan');
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res.data['data'] ?? {});
      setState(() {
        _routePlan = data;
        _isLoading = false;
      });
      _snapRoute(data);
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _snapRoute(Map<String, dynamic> data) async {
    final stops = List<Map<String, dynamic>>.from(data['stops'] ?? []);
    if (stops.isEmpty) return;

    final startLoc = data['startLocation'] as Map<String, dynamic>?;
    final homeLoc = data['homeLocation'] as Map<String, dynamic>?;

    final waypoints = <LatLng>[];
    if (startLoc != null && startLoc['latitude'] != null && startLoc['longitude'] != null) {
      waypoints.add(LatLng((startLoc['latitude'] as num).toDouble(), (startLoc['longitude'] as num).toDouble()));
    }
    for (final s in stops) {
      if (s['latitude'] != null && s['longitude'] != null) {
        waypoints.add(LatLng((s['latitude'] as num).toDouble(), (s['longitude'] as num).toDouble()));
      }
    }
    if (homeLoc != null && homeLoc['latitude'] != null && homeLoc['longitude'] != null) {
      waypoints.add(LatLng((homeLoc['latitude'] as num).toDouble(), (homeLoc['longitude'] as num).toDouble()));
    }
    if (waypoints.length < 2) return;

    setState(() => _isSnapping = true);
    try {
      final result = await ValhallaService.routeWaypoints(waypoints);
      if (!mounted) return;
      setState(() {
        _routePoints = result.points;
        _legKm = result.legKm;
        _roadGrandTotalKm = result.distanceKm;

        // If home was appended, last leg is the return leg.
        if (homeLoc != null && result.legKm.isNotEmpty) {
          _roadReturnKm = result.legKm.last;
          _roadTotalKm = result.distanceKm - _roadReturnKm;
        } else {
          _roadTotalKm = result.distanceKm;
          _roadReturnKm = 0;
        }
        _isSnapping = false;
      });
      if (_mapReady && _routePoints.isNotEmpty) {
        _fitMapToBounds();
      }
    } catch (e) {
      debugPrint('Route snap error: $e');
      if (mounted) setState(() => _isSnapping = false);
    }
  }

  void _fitMapToBounds() {
    if (_routePoints.isEmpty) return;
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;
    for (final p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Route Plan'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSnapping)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRoutePlan),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadRoutePlan, child: const Text('Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadRoutePlan,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final stops = List<Map<String, dynamic>>.from(_routePlan?['stops'] ?? []);
    final startLocation = _routePlan?['startLocation'] as Map<String, dynamic>?;
    final homeLocation = _routePlan?['homeLocation'] as Map<String, dynamic>?;

    if (stops.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No active stops', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Accept new jobs to see your route plan', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          ),
        ),
      );
    }

    // Use Valhalla road distances when available; fallback to backend straight-line.
    final useRoad = _legKm.isNotEmpty;
    final totalRouteKm = useRoad ? _roadTotalKm : (_routePlan?['totalRouteKm'] ?? 0).toDouble();
    final returnKm = useRoad ? _roadReturnKm : (_routePlan?['returnKm'] ?? 0).toDouble();
    final grandTotalKm = useRoad ? _roadGrandTotalKm : (_routePlan?['grandTotalKm'] ?? 0).toDouble();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map showing road-snapped route
          _buildMap(stops, startLocation, homeLocation),
          const SizedBox(height: 20),

          // Summary cards
          _buildSummaryRow(totalRouteKm, returnKm, grandTotalKm, stops.length),
          const SizedBox(height: 20),

          // Route segments timeline
          const Text('Route Segments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),

          // Start point
          if (startLocation != null) _buildTimelineNode(
            label: startLocation['label'] ?? 'Start',
            subtitle: 'Starting point (${startLocation['source']})',
            icon: Icons.trip_origin,
            color: const Color(0xFF10B981),
            isFirst: true,
          ),

          // Segments + stops (use road leg distances if available)
          ...List.generate(stops.length + (homeLocation != null ? 1 : 0), (i) {
            final isReturn = i == stops.length;
            final isLast = i == stops.length;
            final distKm = useRoad
                ? (i < _legKm.length ? _legKm[i] : 0.0)
                : (_routePlan?['segments']?[i]?['distanceKm'] ?? 0).toDouble();
            final label = isReturn
                ? (homeLocation?['address'] ?? 'Home')
                : '#${stops[i]['ticketNumber']} – ${stops[i]['customerName'] ?? 'Customer'}';
            final stop = isReturn ? null : stops[i];

            return Column(
              children: [
                _buildDistanceConnector(distKm),
                _buildTimelineNode(
                  label: label,
                  subtitle: isReturn ? 'Return to home' : 'Stop ${i + 1}',
                  icon: isReturn ? Icons.home : Icons.location_on,
                  color: isReturn ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                  isLast: isLast,
                  stop: stop,
                ),
              ],
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> stops, Map<String, dynamic>? start, Map<String, dynamic>? home) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          onMapReady: () {
            setState(() => _mapReady = true);
            if (_routePoints.isNotEmpty) _fitMapToBounds();
          },
        ),
        children: [
          TileLayer(
            urlTemplate: AppConstants.tileUrl,
            tileSize: AppConstants.tileSize,
            zoomOffset: AppConstants.tileZoomOffset,
          ),
          if (_routePoints.length >= 2)
            PolylineLayer<Object>(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5,
                  color: const Color(0xFF6366F1),
                  borderStrokeWidth: 1,
                  borderColor: const Color(0xFF4338CA),
                ),
              ],
            ),
          MarkerLayer(markers: _buildMarkers(stops, start, home)),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(List<Map<String, dynamic>> stops, Map<String, dynamic>? start, Map<String, dynamic>? home) {
    final markers = <Marker>[];
    if (start != null && start['latitude'] != null && start['longitude'] != null) {
      markers.add(Marker(
        point: LatLng((start['latitude'] as num).toDouble(), (start['longitude'] as num).toDouble()),
        width: 40,
        height: 40,
        child: const Icon(Icons.trip_origin, color: Color(0xFF10B981), size: 32),
      ));
    }
    for (int i = 0; i < stops.length; i++) {
      final s = stops[i];
      if (s['latitude'] == null || s['longitude'] == null) continue;
      final color = s['status'] == 'IN_PROGRESS' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
      markers.add(Marker(
        point: LatLng((s['latitude'] as num).toDouble(), (s['longitude'] as num).toDouble()),
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.location_on, color: color, size: 36),
            Positioned(
              top: 4,
              child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ));
    }
    if (home != null && home['latitude'] != null && home['longitude'] != null) {
      markers.add(Marker(
        point: LatLng((home['latitude'] as num).toDouble(), (home['longitude'] as num).toDouble()),
        width: 40,
        height: 40,
        child: const Icon(Icons.home, color: Color(0xFF8B5CF6), size: 32),
      ));
    }
    return markers;
  }

  Widget _buildSummaryRow(double totalKm, double returnKm, double grandKm, int stopCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Today\'s Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('$stopCount stop${stopCount > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('Route', '${totalKm.toStringAsFixed(1)} km', Icons.directions_car),
              const SizedBox(width: 12),
              _buildMiniStat('Return', '${returnKm.toStringAsFixed(1)} km', Icons.home),
              const SizedBox(width: 12),
              _buildMiniStat('Total', '${grandKm.toStringAsFixed(1)} km', Icons.straighten),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
    Map<String, dynamic>? stop,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
              child: Icon(icon, color: color, size: 18),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                if (stop != null && stop['address'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(child: Text(stop['address'], style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
                if (stop != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stop['status'] == 'IN_PROGRESS' ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stop['status'] == 'IN_PROGRESS' ? 'In Progress' : 'Assigned',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stop['status'] == 'IN_PROGRESS' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceConnector(double km) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Container(width: 2, height: 30, color: Colors.grey[300]),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: Text('${km.toStringAsFixed(1)} km', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
