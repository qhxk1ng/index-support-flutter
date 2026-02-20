import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';

abstract class AdminRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
  Future<List<AdminComplaintModel>> getAllComplaints();
  Future<List<CustomerModel>> getAllCustomers({String? search});
  Future<CustomerModel> updateCustomer({
    required String id,
    String? name,
    String? phoneNumber,
    String? password,
  });
  Future<List<FieldPersonnelModel>> getAllFieldPersonnel();
  Future<List<InstallerModel>> getAllInstallers({String? search});
  Future<InstallerModel> updateInstaller({
    required String id,
    String? name,
    String? phoneNumber,
    String? password,
  });
  Future<Map<String, dynamic>> getTechnicianLocation(String id);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    final response = await apiClient.get(ApiEndpoints.dashboard);
    return DashboardStatsModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<AdminComplaintModel>> getAllComplaints() async {
    final response = await apiClient.get(ApiEndpoints.adminComplaints);
    
    // Debug: Log the first complaint to check if images are present
    final complaintsData = response.data['data'] as List;
    if (complaintsData.isNotEmpty) {
      final firstComplaint = complaintsData[0] as Map<String, dynamic>;
      debugPrint('First complaint ID: ${firstComplaint['id']}');
      debugPrint('Images field: ${firstComplaint['images']}');
      debugPrint('Full complaint data: $firstComplaint');
    }
    
    return complaintsData
        .map((e) => AdminComplaintModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CustomerModel>> getAllCustomers({String? search}) async {
    final queryParams = search != null ? {'search': search} : null;
    final response = await apiClient.get(
      '/admin/customers',
      queryParameters: queryParams,
    );
    return (response.data['data'] as List)
        .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CustomerModel> updateCustomer({
    required String id,
    String? name,
    String? phoneNumber,
    String? password,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (password != null) data['password'] = password;

    final response = await apiClient.put('/admin/customer/$id', data: data);
    return CustomerModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<FieldPersonnelModel>> getAllFieldPersonnel() async {
    final response = await apiClient.get('/admin/field-personnel');
    return (response.data['data'] as List)
        .map((e) => FieldPersonnelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<InstallerModel>> getAllInstallers({String? search}) async {
    final queryParams = search != null ? {'search': search} : null;
    final response = await apiClient.get(
      '/admin/installers',
      queryParameters: queryParams,
    );
    return (response.data['data'] as List)
        .map((e) => InstallerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InstallerModel> updateInstaller({
    required String id,
    String? name,
    String? phoneNumber,
    String? password,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (password != null) data['password'] = password;

    final response = await apiClient.put('/admin/installer/$id', data: data);
    return InstallerModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getTechnicianLocation(String id) async {
    final response = await apiClient.get(ApiEndpoints.getTechnicianLocation(id));
    return response.data['data'] as Map<String, dynamic>;
  }
}
