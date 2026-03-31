import 'package:equatable/equatable.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class RaiseComplaintEvent extends CustomerEvent {
  final String description;
  final double latitude;
  final double longitude;
  final String? address;
  final List<String> images;
  final String? warrantyId;

  const RaiseComplaintEvent({
    required this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.images = const [],
    this.warrantyId,
  });

  @override
  List<Object?> get props => [description, latitude, longitude, address, images, warrantyId];
}

class GetComplaintsEvent extends CustomerEvent {}

class GetComplaintDetailsEvent extends CustomerEvent {
  final String complaintId;

  const GetComplaintDetailsEvent({required this.complaintId});

  @override
  List<Object> get props => [complaintId];
}

class ValidateSerialEvent extends CustomerEvent {
  final String serialNumber;

  const ValidateSerialEvent({required this.serialNumber});

  @override
  List<Object> get props => [serialNumber];
}

class RegisterWarrantyEvent extends CustomerEvent {
  final String serialNumber;
  final int manufacturingMonth;
  final int manufacturingYear;
  final DateTime? purchaseDate;
  final String invoiceUrl;

  const RegisterWarrantyEvent({
    required this.serialNumber,
    required this.manufacturingMonth,
    required this.manufacturingYear,
    this.purchaseDate,
    required this.invoiceUrl,
  });

  @override
  List<Object?> get props => [serialNumber, manufacturingMonth, manufacturingYear, purchaseDate, invoiceUrl];
}

class GetWarrantiesEvent extends CustomerEvent {}

class GetProductsEvent extends CustomerEvent {}
