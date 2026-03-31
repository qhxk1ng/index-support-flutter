import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../domain/entities/warranty_entity.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Registered Products'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        actions: [
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
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
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
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Products Registered',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register your products to activate warranty',
                      style: TextStyle(color: Colors.grey[600]),
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
    final statusColor = _getWarrantyStatusColor(warranty);
    final boardDays = warranty.boardDaysRemaining;
    final batteryDays = warranty.batteryDaysRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEA580C),
                        const Color(0xFFF97316),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warranty.product?.category ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
                    color: statusColor.withOpacity(0.1),
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Serial Number:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          warranty.serialNumber?.serialNumber ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Registered:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(warranty.registrationDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending, size: 20, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        warranty.status == WarrantyStatus.correctionRequested
                            ? 'Correction Requested: ${warranty.correctionRequested}'
                            : warranty.status == WarrantyStatus.rejected
                                ? 'Rejected: ${warranty.rejectionReason}'
                                : 'Pending Admin Approval',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
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
                  color: warranty.boardWarrantyExpired ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: warranty.boardWarrantyExpired ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.memory, size: 20, color: warranty.boardWarrantyExpired ? Colors.red : Colors.green),
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
                              color: warranty.boardWarrantyExpired ? Colors.red : Colors.green,
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
                              color: warranty.boardWarrantyExpired ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.8),
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
                  color: warranty.batteryWarrantyExpired ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: warranty.batteryWarrantyExpired ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.battery_charging_full, size: 20, color: warranty.batteryWarrantyExpired ? Colors.red : Colors.green),
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
                              color: warranty.batteryWarrantyExpired ? Colors.red : Colors.green,
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
                              color: warranty.batteryWarrantyExpired ? Colors.red.withOpacity(0.8) : Colors.green.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
