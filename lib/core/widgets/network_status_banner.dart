import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';

/// Wraps any widget (typically the whole app) with a thin slide-down banner
/// that appears when the device goes offline and disappears when it comes
/// back online. Non-blocking — the rest of the UI is fully interactive.
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;
  const NetworkStatusBanner({super.key, required this.child});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  bool _online = true;
  bool _showRestored = false;

  @override
  void initState() {
    super.initState();
    _online = ConnectivityService.instance.isOnline;
    ConnectivityService.instance.onStatusChanged.listen((online) {
      if (!mounted) return;
      setState(() {
        _online = online;
        if (online) {
          _showRestored = true;
          // Hide the "restored" banner after 2.5s
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted) setState(() => _showRestored = false);
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            offset: (_online && !_showRestored) ? const Offset(0, -1) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              opacity: (_online && !_showRestored) ? 0 : 1,
              child: _BannerContent(online: _online),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerContent extends StatelessWidget {
  final bool online;
  const _BannerContent({required this.online});

  @override
  Widget build(BuildContext context) {
    final bg = online ? AppColors.success : AppColors.warning;
    final icon = online ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final text = online ? 'Back online' : 'No internet connection';

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            boxShadow: [
              BoxShadow(
                color: bg.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
