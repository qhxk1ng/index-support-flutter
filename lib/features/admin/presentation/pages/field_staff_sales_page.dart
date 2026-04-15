import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'staff_route_view_page.dart';

class FieldStaffSalesPage extends StatefulWidget {
  const FieldStaffSalesPage({super.key});

  @override
  State<FieldStaffSalesPage> createState() => _FieldStaffSalesPageState();
}

class _FieldStaffSalesPageState extends State<FieldStaffSalesPage>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _mapReady = false;
  String? _error;
  List<Map<String, dynamic>> _staff = [];
  Map<String, dynamic>? _selectedStaff;
  String _filterRole = 'ALL';
  bool _showMap = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _colorByRole = {
    'FIELD_PERSONNEL': Color(0xFF10B981),
    'SALES': Color(0xFFF59E0B),
  };

  static const _labelByRole = {
    'FIELD_PERSONNEL': 'Field Staff',
    'SALES': 'Sales',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ds = sl<AdminRemoteDataSource>();
      final all = await ds.getLiveTracking();
      if (!mounted) return;
      final filtered = all
          .where((s) => s['role'] == 'FIELD_PERSONNEL' || s['role'] == 'SALES')
          .toList();
      setState(() {
        _staff = filtered;
        _isLoading = false;
        _error = null;
      });
      _animController
        ..reset()
        ..forward();
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

  String _formatLastSeen(dynamic ts) {
    if (ts == null) return 'Never';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d, HH:mm').format(dt);
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _staff.where((s) => s['isOnline'] == true).length;
    final activeCount = _staff.where((s) => s['isActive'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Field Staff & Sales',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _showMap ? 'Show List' : 'Show Map',
            icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
              ),
            )
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildHeader(onlineCount, activeCount),
                    _buildFilterRow(),
                    Expanded(
                      child: _showMap ? _buildMap() : _buildList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _load();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int onlineCount, int activeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0EA5E9).withAlpha(20),
            const Color(0xFF0284C7).withAlpha(10),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          _buildStatChip(
            '${_staff.length}',
            'Total',
            const Color(0xFF0EA5E9),
            Icons.group_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            '$onlineCount',
            'Online',
            const Color(0xFF10B981),
            Icons.circle,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            '$activeCount',
            'Active',
            const Color(0xFFF59E0B),
            Icons.directions_run_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final roles = ['ALL', 'FIELD_PERSONNEL', 'SALES'];
    final labels = {'ALL': 'All', 'FIELD_PERSONNEL': 'Field Staff', 'SALES': 'Sales'};
    final colors = {
      'ALL': const Color(0xFF0EA5E9),
      'FIELD_PERSONNEL': const Color(0xFF10B981),
      'SALES': const Color(0xFFF59E0B),
    };

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: roles.map((role) {
          final selected = _filterRole == role;
          final color = colors[role]!;
          return GestureDetector(
            onTap: () {
              setState(() => _filterRole = role);
              if (_showMap && _mapReady) _fitAll();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? color : color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : color.withAlpha(60),
                ),
              ),
              child: Text(
                labels[role] ?? role,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No staff found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: const Color(0xFF0EA5E9),
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + index * 80),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: _buildStaffCard(_filtered[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> s) {
    final isOnline = s['isOnline'] == true;
    final isActive = s['isActive'] == true;
    final role = s['role'] as String;
    final color = _roleColor(role);
    final name = s['name'] as String? ?? 'Unknown';
    final phone = s['phone'] as String? ?? '';
    final hasLocation = s['latitude'] != null && s['longitude'] != null;

    final statusColor = isOnline
        ? const Color(0xFF10B981)
        : isActive
            ? const Color(0xFFF59E0B)
            : const Color(0xFF9CA3AF);
    final statusLabel = isOnline ? 'Online' : isActive ? 'Active' : 'Offline';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: hasLocation
              ? () {
                  setState(() {
                    _showMap = true;
                    _selectedStaff = s;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_mapReady) {
                      _mapController.move(
                        LatLng(
                          (s['latitude'] as num).toDouble(),
                          (s['longitude'] as num).toDouble(),
                        ),
                        15,
                      );
                    }
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
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
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withAlpha(80)),
                          ),
                          child: Text(
                            _roleLabel(role),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Last seen: ${_formatLastSeen(s['lastSeen'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (hasLocation)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffRouteViewPage(
                                staffId: s['id'] as String,
                                staffName: name,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.route_rounded,
                                    size: 13, color: Color(0xFF6366F1)),
                                SizedBox(width: 4),
                                Text(
                                  'Route',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          'No location yet',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[400]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final withLocation =
        _filtered.where((s) => s['latitude'] != null && s['longitude'] != null).toList();

    if (withLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No location data available yet',
              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Stack(
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
              markers: withLocation.map((s) {
                final lat = (s['latitude'] as num).toDouble();
                final lng = (s['longitude'] as num).toDouble();
                final isOnline = s['isOnline'] == true;
                final role = s['role'] as String;
                final color = _roleColor(role);
                final name = s['name'] as String? ?? '?';
                final isSelected = _selectedStaff?['id'] == s['id'];

                return Marker(
                  point: LatLng(lat, lng),
                  width: isSelected ? 90 : 72,
                  height: isSelected ? 68 : 52,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedStaff = s);
                      _mapController.move(LatLng(lat, lng), 15);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : color.withAlpha(230),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(100),
                                blurRadius: isSelected ? 12 : 6,
                              ),
                            ],
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white, width: 2)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? Colors.greenAccent
                                      : Colors.white38,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                name.split(' ').first,
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
                          size: const Size(10, 6),
                          painter: _TrianglePainter(
                              isSelected ? color : color.withAlpha(230)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (_selectedStaff != null) _buildInfoPanel(_selectedStaff!),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _fitAll,
            backgroundColor: Colors.white,
            child: const Icon(Icons.fit_screen_rounded,
                color: Color(0xFF0EA5E9)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(Map<String, dynamic> s) {
    final role = s['role'] as String;
    final color = _roleColor(role);
    final name = s['name'] as String? ?? 'Unknown';
    final hasLocation = s['latitude'] != null && s['longitude'] != null;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 64,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withAlpha(180)]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1F2937)),
                  ),
                  Text(
                    '${_roleLabel(role)} • ${_formatLastSeen(s['lastSeen'])}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (hasLocation)
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StaffRouteViewPage(
                      staffId: s['id'] as String,
                      staffName: name,
                    ),
                  ),
                ),
                icon: const Icon(Icons.route_rounded,
                    color: Color(0xFF6366F1)),
                tooltip: 'View Route',
              ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
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
