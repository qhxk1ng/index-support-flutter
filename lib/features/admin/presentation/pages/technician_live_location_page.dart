import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../domain/entities/admin_entities.dart';

class TechnicianLiveLocationPage extends StatefulWidget {
  final FieldPersonnelEntity technician;
  final LatLng? destination;

  const TechnicianLiveLocationPage({
    super.key,
    required this.technician,
    this.destination,
  });

  @override
  State<TechnicianLiveLocationPage> createState() => _TechnicianLiveLocationPageState();
}

class _TechnicianLiveLocationPageState extends State<TechnicianLiveLocationPage> {
  final MapController _mapController = MapController();
  Timer? _locationUpdateTimer;
  LatLng? _currentTechnicianLocation;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _initializeMap() {
    if (widget.technician.currentLatitude != null && widget.technician.currentLongitude != null) {
      _currentTechnicianLocation = LatLng(
        widget.technician.currentLatitude!,
        widget.technician.currentLongitude!,
      );
      // Defer map controller operations until after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitMapToBounds();
        }
      });
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _refreshTechnicianLocation();
    });
  }

  Future<void> _refreshTechnicianLocation() async {
    if (!mounted) return;
    try {
      final adminRemoteDataSource = sl<AdminRemoteDataSource>();
      final locationData = await adminRemoteDataSource.getTechnicianLocation(widget.technician.id);
      
      if (locationData['currentLatitude'] != null && locationData['currentLongitude'] != null) {
        setState(() {
          _currentTechnicianLocation = LatLng(
            locationData['currentLatitude'] as double,
            locationData['currentLongitude'] as double,
          );
        });
        _fitMapToBounds();
      }
    } catch (e) {
      // Silently handle errors - location will retry on next timer tick
      debugPrint('Error fetching technician location: $e');
    }
  }

  void _fitMapToBounds() {
    if (_currentTechnicianLocation == null) return;

    try {
      if (widget.destination != null) {
        final bounds = LatLngBounds(
          LatLng(
            _currentTechnicianLocation!.latitude < widget.destination!.latitude
                ? _currentTechnicianLocation!.latitude
                : widget.destination!.latitude,
            _currentTechnicianLocation!.longitude < widget.destination!.longitude
                ? _currentTechnicianLocation!.longitude
                : widget.destination!.longitude,
          ),
          LatLng(
            _currentTechnicianLocation!.latitude > widget.destination!.latitude
                ? _currentTechnicianLocation!.latitude
                : widget.destination!.latitude,
            _currentTechnicianLocation!.longitude > widget.destination!.longitude
                ? _currentTechnicianLocation!.longitude
                : widget.destination!.longitude,
          ),
        );
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(100),
          ),
        );
      } else {
        _mapController.move(_currentTechnicianLocation!, 15);
      }
    } catch (e) {
      // Map controller not ready yet, will retry on next update
    }
  }

  double _calculateDistance() {
    if (_currentTechnicianLocation == null || widget.destination == null) return 0;

    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      _currentTechnicianLocation!,
      widget.destination!,
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_currentTechnicianLocation != null) {
      markers.add(
        Marker(
          point: _currentTechnicianLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.engineering,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    if (widget.destination != null) {
      markers.add(
        Marker(
          point: widget.destination!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (_currentTechnicianLocation == null || widget.destination == null) {
      return [];
    }

    return [
      Polyline(
        points: [_currentTechnicianLocation!, widget.destination!],
        color: const Color(0xFF6366F1),
        strokeWidth: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.technician.name} - Live Location'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentTechnicianLocation != null) {
                _mapController.move(_currentTechnicianLocation!, 15);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTechnicianLocation,
          ),
        ],
      ),
      body: _currentTechnicianLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Location not available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentTechnicianLocation!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${AppConstants.mapboxPublicToken}',
                      userAgentPackageName: 'com.indexcare.app',
                      tileSize: 512,
                      zoomOffset: -1,
                    ),
                    PolylineLayer(
                      polylines: _buildPolylines(),
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                  ],
                ),
                if (_isLoadingRoute)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading route...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.destination != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.route,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'En Route to Customer',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    Text(
                                      'Distance: ${_calculateDistance().toStringAsFixed(2)} km',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                        child: const Icon(Icons.add, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                        child: const Icon(Icons.remove, color: Color(0xFF6366F1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
