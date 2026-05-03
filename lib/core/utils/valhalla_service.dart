import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

/// Service for interacting with a self-hosted Valhalla routing engine.
class ValhallaService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Limit concurrent requests so we don't overwhelm Valhalla.
  static const int _maxConcurrency = 4;
  // Overall budget for a single traceRoute() call.
  static const Duration _overallTimeout = Duration(seconds: 45);

  // In-memory cache: hash of input points → snapped result.
  // Prevents re-snapping the same trace on widget rebuilds.
  static final Map<int, List<LatLng>> _cache = <int, List<LatLng>>{};
  static const int _cacheMaxEntries = 32;

  // ── Snap GPS trace to roads ─────────────────────────────────────
  // Strategy: try trace_route (map matching) first; if a batch fails,
  // fall back to routing between consecutive GPS waypoints which
  // always produces road-following paths. All batches run in parallel
  // with a bounded concurrency cap.
  static Future<List<LatLng>> traceRoute(
    List<LatLng> points, {
    List<DateTime>? timestamps,
    List<double?>? headings,
  }) async {
    if (points.length < 2) return [];

    // Pre-filter: remove stationary / near-duplicate points (< 25m apart)
    // Slightly larger than before to trim low-signal GPS jitter faster.
    final filterResult = _filterNearDuplicatesWithMeta(points, 25.0, timestamps, headings);
    final filtered = filterResult.points;
    if (filtered.length < 2) return points;

    // Cache lookup
    final cacheKey = _hashPoints(filtered);
    final cached = _cache[cacheKey];
    if (cached != null) {
      debugPrint('Valhalla: cache hit (${cached.length} points)');
      return cached;
    }

    debugPrint('Valhalla: ${points.length} raw → ${filtered.length} filtered points');

    try {
      final result = await _tryTraceRoute(
        filtered,
        filterResult.timestamps,
        filterResult.headings,
      ).timeout(_overallTimeout);

      if (result.length >= 2) {
        debugPrint('Valhalla snap done: ${result.length} points');
        _cachePut(cacheKey, result);
        return result;
      }
    } on TimeoutException {
      debugPrint('Valhalla snap overall timeout — returning filtered GPS');
    } catch (e) {
      debugPrint('Valhalla snap error: $e');
    }

    // Last resort: raw (but filtered) GPS trace
    return filtered;
  }

  // Try Valhalla trace_route with minimal request body.
  // Batches run in parallel (bounded by _maxConcurrency). If a batch fails
  // or produces too few points, that specific batch falls back to routing.
  static Future<List<LatLng>> _tryTraceRoute(
    List<LatLng> pts,
    List<DateTime>? timestamps,
    List<double?>? headings,
  ) async {
    const batchSize = 80;

    // Build batch descriptors first (sequential index so we can stitch later).
    final batches = <({int index, List<LatLng> pts, List<DateTime>? ts, List<double?>? hd})>[];
    for (int start = 0; start < pts.length - 1; start += batchSize - 1) {
      final end = (start + batchSize).clamp(0, pts.length);
      final batch = pts.sublist(start, end);
      if (batch.length < 2) break;
      batches.add((
        index: batches.length,
        pts: batch,
        ts: timestamps?.sublist(start, end),
        hd: headings?.sublist(start, end),
      ));
    }

    // Run all batches in parallel with a concurrency cap.
    final results = List<List<LatLng>>.filled(batches.length, const <LatLng>[]);
    await _runBounded<void>(
      batches,
      _maxConcurrency,
      (b) async {
        results[b.index] = await _snapSingleBatch(b.pts, b.ts, b.hd);
      },
    );

    // Stitch sequentially, de-duplicating the join point between batches.
    final merged = <LatLng>[];
    for (final seg in results) {
      if (seg.isEmpty) continue;
      if (merged.isNotEmpty && _samePoint(merged.last, seg.first)) {
        merged.addAll(seg.skip(1));
      } else {
        merged.addAll(seg);
      }
    }
    return merged;
  }

  // Snap one batch via trace_route. If it returns ANY usable result, use it.
  // If it fails entirely, return raw GPS for that batch (no cascading retries).
  // This eliminates the "snapping loop" caused by deep fallback chains.
  static Future<List<LatLng>> _snapSingleBatch(
    List<LatLng> batch,
    List<DateTime>? batchTs,
    List<double?>? batchHd,
  ) async {
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

    try {
      final resp = await _dio.post(
        '${AppConstants.valhallaBaseUrl}/trace_route',
        data: <String, dynamic>{
          'shape': shape,
          'costing': 'auto',
          'shape_match': 'map_snap',
          'search_radius': 100, // wider radius = fewer failed matches
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
          final snapped = <LatLng>[];
          for (final leg in legs) {
            final encoded = leg['shape'] as String?;
            if (encoded == null || encoded.isEmpty) continue;
            final decoded = decodePolyline6(encoded);
            if (snapped.isNotEmpty && decoded.isNotEmpty && _samePoint(snapped.last, decoded.first)) {
              decoded.removeAt(0);
            }
            snapped.addAll(decoded);
          }
          // Trust any non-empty result from trace_route
          if (snapped.length >= 2) return snapped;
        }
      }
    } catch (e) {
      debugPrint('trace_route batch error: $e');
    }

    // No cascading fallback — just return raw GPS for this batch.
    // The rest of the trace's batches still get snapped properly.
    debugPrint('trace_route batch failed (${batch.length} pts), keeping raw GPS for this segment');
    return List<LatLng>.from(batch);
  }

  // Run [task] over [items] with at most [maxConcurrent] in-flight.
  static Future<void> _runBounded<T>(
    List<dynamic> items,
    int maxConcurrent,
    Future<void> Function(dynamic) task,
  ) async {
    if (items.isEmpty) return;
    int next = 0;
    final workers = <Future<void>>[];
    for (int w = 0; w < maxConcurrent && w < items.length; w++) {
      workers.add(() async {
        while (true) {
          final i = next++;
          if (i >= items.length) return;
          await task(items[i]);
        }
      }());
    }
    await Future.wait(workers);
  }

  // Stable hash of a point list for caching.
  static int _hashPoints(List<LatLng> pts) {
    int h = pts.length;
    for (final p in pts) {
      final lat = (p.latitude * 1e5).round();
      final lon = (p.longitude * 1e5).round();
      h = 0x1fffffff & (h * 31 + lat);
      h = 0x1fffffff & (h * 31 + lon);
    }
    return h;
  }

  static void _cachePut(int key, List<LatLng> value) {
    if (_cache.length >= _cacheMaxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
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
