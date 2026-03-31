import 'package:equatable/equatable.dart';

abstract class SalesPersonnelEvent extends Equatable {
  const SalesPersonnelEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardEvent extends SalesPersonnelEvent {}

class LoadProfileEvent extends SalesPersonnelEvent {}

class LogActivityEvent extends SalesPersonnelEvent {
  final String customerName;
  final String businessName;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String? address;
  final String? visitingCardImage;
  final List<String>? businessImages;
  final String? notes;

  const LogActivityEvent({
    required this.customerName,
    required this.businessName,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.address,
    this.visitingCardImage,
    this.businessImages,
    this.notes,
  });

  @override
  List<Object?> get props => [
        customerName,
        businessName,
        phoneNumber,
        latitude,
        longitude,
        address,
        visitingCardImage,
        businessImages,
        notes,
      ];
}

class EndActivityEvent extends SalesPersonnelEvent {
  final String activityId;
  final int timeSpent;

  const EndActivityEvent({
    required this.activityId,
    required this.timeSpent,
  });

  @override
  List<Object?> get props => [activityId, timeSpent];
}

class LoadActivitiesEvent extends SalesPersonnelEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadActivitiesEvent({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class CreateLeadEvent extends SalesPersonnelEvent {
  final String customerName;
  final String businessName;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String? address;
  final String? visitingCardImage;
  final String leadType;
  final String? notes;

  const CreateLeadEvent({
    required this.customerName,
    required this.businessName,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.address,
    this.visitingCardImage,
    required this.leadType,
    this.notes,
  });

  @override
  List<Object?> get props => [
        customerName,
        businessName,
        phoneNumber,
        latitude,
        longitude,
        address,
        visitingCardImage,
        leadType,
        notes,
      ];
}

class LoadLeadsEvent extends SalesPersonnelEvent {
  final String? status;

  const LoadLeadsEvent({this.status});

  @override
  List<Object?> get props => [status];
}

class RecordExpenseEvent extends SalesPersonnelEvent {
  final String expenseType;
  final double amount;
  final String? description;
  final List<String>? receiptImages;
  final DateTime expenseDate;

  const RecordExpenseEvent({
    required this.expenseType,
    required this.amount,
    this.description,
    this.receiptImages,
    required this.expenseDate,
  });

  @override
  List<Object?> get props => [
        expenseType,
        amount,
        description,
        receiptImages,
        expenseDate,
      ];
}

class LoadExpensesEvent extends SalesPersonnelEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadExpensesEvent({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
