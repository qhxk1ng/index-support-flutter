import 'package:equatable/equatable.dart';

enum WarrantyStatus { pending, approved, rejected, correctionRequested }

class WarrantyEntity extends Equatable {
  final String id;
  final String customerId;
  final String productId;
  final String serialNumberId;
  
  // Manufacturing & Registration
  final int manufacturingMonth;
  final int manufacturingYear;
  final DateTime registrationDate;
  final DateTime? purchaseDate;
  final String invoiceUrl;
  
  // Approval Workflow
  final WarrantyStatus status;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final String? correctionRequested;
  
  // Warranty Periods
  final DateTime? boardWarrantyExpiry;
  final DateTime? batteryWarrantyExpiry;
  
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductEntity? product;
  final SerialNumberEntity? serialNumber;

  const WarrantyEntity({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.serialNumberId,
    required this.manufacturingMonth,
    required this.manufacturingYear,
    required this.registrationDate,
    this.purchaseDate,
    required this.invoiceUrl,
    required this.status,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.correctionRequested,
    this.boardWarrantyExpiry,
    this.batteryWarrantyExpiry,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.serialNumber,
  });

  bool get isApproved => status == WarrantyStatus.approved;
  bool get isPending => status == WarrantyStatus.pending;
  bool get isRejected => status == WarrantyStatus.rejected;
  
  bool get boardWarrantyExpired => boardWarrantyExpiry != null && DateTime.now().isAfter(boardWarrantyExpiry!);
  bool get batteryWarrantyExpired => batteryWarrantyExpiry != null && DateTime.now().isAfter(batteryWarrantyExpiry!);

  int get boardDaysRemaining {
    if (boardWarrantyExpiry == null) return 0;
    final difference = boardWarrantyExpiry!.difference(DateTime.now());
    return difference.inDays > 0 ? difference.inDays : 0;
  }
  
  int get batteryDaysRemaining {
    if (batteryWarrantyExpiry == null) return 0;
    final difference = batteryWarrantyExpiry!.difference(DateTime.now());
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        productId,
        serialNumberId,
        manufacturingMonth,
        manufacturingYear,
        registrationDate,
        purchaseDate,
        invoiceUrl,
        status,
        approvedAt,
        approvedBy,
        rejectionReason,
        correctionRequested,
        boardWarrantyExpiry,
        batteryWarrantyExpiry,
        isActive,
        createdAt,
        updatedAt,
        product,
        serialNumber,
      ];
}

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String category;
  final String? description;
  final int warrantyMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.warrantyMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        description,
        warrantyMonths,
        createdAt,
        updatedAt,
      ];
}

class SerialNumberEntity extends Equatable {
  final String id;
  final String productId;
  final String serialNumber;
  final String? productName;
  final int? manufacturingMonth;
  final int? manufacturingYear;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SerialNumberEntity({
    required this.id,
    required this.productId,
    required this.serialNumber,
    this.productName,
    this.manufacturingMonth,
    this.manufacturingYear,
    required this.isUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        serialNumber,
        productName,
        manufacturingMonth,
        manufacturingYear,
        isUsed,
        createdAt,
        updatedAt,
      ];
}
