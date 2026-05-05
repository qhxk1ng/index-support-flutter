import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class GetDashboardStatsEvent extends AdminEvent {}

class GetAllComplaintsEvent extends AdminEvent {}

class GetAllCustomersEvent extends AdminEvent {
  final String? search;

  const GetAllCustomersEvent({this.search});

  @override
  List<Object?> get props => [search];
}

class UpdateCustomerEvent extends AdminEvent {
  final String id;
  final String? name;
  final String? phoneNumber;
  final String? password;

  const UpdateCustomerEvent({
    required this.id,
    this.name,
    this.phoneNumber,
    this.password,
  });

  @override
  List<Object?> get props => [id, name, phoneNumber, password];
}

class GetAllFieldPersonnelEvent extends AdminEvent {}

class GetAllInstallersEvent extends AdminEvent {
  final String? search;

  const GetAllInstallersEvent({this.search});

  @override
  List<Object?> get props => [search];
}

class UpdateInstallerEvent extends AdminEvent {
  final String id;
  final String? name;
  final String? phoneNumber;
  final String? password;

  const UpdateInstallerEvent({
    required this.id,
    this.name,
    this.phoneNumber,
    this.password,
  });

  @override
  List<Object?> get props => [id, name, phoneNumber, password];
}

class GetPendingWarrantiesEvent extends AdminEvent {}

class ApproveWarrantyEvent extends AdminEvent {
  final String warrantyId;

  const ApproveWarrantyEvent({required this.warrantyId});

  @override
  List<Object?> get props => [warrantyId];
}

class RejectWarrantyEvent extends AdminEvent {
  final String warrantyId;
  final String reason;

  const RejectWarrantyEvent({
    required this.warrantyId,
    required this.reason,
  });

  @override
  List<Object?> get props => [warrantyId, reason];
}

class ReassignComplaintEvent extends AdminEvent {
  final String complaintId;
  final String technicianId;

  const ReassignComplaintEvent({
    required this.complaintId,
    required this.technicianId,
  });

  @override
  List<Object?> get props => [complaintId, technicianId];
}

class RejectComplaintEvent extends AdminEvent {
  final String complaintId;
  final String reason;

  const RejectComplaintEvent({
    required this.complaintId,
    this.reason = '',
  });

  @override
  List<Object?> get props => [complaintId, reason];
}
