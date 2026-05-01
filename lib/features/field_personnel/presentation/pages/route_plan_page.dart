import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';

class RoutePlanPage extends StatefulWidget {
  const RoutePlanPage({super.key});

  @override
  State<RoutePlanPage> createState() => _RoutePlanPageState();
}

class _RoutePlanPageState extends State<RoutePlanPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _routePlan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutePlan();
  }

  Future<void> _loadRoutePlan() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = sl<ApiClient>();
      final res = await api.get('/field-personnel/route-plan');
      if (mounted) {
        setState(() {
          _routePlan = Map<String, dynamic>.from(res.data['data'] ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
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
    final segments = List<Map<String, dynamic>>.from(_routePlan?['segments'] ?? []);
    final totalRouteKm = (_routePlan?['totalRouteKm'] ?? 0).toDouble();
    final returnKm = (_routePlan?['returnKm'] ?? 0).toDouble();
    final grandTotalKm = (_routePlan?['grandTotalKm'] ?? 0).toDouble();
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Segments + stops
          ...List.generate(segments.length, (i) {
            final seg = segments[i];
            final isReturn = seg['isReturn'] == true;
            final isLast = i == segments.length - 1;
            final distKm = (seg['distanceKm'] ?? 0).toDouble();

            return Column(
              children: [
                // Distance connector
                _buildDistanceConnector(distKm),
                // Stop node
                _buildTimelineNode(
                  label: seg['to'] ?? '',
                  subtitle: isReturn ? 'Return to home' : 'Stop ${i + 1}',
                  icon: isReturn ? Icons.home : Icons.location_on,
                  color: isReturn ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                  isLast: isLast,
                  stop: !isReturn && i < stops.length ? stops[i] : null,
                ),
              ],
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
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
