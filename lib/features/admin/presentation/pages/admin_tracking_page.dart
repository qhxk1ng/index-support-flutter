import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../domain/entities/admin_entities.dart';
import 'dart:async';

class AdminTrackingPage extends StatefulWidget {
  const AdminTrackingPage({super.key});

  @override
  State<AdminTrackingPage> createState() => _AdminTrackingPageState();
}

class _AdminTrackingPageState extends State<AdminTrackingPage> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  List<FieldPersonnelEntity> _personnel = [];
  bool _isLoading = true;
  String? _selectedPersonnelId;

  @override
  void initState() {
    super.initState();
    _loadPersonnel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadPersonnel());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonnel() async {
    try {
      final adminRemoteDataSource = sl<AdminRemoteDataSource>();
      final personnel = await adminRemoteDataSource.getAllFieldPersonnel();
      
      if (mounted) {
        setState(() {
          _personnel = personnel;
          _isLoading = false;
        });
        
        if (_personnel.isNotEmpty && _selectedPersonnelId == null) {
          _fitMapToPersonnel();
        }
      }
    } catch (e) {
      debugPrint('Error loading personnel: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fitMapToPersonnel() {
    if (_personnel.isEmpty) return;
    
    final activePersonnel = _personnel.where((p) => p.currentLatitude != null && p.currentLongitude != null).toList();
    if (activePersonnel.isEmpty) return;

    try {
      if (activePersonnel.length == 1) {
        _mapController.move(
          LatLng(activePersonnel.first.currentLatitude!, activePersonnel.first.currentLongitude!),
          14,
        );
      } else {
        final bounds = LatLngBounds(
          LatLng(
            activePersonnel.map((p) => p.currentLatitude!).reduce((a, b) => a < b ? a : b),
            activePersonnel.map((p) => p.currentLongitude!).reduce((a, b) => a < b ? a : b),
          ),
          LatLng(
            activePersonnel.map((p) => p.currentLatitude!).reduce((a, b) => a > b ? a : b),
            activePersonnel.map((p) => p.currentLongitude!).reduce((a, b) => a > b ? a : b),
          ),
        );
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)),
        );
      }
    } catch (e) {
      debugPrint('Error fitting map: $e');
    }
  }

  List<Marker> _buildMarkers() {
    return _personnel
        .where((p) => p.currentLatitude != null && p.currentLongitude != null)
        .map((personnel) {
      final isSelected = _selectedPersonnelId == personnel.id;
      final color = personnel.isActive ? const Color(0xFF10B981) : Colors.grey;

      return Marker(
        point: LatLng(personnel.currentLatitude!, personnel.currentLongitude!),
        width: isSelected ? 60 : 45,
        height: isSelected ? 60 : 45,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedPersonnelId = personnel.id);
            _mapController.move(
              LatLng(personnel.currentLatitude!, personnel.currentLongitude!),
              16,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.engineering,
              color: Colors.white,
              size: isSelected ? 28 : 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Technician Tracking'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPersonnel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _personnel.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No technicians available'),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _personnel.isNotEmpty &&
                                _personnel.first.currentLatitude != null
                            ? LatLng(
                                _personnel.first.currentLatitude!,
                                _personnel.first.currentLongitude!,
                              )
                            : const LatLng(0, 0),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.indexcare.app',
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    // Bottom sheet with personnel list
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Technicians (${_personnel.where((p) => p.isActive).length})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 150,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _personnel.length,
                                      itemBuilder: (context, index) {
                                        final person = _personnel[index];
                                        final isSelected = _selectedPersonnelId == person.id;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() => _selectedPersonnelId = person.id);
                                            if (person.currentLatitude != null &&
                                                person.currentLongitude != null) {
                                              _mapController.move(
                                                LatLng(person.currentLatitude!,
                                                    person.currentLongitude!),
                                                16,
                                              );
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF6366F1)
                                                  : Colors.grey[100],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF6366F1)
                                                    : Colors.grey[300]!,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor: person.isActive
                                                          ? const Color(0xFF10B981)
                                                          : Colors.grey,
                                                      child: Text(
                                                        person.name[0].toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          person.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        Text(
                                                          person.isActive
                                                              ? 'Active'
                                                              : 'Offline',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: isSelected
                                                                ? Colors.white70
                                                                : Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
