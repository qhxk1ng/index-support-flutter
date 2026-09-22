import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Modern fullscreen QR Code and Barcode scanner modal for Index Care.
/// Modeled directly after Index Cloud's proven scanner implementation.
/// Features a square scanner frame with animated laser guide,
/// flashlight toggle, camera switch, and manual serial entry fallback.
class BarcodeScannerModal extends StatefulWidget {
  final String title;
  final String instruction;
  final String manualLabel;
  final String manualHint;

  const BarcodeScannerModal({
    super.key,
    this.title = 'Scan Product QR / Barcode',
    this.instruction = 'Point camera at QR code or Barcode',
    this.manualLabel = 'Product Serial Number',
    this.manualHint = 'e.g. INV2501001',
  });

  /// Helper to open the scanner and return the scanned or manually entered serial string.
  static Future<String?> scan(
    BuildContext context, {
    String title = 'Scan Product QR / Barcode',
    String instruction = 'Point camera at QR code or Barcode',
    String manualLabel = 'Product Serial Number',
    String manualHint = 'e.g. INV2501001',
  }) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerModal(
          title: title,
          instruction: instruction,
          manualLabel: manualLabel,
          manualHint: manualHint,
        ),
      ),
    );
  }

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;

  bool _isScanned = false;
  bool _isTorchOn = false;
  bool _permissionGranted = false;
  bool _permissionChecked = false;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;

  static const _primaryGreen = Color(0xFF10B981);
  static const _darkGreen = Color(0xFF064E3B);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    // Check current status first without prompting
    var status = await Permission.camera.status;

    if (!status.isGranted && !status.isLimited) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    final granted = status.isGranted || status.isLimited;

    if (granted) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }

    setState(() {
      _permissionGranted = granted;
      _permissionChecked = true;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue?.trim() ?? barcode.displayValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _isScanned = true;
        HapticFeedback.mediumImpact();

        // Clean serial if wrapped in URL or prefixes
        String cleanSerial = raw;
        if (cleanSerial.contains('=')) {
          cleanSerial = cleanSerial.split('=').last;
        } else if (cleanSerial.contains('/')) {
          cleanSerial = cleanSerial.split('/').last;
        }
        cleanSerial = cleanSerial.replaceAll(RegExp(r'[\r\n\t"\x27]'), '').trim().toUpperCase();

        Navigator.pop(context, cleanSerial);
        break;
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller?.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  void _showManualEntrySheet() {
    final textController = TextEditingController();
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: const BoxDecoration(
              color: Color(0xFF131D2A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.edit_note_rounded, color: _primaryGreen, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Enter Serial Manually',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the serial number printed on the product barcode label.',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.manualLabel,
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: widget.manualHint,
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.qr_code_rounded, color: _primaryGreen),
                    filled: true,
                    fillColor: const Color(0xFF1E2A3A),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryGreen, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryGreen, width: 2),
                    ),
                  ),
                  onSubmitted: (val) {
                    final s = val.trim();
                    if (s.isNotEmpty) {
                      Navigator.pop(ctx, s.toUpperCase());
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final s = textController.text.trim();
                          if (s.isNotEmpty) {
                            Navigator.pop(ctx, s.toUpperCase());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((result) {
      if (result != null && result.isNotEmpty && mounted) {
        _isScanned = true;
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cutOutSize = screenSize.width * 0.72;

    // While requesting permission, show a loading spinner
    if (!_permissionChecked) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _primaryGreen),
        ),
      );
    }

    // Camera permission was denied — show graceful UI with action buttons
    if (!_permissionGranted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_rounded, color: _primaryGreen, size: 72),
                const SizedBox(height: 24),
                const Text(
                  'Camera Permission Required',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'To scan product QR codes and barcodes, please grant camera access in your device settings.',
                  style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _permissionChecked = false;
                      _permissionGranted = false;
                    });
                    _requestCameraPermission();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await openAppSettings();
                    if (mounted) {
                      setState(() {
                        _permissionChecked = false;
                        _permissionGranted = false;
                      });
                      _requestCameraPermission();
                    }
                  },
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open App Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A3A),
                    foregroundColor: _primaryGreen,
                    side: const BorderSide(color: _primaryGreen, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _showManualEntrySheet,
                  child: const Text('Enter Serial Manually Instead',
                      style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Flashlight Toggle
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              color: _isTorchOn ? const Color(0xFFFFC107) : Colors.white70,
              size: 24,
            ),
            tooltip: 'Flashlight',
            onPressed: _toggleTorch,
          ),
          // Camera Switch
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white70, size: 22),
            tooltip: 'Switch Camera',
            onPressed: () => _controller?.switchCamera(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Live Camera Stream
          MobileScanner(
            controller: _controller!,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFFF4444), size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Error: ${error.errorCode.name}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Could not start the camera. Try closing and reopening the scanner, or enter the serial number manually.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _showManualEntrySheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Enter Serial Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Standard Square Scanner Cutout Overlay
          CustomPaint(
            size: Size.infinite,
            painter: _CareScannerOverlayPainter(
              cutOutSize: cutOutSize,
              borderColor: _primaryGreen,
              borderRadius: 20.0,
              borderLength: 36.0,
              borderWidth: 4.5,
              overlayColor: const Color(0x99000000),
            ),
          ),

          // 3. Animated Laser Scanline inside square cutout
          AnimatedBuilder(
            animation: _laserAnimation,
            builder: (context, child) {
              final double topOffset = (screenSize.height - cutOutSize) / 2 +
                  (cutOutSize * _laserAnimation.value) -
                  AppBar().preferredSize.height;
              return Positioned(
                top: topOffset,
                width: cutOutSize - 16,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        _primaryGreen,
                        Color(0xFF6EE7B7),
                        _primaryGreen,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 4. Instructional Header above scan box
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: _primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      widget.instruction,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Controls: Flashlight & Enter Serial Manually
          Positioned(
            bottom: 36,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _toggleTorch,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isTorchOn
                              ? const Color(0xFFFFC107).withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _isTorchOn ? const Color(0xFFFFC107) : Colors.white24,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                              color: _isTorchOn ? const Color(0xFFFFC107) : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isTorchOn ? 'Flashlight: ON' : 'Flashlight: OFF',
                              style: TextStyle(
                                color: _isTorchOn ? const Color(0xFFFFC107) : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Enter Serial Manually Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _showManualEntrySheet,
                    icon: const Icon(Icons.keyboard_rounded, size: 20),
                    label: const Text(
                      'Enter Serial Manually',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2A3A),
                      foregroundColor: _primaryGreen,
                      side: const BorderSide(color: _primaryGreen, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that creates a clean square cutout with glowing corner brackets
class _CareScannerOverlayPainter extends CustomPainter {
  final double cutOutSize;
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final Color overlayColor;

  _CareScannerOverlayPainter({
    required this.cutOutSize,
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - cutOutSize) / 2;
    final double top = (size.height - cutOutSize) / 2;
    final double right = left + cutOutSize;
    final double bottom = top + cutOutSize;

    // Dark backdrop overlay with cutout
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      Radius.circular(borderRadius),
    );
    final cutoutPath = Path()..addRRect(cutoutRRect);
    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final bgPaint = Paint()..color = overlayColor;
    canvas.drawPath(combinedPath, bgPaint);

    // Subtle full border
    final thinBorderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cutoutRRect, thinBorderPaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final double arcRadius = borderRadius;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(left, top + borderLength)
      ..lineTo(left, top + arcRadius)
      ..arcToPoint(Offset(left + arcRadius, top), radius: Radius.circular(arcRadius))
      ..lineTo(left + borderLength, top);
    canvas.drawPath(tlPath, cornerPaint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(right - borderLength, top)
      ..lineTo(right - arcRadius, top)
      ..arcToPoint(Offset(right, top + arcRadius), radius: Radius.circular(arcRadius))
      ..lineTo(right, top + borderLength);
    canvas.drawPath(trPath, cornerPaint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(left, bottom - borderLength)
      ..lineTo(left, bottom - arcRadius)
      ..arcToPoint(Offset(left + arcRadius, bottom), radius: Radius.circular(arcRadius))
      ..lineTo(left + borderLength, bottom);
    canvas.drawPath(blPath, cornerPaint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(right - borderLength, bottom)
      ..lineTo(right - arcRadius, bottom)
      ..arcToPoint(Offset(right, bottom - arcRadius), radius: Radius.circular(arcRadius))
      ..lineTo(right, bottom - borderLength);
    canvas.drawPath(brPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _CareScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutOutSize != cutOutSize ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
