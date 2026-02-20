import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_entities.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class DashboardStatsLoaded extends AdminState {
  final DashboardStatsEntity stats;

  const DashboardStatsLoaded({required this.stats});

  @override
  List<Object> get props => [stats];
}

class ComplaintsLoaded extends AdminState {
  final List<AdminComplaintEntity> complaints;

  const ComplaintsLoaded({required this.complaints});

  @override
  List<Object> get props => [complaints];
}

class CustomersLoaded extends AdminState {
  final List<CustomerEntity> customers;

  const CustomersLoaded({required this.customers});

  @override
  List<Object> get props => [customers];
}

class CustomerUpdated extends AdminState {
  final CustomerEntity customer;

  const CustomerUpdated({required this.customer});

  @override
  List<Object> get props => [customer];
}

class FieldPersonnelLoaded extends AdminState {
  final List<FieldPersonnelEntity> personnel;

  const FieldPersonnelLoaded({required this.personnel});

  @override
  List<Object> get props => [personnel];
}

class InstallersLoaded extends AdminState {
  final List<InstallerEntity> installers;

  const InstallersLoaded({required this.installers});

  @override
  List<Object> get props => [installers];
}

class InstallerUpdated extends AdminState {
  final InstallerEntity installer;

  const InstallerUpdated({required this.installer});

  @override
  List<Object> get props => [installer];
}

class AdminError extends AdminState {
  final String message;

  const AdminError({required this.message});

  @override
  List<Object> get props => [message];
}
