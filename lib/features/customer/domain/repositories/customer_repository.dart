import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/complaint_entity.dart';
import '../entities/warranty_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, ComplaintEntity>> raiseComplaint({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    required List<String> images,
  });

  Future<Either<Failure, List<ComplaintEntity>>> getComplaints();

  Future<Either<Failure, ComplaintEntity>> getComplaintDetails(String id);

  Future<Either<Failure, WarrantyEntity>> registerWarranty({
    required String productId,
    required String serialNumber,
  });

  Future<Either<Failure, List<WarrantyEntity>>> getWarranties();

  Future<Either<Failure, List<ProductEntity>>> getProducts();
}
