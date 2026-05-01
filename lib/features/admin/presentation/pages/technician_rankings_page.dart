import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';
import 'staff_route_view_page.dart';

class TechnicianRankingsPage extends StatefulWidget {
  const TechnicianRankingsPage({super.key});

  @override
  State<TechnicianRankingsPage> createState() => _TechnicianRankingsPageState();
}

class _TechnicianRankingsPageState extends State<TechnicianRankingsPage> {
  List<Map<String, dynamic>> _rankings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  Future<void> _fetchRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(ApiEndpoints.technicianRankings);
      final data = response.data['data'] as List;
      setState(() {
        _rankings = data.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Technician Rankings',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRankings,
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
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchRankings, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchRankings,
                  child: _rankings.isEmpty
                      ? const Center(child: Text('No technicians found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rankings.length + (_rankings.length >= 3 ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Top 3 podium section
                            if (_rankings.length >= 3 && index == 0) {
                              return _buildPodium(isDark);
                            }
                            final realIndex = _rankings.length >= 3 ? index - 1 : index;
                            final tech = _rankings[realIndex];
                            return _buildRankingCard(tech, isDark);
                          },
                        ),
                ),
    );
  }

  Widget _buildPodium(bool isDark) {
    final top3 = _rankings.take(3).toList();
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [const Color(0xFFF59E0B), const Color(0xFF9CA3AF), const Color(0xFFCD7F32)];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Top Performers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF92400E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(top3.length, (i) {
              final tech = top3[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToRoute(tech['id'] as String, tech['name'] as String),
                  child: Column(
                    children: [
                      Text(medals[i], style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors[i].withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors[i], width: 2),
                        ),
                        child: Text(
                          (tech['completedJobs'] as int).toString(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colors[i],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tech['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tech['completedJobs']} jobs',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> tech, bool isDark) {
    final rank = tech['rank'] as int;
    final isOnline = tech['isOnline'] as bool? ?? false;
    final completed = tech['completedJobs'] as int? ?? 0;
    final active = tech['activeJobs'] as int? ?? 0;
    final pending = tech['pendingJobs'] as int? ?? 0;
    final totalKm = (tech['totalKmTraveled'] as num?)?.toDouble() ?? 0;
    final returnKm = tech['returnDistanceKm'] as num?;
    final lastJob = tech['lastJobLocation'] as Map<String, dynamic>?;
    final home = tech['homeLocation'] as Map<String, dynamic>?;

    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFF59E0B);
    } else if (rank == 2) {
      rankColor = const Color(0xFF9CA3AF);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToRoute(tech['id'] as String, tech['name'] as String),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(rank <= 3 ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor, width: rank <= 3 ? 2 : 1),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tech['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tech['phoneNumber'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stats row
                      Row(
                        children: [
                          _buildMiniStat('Done', completed.toString(), Colors.green),
                          const SizedBox(width: 12),
                          _buildMiniStat('Active', active.toString(), Colors.blue),
                          const SizedBox(width: 12),
                          _buildMiniStat('Pending', pending.toString(), Colors.orange),
                          const SizedBox(width: 12),
                          _buildMiniStat('KM', totalKm.toStringAsFixed(1), Colors.purple),
                        ],
                      ),
                      // Location info
                      if (lastJob != null || home != null || returnKm != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (lastJob != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: Colors.green),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Last: #${lastJob['ticketNumber'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 10, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            if (returnKm != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.home, size: 12, color: Colors.red),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${returnKm.toStringAsFixed(1)} km home',
                                    style: const TextStyle(fontSize: 10, color: Colors.red),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Completed count large
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        completed.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'done',
                        style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  void _navigateToRoute(String id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffRouteViewPage(staffId: id, staffName: name),
      ),
    );
  }
}
