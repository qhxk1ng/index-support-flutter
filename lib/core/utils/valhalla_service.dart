import 'dart:async';
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

  // Limit concurrent requests so we don't overwhelm Valhalla.
  static const int _maxConcurrency = 4;

  // In-memory cache: hash of input points → list of snapped segments.
  // Prevents re-snapping the same trace on widget rebuilds.
  static final Map<int, List<List<LatLng>>> _segCache =
      <int, List<List<LatLng>>>{};
  static const int _cacheMaxEntries = 32;

  // ── Tunable thresholds ──────────────────────────────────────────
  // Two consecutive GPS points further apart than this are treated as
  // a signal-loss gap and the trace is split there — we NEVER bridge
  // these with a straight line.
  static const double _gapMeters = 400.0;

  // Time gap (seconds) that also splits the trace. Phone sleep / app
  // backgrounded typically shows up as a multi-minute pause between
  // samples with moderate distance jump.
  // Increased from 300s to 600s to avoid splitting at short stops
  // (traffic lights, parking, quick store visits).
  static const int _gapSeconds = 600;

  // Speed (km/h) above which we treat the jump as a GPS glitch, not
  // real motion — 120 km/h is higher than any legal driving speed here.
  static const double _maxSpeedKmh = 120.0;

  // Near-duplicate filter: consecutive samples closer than this are
  // folded into the previous kept point (keeps timestamps aligned).
  // Aligned to web (12m) — removes noisy near-duplicates that confuse
  // Valhalla's map matcher while still preserving low-speed motion.
  static const double _duplicateMeters = 12.0;

  // Snap-quality validation knobs.
  // The first/last snapped point must be within this distance (m) of
  // the corresponding raw point — otherwise trace_route bolted onto
  // the wrong road. Reduced from 350m to 200m to catch wrong-road
  // lock-ons earlier while still accepting urban GPS drift.
  static const double _endpointDriftMeters = 200.0;

  // The snapped polyline length must stay within these multiples of
  // the raw GPS trace length. Catches detours where map-matching
  // sent the route down an unrelated road and back — but the bounds
  // are loose because road-following naturally inflates length vs
  // a noisy straight-cutting GPS trace.
  // Tightened max ratio from 3.0 to 2.2: detour >2.2x raw GPS = likely wrong road.
  static const double _minLengthRatio = 0.3;
  static const double _maxLengthRatio = 2.2;

  // ── Snap GPS trace to roads ─────────────────────────────────────
  // Returns one polyline per continuous road-snapped segment. Any gap
  // (signal loss, stationary period, GPS glitch, or unmatchable region)
  // becomes a break between segments — the UI must render each segment
  // as its own polyline so gaps stay visible rather than getting bridged
  // by a straight line through buildings / rivers / nothing.
  //
  // Pipeline per sub-trace:
  //   1. Filter near-duplicates (< 15 m)
  //   2. Split at spatial / temporal / velocity gaps
  //   3. For each sub-trace, try Valhalla `trace_route` with tight params
  //   4. Validate endpoints drift + length ratio — reject bad snaps
  //   5. On reject, fall back to `route`-along-subsampled-waypoints
  //   6. On another reject, emit raw filtered points (last-resort so the
  //      user at least sees approximate direction)
  static Future<List<List<LatLng>>> traceRoute(
    List<LatLng> points, {
    List<DateTime>? timestamps,
    List<double?>? headings,
  }) async {
    if (points.length < 2) return const [];

    // 1. Pre-filter near-duplicates to keep trace_route request size sane.
    final filtered = _filterNearDuplicatesWithMeta(
      points,
      _duplicateMeters,
      timestamps,
      headings,
    );
    if (filtered.points.length < 2) return const [];

    // Cache lookup on the filtered trace.
    final cacheKey = _hashPoints(filtered.points);
    final cached = _segCache[cacheKey];
    if (cached != null) {
      debugPrint('Valhalla: cache hit (${cached.length} segments)');
      return cached;
    }

    // 2. Split at gaps so we never ask trace_route to bridge signal loss.
    final subTraces = _splitAtGaps(
      filtered.points,
      filtered.timestamps,
      filtered.headings,
    );

    debugPrint(
      'Valhalla: ${points.length} raw → ${filtered.points.length} filtered '
      '→ ${subTraces.length} sub-traces',
    );

    // 3+4+5. Snap each sub-trace independently.
    final segments = <List<LatLng>>[];
    for (final sub in subTraces) {
      if (sub.pts.length < 2) continue;
      final snapped = await _snapSubTrace(sub.pts, sub.ts, sub.hd);
      if (snapped.length >= 2) segments.add(snapped);
    }

    _segCachePut(cacheKey, segments);
    debugPrint('Valhalla snap done: ${segments.length} segments');
    return segments;
  }

  // ── Single-sub-trace snapping ───────────────────────────────────
  // Runs the three-stage fallback on one continuous GPS sub-trace.
  static Future<List<LatLng>> _snapSubTrace(
    List<LatLng> pts,
    List<DateTime>? ts,
    List<double?>? hd,
  ) async {
    // Stage A: trace_route. Large sub-traces are split into overlapping
    // batches so Valhalla isn't asked to match 1000+ points in one call.
    final snapA = pts.length <= 100
        ? await _traceRouteOnce(pts, ts, hd)
        : await _traceRouteBatched(pts, ts, hd);

    if (_validateSnap(pts, snapA)) return snapA;
    if (snapA.length >= 2) {
      debugPrint('trace_route produced invalid snap '
          '(endpoints drift or length ratio out of bounds), trying route');
    }

    // Stage B: route along subsampled waypoints — more forgiving when
    // GPS is noisy but can still produce a sensible road path.
    final subsampled = _subsample(pts, maxPoints: 20);
    final snapB = await _routeAlongWaypoints(subsampled);
    if (_validateSnap(pts, snapB)) return snapB;

    // Stage C: raw filtered trace (NOT a straight line — real samples,
    // just not road-snapped). Caller can style these differently if it
    // wants to indicate "unsnapped". Length check prevents emitting a
    // single straight segment across a huge gap.
    if (_totalLengthMeters(pts) < _gapMeters * 2) {
      debugPrint('Falling back to raw trace for ${pts.length} points');
      return List<LatLng>.from(pts);
    }

    // Trace is too sparse / long for honest rendering — drop it entirely
    // so the map shows a gap instead of a misleading line.
    debugPrint('Dropping ${pts.length} pts: too sparse to render honestly');
    return const [];
  }

  // ── Stage A: trace_route (map matching) ─────────────────────────
  // Single trace_route call. Tight `search_radius` + `gps_accuracy`
  // reduce snapping to nearby wrong roads (e.g. parallel service roads).
  // `turn_penalty_factor` discourages meandering via unlikely turns.
  // Added costing options to restrict to drivable roads only (avoid service roads, alleys, etc.)
  static Future<List<LatLng>> _traceRouteOnce(
    List<LatLng> pts,
    List<DateTime>? ts,
    List<double?>? hd,
  ) async {
    final shape = <Map<String, dynamic>>[];
    for (int i = 0; i < pts.length; i++) {
      final point = <String, dynamic>{
        'lat': pts[i].latitude,
        'lon': pts[i].longitude,
      };
      if (ts != null && i < ts.length) {
        point['time'] = (ts[i].millisecondsSinceEpoch / 1000).round();
      }
      if (hd != null && i < hd.length && hd[i] != null && hd[i]! >= 0) {
        point['heading'] = hd[i];
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
          // Tightened from 35/15 to 25/12 to reduce snapping to nearby
          // wrong roads (e.g. parallel service roads, highways).
          'search_radius': 25,
          'gps_accuracy': 12,
          'trace_options': <String, dynamic>{
            'search_radius': 25.0,
            'gps_accuracy': 12.0,
            'turn_penalty_factor': 1.0,
            // Break distance: penalize discontinuities heavily so
            // trace_route stays close to the input GPS trace.
            'break_distance': 100.0,
          },
          'costing_options': <String, dynamic>{
            'auto': <String, dynamic>{
              'exclude_unpaved': true,
              'exclude_cash_only_tolls': false,
              'exclude_ferries': false,
              'service_penalty': 50.0, // Heavy penalty for service roads
              'alley_penalty': 50.0, // Heavy penalty for alleys
              'driving_side': 'right',
            },
          },
        },
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (resp.statusCode == 200) {
        return _decodeLegs(resp.data['trip']?['legs'] as List?);
      }
    } catch (e) {
      debugPrint('trace_route error: $e');
    }
    return const [];
  }

  // Batched trace_route for long sub-traces (>100 points). Overlaps
  // boundaries by one point so Valhalla can stitch the legs cleanly.
  static Future<List<LatLng>> _traceRouteBatched(
    List<LatLng> pts,
    List<DateTime>? ts,
    List<double?>? hd,
  ) async {
    const batchSize = 80;

    final batches = <({
      int index,
      List<LatLng> pts,
      List<DateTime>? ts,
      List<double?>? hd,
    })>[];
    for (int start = 0; start < pts.length - 1; start += batchSize - 1) {
      final end = (start + batchSize).clamp(0, pts.length);
      final batch = pts.sublist(start, end);
      if (batch.length < 2) break;
      batches.add((
        index: batches.length,
        pts: batch,
        ts: ts?.sublist(start, end),
        hd: hd?.sublist(start, end),
      ));
    }

    final results = List<List<LatLng>>.filled(batches.length, const <LatLng>[]);
    await _runBounded<void>(
      batches,
      _maxConcurrency,
      (b) async {
        final snap = await _traceRouteOnce(b.pts, b.ts, b.hd);
        // Per-batch validation: if this batch snap is bad, skip it —
        // don't let one bad chunk poison the whole stitched polyline.
        if (_validateSnap(b.pts, snap)) {
          results[b.index] = snap;
        }
      },
    );

    return _stitch(results);
  }

  // ── Route a single pair of points (last-resort fallback) ───────
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
          'costing_options': <String, dynamic>{
            'auto': <String, dynamic>{
              'exclude_unpaved': true,
              'exclude_cash_only_tolls': false,
              'exclude_ferries': false,
              'service_penalty': 50.0,
              'alley_penalty': 50.0,
              'driving_side': 'right',
            },
          },
        },
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (resp.statusCode == 200) {
        final legs = resp.data['trip']?['legs'] as List?;
        final decoded = _decodeLegs(legs);
        if (decoded.length >= 2) return decoded;
      }
    } catch (_) {}
    return null;
  }

  // Try /route for one batch of waypoints; on failure retry as parallel pairs.
  static Future<List<LatLng>> _routeSingleBatch(List<LatLng> batch) async {
    final locations = batch
        .map((p) => <String, dynamic>{'lat': p.latitude, 'lon': p.longitude})
        .toList();

    try {
      final resp = await _dio.post(
        '${AppConstants.valhallaBaseUrl}/route',
        data: <String, dynamic>{
          'locations': locations,
          'costing': 'auto',
          'costing_options': <String, dynamic>{
            'auto': <String, dynamic>{
              'exclude_unpaved': true,
              'exclude_cash_only_tolls': false,
              'exclude_ferries': false,
              'service_penalty': 50.0,
              'alley_penalty': 50.0,
              'driving_side': 'right',
            },
          },
        },
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (resp.statusCode == 200) {
        final decoded = _decodeLegs(resp.data['trip']?['legs'] as List?);
        if (decoded.length >= 2) return decoded;
      }
    } catch (e) {
      debugPrint('route batch error: $e');
    }

    // Retry as parallel pairs
    debugPrint('Route batch failed (${batch.length} pts), retrying as parallel pairs');
    final pairs = <({int index, LatLng a, LatLng b})>[];
    for (int i = 0; i < batch.length - 1; i++) {
      pairs.add((index: i, a: batch[i], b: batch[i + 1]));
    }

    final pairResults = List<List<LatLng>?>.filled(pairs.length, null);
    await _runBounded<void>(
      pairs,
      _maxConcurrency,
      (p) async {
        pairResults[p.index] = await _routePair(p.a, p.b);
      },
    );

    final out = <LatLng>[];
    for (int i = 0; i < pairs.length; i++) {
      final seg = pairResults[i];
      if (seg != null && seg.length >= 2) {
        if (out.isNotEmpty && _samePoint(out.last, seg.first)) {
          out.addAll(seg.skip(1));
        } else {
          out.addAll(seg);
        }
      } else {
        // Last resort: raw line for this gap
        if (out.isEmpty || !_samePoint(out.last, pairs[i].a)) {
          out.add(pairs[i].a);
        }
        out.add(pairs[i].b);
      }
    }
    return out;
  }

  // ── Stage B: route-along-waypoints ──────────────────────────────
  // Batches of 10 run in parallel; failed batches fall back to parallel
  // pair calls. Mirrors the web JS implementation exactly.
  static Future<List<LatLng>> _routeAlongWaypoints(List<LatLng> pts) async {
    if (pts.length < 2) return const [];

    const maxWp = 10;
    final batches = <({int index, List<LatLng> pts})>[];
    for (int start = 0; start < pts.length - 1; start += maxWp - 1) {
      final end = (start + maxWp).clamp(0, pts.length);
      final batch = pts.sublist(start, end);
      if (batch.length < 2) break;
      batches.add((index: batches.length, pts: batch));
    }

    final results = List<List<LatLng>>.filled(batches.length, const <LatLng>[]);
    await _runBounded<void>(
      batches,
      _maxConcurrency,
      (b) async {
        results[b.index] = await _routeSingleBatch(b.pts);
      },
    );

    return _stitch(results);
  }

  // ── Snap quality gate ───────────────────────────────────────────
  // Rejects snaps where (a) the endpoints drifted too far from the
  // input GPS (map-matcher locked onto a wrong road), or (b) the
  // snapped length is wildly inflated/collapsed vs raw GPS (detour),
  // or (c) mid-points deviate too far (wrong-road detour in middle).
  static bool _validateSnap(List<LatLng> raw, List<LatLng> snapped) {
    if (snapped.length < 2) return false;
    if (raw.length < 2) return true;

    const dist = Distance();

    // Endpoint drift check
    final firstDrift = dist.as(LengthUnit.Meter, raw.first, snapped.first);
    final lastDrift = dist.as(LengthUnit.Meter, raw.last, snapped.last);
    if (firstDrift > _endpointDriftMeters || lastDrift > _endpointDriftMeters) {
      debugPrint(
        'Snap rejected: endpoint drift '
        '(first=${firstDrift.toStringAsFixed(0)}m, '
        'last=${lastDrift.toStringAsFixed(0)}m)',
      );
      return false;
    }

    // Mid-point drift check: sample ~3 points along the raw trace
    // and ensure the snapped path stays within 150m at those locations.
    // Catches map-matcher sending the route down a parallel wrong road
    // in the middle of the trace.
    if (raw.length >= 5) {
      // Tightened from 150m to 100m; parallel roads are typically 50-100 m away.
      const midDriftLimit = 100.0;
      // 5 evenly-spaced samples at 10/25/50/75/90 % to catch mid-route detours.
      final checkIndices = <int>[
        (raw.length * 0.10).floor().clamp(1, raw.length - 2),
        (raw.length * 0.25).floor(),
        (raw.length * 0.50).floor(),
        (raw.length * 0.75).floor(),
        (raw.length * 0.90).floor().clamp(1, raw.length - 2),
      ];
      for (final idx in checkIndices) {
        final rawPt = raw[idx];
        // Find nearest snapped point
        var minDist = double.infinity;
        for (final snapPt in snapped) {
          final d = dist.as(LengthUnit.Meter, rawPt, snapPt);
          if (d < minDist) minDist = d;
        }
        if (minDist > midDriftLimit) {
          debugPrint(
            'Snap rejected: mid-point drift at index $idx '
            '(dist=${minDist.toStringAsFixed(0)}m > $midDriftLimit m)',
          );
          return false;
        }
      }
    }

    // Length ratio check
    final rawLen = _totalLengthMeters(raw);
    // Only enforce the length ratio on non-trivial traces (> 50 m), so
    // that short hops near a stop aren't rejected over noise.
    if (rawLen > 50) {
      final snapLen = _totalLengthMeters(snapped);
      final ratio = snapLen / rawLen;
      if (ratio < _minLengthRatio || ratio > _maxLengthRatio) {
        debugPrint(
          'Snap rejected: length ratio ${ratio.toStringAsFixed(2)} '
          '(raw=${rawLen.toStringAsFixed(0)}m snap=${snapLen.toStringAsFixed(0)}m)',
        );
        return false;
      }
    }

    return true;
  }

  // ── Gap-based splitting ─────────────────────────────────────────
  // Breaks the trace wherever consecutive samples exceed spatial,
  // temporal, or velocity thresholds. Each returned sub-trace is
  // safely continuous — trace_route can handle it end-to-end.
  static List<({List<LatLng> pts, List<DateTime>? ts, List<double?>? hd})>
      _splitAtGaps(
    List<LatLng> pts,
    List<DateTime>? ts,
    List<double?>? hd,
  ) {
    final segments = <({
      List<LatLng> pts,
      List<DateTime>? ts,
      List<double?>? hd,
    })>[];
    final curPts = <LatLng>[pts.first];
    final curTs = ts != null ? <DateTime>[ts.first] : null;
    final curHd = hd != null ? <double?>[hd.first] : null;
    const dist = Distance();

    void flush() {
      if (curPts.length >= 2) {
        segments.add((
          pts: List<LatLng>.from(curPts),
          ts: curTs != null ? List<DateTime>.from(curTs) : null,
          hd: curHd != null ? List<double?>.from(curHd) : null,
        ));
      }
      curPts.clear();
      curTs?.clear();
      curHd?.clear();
    }

    for (int i = 1; i < pts.length; i++) {
      final d = dist.as(LengthUnit.Meter, pts[i - 1], pts[i]);
      var split = d > _gapMeters;

      if (!split && ts != null) {
        final dtSec = ts[i].difference(ts[i - 1]).inSeconds;
        // Sleep/backgrounded app: long pause plus meaningful motion.
        if (dtSec > _gapSeconds && d > 100) split = true;
        // GPS glitch: impossibly fast jump between samples.
        if (dtSec > 0) {
          final speedKmh = (d / dtSec) * 3.6;
          if (speedKmh > _maxSpeedKmh) split = true;
        }
      }

      if (split) {
        flush();
      }

      curPts.add(pts[i]);
      curTs?.add(ts![i]);
      curHd?.add(hd![i]);
    }

    flush();
    return segments;
  }

  // ── Helpers ─────────────────────────────────────────────────────
  // Concatenate per-batch segments, de-duplicating the shared boundary.
  static List<LatLng> _stitch(List<List<LatLng>> pieces) {
    final out = <LatLng>[];
    for (final seg in pieces) {
      if (seg.isEmpty) continue;
      if (out.isNotEmpty && _samePoint(out.last, seg.first)) {
        out.addAll(seg.skip(1));
      } else {
        out.addAll(seg);
      }
    }
    return out;
  }

  // Decode Valhalla `legs[*].shape` (polyline6) into a continuous list
  // of LatLng, stripping the duplicate point between adjacent legs.
  static List<LatLng> _decodeLegs(List? legs) {
    if (legs == null || legs.isEmpty) return const [];
    final out = <LatLng>[];
    for (final leg in legs) {
      final encoded = leg['shape'] as String?;
      if (encoded == null || encoded.isEmpty) continue;
      final decoded = decodePolyline6(encoded);
      if (out.isNotEmpty &&
          decoded.isNotEmpty &&
          _samePoint(out.last, decoded.first)) {
        decoded.removeAt(0);
      }
      out.addAll(decoded);
    }
    return out;
  }

  // Evenly pick up to [maxPoints] samples from [pts] preserving the
  // first and last points. Used to keep `/route` requests under the
  // Valhalla waypoint cap while still hinting at the GPS trajectory.
  static List<LatLng> _subsample(List<LatLng> pts, {required int maxPoints}) {
    if (pts.length <= maxPoints) return List<LatLng>.from(pts);
    final out = <LatLng>[];
    final step = (pts.length - 1) / (maxPoints - 1);
    for (int i = 0; i < maxPoints; i++) {
      final idx = (i * step).round().clamp(0, pts.length - 1);
      out.add(pts[idx]);
    }
    return out;
  }

  // Sum of great-circle distances (m) between consecutive points.
  static double _totalLengthMeters(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    const dist = Distance();
    double total = 0;
    for (int i = 1; i < pts.length; i++) {
      total += dist.as(LengthUnit.Meter, pts[i - 1], pts[i]);
    }
    return total;
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

  static void _segCachePut(int key, List<List<LatLng>> value) {
    if (_segCache.length >= _cacheMaxEntries) {
      _segCache.remove(_segCache.keys.first);
    }
    _segCache[key] = value;
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

  // ── Valhalla multi-waypoint route ─────────────────────────────────
  // Chains an arbitrary list of waypoints through a single Valhalla
  // /route call and returns one combined polyline + per-leg distances
  // + total distance (km). The caller keeps stops in the order given
  // (no reordering / TSP solving). Used for the field-personnel route
  // plan map which renders the day's planned journey: start → stop1
  // → stop2 → ... → home.
  // Added costing options to restrict to drivable roads only.
  static Future<({List<LatLng> points, List<double> legKm, double distanceKm})>
      routeWaypoints(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      return (points: <LatLng>[], legKm: <double>[], distanceKm: 0.0);
    }

    try {
      final body = {
        'locations': waypoints
            .map((p) => {'lat': p.latitude, 'lon': p.longitude})
            .toList(),
        'costing': 'auto',
        'units': 'kilometers',
        'costing_options': <String, dynamic>{
          'auto': <String, dynamic>{
            'exclude_unpaved': true,
            'exclude_cash_only_tolls': false,
            'exclude_ferries': false,
            'service_penalty': 50.0,
            'alley_penalty': 50.0,
            'driving_side': 'right',
          },
        },
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
        debugPrint('Valhalla multi-route failed: ${resp.statusCode}');
        return (points: <LatLng>[], legKm: <double>[], distanceKm: 0.0);
      }

      final trip = resp.data['trip'];
      if (trip == null) {
        return (points: <LatLng>[], legKm: <double>[], distanceKm: 0.0);
      }

      final legs = trip['legs'] as List?;
      if (legs == null || legs.isEmpty) {
        return (points: <LatLng>[], legKm: <double>[], distanceKm: 0.0);
      }

      final allPoints = <LatLng>[];
      final legKm = <double>[];
      for (final leg in legs) {
        final encoded = leg['shape'] as String?;
        if (encoded != null && encoded.isNotEmpty) {
          final decoded = decodePolyline6(encoded);
          if (allPoints.isNotEmpty && decoded.isNotEmpty) {
            if (_samePoint(allPoints.last, decoded.first)) {
              decoded.removeAt(0);
            }
          }
          allPoints.addAll(decoded);
        }
        legKm.add((leg['summary']?['length'] as num?)?.toDouble() ?? 0.0);
      }

      final distanceKm =
          (trip['summary']?['length'] as num?)?.toDouble() ?? 0.0;
      return (points: allPoints, legKm: legKm, distanceKm: distanceKm);
    } catch (e) {
      debugPrint('Valhalla multi-route error: $e');
      return (points: <LatLng>[], legKm: <double>[], distanceKm: 0.0);
    }
  }

  // ── Valhalla route (Directions) ──────────────────────────────────
  // Calculates the optimal driving route between two points.
  // Used for live tracking (technician → job site).
  // Added costing options to restrict to drivable roads only.
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
        'costing_options': <String, dynamic>{
          'auto': <String, dynamic>{
            'exclude_unpaved': true,
            'exclude_cash_only_tolls': false,
            'exclude_ferries': false,
            'service_penalty': 50.0,
            'alley_penalty': 50.0,
            'driving_side': 'right',
          },
        },
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
