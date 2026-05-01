import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

/// Service for interacting with a self-hosted Valhalla routing engine.
class ValhallaService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ── Snap GPS trace to roads ─────────────────────────────────────
  // Strategy: try trace_route (map matching) first; if it fails,
  // fall back to routing between consecutive GPS waypoints which
  // always produces road-following paths.
  static Future<List<LatLng>> traceRoute(
    List<LatLng> points, {
    List<DateTime>? timestamps,
    List<double?>? headings,
  }) async {
    if (points.length < 2) return [];

    // Pre-filter: remove stationary / near-duplicate points (< 20m apart)
    // Also filter corresponding timestamps/headings in sync
    final filterResult = _filterNearDuplicatesWithMeta(points, 20.0, timestamps, headings);
    final filtered = filterResult.points;
    if (filtered.length < 2) return points;

    debugPrint('Valhalla: ${points.length} raw → ${filtered.length} filtered points');

    // 1. Try trace_route (true map matching — best accuracy)
    final traced = await _tryTraceRoute(filtered, filterResult.timestamps, filterResult.headings);
    if (traced.length >= 2) {
      debugPrint('Valhalla trace_route success: ${traced.length} snapped points');
      return traced;
    }

    // 2. Fallback: route between GPS waypoints (always follows roads)
    debugPrint('Valhalla trace_route failed, using route fallback');
    final routed = await _routeAlongWaypoints(filtered);
    debugPrint('Valhalla route fallback: ${routed.length} points');
    return routed.length >= 2 ? routed : filtered;
  }

  // Try Valhalla trace_route with minimal request body.
  // If a batch fails, falls back to route for just that segment.
  static Future<List<LatLng>> _tryTraceRoute(
    List<LatLng> pts,
    List<DateTime>? timestamps,
    List<double?>? headings,
  ) async {
    final allSnapped = <LatLng>[];
    const batchSize = 80;

    for (int start = 0; start < pts.length - 1; start += batchSize - 1) {
      final end = (start + batchSize).clamp(0, pts.length);
      final batch = pts.sublist(start, end);
      if (batch.length < 2) break;

      final batchTs = timestamps?.sublist(start, end);
      final batchHd = headings?.sublist(start, end);

      final shape = <Map<String, dynamic>>[];
      for (int i = 0; i < batch.length; i++) {
        final point = <String, dynamic>{
          'lat': batch[i].latitude,
          'lon': batch[i].longitude,
        };
        if (batchTs != null && i < batchTs.length) {
          point['time'] = (batchTs[i].millisecondsSinceEpoch / 1000).round();
        }
        if (batchHd != null && i < batchHd.length && batchHd[i] != null && batchHd[i]! >= 0) {
          point['heading'] = batchHd[i];
          point['heading_tolerance'] = 45;
        }
        shape.add(point);
      }

      List<LatLng>? batchSnapped;
      try {
        final resp = await _dio.post(
          '${AppConstants.valhallaBaseUrl}/trace_route',
          data: <String, dynamic>{
            'shape': shape,
            'costing': 'auto',
            'shape_match': 'map_snap',
            'search_radius': 50,
            'gps_accuracy': 20,
          },
          options: Options(
            contentType: 'application/json',
            validateStatus: (s) => s != null && s < 500,
          ),
        );

        if (resp.statusCode == 200) {
          final legs = resp.data['trip']?['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            batchSnapped = <LatLng>[];
            for (final leg in legs) {
              final encoded = leg['shape'] as String?;
              if (encoded == null || encoded.isEmpty) continue;
              final decoded = decodePolyline6(encoded);
              if (batchSnapped!.isNotEmpty && decoded.isNotEmpty) {
                if (_samePoint(batchSnapped.last, decoded.first)) {
                  decoded.removeAt(0);
                }
              }
              batchSnapped.addAll(decoded);
            }
          }
        }
      } catch (e) {
        debugPrint('trace_route batch error: $e');
      }

      // Validate: snapped result should have significantly more points than input
      // (road-snapped routes add intermediate road geometry). If not, snap was poor.
      final snapRatio = batchSnapped != null && batch.isNotEmpty
          ? batchSnapped.length / batch.length
          : 0.0;
      if (batchSnapped != null && batchSnapped.length >= 2 && snapRatio > 1.5) {
        if (allSnapped.isNotEmpty && _samePoint(allSnapped.last, batchSnapped.first)) {
          batchSnapped.removeAt(0);
        }
        allSnapped.addAll(batchSnapped);
      } else {
        // Fallback: route this segment via waypoints
        debugPrint('trace_route batch ${start ~/ batchSize} ${batchSnapped != null ? "poor quality (ratio ${snapRatio.toStringAsFixed(1)})" : "failed"}, using route fallback');
        final routed = await _routeAlongWaypoints(batch);
        if (allSnapped.isNotEmpty && routed.isNotEmpty && _samePoint(allSnapped.last, routed.first)) {
          routed.removeAt(0);
        }
        allSnapped.addAll(routed);
      }
    }
    return allSnapped;
  }

  // Route a single pair of points.
  static Future<List<LatLng>?> _routePair(LatLng a, LatLng b) async {
    try {
      final resp = await _dio.post(
        '${AppConstants.valhallaBaseUrl}/route',
        data: <String, dynamic>{
          'locations': [
            {'lat': a.latitude, 'lon': a.longitude},
            {'lat': b.latitude, 'lon': b.longitude},
          ],
          'costing': 'auto',
        },
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (resp.statusCode == 200) {
        final legs = resp.data['trip']?['legs'] as List?;
        if (legs != null && legs.isNotEmpty) {
          final seg = <LatLng>[];
          for (final leg in legs) {
            final encoded = leg['shape'] as String?;
            if (encoded == null || encoded.isEmpty) continue;
            seg.addAll(decodePolyline6(encoded));
          }
          if (seg.length >= 2) return seg;
        }
      }
    } catch (_) {}
    return null;
  }

  // Route between consecutive GPS waypoints using Valhalla route endpoint.
  // Batches of 10. If a batch fails, retries as individual pairs.
  static Future<List<LatLng>> _routeAlongWaypoints(List<LatLng> pts) async {
    if (pts.length < 2) return [];

    final allRouted = <LatLng>[];
    const maxWaypoints = 10;

    for (int start = 0; start < pts.length - 1; start += maxWaypoints - 1) {
      final end = (start + maxWaypoints).clamp(0, pts.length);
      final batch = pts.sublist(start, end);
      if (batch.length < 2) break;

      final locations = batch
          .map((p) => <String, dynamic>{
                'lat': p.latitude,
                'lon': p.longitude,
              })
          .toList();

      bool batchOk = false;
      try {
        final resp = await _dio.post(
          '${AppConstants.valhallaBaseUrl}/route',
          data: <String, dynamic>{
            'locations': locations,
            'costing': 'auto',
          },
          options: Options(
            contentType: 'application/json',
            validateStatus: (s) => s != null && s < 500,
          ),
        );

        if (resp.statusCode == 200) {
          final legs = resp.data['trip']?['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            for (final leg in legs) {
              final encoded = leg['shape'] as String?;
              if (encoded == null || encoded.isEmpty) continue;
              final decoded = decodePolyline6(encoded);
              if (allRouted.isNotEmpty && decoded.isNotEmpty) {
                if (_samePoint(allRouted.last, decoded.first)) {
                  decoded.removeAt(0);
                }
              }
              allRouted.addAll(decoded);
            }
            batchOk = true;
          }
        }
      } catch (e) {
        debugPrint('route batch error: $e');
      }

      // If batch failed, retry as individual pairs
      if (!batchOk) {
        debugPrint('Route batch failed (${batch.length} pts), retrying as pairs');
        for (int i = 0; i < batch.length - 1; i++) {
          final seg = await _routePair(batch[i], batch[i + 1]);
          if (seg != null) {
            if (allRouted.isNotEmpty && _samePoint(allRouted.last, seg.first)) {
              seg.removeAt(0);
            }
            allRouted.addAll(seg);
          } else {
            // Last resort: raw line for this single gap
            if (allRouted.isEmpty || !_samePoint(allRouted.last, batch[i])) {
              allRouted.add(batch[i]);
            }
            allRouted.add(batch[i + 1]);
          }
        }
      }
    }
    return allRouted;
  }

  // Remove GPS points within [minMeters] of the previous kept point,
  // keeping timestamps and headings arrays in sync.
  static ({List<LatLng> points, List<DateTime>? timestamps, List<double?>? headings})
      _filterNearDuplicatesWithMeta(
    List<LatLng> pts,
    double minMeters,
    List<DateTime>? timestamps,
    List<double?>? headings,
  ) {
    if (pts.isEmpty) return (points: [], timestamps: null, headings: null);
    const dist = Distance();
    final rPts = <LatLng>[pts.first];
    final rTs = timestamps != null ? <DateTime>[timestamps.first] : null;
    final rHd = headings != null ? <double?>[headings.first] : null;

    for (int i = 1; i < pts.length; i++) {
      if (dist.as(LengthUnit.Meter, rPts.last, pts[i]) >= minMeters) {
        rPts.add(pts[i]);
        rTs?.add(timestamps![i]);
        rHd?.add(headings![i]);
      }
    }
    if (rPts.length > 1 && !_samePoint(rPts.last, pts.last)) {
      rPts.add(pts.last);
      if (timestamps != null) rTs!.add(timestamps.last);
      if (headings != null) rHd!.add(headings.last);
    }
    return (points: rPts, timestamps: rTs, headings: rHd);
  }

  // ── Valhalla route (Directions) ──────────────────────────────────
  // Calculates the optimal driving route between two points.
  // Used for live tracking (technician → job site).
  static Future<({List<LatLng> points, double distanceKm})> route(
    LatLng from,
    LatLng to,
  ) async {
    try {
      final body = {
        'locations': [
          {'lat': from.latitude, 'lon': from.longitude},
          {'lat': to.latitude, 'lon': to.longitude},
        ],
        'costing': 'auto',
        'units': 'kilometers',
      };

      final resp = await _dio.post(
        '${AppConstants.valhallaBaseUrl}/route',
        data: body,
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (resp.statusCode != 200) {
        debugPrint('Valhalla route failed: ${resp.statusCode} - ${resp.data}');
        return (points: <LatLng>[], distanceKm: 0.0);
      }

      final trip = resp.data['trip'];
      if (trip == null) return (points: <LatLng>[], distanceKm: 0.0);

      final legs = trip['legs'] as List?;
      if (legs == null || legs.isEmpty) return (points: <LatLng>[], distanceKm: 0.0);

      final allPoints = <LatLng>[];
      for (final leg in legs) {
        final encoded = leg['shape'] as String?;
        if (encoded == null || encoded.isEmpty) continue;
        final decoded = decodePolyline6(encoded);
        if (allPoints.isNotEmpty && decoded.isNotEmpty) {
          if (_samePoint(allPoints.last, decoded.first)) {
            decoded.removeAt(0);
          }
        }
        allPoints.addAll(decoded);
      }

      final distanceKm = (trip['summary']?['length'] as num?)?.toDouble() ?? 0.0;
      return (points: allPoints, distanceKm: distanceKm);
    } catch (e) {
      debugPrint('Valhalla route error: $e');
      return (points: <LatLng>[], distanceKm: 0.0);
    }
  }

  // ── Polyline decoder (precision 6) ───────────────────────────────
  // Valhalla uses Google's encoded polyline format but with precision 6
  // (1e6) instead of Google Maps' precision 5 (1e5).
  static List<LatLng> decodePolyline6(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return points;
  }

  static bool _samePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 1e-7 &&
        (a.longitude - b.longitude).abs() < 1e-7;
  }
}
