import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';

class FieldPersonnelDashboardPage extends StatefulWidget {
  const FieldPersonnelDashboardPage({super.key});

  @override
  State<FieldPersonnelDashboardPage> createState() => _FieldPersonnelDashboardPageState();
}

class _FieldPersonnelDashboardPageState extends State<FieldPersonnelDashboardPage> {
  bool _isSidebarExpanded = false;
  int _workAssigned = 0;
  int _tasksCompletedThisMonth = 0;
  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _assignedTickets = [];
  List<Map<String, dynamic>> _pendingJobs = [];
  Timer? _refreshTimer;
  Timer? _jobAlertTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
    _loadStats();
    _pollPendingJobs();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadStats());
    _jobAlertTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollPendingJobs());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _jobAlertTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationTracking() async {
    await BackgroundLocationService.initialize();
    await BackgroundLocationService.start();
    final locationService = sl<LocationTrackingService>();
    await locationService.startTracking();
  }

  Future<void> _loadStats() async {
    try {
      final apiClient = sl<ApiClient>();
      final statsResponse = await apiClient.get('/field-personnel/dashboard');
      final ticketsResponse = await apiClient.get('/field-personnel/assigned-tickets');
      
      if (mounted) {
        setState(() {
          _workAssigned = statsResponse.data['data']['workAssigned'] ?? 0;
          _tasksCompletedThisMonth = statsResponse.data['data']['tasksCompletedThisMonth'] ?? 0;
          _assignedTickets = List<Map<String, dynamic>>.from(ticketsResponse.data['data'] ?? []);
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _pollPendingJobs() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/complaints/pending-jobs');
      final jobs = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      
      if (mounted && jobs.isNotEmpty) {
        // Show alert for the first pending job if we haven't shown it yet
        final newJobIds = jobs.map((j) => j['complaintId']).toSet();
        final oldJobIds = _pendingJobs.map((j) => j['complaintId']).toSet();
        final brandNew = newJobIds.difference(oldJobIds);
        
        setState(() => _pendingJobs = jobs);
        
        if (brandNew.isNotEmpty) {
          final newJob = jobs.firstWhere((j) => brandNew.contains(j['complaintId']));
          _showJobAlertDialog(newJob);
        }
      } else if (mounted) {
        setState(() => _pendingJobs = jobs);
      }
    } catch (e) {
      debugPrint('Error polling pending jobs: $e');
    }
  }

  void _showJobAlertDialog(Map<String, dynamic> job) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Job Found!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket #${job['ticketNumber'] ?? ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job['address'] ?? 'Location provided',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${job['distanceKm']?.toStringAsFixed(1) ?? '?'} km away',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text('Issue: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job['description'] ?? 'No description',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          SizedBox(
            width: 120,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _declineJob(job['complaintId']);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _acceptJob(job['complaintId']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptJob(String complaintId) async {
    try {
      final apiClient = sl<ApiClient>();
      await apiClient.post('/complaints/$complaintId/accept');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job accepted!'), backgroundColor: Color(0xFF10B981)),
        );
      }
      _loadStats();
      _pollPendingJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _declineJob(String complaintId) async {
    try {
      final apiClient = sl<ApiClient>();
      await apiClient.post('/complaints/$complaintId/decline');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job declined')),
        );
      }
      _pollPendingJobs();
    } catch (e) {
      debugPrint('Error declining job: $e');
    }
  }

  Future<void> _startJourneyForTicket(Map<String, dynamic> ticket) async {
    try {
      final apiClient = sl<ApiClient>();
      await apiClient.post('/complaints/${ticket['id']}/start-journey');
      
      // Open Google Maps for navigation
      final lat = ticket['customerLatitude'];
      final lng = ticket['customerLongitude'];
      if (lat != null && lng != null) {
        final url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
        final fallbackUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey started! Navigating...'), backgroundColor: Color(0xFF10B981)),
        );
      }
      _loadStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _endJourneyForTicket(Map<String, dynamic> ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stop_circle, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('End Journey', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to end this journey?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Journey'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiClient = sl<ApiClient>();
        await apiClient.post('/complaints/${ticket['id']}/end-journey');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journey ended'), backgroundColor: Color(0xFF10B981)),
          );
        }
        _loadStats();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showCompleteTaskDialog(Map<String, dynamic> ticket) async {
    final remarksController = TextEditingController();
    List<File> selectedImages = [];
    List<String> uploadedUrls = [];
    bool isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Complete Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ticket #${ticket['ticketNumber'] ?? ticket['id']?.substring(0, 8)}',
                    style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Completion Photo *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...selectedImages.map((img) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(img, width: 70, height: 70, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedImages.remove(img)),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.camera);
                        if (picked != null) {
                          setDialogState(() => selectedImages.add(File(picked.path)));
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Remarks *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the work done...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (remarksController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide remarks')),
                  );
                  return;
                }
                if (selectedImages.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please take at least one photo')),
                  );
                  return;
                }

                setDialogState(() => isUploading = true);

                try {
                  // Upload images first
                  final apiClient = sl<ApiClient>();
                  final formData = FormData();
                  for (final img in selectedImages) {
                    formData.files.add(MapEntry(
                      'images',
                      await MultipartFile.fromFile(img.path),
                    ));
                  }
                  final uploadResponse = await apiClient.uploadFile('/upload/images', formData);
                  uploadedUrls = List<String>.from(uploadResponse.data['data'] ?? []);

                  // Get current location for proximity check
                  final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                  // Complete the task
                  await apiClient.post('/complaints/${ticket['id']}/complete', data: {
                    'completionImages': uploadedUrls,
                    'completionRemarks': remarksController.text.trim(),
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task completed!'), backgroundColor: Color(0xFF10B981)),
                    );
                    _loadStats();
                  }
                } catch (e) {
                  setDialogState(() => isUploading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String technicianName = 'Technician';
        if (state is AuthAuthenticated) {
          technicianName = state.user.name;
        }

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: _buildDashboardContent(technicianName),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildSidebar(technicianName),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: _toggleSidebar,
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Field Technician',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_pendingJobs.isNotEmpty)
            GestureDetector(
              onTap: () => _showJobAlertDialog(_pendingJobs.first),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_pendingJobs.length} New',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Tracking',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(String technicianName) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
        await _pollPendingJobs();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $technicianName!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text("Here's your work overview", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 24),
            // Pending job alerts banner
            if (_pendingJobs.isNotEmpty) ...[
              _buildPendingJobsBanner(),
              const SizedBox(height: 24),
            ],
            const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            _isLoadingStats ? const Center(child: CircularProgressIndicator()) : _buildOverviewCards(),
            const SizedBox(height: 24),
            // Assigned work section
            if (_assignedTickets.isNotEmpty) ...[
              const Text('Active Work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 16),
              ..._assignedTickets.map((t) => _buildAssignedTicketCard(t)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingJobsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_pendingJobs.length} New Job${_pendingJobs.length > 1 ? 's' : ''} Available!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Tap to view and accept', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showJobAlertDialog(_pendingJobs.first),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFF59E0B)),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        _buildStatCard('Work Assigned', _workAssigned.toString(), Icons.assignment, const Color(0xFF3B82F6), 'Active tasks'),
        const SizedBox(height: 12),
        _buildStatCard('Completed This Month', _tasksCompletedThisMonth.toString(), Icons.check_circle, const Color(0xFF10B981), 'Successfully completed'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] ?? 'ASSIGNED';
    final journeyStarted = status == 'IN_PROGRESS';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.assignment, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket['customerName'] ?? 'Customer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(ticket['issueDescription'] ?? 'No description', style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: journeyStarted ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  journeyStarted ? 'En Route' : 'Assigned',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: journeyStarted ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(ticket['customerAddress'] ?? 'Address not available', style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!journeyStarted)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startJourneyForTicket(ticket),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Start Journey'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (journeyStarted) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final lat = ticket['customerLatitude'];
                      final lng = ticket['customerLongitude'];
                      if (lat != null && lng != null) {
                        final url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
                        final fallbackUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
                        canLaunchUrl(url).then((can) {
                          if (can) {
                            launchUrl(url);
                          } else {
                            launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompleteTaskDialog(ticket),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (journeyStarted) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _endJourneyForTicket(ticket),
                icon: const Icon(Icons.stop_circle, size: 18),
                label: const Text('End Journey'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar(String technicianName) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _isSidebarExpanded ? 0 : -280,
      top: 0,
      bottom: 0,
      width: 280,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(4, 0))],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 24, backgroundColor: Color(0xFF10B981), child: Icon(Icons.engineering, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(technicianName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text('Field Technician', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _toggleSidebar),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildSidebarItem(icon: Icons.dashboard, title: 'Dashboard', onTap: () => _toggleSidebar()),
                      _buildSidebarItem(icon: Icons.settings, title: 'Settings', onTap: () => _toggleSidebar()),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                _buildSidebarItem(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  isDestructive: true,
                  onTap: () {
                    _toggleSidebar();
                    context.read<AuthBloc>().add(LogoutEvent());
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? Colors.red[300] : Colors.white70, size: 22),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(fontSize: 15, color: isDestructive ? Colors.red[300] : Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
