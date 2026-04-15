import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../data/models/warranty_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';

class WarrantyRegistrationPage extends StatefulWidget {
  const WarrantyRegistrationPage({super.key});

  @override
  State<WarrantyRegistrationPage> createState() => _WarrantyRegistrationPageState();
}

class _WarrantyRegistrationPageState extends State<WarrantyRegistrationPage>
    with TickerProviderStateMixin {
  // Step 0 = choose method, 1 = scanning QR, 2 = manual entry,
  // 3 = product preview/confirm, 4 = invoice upload, 5 = success
  int _step = 0;

  final _manualController = TextEditingController();
  final _manualFormKey = GlobalKey<FormState>();

  String? _scannedSerial;
  ProductModel? _validatedProduct;
  
  // Invoice upload
  File? _invoiceImage;
  String? _uploadedInvoiceUrl;
  bool _isUploading = false;
  
  // Manufacturing and purchase dates
  int? _manufacturingMonth;
  int? _manufacturingYear;
  DateTime? _purchaseDate;
  
  final _imagePicker = ImagePicker();

  // QR
  MobileScannerController? _qrController;
  bool _qrProcessed = false;

  // Animations
  late AnimationController _successController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

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
    _fadeAnim = CurvedAnimation(parent: _successController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _manualController.dispose();
    _qrController?.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_qrProcessed) return;
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.displayValue?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      _qrProcessed = true;
      _qrController?.stop();
      _validateSerial(code);
    }
  }

  void _validateSerial(String serial) {
    setState(() => _scannedSerial = serial.trim().toUpperCase());
    context.read<CustomerBloc>().add(ValidateSerialEvent(serialNumber: serial.trim()));
  }

  void _proceedToInvoiceUpload() {
    setState(() => _step = 4);
  }
  
  Future<void> _pickInvoiceImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _invoiceImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }
  
  Future<void> _uploadInvoiceAndRegister() async {
    if (_invoiceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload invoice image')),
      );
      return;
    }
    
    if (_manufacturingMonth == null || _manufacturingYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select manufacturing date')),
      );
      return;
    }
    
    setState(() => _isUploading = true);
    
    try {
      // Upload invoice image
      final formData = FormData.fromMap({
        'invoice': await MultipartFile.fromFile(
          _invoiceImage!.path,
          filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      
      final apiClient = sl<ApiClient>();
      final response = await apiClient.post(
        ApiEndpoints.uploadInvoice,
        data: formData,
      );
      
      // Extract URL with proper null checking
      final responseData = response.data;
      if (responseData == null) {
        throw Exception('No response data received');
      }
      
      final data = responseData['data'];
      if (data == null) {
        throw Exception('No data in response');
      }
      
      final url = data['invoiceUrl'];
      if (url == null || url is! String) {
        throw Exception('Invalid or missing invoiceUrl in response');
      }
      
      _uploadedInvoiceUrl = url;
      
      // Register warranty
      if (mounted) {
        context.read<CustomerBloc>().add(
          RegisterWarrantyEvent(
            serialNumber: _scannedSerial!,
            manufacturingMonth: _manufacturingMonth!,
            manufacturingYear: _manufacturingYear!,
            purchaseDate: _purchaseDate,
            invoiceUrl: _uploadedInvoiceUrl!,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _reset() {
    _qrController?.stop();
    _qrController?.dispose();
    _qrController = null;
    _qrProcessed = false;
    _scannedSerial = null;
    _validatedProduct = null;
    _manualController.clear();
    _successController.reset();
    setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is SerialValidated) {
          setState(() {
            _validatedProduct = state.product;
            _step = 3;
          });
        } else if (state is WarrantyRegistered) {
          setState(() {
            _step = 5;
            _isUploading = false;
          });
          _successController.forward();
        } else if (state is CustomerError) {
          setState(() => _isUploading = false);
          // If scanning failed, allow re-scan
          if (_step == 1) {
            setState(() {
              _qrProcessed = false;
              _qrController?.start();
            });
          }
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _step == 5
            ? null
            : AppBar(
                title: const Text('Register Warranty'),
                centerTitle: true,
                elevation: 0,
                backgroundColor: _green,
                foregroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: _step == 0
                    ? const BackButton()
                    : IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _reset,
                      ),
              ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildChooseMethod();
      case 1:
        return _buildQRScanner();
      case 2:
        return _buildManualEntry();
      case 3:
        return _buildProductPreview();
      case 4:
        return _buildInvoiceUpload();
      case 5:
        return _buildSuccess();
      default:
        return _buildChooseMethod();
    }
  }

  // ── Step 0: Choose method ──────────────────────────────────────────────────
  Widget _buildChooseMethod() {
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
              gradient: const LinearGradient(
                colors: [_green, _greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.35),
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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'How would you like to register?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MethodCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Code',
            subtitle: 'Point your camera at the QR code on the product',
            color: const Color(0xFF6366F1),
            onTap: () => setState(() => _step = 1),
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
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The QR code and serial number are printed on the product box and the device label.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: QR Scanner ─────────────────────────────────────────────────────
  Widget _buildQRScanner() {
    _qrController ??= MobileScannerController();
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final isLoading = state is CustomerLoading;
        final cutOutSize = MediaQuery.of(context).size.width * 0.7;
        return Stack(
          key: const ValueKey('qr'),
          children: [
            MobileScanner(
              controller: _qrController!,
              onDetect: _onDetect,
            ),
            // Scan overlay
            Center(
              child: Container(
                width: cutOutSize,
                height: cutOutSize,
                decoration: BoxDecoration(
                  border: Border.all(color: _green, width: 6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // Top label
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Text(
                  'Point camera at the QR code\non your product',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            // Bottom hint
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Column(
                        children: [
                          const Text(
                            'Having trouble scanning?',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _qrController?.stop();
                              _qrController?.dispose();
                              _qrController = null;
                              setState(() => _step = 2);
                            },
                            child: const Text(
                              'Enter manually instead',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Step 2: Manual Entry ───────────────────────────────────────────────────
  Widget _buildManualEntry() {
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
                      color: const Color(0xFFEFF6FF),
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
                const Text(
                  'Enter Serial Number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find it on the product box or device label',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                // Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _manualController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
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
                      fillColor: Colors.white,
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            children: const [
                              TextSpan(text: 'Example: '),
                              TextSpan(
                                text: 'LF1500-2603-B01-49B9AC64',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
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
                              _validateSerial(_manualController.text.trim());
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
                            'Validate Serial Number',
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

  // ── Step 3: Product Preview / Confirm ──────────────────────────────────────
  Widget _buildProductPreview() {
    final product = _validatedProduct;
    if (product == null) return const SizedBox.shrink();

    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final isLoading = state is CustomerLoading;
        return SingleChildScrollView(
          key: const ValueKey('preview'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Valid badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: _green, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Serial number verified!',
                        style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Product card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_green, _greenLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.category,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Serial Number',
                      value: _scannedSerial ?? '',
                      monospace: true,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Warranty Period',
                      value: '${product.warrantyMonths} months',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Coverage Until',
                      value: _calcExpiry(product.warrantyMonths),
                      highlight: true,
                    ),
                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.info_outline,
                        label: 'Description',
                        value: product.description!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _proceedToInvoiceUpload,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Continue to Upload Invoice',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading ? null : _reset,
                child: Text(
                  'Use a different serial number',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Step 4: Invoice Upload ────────────────────────────────────────────────
  Widget _buildInvoiceUpload() {
    final currentYear = DateTime.now().year;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final isLoading = state is CustomerLoading || _isUploading;
        
        return SingleChildScrollView(
          key: const ValueKey('invoice'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Invoice & Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please upload your purchase invoice and provide manufacturing details',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              
              // Invoice Image Upload
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: _green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Invoice/Bill Image *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_invoiceImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _invoiceImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () => setState(() => _invoiceImage = null),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : () => _pickInvoiceImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : () => _pickInvoiceImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Manufacturing Date
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: _green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Manufacturing Date *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _manufacturingMonth,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(12, (i) => i + 1)
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(months[m - 1]),
                                    ))
                                .toList(),
                            onChanged: isLoading ? null : (val) => setState(() => _manufacturingMonth = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _manufacturingYear,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(10, (i) => currentYear - i)
                                .map((y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(y.toString()),
                                    ))
                                .toList(),
                            onChanged: isLoading ? null : (val) => setState(() => _manufacturingYear = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Purchase Date (Optional)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_bag, color: _green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Purchase Date (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _purchaseDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _purchaseDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _purchaseDate != null
                            ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                            : 'Select Purchase Date',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Submit Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _uploadInvoiceAndRegister,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Register Warranty',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Step 5: Success ────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return FadeTransition(
      key: const ValueKey('success'),
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
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
              const SizedBox(height: 32),
              const Text(
                'Warranty Registered!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your product is now protected.\nWarranty has been successfully activated.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              if (_validatedProduct != null) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _validatedProduct!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_validatedProduct!.warrantyMonths} months • Until ${_calcExpiry(_validatedProduct!.warrantyMonths)}',
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
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
      ),
    );
  }

  String _calcExpiry(int months) {
    final expiry = DateTime.now().add(Duration(days: months * 30));
    final months3 = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months3[expiry.month - 1]} ${expiry.day}, ${expiry.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                color: color.withOpacity(0.1),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
                  color: Colors.grey[500],
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
                  color: highlight ? const Color(0xFF059669) : const Color(0xFF1E293B),
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
