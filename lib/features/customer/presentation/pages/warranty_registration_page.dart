import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/widgets/barcode_scanner_modal.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../domain/entities/warranty_entity.dart';
import '../../data/models/warranty_model.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/theme_toggle_button.dart';

class WarrantyRegistrationPage extends StatefulWidget {
  const WarrantyRegistrationPage({super.key});

  @override
  State<WarrantyRegistrationPage> createState() => _WarrantyRegistrationPageState();
}

class _WarrantyRegistrationPageState extends State<WarrantyRegistrationPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Step 0 = choose method, 1 = scanning QR, 2 = manual entry, 5 = success (Warranty Approved)
  int _step = 0;

  final _manualController = TextEditingController();
  final _manualFormKey = GlobalKey<FormState>();

  String? _scannedSerial;
  ProductModel? _validatedProduct;
  WarrantyEntity? _registeredWarranty;

  // Animations
  late AnimationController _successController;
  late Animation<double> _scaleAnim;

  static const _green = Color(0xFF059669);
  static const _greenLight = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _manualController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _startQRScanning() async {
    final serial = await BarcodeScannerModal.scan(
      context,
      title: 'Scan Product QR / Barcode',
      instruction: 'Point camera at product QR code or Barcode',
      manualLabel: 'Product Serial Number',
      manualHint: 'e.g. INV2501001',
    );

    if (serial != null && serial.isNotEmpty && mounted) {
      _onCodeFound(serial);
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final controller = MobileScannerController();
      final capture = await controller.analyzeImage(image.path);
      await controller.dispose();
      final barcode = capture?.barcodes.firstOrNull;
      final raw = barcode?.rawValue ?? barcode?.displayValue;

      if (raw != null && raw.trim().isNotEmpty) {
        _onCodeFound(raw);
      } else {
        if (mounted) {
          AppSnackbar.showError(
            context,
            'No QR code detected in the selected image. Please try another image or enter the serial manually.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to scan image: $e');
      }
    }
  }


  void _onCodeFound(String raw) {
    HapticFeedback.mediumImpact();
    // Clean serial if wrapped in URL or parameter prefix
    String cleanSerial = raw.trim();
    if (cleanSerial.contains('=')) {
      cleanSerial = cleanSerial.split('=').last;
    } else if (cleanSerial.contains('/')) {
      cleanSerial = cleanSerial.split('/').last;
    }
    cleanSerial = cleanSerial.replaceAll(RegExp(r'[\r\n\t"\x27]'), '').trim().toUpperCase();

    _registerWarrantyDirectly(cleanSerial);
  }

  void _registerWarrantyDirectly(String serial) {
    final cleanSerial = serial.trim().toUpperCase();
    setState(() => _scannedSerial = cleanSerial);
    context.read<CustomerBloc>().add(
      RegisterWarrantyEvent(serialNumber: cleanSerial),
    );
  }

  void _showInvalidQrDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.red,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Invalid QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _reset();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _startQRScanning();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Scan Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    _scannedSerial = null;
    _validatedProduct = null;
    _registeredWarranty = null;
    _manualController.clear();
    _successController.reset();
    setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is WarrantyRegistered) {
          setState(() {
            _registeredWarranty = state.warranty;
            if (state.warranty.product is ProductModel) {
              _validatedProduct = state.warranty.product as ProductModel;
            }
            _step = 5;
          });
          _successController.forward();
        } else if (state is CustomerError) {
          final msgLower = state.message.toLowerCase();
          final isQrIssue = _step == 1 ||
              msgLower.contains('invalid qr') ||
              msgLower.contains('tagged as sold') ||
              msgLower.contains('not recognized');

          if (isQrIssue) {
            _showInvalidQrDialog(state.message);
          } else {
            AppSnackbar.showError(context, state.message);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_step == 5 ? 'Warranty Approved' : 'Register Warranty'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : _green,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_step == 5)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, true),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: ThemeToggleButton(isInAppBar: true),
              ),
          ],
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: _step == 0
              ? const BackButton()
              : (_step == 5
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _reset,
                    )),
          automaticallyImplyLeading: _step != 5,
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildChooseMethod();
      case 2:
        return _buildManualEntry();
      case 5:
        return _buildSuccess();
      default:
        return _buildChooseMethod();
    }
  }

  // ── Step 0: Choose method ──────────────────────────────────────────────────
  Widget _buildChooseMethod() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      key: const ValueKey('choose'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                    : [_green, _greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : _green.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Register Your Product',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Activate warranty protection for your device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'How would you like to register?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MethodCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Code',
            subtitle: 'Point your camera at the QR code on the product',
            color: const Color(0xFF6366F1),
            onTap: _startQRScanning,
          ),
          const SizedBox(height: 12),
          _MethodCard(
            icon: Icons.photo_library_outlined,
            title: 'Scan from Gallery Photo',
            subtitle: 'Upload a picture of the QR code from your gallery',
            color: const Color(0xFF10B981),
            onTap: _scanFromGallery,
          ),
          const SizedBox(height: 12),
          _MethodCard(
            icon: Icons.keyboard_alt_outlined,
            title: 'Enter Details Manually',
            subtitle: 'Type in the serial number from the product label',
            color: const Color(0xFF0EA5E9),
            onTap: () => setState(() => _step = 2),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF064E3B).withOpacity(0.2)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF059669).withOpacity(0.4)
                    : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The QR code and serial number are printed on the product box and the device label.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFD1FAE5) : Colors.grey[700],
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

  // ── Step 2: Manual Entry ───────────────────────────────────────────────────
  Widget _buildManualEntry() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final isLoading = state is CustomerLoading;
        return SingleChildScrollView(
          key: const ValueKey('manual'),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _manualFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Illustration
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0EA5E9).withOpacity(0.15)
                          : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withOpacity(0.15),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 64,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Enter Serial Number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find it on the product box or device label',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                // Input
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _manualController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Serial Number',
                      hintText: 'e.g. LF1500-2603-B01-49B9AC64',
                      prefixIcon: const Icon(Icons.tag_rounded, color: _green),
                      suffixIcon: _manualController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _manualController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A).withOpacity(0.5)
                          : Colors.white,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter serial number';
                      if (v.trim().length < 6) return 'Serial number too short';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Example
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withOpacity(0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700],
                            ),
                            children: [
                              const TextSpan(text: 'Example: '),
                              TextSpan(
                                text: 'LF1500-2603-B01-49B9AC64',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_manualFormKey.currentState!.validate()) {
                              _registerWarrantyDirectly(_manualController.text.trim());
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Register & Activate Warranty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Step 5: Success (Warranty Approved) ───────────────────────────────────
  Widget _buildSuccess() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = _registeredWarranty?.product ?? _validatedProduct;
    final productName = product?.name ?? 'Registered Product';
    final productCategory = product?.category ?? '';
    final serial = _scannedSerial ?? _registeredWarranty?.serialNumber?.serialNumber ?? '';
    
    String expiryText = '';
    if (_registeredWarranty?.boardWarrantyExpiry != null) {
      final exp = _registeredWarranty!.boardWarrantyExpiry!;
      final months3 = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      expiryText = '${months3[exp.month - 1]} ${exp.day}, ${exp.year}';
    } else if (product != null) {
      expiryText = _calcExpiry(product.warrantyMonths);
    }

    return Center(
      key: const ValueKey('success'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_green, _greenLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Warranty Approved!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your product warranty is approved and active immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Approved Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: _green, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'STATUS: APPROVED',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF059669).withOpacity(0.4)
                      : const Color(0xFFBBF7D0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (productCategory.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      productCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 14),
                  if (serial.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Serial Number',
                      value: serial,
                      monospace: true,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (expiryText.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Coverage Until',
                      value: expiryText,
                      highlight: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _reset,
              child: const Text(
                'Register another product',
                style: TextStyle(color: _green, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calcExpiry(int months) {
    final expiry = DateTime.now().add(Duration(days: months * 30));
    final months3 = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months3[expiry.month - 1]} ${expiry.day}, ${expiry.year}';
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? const Color(0xFF64748B) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF059669)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: highlight
                      ? const Color(0xFF059669)
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  fontFamily: monospace ? 'monospace' : null,
                  letterSpacing: monospace ? 0.5 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
