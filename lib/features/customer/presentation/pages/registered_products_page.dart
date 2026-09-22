import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../domain/entities/warranty_entity.dart';
import '../../../../core/services/warranty_card_pdf_service.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class RegisteredProductsPage extends StatefulWidget {
  const RegisteredProductsPage({super.key});

  @override
  State<RegisteredProductsPage> createState() => _RegisteredProductsPageState();
}

class _RegisteredProductsPageState extends State<RegisteredProductsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(GetWarrantiesEvent());
  }

  Color _getWarrantyStatusColor(WarrantyEntity warranty) {
    if (!warranty.isApproved) return Colors.grey;
    if (warranty.boardWarrantyExpired && warranty.batteryWarrantyExpired) return Colors.red;
    final minDays = warranty.boardDaysRemaining < warranty.batteryDaysRemaining 
        ? warranty.boardDaysRemaining 
        : warranty.batteryDaysRemaining;
    if (minDays < 30) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Registered Products',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: ThemeToggleButton(isInAppBar: true),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CustomerBloc>().add(GetWarrantiesEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CustomerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<CustomerBloc>().add(GetWarrantiesEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is WarrantiesLoaded) {
            if (state.warranties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: isDark ? const Color(0xFF475569) : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Products Registered',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register your products to activate warranty',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<CustomerBloc>().add(GetWarrantiesEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.warranties.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(state.warranties[index]);
                },
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProductCard(WarrantyEntity warranty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getWarrantyStatusColor(warranty);
    final boardDays = warranty.boardDaysRemaining;
    final batteryDays = warranty.batteryDaysRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEA580C),
                        Color(0xFFF97316),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warranty.product?.name ?? 'Product',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warranty.product?.category ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        !warranty.isApproved
                            ? Icons.pending_outlined
                            : (warranty.boardWarrantyExpired && warranty.batteryWarrantyExpired)
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        !warranty.isApproved
                            ? 'Pending'
                            : (warranty.boardWarrantyExpired && warranty.batteryWarrantyExpired)
                                ? 'Expired'
                                : 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Serial Number:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          warranty.serialNumber?.serialNumber ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Registered:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(warranty.registrationDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!warranty.isApproved)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(isDark ? 0.4 : 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending, size: 20, color: isDark ? const Color(0xFFFBBF24) : Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        warranty.status == WarrantyStatus.correctionRequested
                            ? 'Correction Requested: ${warranty.correctionRequested}'
                            : warranty.status == WarrantyStatus.rejected
                                ? 'Rejected: ${warranty.rejectionReason}'
                                : 'Pending Admin Approval',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFFBBF24) : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (warranty.isApproved)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warranty.boardWarrantyExpired
                      ? Colors.red.withOpacity(isDark ? 0.15 : 0.1)
                      : Colors.green.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: warranty.boardWarrantyExpired
                        ? Colors.red.withOpacity(isDark ? 0.4 : 0.3)
                        : Colors.green.withOpacity(isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.memory,
                      size: 20,
                      color: warranty.boardWarrantyExpired
                          ? (isDark ? const Color(0xFFF87171) : Colors.red)
                          : (isDark ? const Color(0xFF4ADE80) : Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warranty.boardWarrantyExpired
                                ? 'Board Warranty Expired'
                                : 'Board Warranty Valid',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: warranty.boardWarrantyExpired
                                  ? (isDark ? const Color(0xFFF87171) : Colors.red)
                                  : (isDark ? const Color(0xFF4ADE80) : Colors.green),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            warranty.boardWarrantyExpired
                                ? 'Expired on ${DateFormat('MMM dd, yyyy').format(warranty.boardWarrantyExpiry!)}'
                                : boardDays > 0
                                    ? '$boardDays days remaining • Expires ${DateFormat('MMM dd, yyyy').format(warranty.boardWarrantyExpiry!)}'
                                    : 'Expires today',
                            style: TextStyle(
                              fontSize: 11,
                              color: warranty.boardWarrantyExpired
                                  ? (isDark ? const Color(0xFFFCA5A5) : Colors.red.withOpacity(0.8))
                                  : (isDark ? const Color(0xFF86EFAC) : Colors.green.withOpacity(0.8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (warranty.isApproved)
              const SizedBox(height: 8),
            if (warranty.isApproved)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warranty.batteryWarrantyExpired
                      ? Colors.red.withOpacity(isDark ? 0.15 : 0.1)
                      : Colors.green.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: warranty.batteryWarrantyExpired
                        ? Colors.red.withOpacity(isDark ? 0.4 : 0.3)
                        : Colors.green.withOpacity(isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.battery_charging_full,
                      size: 20,
                      color: warranty.batteryWarrantyExpired
                          ? (isDark ? const Color(0xFFF87171) : Colors.red)
                          : (isDark ? const Color(0xFF4ADE80) : Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warranty.batteryWarrantyExpired
                                ? 'Battery Warranty Expired'
                                : 'Battery Warranty Valid',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: warranty.batteryWarrantyExpired
                                  ? (isDark ? const Color(0xFFF87171) : Colors.red)
                                  : (isDark ? const Color(0xFF4ADE80) : Colors.green),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            warranty.batteryWarrantyExpired
                                ? 'Expired on ${DateFormat('MMM dd, yyyy').format(warranty.batteryWarrantyExpiry!)}'
                                : batteryDays > 0
                                    ? '$batteryDays days remaining • Expires ${DateFormat('MMM dd, yyyy').format(warranty.batteryWarrantyExpiry!)}'
                                    : 'Expires today',
                            style: TextStyle(
                              fontSize: 11,
                              color: warranty.batteryWarrantyExpired
                                  ? (isDark ? const Color(0xFFFCA5A5) : Colors.red.withOpacity(0.8))
                                  : (isDark ? const Color(0xFF86EFAC) : Colors.green.withOpacity(0.8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  final customerName = authState is AuthAuthenticated
                      ? authState.user.name
                      : warranty.customerName;

                  WarrantyCardPdfService.downloadOrPreview(
                    context,
                    warranty: warranty,
                    customerName: customerName,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text(
                  'Download Warranty Card',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F5597),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
