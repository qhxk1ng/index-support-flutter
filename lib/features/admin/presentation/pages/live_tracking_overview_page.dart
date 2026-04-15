import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'staff_route_view_page.dart';

class LiveTrackingOverviewPage extends StatefulWidget {
  const LiveTrackingOverviewPage({super.key});

  @override
  State<LiveTrackingOverviewPage> createState() => _LiveTrackingOverviewPageState();
}

class _LiveTrackingOverviewPageState extends State<LiveTrackingOverviewPage> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _mapReady = false;
  String? _error;
  List<Map<String, dynamic>> _staff = [];
  Map<String, dynamic>? _selectedStaff;
  String _filterRole = 'ALL';


  static const _colorByRole = {
    'FIELD_PERSONNEL': Color(0xFF10B981),
    'TECHNICIAN': Color(0xFF3B82F6),
    'SALES': Color(0xFFF59E0B),
  };
  static const _labelByRole = {
    'FIELD_PERSONNEL': 'Field',
    'TECHNICIAN': 'Installer',
    'SALES': 'Sales',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ds = sl<AdminRemoteDataSource>();
      final data = await ds.getLiveTracking();
      if (!mounted) return;
      setState(() {
        _staff = data;
        _isLoading = false;
        _error = null;
      });
      if (_mapReady) _fitAll();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterRole == 'ALL') return _staff;
    return _staff.where((s) => s['role'] == _filterRole).toList();
  }

  void _fitAll() {
    final points = _filtered
        .where((s) => s['latitude'] != null && s['longitude'] != null)
        .map((s) => LatLng(
              (s['latitude'] as num).toDouble(),
              (s['longitude'] as num).toDouble(),
            ))
        .toList();
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (_) {}
  }

  Color _roleColor(String role) => _colorByRole[role] ?? Colors.grey;
  String _roleLabel(String role) => _labelByRole[role] ?? role;

  @override
  Widget build(BuildContext context) {
    final activeCount = _staff.where((s) => s['isActive'] == true).length;
    final onlineCount = _staff.where((s) => s['isOnline'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking Overview'),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Text(
                  '$onlineCount online',
                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _load();
                        },
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
                        initialCenter: const LatLng(13.0827, 80.2707),
                        initialZoom: 11,
                        onMapReady: () {
                          setState(() => _mapReady = true);
                          _fitAll();
                        },
                        onTap: (_, __) => setState(() => _selectedStaff = null),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: AppConstants.tileUrl,
                          userAgentPackageName: 'com.indexcare.app',
                          tileSize: AppConstants.tileSize,
                          zoomOffset: AppConstants.tileZoomOffset,
                        ),
                        MarkerLayer(
                          markers: _filtered.where((s) => s['latitude'] != null && s['longitude'] != null).map((s) {
                            final lat = (s['latitude'] as num).toDouble();
                            final lng = (s['longitude'] as num).toDouble();
                            final isActive = s['isActive'] == true;
                            final isOnline = s['isOnline'] == true;
                            final color = _roleColor(s['role'] as String);
                            final isSelected = _selectedStaff?['id'] == s['id'];

                            return Marker(
                              point: LatLng(lat, lng),
                              width: isSelected ? 90 : 72,
                              height: isSelected ? 72 : 56,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedStaff = s);
                                  _mapController.move(LatLng(lat, lng), 14);
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? color : color.withAlpha(230),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withAlpha(100),
                                            blurRadius: isSelected ? 12 : 6,
                                            spreadRadius: isSelected ? 2 : 0,
                                          ),
                                        ],
                                        border: isSelected
                                            ? Border.all(color: Colors.white, width: 2)
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isOnline
                                                  ? Colors.greenAccent
                                                  : (isActive ? Colors.yellow : Colors.white38),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (s['name'] as String).split(' ').first,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isSelected ? 12 : 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CustomPaint(
                                      size: const Size(12, 8),
                                      painter: _TrianglePainter(color: isSelected ? color : color.withAlpha(230)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Role filter chips
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('ALL', 'All (${_staff.length})', const Color(0xFF1F2937)),
                            const SizedBox(width: 8),
                            _filterChip('FIELD_PERSONNEL', 'Field (${_staff.where((s) => s['role'] == 'FIELD_PERSONNEL').length})', const Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            _filterChip('TECHNICIAN', 'Installers (${_staff.where((s) => s['role'] == 'TECHNICIAN').length})', const Color(0xFF3B82F6)),
                            const SizedBox(width: 8),
                            _filterChip('SALES', 'Sales (${_staff.where((s) => s['role'] == 'SALES').length})', const Color(0xFFF59E0B)),
                          ],
                        ),
                      ),
                    ),

                    // Fit all FAB
                    Positioned(
                      right: 12,
                      bottom: _selectedStaff != null ? 220 : 100,
                      child: FloatingActionButton.small(
                        heroTag: 'fit',
                        backgroundColor: Colors.white,
                        onPressed: _fitAll,
                        child: const Icon(Icons.fit_screen, color: Color(0xFF1F2937)),
                      ),
                    ),

                    // Selected staff card
                    if (_selectedStaff != null) _buildSelectedCard(),

                    // Bottom summary bar
                    if (_selectedStaff == null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildSummaryBar(activeCount),
                      ),
                  ],
                ),
    );
  }

  Widget _filterChip(String role, String label, Color color) {
    final selected = _filterRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterRole = role;
          _selectedStaff = null;
        });
        Future.delayed(const Duration(milliseconds: 100), _fitAll);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCard() {
    final s = _selectedStaff!;
    final color = _roleColor(s['role'] as String);
    final isOnline = s['isOnline'] == true;
    final lastSeen = s['lastSeen']?.toString();
    String lastSeenText = '--';
    if (lastSeen != null) {
      try {
        final dt = DateTime.parse(lastSeen).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          lastSeenText = 'Just now';
        } else if (diff.inMinutes < 60) {
          lastSeenText = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          lastSeenText = '${diff.inHours}h ago';
        } else {
          lastSeenText = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withAlpha(180)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (s['name'] as String)[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _roleLabel(s['role'] as String),
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(fontSize: 11, color: isOnline ? Colors.green : Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() => _selectedStaff = null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Last seen: $lastSeenText', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(s['phone'] as String? ?? '--', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffRouteViewPage(
                        staffId: s['id'] as String,
                        staffName: s['name'] as String,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.route_rounded, size: 18),
                label: const Text('View Today\'s Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(int activeCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('${_staff.length}', 'Total Staff', Colors.white),
          _summaryItem('$activeCount', 'Active', Colors.greenAccent),
          _summaryItem(
            '${_staff.where((s) => s['role'] == 'FIELD_PERSONNEL').length}',
            'Field',
            const Color(0xFF10B981),
          ),
          _summaryItem(
            '${_staff.where((s) => s['role'] == 'TECHNICIAN').length}',
            'Installers',
            const Color(0xFF3B82F6),
          ),
          _summaryItem(
            '${_staff.where((s) => s['role'] == 'SALES').length}',
            'Sales',
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
