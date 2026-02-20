

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/complaint_model.dart';
import '../models/warranty_model.dart';

abstract class CustomerRemoteDataSource {
  Future<ComplaintModel> raiseComplaint({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    required List<String> images,
  });

  Future<List<ComplaintModel>> getComplaints();

  Future<ComplaintModel> getComplaintDetails(String id);

  Future<WarrantyModel> registerWarranty({
    required String productId,
    required String serialNumber,
  });

  Future<List<WarrantyModel>> getWarranties();

  Future<List<ProductModel>> getProducts();
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final ApiClient apiClient;

  CustomerRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ComplaintModel> raiseComplaint({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    required List<String> images,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.raiseComplaint,
      data: {
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'images': images,
      },
    );

    return ComplaintModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    final response = await apiClient.get(ApiEndpoints.getComplaints);

    return (response.data['data'] as List)
        .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ComplaintModel> getComplaintDetails(String id) async {
    final response = await apiClient.get(ApiEndpoints.getComplaintDetails(id));

    return ComplaintModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<WarrantyModel> registerWarranty({
    required String productId,
    required String serialNumber,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.registerWarranty,
      data: {
        'productId': productId,
        'serialNumber': serialNumber,
      },
    );

    return WarrantyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<WarrantyModel>> getWarranties() async {
    final response = await apiClient.get(ApiEndpoints.getWarranties);

    return (response.data['data'] as List)
        .map((e) => WarrantyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await apiClient.get(ApiEndpoints.getProducts);

    return (response.data['data'] as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
