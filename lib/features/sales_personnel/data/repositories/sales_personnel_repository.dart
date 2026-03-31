import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/sales_personnel_entities.dart';
import '../models/sales_personnel_models.dart';

class SalesPersonnelRepository {
  final ApiClient apiClient;

  SalesPersonnelRepository({required this.apiClient});

  Future<Either<Failure, SalesPersonnelProfile>> getProfile() async {
    try {
      final response = await apiClient.get('/sales-personnel/profile');
      return Right(SalesPersonnelProfileModel.fromJson(response.data['data']));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SalesActivity>> logActivity({
    required String customerName,
    required String businessName,
    required String phoneNumber,
    required double latitude,
    required double longitude,
    String? address,
    String? visitingCardImage,
    List<String>? businessImages,
    String? notes,
  }) async {
    try {
      final response = await apiClient.post(
        '/sales-personnel/activities',
        data: {
          'customerName': customerName,
          'businessName': businessName,
          'phoneNumber': phoneNumber,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'visitingCardImage': visitingCardImage,
          'businessImages': businessImages ?? [],
          'notes': notes,
        },
      );
      return Right(SalesActivityModel.fromJson(response.data['data']));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SalesActivity>> endActivity({
    required String activityId,
    required int timeSpent,
  }) async {
    try {
      final response = await apiClient.put(
        '/sales-personnel/activities/$activityId/end',
        data: {'timeSpent': timeSpent},
      );
      return Right(SalesActivityModel.fromJson(response.data['data']));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<SalesActivity>>> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await apiClient.get(
        '/sales-personnel/activities',
        queryParameters: queryParams,
      );
      
      final data = response.data['data'];
      final activitiesList = data is Map ? data['activities'] as List : data as List;
      final activities = activitiesList
          .map((json) => SalesActivityModel.fromJson(json))
          .toList();
      return Right(activities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SalesLead>> createLead({
    required String customerName,
    required String businessName,
    required String phoneNumber,
    required double latitude,
    required double longitude,
    String? address,
    String? visitingCardImage,
    required String leadType,
    String? notes,
  }) async {
    try {
      final response = await apiClient.post(
        '/sales-personnel/leads',
        data: {
          'customerName': customerName,
          'businessName': businessName,
          'phoneNumber': phoneNumber,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'visitingCardImage': visitingCardImage,
          'leadType': leadType,
          'notes': notes,
        },
      );
      return Right(SalesLeadModel.fromJson(response.data['data']));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<SalesLead>>> getLeads({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await apiClient.get(
        '/sales-personnel/leads',
        queryParameters: queryParams,
      );
      
      final data = response.data['data'];
      final leadsList = data is Map ? data['leads'] as List : data as List;
      final leads = leadsList
          .map((json) => SalesLeadModel.fromJson(json))
          .toList();
      return Right(leads);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SalesExpense>> recordExpense({
    required String expenseType,
    required double amount,
    String? description,
    List<String>? receiptImages,
    required DateTime expenseDate,
  }) async {
    try {
      final response = await apiClient.post(
        '/sales-personnel/expenses',
        data: {
          'expenseType': expenseType,
          'amount': amount,
          'description': description,
          'receiptImages': receiptImages ?? [],
          'expenseDate': expenseDate.toIso8601String(),
        },
      );
      return Right(SalesExpenseModel.fromJson(response.data['data']));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<SalesExpense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await apiClient.get(
        '/sales-personnel/expenses',
        queryParameters: queryParams,
      );
      
      final data = response.data['data'];
      final expensesList = data is Map ? data['expenses'] as List : data as List;
      final expenses = expensesList
          .map((json) => SalesExpenseModel.fromJson(json))
          .toList();
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, SalesPersonnelStats>> getDashboardStats() async {
    try {
      final response = await apiClient.get('/sales-personnel/dashboard/stats');
      return Right(SalesPersonnelStatsModel.fromJson(response.data['data']));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
