import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/customer_repository.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository customerRepository;

  CustomerBloc({required this.customerRepository}) : super(CustomerInitial()) {
    on<RaiseComplaintEvent>(_onRaiseComplaint);
    on<GetComplaintsEvent>(_onGetComplaints);
    on<GetComplaintDetailsEvent>(_onGetComplaintDetails);
    on<RegisterWarrantyEvent>(_onRegisterWarranty);
    on<GetWarrantiesEvent>(_onGetWarranties);
    on<GetProductsEvent>(_onGetProducts);
  }

  Future<void> _onRaiseComplaint(
    RaiseComplaintEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    final result = await customerRepository.raiseComplaint(
      description: event.description,
      latitude: event.latitude,
      longitude: event.longitude,
      address: event.address,
      images: event.images,
    );

    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (complaint) => emit(ComplaintRaised(complaint: complaint)),
    );
  }

  Future<void> _onGetComplaints(
    GetComplaintsEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    final result = await customerRepository.getComplaints();

    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (complaints) => emit(ComplaintsLoaded(complaints: complaints)),
    );
  }

  Future<void> _onGetComplaintDetails(
    GetComplaintDetailsEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    final result = await customerRepository.getComplaintDetails(event.complaintId);

    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (complaint) => emit(ComplaintDetailsLoaded(complaint: complaint)),
    );
  }

  Future<void> _onRegisterWarranty(
    RegisterWarrantyEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    final result = await customerRepository.registerWarranty(
      productId: event.productId,
      serialNumber: event.serialNumber,
    );

    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (warranty) => emit(WarrantyRegistered(warranty: warranty)),
    );
  }

  Future<void> _onGetWarranties(
    GetWarrantiesEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    final result = await customerRepository.getWarranties();

    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (warranties) => emit(WarrantiesLoaded(warranties: warranties)),
    );
  }

  Future<void> _onGetProducts(
    GetProductsEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    final result = await customerRepository.getProducts();

    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (products) => emit(ProductsLoaded(products: products)),
    );
  }
}
