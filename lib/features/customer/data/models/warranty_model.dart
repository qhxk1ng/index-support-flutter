import '../../domain/entities/warranty_entity.dart';

class WarrantyModel extends WarrantyEntity {
  const WarrantyModel({
    required super.id,
    required super.customerId,
    required super.productId,
    required super.serialNumberId,
    required super.manufacturingMonth,
    required super.manufacturingYear,
    required super.registrationDate,
    super.purchaseDate,
    required super.invoiceUrl,
    required super.status,
    super.approvedAt,
    super.approvedBy,
    super.rejectionReason,
    super.correctionRequested,
    super.boardWarrantyExpiry,
    super.batteryWarrantyExpiry,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.product,
    super.serialNumber,
  });

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    return WarrantyModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      productId: json['productId'] as String,
      serialNumberId: json['serialNumberId'] as String,
      manufacturingMonth: json['manufacturingMonth'] as int,
      manufacturingYear: json['manufacturingYear'] as int,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate'] as String) : null,
      invoiceUrl: json['invoiceUrl'] as String,
      status: _parseWarrantyStatus(json['status'] as String),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
      approvedBy: json['approvedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      correctionRequested: json['correctionRequested'] as String?,
      boardWarrantyExpiry: json['boardWarrantyExpiry'] != null ? DateTime.parse(json['boardWarrantyExpiry'] as String) : null,
      batteryWarrantyExpiry: json['batteryWarrantyExpiry'] != null ? DateTime.parse(json['batteryWarrantyExpiry'] as String) : null,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      serialNumber: json['serialNumber'] != null
          ? SerialNumberModel.fromJson(json['serialNumber'] as Map<String, dynamic>)
          : null,
    );
  }

  static WarrantyStatus _parseWarrantyStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return WarrantyStatus.pending;
      case 'APPROVED':
        return WarrantyStatus.approved;
      case 'REJECTED':
        return WarrantyStatus.rejected;
      case 'CORRECTION_REQUESTED':
        return WarrantyStatus.correctionRequested;
      default:
        return WarrantyStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'productId': productId,
      'serialNumberId': serialNumberId,
      'manufacturingMonth': manufacturingMonth,
      'manufacturingYear': manufacturingYear,
      'registrationDate': registrationDate.toIso8601String(),
      'purchaseDate': purchaseDate?.toIso8601String(),
      'invoiceUrl': invoiceUrl,
      'status': status.name.toUpperCase(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'correctionRequested': correctionRequested,
      'boardWarrantyExpiry': boardWarrantyExpiry?.toIso8601String(),
      'batteryWarrantyExpiry': batteryWarrantyExpiry?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.category,
    super.description,
    required super.warrantyMonths,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      warrantyMonths: json['warrantyMonths'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'warrantyMonths': warrantyMonths,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class SerialNumberModel extends SerialNumberEntity {
  const SerialNumberModel({
    required super.id,
    required super.productId,
    required super.serialNumber,
    super.productName,
    super.manufacturingMonth,
    super.manufacturingYear,
    required super.isUsed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SerialNumberModel.fromJson(Map<String, dynamic> json) {
    return SerialNumberModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      serialNumber: json['serialNumber'] as String,
      productName: json['productName'] as String?,
      manufacturingMonth: json['manufacturingMonth'] as int?,
      manufacturingYear: json['manufacturingYear'] as int?,
      isUsed: json['isUsed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'serialNumber': serialNumber,
      'productName': productName,
      'manufacturingMonth': manufacturingMonth,
      'manufacturingYear': manufacturingYear,
      'isUsed': isUsed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
