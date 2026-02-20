import 'package:equatable/equatable.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/warranty_entity.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class ComplaintRaised extends CustomerState {
  final ComplaintEntity complaint;

  const ComplaintRaised({required this.complaint});

  @override
  List<Object> get props => [complaint];
}

class ComplaintsLoaded extends CustomerState {
  final List<ComplaintEntity> complaints;

  const ComplaintsLoaded({required this.complaints});

  @override
  List<Object> get props => [complaints];
}

class ComplaintDetailsLoaded extends CustomerState {
  final ComplaintEntity complaint;

  const ComplaintDetailsLoaded({required this.complaint});

  @override
  List<Object> get props => [complaint];
}

class WarrantyRegistered extends CustomerState {
  final WarrantyEntity warranty;

  const WarrantyRegistered({required this.warranty});

  @override
  List<Object> get props => [warranty];
}

class WarrantiesLoaded extends CustomerState {
  final List<WarrantyEntity> warranties;

  const WarrantiesLoaded({required this.warranties});

  @override
  List<Object> get props => [warranties];
}

class ProductsLoaded extends CustomerState {
  final List<ProductEntity> products;

  const ProductsLoaded({required this.products});

  @override
  List<Object> get props => [products];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError({required this.message});

  @override
  List<Object> get props => [message];
}
