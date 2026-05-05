import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Global connectivity monitor. Emits `true` when the device has at least
/// one active network interface (Wi-Fi, mobile, ethernet), `false` when
/// completely offline. Consumers should subscribe to [onStatusChanged].
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<dynamic>? _sub;
  bool _isOnline = true;

  /// Current known status. Defaults to `true` until the first check resolves.
  bool get isOnline => _isOnline;

  /// Stream of online/offline transitions. Only fires when state changes.
  Stream<bool> get onStatusChanged => _controller.stream;

  /// Start listening. Safe to call multiple times.
  Future<void> start() async {
    _sub ??= _connectivity.onConnectivityChanged.listen(_handleDynamic);
    final current = await _connectivity.checkConnectivity();
    _handleDynamic(current);
  }

  Future<bool> refresh() async {
    final current = await _connectivity.checkConnectivity();
    _handleDynamic(current);
    return _isOnline;
  }

  /// Accepts either a single [ConnectivityResult] (plugin v5) or a
  /// [List<ConnectivityResult>] (plugin v6+). This keeps the service
  /// compatible across plugin versions.
  void _handleDynamic(dynamic result) {
    bool online;
    if (result is List) {
      online = result.any((r) => r != ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      online = result != ConnectivityResult.none;
    } else {
      online = true; // unknown shape — assume online rather than banner
    }
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(online);
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _controller.close();
  }
}
