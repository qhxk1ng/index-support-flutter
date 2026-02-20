import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';

class TicketNavigationPage extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketNavigationPage({super.key, required this.ticket});

  @override
  State<TicketNavigationPage> createState() => _TicketNavigationPageState();
}

class _TicketNavigationPageState extends State<TicketNavigationPage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _destination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _locationTimer;
  double? _distanceInKm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final destLat = widget.ticket['customerLatitude'] as double?;
      final destLng = widget.ticket['customerLongitude'] as double?;

      if (destLat == null || destLng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer location not available')),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _destination = LatLng(destLat, destLng);
        _isLoading = false;
      });

      _updateMarkers();
      _drawRoute();
      _calculateDistance();

      _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        final newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = LatLng(newPosition.latitude, newPosition.longitude);
        });
        _updateMarkers();
        _calculateDistance();
      });
    } catch (e) {
      print('Error initializing navigation: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    _markers = {
      if (_currentPosition != null)
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      if (_destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Customer Location',
            snippet: widget.ticket['customerName'] ?? 'Customer',
          ),
        ),
    };
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null || _destination == null) return;

    try {
      PolylinePoints polylinePoints = PolylinePoints();
      
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
        request: PolylineRequest(
          origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination: PointLatLng(_destination!.latitude, _destination!.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF10B981),
              width: 5,
              points: polylineCoordinates,
            ),
          );
        });
      }
    } catch (e) {
      _drawStraightLine();
    }
  }

  void _drawStraightLine() {
    if (_currentPosition == null || _destination == null) return;

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFF10B981),
          width: 5,
          points: [_currentPosition!, _destination!],
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    });
  }

  void _calculateDistance() {
    if (_currentPosition == null || _destination == null) return;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );

    setState(() {
      _distanceInKm = distance / 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(0, 0),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentPosition != null && _destination != null) {
                      _fitMapToBounds();
                    }
                  },
                ),
                _buildTopCard(),
                _buildBottomCard(),
                Positioned(
                  top: 50,
                  left: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                ),
                Positioned(
                  bottom: 200,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _centerOnCurrentLocation,
                    child: const Icon(Icons.my_location, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopCard() {
    return Positioned(
      top: 50,
      left: 80,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.navigation, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Navigating to Customer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_distanceInKm != null)
                      Text(
                        '${_distanceInKm!.toStringAsFixed(2)} km away',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ticket['customerName'] ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.ticket['issueDescription'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Mark as arrived or in progress
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Arrived'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fitMapToBounds() {
    if (_currentPosition == null || _destination == null || _mapController == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        _currentPosition!.latitude < _destination!.latitude
            ? _currentPosition!.latitude
            : _destination!.latitude,
        _currentPosition!.longitude < _destination!.longitude
            ? _currentPosition!.longitude
            : _destination!.longitude,
      ),
      northeast: LatLng(
        _currentPosition!.latitude > _destination!.latitude
            ? _currentPosition!.latitude
            : _destination!.latitude,
        _currentPosition!.longitude > _destination!.longitude
            ? _currentPosition!.longitude
            : _destination!.longitude,
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }
}
