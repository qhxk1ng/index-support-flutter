import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository adminRepository;

  AdminBloc({required this.adminRepository}) : super(AdminInitial()) {
    on<GetDashboardStatsEvent>(_onGetDashboardStats);
    on<GetAllComplaintsEvent>(_onGetAllComplaints);
    on<GetAllCustomersEvent>(_onGetAllCustomers);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<GetAllFieldPersonnelEvent>(_onGetAllFieldPersonnel);
    on<GetAllInstallersEvent>(_onGetAllInstallers);
    on<UpdateInstallerEvent>(_onUpdateInstaller);
  }

  Future<void> _onGetDashboardStats(
    GetDashboardStatsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await adminRepository.getDashboardStats();

    result.fold(
      (failure) => emit(AdminError(message: failure.message)),
      (stats) => emit(DashboardStatsLoaded(stats: stats)),
    );
  }

  Future<void> _onGetAllComplaints(
    GetAllComplaintsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await adminRepository.getAllComplaints();

    result.fold(
      (failure) => emit(AdminError(message: failure.message)),
      (complaints) => emit(ComplaintsLoaded(complaints: complaints)),
    );
  }

  Future<void> _onGetAllCustomers(
    GetAllCustomersEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await adminRepository.getAllCustomers(search: event.search);

    result.fold(
      (failure) => emit(AdminError(message: failure.message)),
      (customers) => emit(CustomersLoaded(customers: customers)),
    );
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await adminRepository.updateCustomer(
      id: event.id,
      name: event.name,
      phoneNumber: event.phoneNumber,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AdminError(message: failure.message)),
      (customer) => emit(CustomerUpdated(customer: customer)),
    );
  }

  Future<void> _onGetAllFieldPersonnel(
    GetAllFieldPersonnelEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await adminRepository.getAllFieldPersonnel();

    result.fold(
      (failure) => emit(AdminError(message: failure.message)),
      (personnel) => emit(FieldPersonnelLoaded(personnel: personnel)),
    );
  }

  Future<void> _onGetAllInstallers(
    GetAllInstallersEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await adminRepository.getAllInstallers(search: event.search);

    result.fold(
      (failure) => emit(AdminError(message: failure.message)),
      (installers) => emit(InstallersLoaded(installers: installers)),
    );
  }

  Future<void> _onUpdateInstaller(
    UpdateInstallerEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());

    final result = await adminRepository.updateInstaller(
      id: event.id,
      name: event.name,
      phoneNumber: event.phoneNumber,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AdminError(message: failure.message)),
      (installer) => emit(InstallerUpdated(installer: installer)),
    );
  }
}
