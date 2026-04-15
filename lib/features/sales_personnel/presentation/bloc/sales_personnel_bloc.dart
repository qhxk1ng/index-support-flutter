import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/sales_personnel_repository.dart';
import 'sales_personnel_event.dart';
import 'sales_personnel_state.dart';

class SalesPersonnelBloc extends Bloc<SalesPersonnelEvent, SalesPersonnelState> {
  final SalesPersonnelRepository repository;

  SalesPersonnelBloc({required this.repository}) : super(SalesPersonnelInitial()) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<LoadProfileEvent>(_onLoadProfile);
    on<LogActivityEvent>(_onLogActivity);
    on<EndActivityEvent>(_onEndActivity);
    on<LoadActivitiesEvent>(_onLoadActivities);
    on<CreateLeadEvent>(_onCreateLead);
    on<LoadLeadsEvent>(_onLoadLeads);
    on<RecordExpenseEvent>(_onRecordExpense);
    on<LoadExpensesEvent>(_onLoadExpenses);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    final statsResult = await repository.getDashboardStats();
    final profileResult = await repository.getProfile();

    statsResult.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (stats) {
        profileResult.fold(
          (failure) => emit(DashboardLoaded(stats: stats)),
          (profile) => emit(DashboardLoaded(stats: stats, profile: profile)),
        );
      },
    );
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    final result = await repository.getProfile();

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onLogActivity(
    LogActivityEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    // Upload visiting card if present
    String? visitingCardUrl;
    if (event.visitingCardFile != null) {
      final uploadResult = await repository.uploadImages([event.visitingCardFile!]);
      final failed = uploadResult.fold<String?>((f) => f.toString(), (_) => null);
      if (failed != null) {
        emit(SalesPersonnelError(message: 'Failed to upload visiting card: $failed'));
        return;
      }
      visitingCardUrl = uploadResult.getOrElse(() => []).firstOrNull;
    }

    // Upload business images if present
    List<String>? businessImageUrls;
    if (event.businessImageFiles.isNotEmpty) {
      final uploadResult = await repository.uploadImages(event.businessImageFiles);
      final failed = uploadResult.fold<String?>((f) => f.toString(), (_) => null);
      if (failed != null) {
        emit(SalesPersonnelError(message: 'Failed to upload business images: $failed'));
        return;
      }
      businessImageUrls = uploadResult.getOrElse(() => []);
    }

    final result = await repository.logActivity(
      customerName: event.customerName,
      businessName: event.businessName,
      phoneNumber: event.phoneNumber,
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
      visitingCardImage: visitingCardUrl,
      businessImages: businessImageUrls,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (activity) => emit(ActivityLogged(activity: activity)),
    );
  }

  Future<void> _onEndActivity(
    EndActivityEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    final result = await repository.endActivity(
      activityId: event.activityId,
      timeSpent: event.timeSpent,
    );

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (activity) => emit(ActivityEnded(activity: activity)),
    );
  }

  Future<void> _onLoadActivities(
    LoadActivitiesEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    final result = await repository.getActivities(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (activities) => emit(ActivitiesLoaded(activities: activities)),
    );
  }

  Future<void> _onCreateLead(
    CreateLeadEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    final result = await repository.createLead(
      customerName: event.customerName,
      businessName: event.businessName,
      phoneNumber: event.phoneNumber,
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
      visitingCardImage: event.visitingCardImage,
      leadType: event.leadType,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (lead) => emit(LeadCreated(lead: lead)),
    );
  }

  Future<void> _onLoadLeads(
    LoadLeadsEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    final result = await repository.getLeads(status: event.status);

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (leads) => emit(LeadsLoaded(leads: leads)),
    );
  }

  Future<void> _onRecordExpense(
    RecordExpenseEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    // Upload receipt images if present
    List<String>? receiptUrls;
    if (event.receiptImageFiles.isNotEmpty) {
      final uploadResult = await repository.uploadImages(event.receiptImageFiles);
      final failed = uploadResult.fold<String?>((f) => f.toString(), (_) => null);
      if (failed != null) {
        emit(SalesPersonnelError(message: 'Failed to upload receipts: $failed'));
        return;
      }
      receiptUrls = uploadResult.getOrElse(() => []);
    }

    final result = await repository.recordExpense(
      expenseType: event.expenseType,
      amount: event.amount,
      description: event.description,
      receiptImages: receiptUrls,
      expenseDate: event.expenseDate,
    );

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (expense) => emit(ExpenseRecorded(expense: expense)),
    );
  }

  Future<void> _onLoadExpenses(
    LoadExpensesEvent event,
    Emitter<SalesPersonnelState> emit,
  ) async {
    emit(SalesPersonnelLoading());

    final result = await repository.getExpenses(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(SalesPersonnelError(message: failure.toString())),
      (expenses) => emit(ExpensesLoaded(expenses: expenses)),
    );
  }
}
