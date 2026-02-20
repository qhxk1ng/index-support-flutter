import '../../../../core/network/api_client.dart';

abstract class FieldPersonnelRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<Map<String, dynamic>>> getAssignedTickets();
  Future<void> updateTicketStatus(String ticketId, String status);
}

class FieldPersonnelRemoteDataSourceImpl implements FieldPersonnelRemoteDataSource {
  final ApiClient apiClient;

  FieldPersonnelRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await apiClient.get('/field-personnel/dashboard');
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getAssignedTickets() async {
    final response = await apiClient.get('/field-personnel/assigned-tickets');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  @override
  Future<void> updateTicketStatus(String ticketId, String status) async {
    await apiClient.put('/field-personnel/ticket/$ticketId/status', data: {
      'status': status,
    });
  }
}
