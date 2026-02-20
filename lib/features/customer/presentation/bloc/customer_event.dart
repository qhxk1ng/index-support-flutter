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

  const RaiseComplaintEvent({
    required this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.images = const [],
  });

  @override
  List<Object?> get props => [description, latitude, longitude, address, images];
}

class GetComplaintsEvent extends CustomerEvent {}

class GetComplaintDetailsEvent extends CustomerEvent {
  final String complaintId;

  const GetComplaintDetailsEvent({required this.complaintId});

  @override
  List<Object> get props => [complaintId];
}

class RegisterWarrantyEvent extends CustomerEvent {
  final String productId;
  final String serialNumber;

  const RegisterWarrantyEvent({
    required this.productId,
    required this.serialNumber,
  });

  @override
  List<Object> get props => [productId, serialNumber];
}

class GetWarrantiesEvent extends CustomerEvent {}

class GetProductsEvent extends CustomerEvent {}
