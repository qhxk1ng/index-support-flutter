import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_entities.dart';

abstract class AdminRepository {
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats();
  Future<Either<Failure, List<AdminComplaintEntity>>> getAllComplaints();
  Future<Either<Failure, List<CustomerEntity>>> getAllCustomers({String? search});
  Future<Either<Failure, CustomerEntity>> updateCustomer({
    required String id,
    String? name,
    String? phoneNumber,
    String? password,
  });
  Future<Either<Failure, List<FieldPersonnelEntity>>> getAllFieldPersonnel();
  Future<Either<Failure, List<InstallerEntity>>> getAllInstallers({String? search});
  Future<Either<Failure, InstallerEntity>> updateInstaller({
    required String id,
    String? name,
    String? phoneNumber,
    String? password,
  });
}
