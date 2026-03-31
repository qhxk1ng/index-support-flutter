import 'package:equatable/equatable.dart';
import '../../domain/entities/sales_personnel_entities.dart';

abstract class SalesPersonnelState extends Equatable {
  const SalesPersonnelState();

  @override
  List<Object?> get props => [];
}

class SalesPersonnelInitial extends SalesPersonnelState {}

class SalesPersonnelLoading extends SalesPersonnelState {}

class SalesPersonnelError extends SalesPersonnelState {
  final String message;

  const SalesPersonnelError({required this.message});

  @override
  List<Object?> get props => [message];
}

class DashboardLoaded extends SalesPersonnelState {
  final SalesPersonnelStats stats;
  final SalesPersonnelProfile? profile;

  const DashboardLoaded({
    required this.stats,
    this.profile,
  });

  @override
  List<Object?> get props => [stats, profile];
}

class ProfileLoaded extends SalesPersonnelState {
  final SalesPersonnelProfile profile;

  const ProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ActivityLogged extends SalesPersonnelState {
  final SalesActivity activity;

  const ActivityLogged({required this.activity});

  @override
  List<Object?> get props => [activity];
}

class ActivityEnded extends SalesPersonnelState {
  final SalesActivity activity;

  const ActivityEnded({required this.activity});

  @override
  List<Object?> get props => [activity];
}

class ActivitiesLoaded extends SalesPersonnelState {
  final List<SalesActivity> activities;

  const ActivitiesLoaded({required this.activities});

  @override
  List<Object?> get props => [activities];
}

class LeadCreated extends SalesPersonnelState {
  final SalesLead lead;

  const LeadCreated({required this.lead});

  @override
  List<Object?> get props => [lead];
}

class LeadsLoaded extends SalesPersonnelState {
  final List<SalesLead> leads;

  const LeadsLoaded({required this.leads});

  @override
  List<Object?> get props => [leads];
}

class ExpenseRecorded extends SalesPersonnelState {
  final SalesExpense expense;

  const ExpenseRecorded({required this.expense});

  @override
  List<Object?> get props => [expense];
}

class ExpensesLoaded extends SalesPersonnelState {
  final List<SalesExpense> expenses;

  const ExpensesLoaded({required this.expenses});

  @override
  List<Object?> get props => [expenses];
}
