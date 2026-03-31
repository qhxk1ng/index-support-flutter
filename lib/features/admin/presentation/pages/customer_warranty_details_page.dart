import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/config/app_config.dart';

class CustomerWarrantyDetailsPage extends StatelessWidget {
  final String customerId;
  final String customerName;
  final String phoneNumber;

  const CustomerWarrantyDetailsPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Warranty Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info Card
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  phoneNumber,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow('Customer ID', customerId),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Registered Products Section
            const Text(
              'Registered Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            
            // TODO: Fetch and display actual warranty data from API
            _buildWarrantyCard(
              productName: 'Solar Panel 500W',
              serialNumber: 'SP500-2024-001',
              status: 'APPROVED',
              registrationDate: DateTime.now().subtract(const Duration(days: 30)),
              invoiceUrl: '/uploads/invoices/sample-invoice.jpg',
              manufacturingMonth: 1,
              manufacturingYear: 2024,
              boardWarrantyExpiry: DateTime.now().add(const Duration(days: 1065)),
              batteryWarrantyExpiry: DateTime.now().add(const Duration(days: 1795)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyCard({
    required String productName,
    required String serialNumber,
    required String status,
    required DateTime registrationDate,
    required String invoiceUrl,
    required int manufacturingMonth,
    required int manufacturingYear,
    required DateTime boardWarrantyExpiry,
    required DateTime batteryWarrantyExpiry,
  }) {
    final statusColor = status == 'APPROVED'
        ? Colors.green
        : status == 'PENDING'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.qr_code, 'Serial Number', serialNumber),
          _buildDetailRow(Icons.calendar_today, 'Registered', 
              '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}'),
          _buildDetailRow(Icons.factory, 'Manufacturing', 
              '$manufacturingMonth/$manufacturingYear'),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Invoice Image
          const Text(
            'Invoice/Bill',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                // Show full-screen invoice image
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenImage(
                      imageUrl: '${AppConfig.baseUrl}$invoiceUrl',
                      title: 'Invoice',
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: '${AppConfig.baseUrl}$invoiceUrl',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Warranty Status
          const Text(
            'Warranty Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildWarrantyStatusCard(
                  'Board Warranty',
                  boardWarrantyExpiry,
                  Icons.memory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWarrantyStatusCard(
                  'Battery Warranty',
                  batteryWarrantyExpiry,
                  Icons.battery_charging_full,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyStatusCard(String title, DateTime expiryDate, IconData icon) {
    final isExpired = expiryDate.isBefore(DateTime.now());
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isExpired ? Colors.red : Colors.green),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isExpired
                ? 'Expired'
                : '$daysRemaining days left',
            style: TextStyle(
              fontSize: 11,
              color: isExpired ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImage({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
