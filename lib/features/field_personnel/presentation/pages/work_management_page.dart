import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';

/// Page for managing work on a specific complaint ticket.
/// Handles: QR scan / manual start → log parts replaced → end work.
class WorkManagementPage extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const WorkManagementPage({super.key, required this.ticket});

  @override
  State<WorkManagementPage> createState() => _WorkManagementPageState();
}

class _WorkManagementPageState extends State<WorkManagementPage> {
  bool _isLoading = false;
  bool _workStarted = false;
  bool _workEnded = false;
  String? _workStartMethod;
  String? _verifiedSerial;
  List<Map<String, dynamic>> _workLogs = [];
  List<Map<String, dynamic>> _partsReplaced = [];

  @override
  void initState() {
    super.initState();
    _workStarted = widget.ticket['workStartedAt'] != null;
    _workEnded = widget.ticket['workEndedAt'] != null;
    if (_workStarted) _loadWorkLogs();
  }

  Future<void> _loadWorkLogs() async {
    try {
      final api = sl<ApiClient>();
      final res = await api.get('/complaints/${widget.ticket['id']}/work-logs');
      if (mounted) {
        setState(() {
          _workLogs = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
          _partsReplaced = _workLogs.where((l) => l['action'] == 'PART_REPLACED').toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading work logs: $e');
    }
  }

  // ─── QR Scan Method ──────────────────────────────────────────────────────
  Future<void> _startWorkWithQR() async {
    final scannedSerial = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QRScanPage()),
    );
    if (scannedSerial != null && scannedSerial.isNotEmpty && mounted) {
      await _submitStartWork('QR_SCAN', serialNumber: scannedSerial);
    }
  }

  // ─── Manual Serial Entry ─────────────────────────────────────────────────
  Future<void> _startWorkWithManualSerial() async {
    final controller = TextEditingController();
    final serial = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter Serial Number', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'e.g. IDX-2024-00001',
            prefixIcon: const Icon(Icons.pin),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Verify & Start'),
          ),
        ],
      ),
    );
    if (serial != null && serial.isNotEmpty && mounted) {
      await _submitStartWork('MANUAL_SERIAL', serialNumber: serial);
    }
  }

  // ─── Photo Verify Method (no QR / no serial) ────────────────────────────
  Future<void> _startWorkWithPhoto() async {
    final picker = ImagePicker();
    final List<File> photos = [];
    bool done = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Photo Verification', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Take a photo of the product (name plate, label, or full unit) to verify.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...photos.map((img) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(img, width: 70, height: 70, fit: BoxFit.cover),
                      )),
                  GestureDetector(
                    onTap: () async {
                      final picked = await picker.pickImage(source: ImageSource.camera);
                      if (picked != null) setDState(() => photos.add(File(picked.path)));
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: photos.isEmpty
                  ? null
                  : () {
                      done = true;
                      Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Work'),
            ),
          ],
        ),
      ),
    );

    if (done && photos.isNotEmpty && mounted) {
      // Upload photos first
      try {
        setState(() => _isLoading = true);
        final api = sl<ApiClient>();
        final formData = FormData();
        for (final img in photos) {
          formData.files.add(MapEntry('images', await MultipartFile.fromFile(img.path)));
        }
        final uploadRes = await api.uploadFile('/upload/images', formData);
        final urls = List<String>.from(uploadRes.data['data'] ?? []);
        await _submitStartWork('PHOTO_VERIFY', images: urls);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ─── Submit Start Work ───────────────────────────────────────────────────
  Future<void> _submitStartWork(String method, {String? serialNumber, List<String>? images}) async {
    setState(() => _isLoading = true);
    try {
      final api = sl<ApiClient>();
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await api.post('/complaints/${widget.ticket['id']}/start-work', data: {
        'method': method,
        if (serialNumber != null) 'serialNumber': serialNumber,
        if (images != null) 'images': images,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      if (mounted) {
        setState(() {
          _workStarted = true;
          _workStartMethod = method;
          _verifiedSerial = serialNumber;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work started!'), backgroundColor: Color(0xFF10B981)),
        );
        _loadWorkLogs();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Log Part Replaced ───────────────────────────────────────────────────
  Future<void> _showLogPartDialog() async {
    final partNameCtrl = TextEditingController();
    final oldSerialCtrl = TextEditingController();
    final newSerialCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Part Replacement', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: partNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Part Name *',
                  hintText: 'e.g. Board, Battery, Motor',
                  prefixIcon: const Icon(Icons.build),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: oldSerialCtrl,
                decoration: InputDecoration(
                  labelText: 'Old Part Serial (optional)',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newSerialCtrl,
                decoration: InputDecoration(
                  labelText: 'New Part Serial (optional)',
                  prefixIcon: const Icon(Icons.qr_code_2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (partNameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Part name is required')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Part'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final api = sl<ApiClient>();
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await api.post('/complaints/${widget.ticket['id']}/log-part', data: {
          'partName': partNameCtrl.text.trim(),
          'oldPartSerial': oldSerialCtrl.text.trim().isNotEmpty ? oldSerialCtrl.text.trim() : null,
          'newPartSerial': newSerialCtrl.text.trim().isNotEmpty ? newSerialCtrl.text.trim() : null,
          'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${partNameCtrl.text.trim()}" replacement logged'), backgroundColor: const Color(0xFF10B981)),
          );
          _loadWorkLogs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ─── End Work ────────────────────────────────────────────────────────────
  Future<void> _endWork() async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Work', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_partsReplaced.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_partsReplaced.length} part(s) replaced:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    ..._partsReplaced.map((p) => Text('• ${p['partName']}', style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Completion Notes',
                hintText: 'Summary of work done...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Work'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final api = sl<ApiClient>();
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await api.post('/complaints/${widget.ticket['id']}/end-work', data: {
          'notes': notesCtrl.text.trim(),
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        if (mounted) {
          setState(() {
            _workEnded = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work ended!'), backgroundColor: Color(0xFF10B981)),
          );
          _loadWorkLogs();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Ticket #${widget.ticket['ticketNumber'] ?? ''}'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTicketInfo(),
                  const SizedBox(height: 20),
                  if (!_workStarted) _buildStartWorkSection(),
                  if (_workStarted && !_workEnded) _buildActiveWorkSection(),
                  if (_workEnded) _buildWorkCompletedSection(),
                  if (_workLogs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildWorkLogTimeline(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTicketInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.assignment, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.ticket['customerName'] ?? 'Customer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.ticket['customerPhone'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.ticket['issueDescription'] ?? widget.ticket['description'] ?? 'No description',
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          if (widget.ticket['customerAddress'] != null || widget.ticket['address'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(widget.ticket['customerAddress'] ?? widget.ticket['address'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Start Work Section (before work starts) ────────────────────────────
  Widget _buildStartWorkSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Start Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Verify the product to begin work', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),

          // Primary: QR Scan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startWorkWithQR,
              icon: const Icon(Icons.qr_code_scanner, size: 22),
              label: const Text('Scan Product QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 12),

          // Alternative: Manual serial
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startWorkWithManualSerial,
              icon: const Icon(Icons.keyboard, size: 20),
              label: const Text('Enter Serial Number Manually'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Alternative: Photo verify (no QR on product)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startWorkWithPhoto,
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('No QR? Take Product Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Active Work Section (work in progress) ─────────────────────────────
  Widget _buildActiveWorkSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.engineering, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Work In Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    Text(
                      _verifiedSerial != null
                          ? 'Serial: $_verifiedSerial (${_workStartMethod ?? ""})'
                          : 'Log any parts you replace',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_partsReplaced.isNotEmpty) ...[
            ...(_partsReplaced.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, size: 18, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['partName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (p['oldPartSerial'] != null || p['newPartSerial'] != null)
                              Text(
                                '${p['oldPartSerial'] ?? '?'} → ${p['newPartSerial'] ?? '?'}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))),
            const SizedBox(height: 8),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLogPartDialog,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Log Part Replacement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _endWork,
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('End Work'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Work Completed Section ──────────────────────────────────────────────
  Widget _buildWorkCompletedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Work Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                if (_partsReplaced.isNotEmpty)
                  Text('${_partsReplaced.length} part(s) replaced', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Work Log Timeline ───────────────────────────────────────────────────
  Widget _buildWorkLogTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Work Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._workLogs.asMap().entries.map((entry) {
            final log = entry.value;
            final isLast = entry.key == _workLogs.length - 1;
            final action = log['action'] ?? '';
            IconData icon;
            Color color;
            switch (action) {
              case 'WORK_STARTED':
                icon = Icons.play_circle;
                color = const Color(0xFF10B981);
                break;
              case 'PART_REPLACED':
                icon = Icons.swap_horiz;
                color = const Color(0xFF3B82F6);
                break;
              case 'WORK_ENDED':
                icon = Icons.stop_circle;
                color = const Color(0xFF8B5CF6);
                break;
              default:
                icon = Icons.circle;
                color = Colors.grey;
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(icon, color: color, size: 22),
                      if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey[200])),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.replaceAll('_', ' '),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color),
                          ),
                          if (log['partName'] != null)
                            Text('Part: ${log['partName']}', style: const TextStyle(fontSize: 12)),
                          if (log['notes'] != null)
                            Text(log['notes'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── QR Scanner Page ───────────────────────────────────────────────────────
class _QRScanPage extends StatefulWidget {
  const _QRScanPage();

  @override
  State<_QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<_QRScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product QR'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_hasScanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _hasScanned = true;
                Navigator.pop(context, barcode!.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF10B981), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at the product QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.5))]),
            ),
          ),
        ],
      ),
    );
  }
}
