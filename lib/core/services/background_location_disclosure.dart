import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background_location_service.dart';

/// Handles the Google Play-compliant "prominent disclosure" flow before
/// requesting and using the user's background location.
///
/// Google Play policy requires that the user be shown a clear in-app
/// disclosure that:
///   1. Identifies the type of data being accessed (location).
///   2. Explains the data is also collected in the background.
///   3. Explains why the data is collected and how it is used.
///   4. Asks for affirmative consent (Allow / Deny) before any system
///      runtime permission prompt is shown.
///
/// The flow in [requestAndStart]:
///   - If the user previously accepted the disclosure and granted both
///     foreground + background permission, start the service silently.
///   - Otherwise show the disclosure dialog.
///   - On Allow: request foreground location → request background location
///     → start the foreground service.
///   - On Deny: do nothing; the user can re-trigger from the role dashboard.
class BackgroundLocationDisclosure {
  static const _disclosureAcceptedKey = 'background_location_disclosure_accepted';
  static const _batteryDisclosureAcceptedKey =
      'background_battery_disclosure_accepted';

  /// Entry point used by role dashboards (Field Personnel, Sales Personnel,
  /// Installer) when their UI loads. Safe to call multiple times.
  static Future<void> requestAndStart(
    BuildContext context, {
    required String roleLabel,
  }) async {
    // 1. If background permission is already granted and disclosure was
    //    previously accepted, just (re)start the service.
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_disclosureAcceptedKey) ?? false;
    final bgStatus = await Permission.locationAlways.status
        .timeout(const Duration(seconds: 3), onTimeout: () {
      debugPrint('BackgroundLocationDisclosure: locationAlways status timeout');
      return PermissionStatus.denied;
    });

    if (accepted && bgStatus.isGranted) {
      // Already through the disclosure flow once. Still re-check battery
      // optimization in case the user disabled it between sessions —
      // otherwise the foreground service will be killed in Doze mode.
      if (context.mounted) {
        await _ensureBatteryOptimizationDisabled(context, roleLabel, prefs);
      }
      await BackgroundLocationService.start();
      return;
    }

    if (!context.mounted) return;

    // 2. Show the prominent disclosure dialog.
    final userAllowed = await _showDisclosureDialog(context, roleLabel);
    if (userAllowed != true) return;

    await prefs.setBool(_disclosureAcceptedKey, true);

    if (!context.mounted) return;

    // 3. Foreground location first (required prerequisite for background).
    var fg = await Permission.locationWhenInUse.status
        .timeout(const Duration(seconds: 3), onTimeout: () {
      debugPrint('BackgroundLocationDisclosure: locationWhenInUse status timeout');
      return PermissionStatus.denied;
    });
    if (!fg.isGranted) {
      fg = await Permission.locationWhenInUse.request().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('BackgroundLocationDisclosure: locationWhenInUse request timeout');
          return PermissionStatus.denied;
        },
      );
    }
    if (!fg.isGranted) {
      if (context.mounted) {
        _showSnack(context,
            'Location permission denied. Background tracking will not start.');
      }
      return;
    }

    // 4. Make sure device location services are on.
    final servicesEnabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('BackgroundLocationDisclosure: isLocationServiceEnabled timeout');
      return false;
    });
    if (!servicesEnabled) {
      if (context.mounted) {
        _showSnack(context,
            'Please turn on Location services in your device settings.');
      }
      return;
    }

    // 5. Background ("Allow all the time") permission.
    var bg = await Permission.locationAlways.status
        .timeout(const Duration(seconds: 3), onTimeout: () {
      debugPrint('BackgroundLocationDisclosure: locationAlways status timeout (2)');
      return PermissionStatus.denied;
    });
    if (!bg.isGranted) {
      bg = await Permission.locationAlways.request().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('BackgroundLocationDisclosure: locationAlways request timeout');
          return PermissionStatus.denied;
        },
      );
    }
    if (!bg.isGranted) {
      if (context.mounted) {
        _showSnack(context,
            'Background location not granted. Please choose "Allow all the time" in Settings to enable live $roleLabel tracking.');
      }
      return;
    }

    // 6. Show our own "app runs in background" disclosure, then the system
    //    battery-optimization prompt. Without this exemption, Android Doze
    //    will suspend the foreground service after a few minutes and live
    //    tracking will silently die.
    if (context.mounted) {
      await _ensureBatteryOptimizationDisabled(context, roleLabel, prefs);
    }

    // 7. Start the foreground service.
    await BackgroundLocationService.start();
  }

  /// Shows an in-app dialog explaining that the app will keep running in the
  /// background, then triggers the system battery-optimization prompt if the
  /// user accepts. Safe to call repeatedly — if the exemption is already
  /// granted, this returns immediately.
  static Future<void> _ensureBatteryOptimizationDisabled(
    BuildContext context,
    String roleLabel,
    SharedPreferences prefs,
  ) async {
    bool ignoring = false;
    try {
      ignoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } catch (_) {}
    if (ignoring) return;
    if (!context.mounted) return;

    final accepted = await _showBatteryDisclosureDialog(context, roleLabel);
    if (accepted != true) return;

    await prefs.setBool(_batteryDisclosureAcceptedKey, true);

    try {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } catch (e) {
      debugPrint(
          'BackgroundLocationDisclosure: battery opt request failed: $e');
    }
  }

  /// In-app prompt shown right before the Android "Allow app to run in
  /// background?" system dialog. Mirrors the location disclosure styling.
  static Future<bool?> _showBatteryDisclosureDialog(
    BuildContext context,
    String roleLabel,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.battery_charging_full_rounded,
                    size: 36,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Allow Index Care to run in the background',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'To keep live $roleLabel tracking active even when your screen '
                'is off or you switch to other apps, Index Care needs to be '
                'excluded from battery optimization.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              _bullet(
                  'On the next screen Android will ask: "Allow Index Care to '
                  'run in the background?" — please tap Allow.'),
              _bullet(
                  'This only allows tracking while you are on duty. Logging '
                  'out stops it instantly.'),
              _bullet(
                  'Battery impact is minimal — we only send a location '
                  'heartbeat every 30 seconds.'),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Not now',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Allow & Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the prominent disclosure dialog. Wording follows Google Play's
  /// required template (data type, background mention, purpose, consent).
  static Future<bool?> _showDisclosureDialog(
    BuildContext context,
    String roleLabel,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    size: 36,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Center(
                child: Text(
                  'Allow background location?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Required Google-compliant disclosure paragraph.
              Text(
                'Index Care collects location data to enable live $roleLabel tracking, '
                'route recording, and accurate visit logging — even when the app is '
                'closed or not in use.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 14),

              // Bullet list - exactly what is collected, why, and with whom shared.
              _bullet('Your real-time GPS location is collected at intervals (≈ 30 s) '
                  'while you are on duty, even when the app is in the background.'),
              _bullet('Location is used only to dispatch you to the nearest customer, '
                  'record kilometres travelled, and verify on-site visits.'),
              _bullet('Data is shared only with administrators inside your '
                  'organisation. It is never sold or shared with advertisers.'),
              _bullet('A persistent notification is shown whenever tracking is active, '
                  'so you always know it is running.'),
              _bullet('You can stop tracking any time by logging out, or by revoking '
                  'permission in your device Settings.'),

              const SizedBox(height: 12),

              // Privacy policy link
              GestureDetector(
                onTap: () {
                  // Optionally open the privacy policy URL.
                },
                child: const Text(
                  'See our Privacy Policy at indexinformatics.in/privacy_policy_index_care.php',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Deny',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Allow & Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
