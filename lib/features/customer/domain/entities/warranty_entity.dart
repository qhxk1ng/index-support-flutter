import 'package:equatable/equatable.dart';

class WarrantyEntity extends Equatable {
  final String id;
  final String customerId;
  final String productId;
  final String serialNumberId;
  final DateTime registrationDate;
  final DateTime expiryDate;
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
    required this.registrationDate,
    required this.expiryDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.product,
    this.serialNumber,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  int get daysRemaining {
    final difference = expiryDate.difference(DateTime.now());
    return difference.inDays;
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        productId,
        serialNumberId,
        registrationDate,
        expiryDate,
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
  final bool isUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SerialNumberEntity({
    required this.id,
    required this.productId,
    required this.serialNumber,
    required this.isUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
        id,
        productId,
        serialNumber,
        isUsed,
        createdAt,
        updatedAt,
      ];
}
