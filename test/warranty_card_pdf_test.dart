import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:index_care_app/core/services/warranty_card_pdf_service.dart';
import 'package:index_care_app/features/customer/domain/entities/warranty_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WarrantyCardPdfService Clause & Period Logic Tests', () {
    final lfInverterWarranty = WarrantyEntity(
      id: 'w1',
      customerId: 'c1',
      productId: 'p1',
      serialNumberId: 's1',
      manufacturingMonth: 5,
      manufacturingYear: 2024,
      registrationDate: DateTime(2024, 5, 15),
      invoiceUrl: 'https://example.com/inv.jpg',
      status: WarrantyStatus.approved,
      boardWarrantyExpiry: DateTime(2026, 5, 15),
      batteryWarrantyExpiry: DateTime(2029, 5, 15),
      isActive: true,
      createdAt: DateTime(2024, 5, 15),
      updatedAt: DateTime(2024, 5, 15),
      product: ProductEntity(
        id: 'p1',
        name: 'Index Solar Inverter LF Series',
        category: 'Solar Inverter',
        warrantyMonths: 60,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      serialNumber: SerialNumberEntity(
        id: 's1',
        productId: 'p1',
        serialNumber: 'SN-LF-2024-001',
        isUsed: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      customerName: 'Rahul Sharma',
    );

    final pulseBatteryWarranty = WarrantyEntity(
      id: 'w2',
      customerId: 'c2',
      productId: 'p2',
      serialNumberId: 's2',
      manufacturingMonth: 3,
      manufacturingYear: 2024,
      registrationDate: DateTime(2024, 3, 10),
      invoiceUrl: 'https://example.com/inv2.jpg',
      status: WarrantyStatus.approved,
      boardWarrantyExpiry: DateTime(2029, 3, 10),
      batteryWarrantyExpiry: DateTime(2029, 3, 10),
      isActive: true,
      createdAt: DateTime(2024, 3, 10),
      updatedAt: DateTime(2024, 3, 10),
      product: ProductEntity(
        id: 'p2',
        name: 'Index Pulse LFP Battery',
        category: 'Battery',
        warrantyMonths: 60,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      serialNumber: SerialNumberEntity(
        id: 's2',
        productId: 'p2',
        serialNumber: 'SN-PULSE-2024-089',
        isUsed: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      customerName: 'Priya Nair',
    );

    test('LF Inverter validity text matches requirements', () {
      final validity = WarrantyCardPdfService.getValidityPeriodText(lfInverterWarranty);
      expect(
        validity,
        'Warranty is applicable for 2 years on Inverter internal components and 5 years on the LFP battery',
      );

      final totalPeriod = WarrantyCardPdfService.getTotalWarrantyPeriodText(lfInverterWarranty);
      expect(totalPeriod, '2 Years (Inverter) / 5 Years (LFP Battery)');
    });

    test('Pulse Battery validity text matches requirements', () {
      final validity = WarrantyCardPdfService.getValidityPeriodText(pulseBatteryWarranty);
      expect(
        validity,
        'Warranty is applicable for 5 years on the LFP battery cells and electrical components',
      );

      final totalPeriod = WarrantyCardPdfService.getTotalWarrantyPeriodText(pulseBatteryWarranty);
      expect(totalPeriod, '5 Years (LFP Battery Cells & Electrical Components)');
    });

    test('Generates non-empty PDF bytes for LF Inverter', () async {
      final Uint8List bytes = await WarrantyCardPdfService.generateWarrantyCardPdf(
        warranty: lfInverterWarranty,
        customerName: 'Rahul Sharma',
      );
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      // PDF starts with %PDF-
      expect(bytes[0], 0x25); // '%'
      expect(bytes[1], 0x50); // 'P'
      expect(bytes[2], 0x44); // 'D'
      expect(bytes[3], 0x46); // 'F'
    });

    test('Generates non-empty PDF bytes for Pulse Battery', () async {
      final Uint8List bytes = await WarrantyCardPdfService.generateWarrantyCardPdf(
        warranty: pulseBatteryWarranty,
        customerName: 'Priya Nair',
      );
      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(bytes[0], 0x25); // '%'
      expect(bytes[1], 0x50); // 'P'
      expect(bytes[2], 0x44); // 'D'
      expect(bytes[3], 0x46); // 'F'
    });
  });
}
