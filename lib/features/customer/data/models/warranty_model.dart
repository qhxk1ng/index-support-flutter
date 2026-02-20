import '../../domain/entities/warranty_entity.dart';

class WarrantyModel extends WarrantyEntity {
  const WarrantyModel({
    required super.id,
    required super.customerId,
    required super.productId,
    required super.serialNumberId,
    required super.registrationDate,
    required super.expiryDate,
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
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'productId': productId,
      'serialNumberId': serialNumberId,
      'registrationDate': registrationDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
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
    required super.isUsed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SerialNumberModel.fromJson(Map<String, dynamic> json) {
    return SerialNumberModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      serialNumber: json['serialNumber'] as String,
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
      'isUsed': isUsed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
