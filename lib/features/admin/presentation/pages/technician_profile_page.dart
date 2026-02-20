import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';

class TechnicianProfilePage extends StatefulWidget {
  final String technicianId;
  final String technicianName;

  const TechnicianProfilePage({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  bool _showLocations = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(
        '/admin/technician/${widget.technicianId}/profile',
      );
      if (mounted) {
        setState(() {
          _profile = response.data['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load profile';
        });
      }
    }
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours < 24) return '${hours}h ${mins}m';
    final days = hours ~/ 24;
    final remHours = hours % 24;
    return '${days}d ${remHours}h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.technicianName),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_profile == null) return const SizedBox();

    final totalTimeMin = (_profile!['totalTimeOnAppMinutes'] as num?)?.toInt() ?? 0;
    final totalGpsKm = (_profile!['totalGpsKm'] as num?)?.toDouble() ?? 0;
    final completedJobs = (_profile!['completedJobs'] as num?)?.toInt() ?? 0;
    final activeJobs = (_profile!['activeJobs'] as num?)?.toInt() ?? 0;
    final isOnline = _profile!['isOnline'] == true;
    final phone = _profile!['phoneNumber'] as String? ?? '';
    final email = _profile!['email'] as String?;
    final lastSeen = _profile!['lastSeen'] != null
        ? DateTime.tryParse(_profile!['lastSeen'].toString())
        : null;
    final locations = (_profile!['visitedLocations'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.engineering, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.technicianName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        if (email != null)
                          Text(email, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (lastSeen != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last seen: ${DateFormat('MMM dd, yyyy HH:mm').format(lastSeen)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],

            const SizedBox(height: 20),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildStatCard(
                  'Time on App',
                  _formatDuration(totalTimeMin),
                  Icons.access_time_rounded,
                  const Color(0xFF3B82F6),
                ),
                _buildStatCard(
                  'Total KMs (GPS)',
                  '${totalGpsKm.toStringAsFixed(1)} km',
                  Icons.route_rounded,
                  const Color(0xFF10B981),
                ),
                _buildStatCard(
                  'Completed Jobs',
                  completedJobs.toString(),
                  Icons.check_circle_rounded,
                  const Color(0xFF8B5CF6),
                ),
                _buildStatCard(
                  'Active Jobs',
                  activeJobs.toString(),
                  Icons.work_rounded,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Locations section
            InkWell(
              onTap: () => setState(() => _showLocations = !_showLocations),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Locations Visited',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '${locations.length} unique locations',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _showLocations ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),

            if (_showLocations && locations.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...locations.map((loc) {
                final lat = (loc['latitude'] as num?)?.toDouble() ?? 0;
                final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;
                final timeSpent = (loc['timeSpentMinutes'] as num?)?.toInt() ?? 0;
                final visitCount = (loc['visitCount'] as num?)?.toInt() ?? 0;
                final firstVisit = loc['firstVisit'] != null
                    ? DateTime.tryParse(loc['firstVisit'].toString())
                    : null;
                final lastVisit = loc['lastVisit'] != null
                    ? DateTime.tryParse(loc['lastVisit'].toString())
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pin_drop, color: Color(0xFFEF4444), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Time: ${_formatDuration(timeSpent)} • Visits: $visitCount',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (firstVisit != null && lastVisit != null)
                              Text(
                                '${DateFormat('MMM dd HH:mm').format(firstVisit)} → ${DateFormat('MMM dd HH:mm').format(lastVisit)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
