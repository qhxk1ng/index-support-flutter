import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/valhalla_service.dart';
import '../../data/datasources/admin_remote_data_source.dart';

class _Trip {
  final List<LatLng> rawPoints;
  final List<DateTime> timestamps;
  final List<double?> headings;
  List<LatLng> snappedPoints;
  final Color color;
  final int index;
  bool visible;
  bool snapping;

  _Trip({
    required this.rawPoints,
    required this.timestamps,
    required this.headings,
    required this.color,
    required this.index,
    this.visible = true,
    this.snapping = false,
  }) : snappedPoints = [];

  String get timeRange {
    if (timestamps.isEmpty) return '--';
    final start = DateFormat('hh:mm a').format(timestamps.first);
    final end = DateFormat('hh:mm a').format(timestamps.last);
    return '$start - $end';
  }

  int get durationMinutes {
    if (timestamps.length < 2) return 0;
    return timestamps.last.difference(timestamps.first).inMinutes;
  }
}

class _Stop {
  LatLng position;
  int totalMinutes;
  DateTime startTime;
  DateTime endTime;
  int visitCount;

  _Stop({
    required this.position,
    required this.totalMinutes,
    required this.startTime,
    required this.endTime,
    this.visitCount = 1,
  });

  String get label {
    final dur = totalMinutes < 60
        ? '${totalMinutes}m'
        : '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
    final time = DateFormat('hh:mm a').format(startTime);
    if (visitCount > 1) return '$dur ($visitCount visits, from $time)';
    return '$dur (from $time)';
  }
}

class StaffRouteViewPage extends StatefulWidget {
  final String staffId;
  final String staffName;

  const StaffRouteViewPage({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<StaffRouteViewPage> createState() => _StaffRouteViewPageState();
}

class _StaffRouteViewPageState extends State<StaffRouteViewPage> {
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _mapReady = false;
  String? _error;

  List<_Trip> _trips = [];
  List<_Stop> _stops = [];
  double _totalKm = 0;
  int _totalPoints = 0;
  int _durationMinutes = 0;
  String? _startTime;
  String? _endTime;

  DateTime _selectedDate = DateTime.now();
  Timer? _refreshTimer;

  static const _indigo = Color(0xFF6366F1);
  static const _green = Color(0xFF059669);

  static const _tripColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
  ];

  static const _sessionGapMs = 15 * 60 * 1000;

  @override
  void initState() {
    super.initState();
    _loadRoute();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadRoute());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<_Trip> _segmentTrips(List<Map<String, dynamic>> route) {
    if (route.isEmpty) return [];

    final trips = <_Trip>[];
    var currentPoints = <LatLng>[];
    var currentTimestamps = <DateTime>[];

    var currentHeadings = <double?>[];

    for (int i = 0; i < route.length; i++) {
      final p = route[i];
      final lat = (p['latitude'] as num).toDouble();
      final lng = (p['longitude'] as num).toDouble();
      final ts = DateTime.parse(p['timestamp'].toString()).toLocal();
      final heading = (p['heading'] as num?)?.toDouble();

      if (i > 0 && currentTimestamps.isNotEmpty) {
        final gap = ts.difference(currentTimestamps.last).inMilliseconds;
        if (gap > _sessionGapMs) {
          if (currentPoints.length >= 2) {
            trips.add(_Trip(
              rawPoints: List.from(currentPoints),
              timestamps: List.from(currentTimestamps),
              headings: List.from(currentHeadings),
              color: _tripColors[trips.length % _tripColors.length],
              index: trips.length,
            ));
          }
          currentPoints = [];
          currentTimestamps = [];
          currentHeadings = [];
        }
      }

      currentPoints.add(LatLng(lat, lng));
      currentTimestamps.add(ts);
      currentHeadings.add(heading);
    }

    if (currentPoints.length >= 2) {
      trips.add(_Trip(
        rawPoints: List.from(currentPoints),
        timestamps: List.from(currentTimestamps),
        headings: List.from(currentHeadings),
        color: _tripColors[trips.length % _tripColors.length],
        index: trips.length,
      ));
    }

    return trips;
  }

  Future<void> _loadRoute() async {
    try {
      final ds = sl<AdminRemoteDataSource>();
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endDate = startDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final data = await ds.getStaffRoute(
        widget.staffId,
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
      );

      if (!mounted) return;

      final route = data['route'] as List? ?? [];
      final routeMaps = route.map((p) => p as Map<String, dynamic>).toList();
      final trips = _segmentTrips(routeMaps);

      // Detect stationary stops across all GPS data
      final allPts = <LatLng>[];
      final allTs = <DateTime>[];
      for (final t in trips) {
        allPts.addAll(t.rawPoints);
        allTs.addAll(t.timestamps);
      }
      final stops = _detectAndMergeStops(allPts, allTs);

      setState(() {
        _trips = trips;
        _stops = stops;
        _totalKm = (data['totalKm'] as num?)?.toDouble() ?? 0;
        _totalPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
        _durationMinutes = (data['durationMinutes'] as num?)?.toInt() ?? 0;
        _startTime = data['startTime']?.toString();
        _endTime = data['endTime']?.toString();
        _isLoading = false;
        _error = null;
      });

      for (final trip in trips) {
        _snapTripToRoads(trip);
      }

      if (_mapReady && _allPoints.isNotEmpty) {
        _fitBounds(_allPoints);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<LatLng> get _allPoints {
    final pts = <LatLng>[];
    for (final t in _trips) {
      pts.addAll(t.rawPoints);
    }
    return pts;
  }

  // ── Stationary Stop Detection ────────────────────────────────────
  // Detects when technician stays within 50m for 5+ minutes, then merges
  // nearby stops (within 100m) into a single combined stop.
  List<_Stop> _detectAndMergeStops(List<LatLng> pts, List<DateTime> timestamps) {
    if (pts.length < 2) return [];
    const dist = Distance();
    const stayRadiusM = 50.0;
    const minStayMinutes = 5;
    const mergeRadiusM = 100.0;

    final rawStops = <_Stop>[];
    int i = 0;
    while (i < pts.length) {
      final anchor = pts[i];
      final anchorTs = timestamps[i];
      int j = i + 1;
      // Expand window while points stay within radius
      while (j < pts.length &&
          dist.as(LengthUnit.Meter, anchor, pts[j]) <= stayRadiusM) {
        j++;
      }
      final lastIdx = j - 1;
      final minutes = timestamps[lastIdx].difference(anchorTs).inMinutes;
      if (minutes >= minStayMinutes) {
        // Compute centroid of the cluster
        double latSum = 0, lngSum = 0;
        for (int k = i; k <= lastIdx; k++) {
          latSum += pts[k].latitude;
          lngSum += pts[k].longitude;
        }
        final count = lastIdx - i + 1;
        rawStops.add(_Stop(
          position: LatLng(latSum / count, lngSum / count),
          totalMinutes: minutes,
          startTime: anchorTs,
          endTime: timestamps[lastIdx],
        ));
        i = j; // skip past this cluster
      } else {
        i++;
      }
    }

    // Merge nearby stops (within 100m)
    if (rawStops.isEmpty) return [];
    final merged = <_Stop>[rawStops.first];
    for (int s = 1; s < rawStops.length; s++) {
      final last = merged.last;
      final cur = rawStops[s];
      if (dist.as(LengthUnit.Meter, last.position, cur.position) <= mergeRadiusM) {
        // Merge into existing stop
        last.totalMinutes += cur.totalMinutes;
        last.visitCount += 1;
        if (cur.endTime.isAfter(last.endTime)) last.endTime = cur.endTime;
      } else {
        merged.add(cur);
      }
    }
    return merged;
  }

  // ── Valhalla trace_route (Map Matching) ─────────────────────────
  // Uses self-hosted Valhalla to snap GPS traces to actual roads traveled.
  Future<void> _snapTripToRoads(_Trip trip) async {
    if (trip.rawPoints.length < 2) return;
    setState(() => trip.snapping = true);

    try {
      final snapped = await ValhallaService.traceRoute(
        trip.rawPoints,
        timestamps: trip.timestamps,
        headings: trip.headings,
      );

      if (mounted && snapped.length >= 2) {
        setState(() {
          trip.snappedPoints = snapped;
          trip.snapping = false;
        });
      } else {
        if (mounted) setState(() => trip.snapping = false);
      }
    } catch (e) {
      debugPrint('Snap error for trip ${trip.index}: $e');
      if (mounted) setState(() => trip.snapping = false);
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    try {
      if (points.length == 1) {
        _mapController.move(points.first, 14);
        return;
      }
      final bounds = LatLngBounds.fromPoints(points);
      // If all points are at the same spot, bounds have zero area → fitCamera
      // calculates Infinity zoom. Fall back to a fixed zoom in that case.
      final latSpan = (bounds.north - bounds.south).abs();
      final lngSpan = (bounds.east - bounds.west).abs();
      if (latSpan < 0.0001 && lngSpan < 0.0001) {
        _mapController.move(points.first, 16);
        return;
      }
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _indigo),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
        _trips = [];
      });
      _loadRoute();
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateLabel = isToday ? 'Today' : DateFormat('dd MMM yyyy').format(_selectedDate);
    final anySnapping = _trips.any((t) => t.snapping);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.staffName}\'s Route'),
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
            label: Text(dateLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadRoute();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _indigo))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Failed to load route', style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadRoute();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No route data for $dateLabel',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _pickDate,
                            child: const Text('Pick another date'),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _trips.first.rawPoints.first,
                            initialZoom: 14,
                            onMapReady: () {
                              _mapReady = true;
                              if (_allPoints.length >= 2) _fitBounds(_allPoints);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: AppConstants.tileUrl,
                              userAgentPackageName: 'com.indexcare.app',
                              tileSize: AppConstants.tileSize,
                              zoomOffset: AppConstants.tileZoomOffset,
                            ),
                            PolylineLayer<Object>(
                              polylines: _buildPolylines(),
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                          ],
                        ),

                        // Snapping indicator
                        if (anySnapping)
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _indigo)),
                                    SizedBox(width: 8),
                                    Text('Snapping to roads...', style: TextStyle(fontSize: 12, color: _indigo, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Trip filter chips
                        if (_trips.length > 1)
                          Positioned(
                            top: anySnapping ? 48 : 12,
                            left: 12,
                            right: 60,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _tripChip(-1, 'All Trips', _indigo),
                                  ..._trips.map((t) => Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: _tripChip(
                                          t.index,
                                          'Trip ${t.index + 1}',
                                          t.color,
                                          subtitle: t.timeRange,
                                          visible: t.visible,
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),

                        // Stats overlay at bottom
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 20,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin_circle, color: _indigo, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.staffName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _indigo.withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dateLabel,
                                        style: const TextStyle(fontSize: 12, color: _indigo, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildStat(Icons.straighten, '${_totalKm.toStringAsFixed(1)} km', 'Distance'),
                                    _buildDivider(),
                                    _buildStat(Icons.timer_outlined, _formatDuration(_durationMinutes), 'Duration'),
                                    _buildDivider(),
                                    _buildStat(Icons.login, _formatTime(_startTime), 'Start'),
                                    _buildDivider(),
                                    _buildStat(Icons.logout, _formatTime(_endTime), 'End'),
                                  ],
                                ),
                                if (_totalPoints > 0 || _trips.length > 1) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_totalPoints GPS points recorded${_trips.length > 1 ? '  •  ${_trips.length} trips' : ''}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Re-center button
                        Positioned(
                          right: 16,
                          top: 16,
                          child: FloatingActionButton.small(
                            heroTag: 'fit',
                            backgroundColor: Colors.white,
                            onPressed: () {
                              final visible = _trips.where((t) => t.visible).expand((t) => t.rawPoints).toList();
                              if (visible.isNotEmpty) _fitBounds(visible);
                            },
                            child: const Icon(Icons.fit_screen, color: _indigo),
                          ),
                        ),
                      ],
                    ),
    );
  }

  List<Polyline<Object>> _buildPolylines() {
    final polylines = <Polyline<Object>>[];
    for (final trip in _trips) {
      if (!trip.visible) continue;
      final points = trip.snappedPoints.length >= 2 ? trip.snappedPoints : trip.rawPoints;
      final isSnapped = trip.snappedPoints.length >= 2;
      polylines.add(Polyline(
        points: points,
        strokeWidth: isSnapped ? 5 : 4,
        color: trip.color,
        borderStrokeWidth: isSnapped ? 2 : 0,
        borderColor: isSnapped ? Colors.white : Colors.transparent,
        pattern: isSnapped ? const StrokePattern.solid() : const StrokePattern.dotted(),
      ));
    }
    return polylines;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final trip in _trips) {
      if (!trip.visible || trip.rawPoints.isEmpty) continue;
      markers.add(Marker(
        point: trip.rawPoints.first,
        width: 36,
        height: 36,
        child: Icon(Icons.flag_circle, color: trip.color, size: 28),
      ));
      if (trip.rawPoints.length >= 2) {
        markers.add(Marker(
          point: trip.rawPoints.last,
          width: 36,
          height: 36,
          child: Icon(Icons.location_on, color: trip.color.withAlpha(200), size: 28),
        ));
      }
    }
    // Stationary stop markers
    for (final stop in _stops) {
      markers.add(Marker(
        point: stop.position,
        width: 120,
        height: 52,
        child: GestureDetector(
          onTap: () => _showStopInfo(stop),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4)],
                ),
                child: Text(
                  stop.label,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.flag, color: Color(0xFFEF4444), size: 22),
            ],
          ),
        ),
      ));
    }
    return markers;
  }

  void _showStopInfo(_Stop stop) {
    final timeRange =
        '${DateFormat('hh:mm a').format(stop.startTime)} - ${DateFormat('hh:mm a').format(stop.endTime)}';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag, color: Color(0xFFEF4444), size: 36),
            const SizedBox(height: 8),
            Text(
              'Stationary Stop',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            _stopInfoRow(Icons.timer, 'Duration', _formatDuration(stop.totalMinutes)),
            _stopInfoRow(Icons.schedule, 'Time', timeRange),
            if (stop.visitCount > 1)
              _stopInfoRow(Icons.repeat, 'Visits', '${stop.visitCount} times at this spot'),
            _stopInfoRow(
              Icons.location_on,
              'Location',
              '${stop.position.latitude.toStringAsFixed(5)}, ${stop.position.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _stopInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _indigo),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _tripChip(int index, String label, Color color, {String? subtitle, bool visible = true}) {
    final isAll = index == -1;
    final allVisible = _trips.every((t) => t.visible);
    final isSelected = isAll ? allVisible : visible;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isAll) {
            final newVal = !allVisible;
            for (final t in _trips) {
              t.visible = newVal;
            }
          } else {
            _trips[index].visible = !_trips[index].visible;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6)],
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: _indigo),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: Colors.grey[200]);
  }
}
