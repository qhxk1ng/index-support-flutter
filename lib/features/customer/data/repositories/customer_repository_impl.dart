import 'package:dartz/dartz.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/complaint_entity.dart';
import '../../domain/entities/warranty_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';
import '../models/warranty_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ComplaintEntity>> raiseComplaint({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    required List<String> images,
  }) async {
    try {
      final result = await remoteDataSource.raiseComplaint(
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
        images: images,
      );
      return Right(result);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ComplaintEntity>>> getComplaints() async {
    try {
      final result = await remoteDataSource.getComplaints();
      return Right(result);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, ComplaintEntity>> getComplaintDetails(String id) async {
    try {
      final result = await remoteDataSource.getComplaintDetails(id);
      return Right(result);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, ProductModel>> validateSerial(String serialNumber) async {
    try {
      final result = await remoteDataSource.validateSerial(serialNumber);
      return Right(result);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, WarrantyEntity>> registerWarranty({
    required String serialNumber,
    required int manufacturingMonth,
    required int manufacturingYear,
    DateTime? purchaseDate,
    required String invoiceUrl,
  }) async {
    try {
      final result = await remoteDataSource.registerWarranty(
        serialNumber: serialNumber,
        manufacturingMonth: manufacturingMonth,
        manufacturingYear: manufacturingYear,
        purchaseDate: purchaseDate,
        invoiceUrl: invoiceUrl,
      );
      return Right(result);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<WarrantyEntity>>> getWarranties() async {
    try {
      final result = await remoteDataSource.getWarranties();
      return Right(result);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    try {
      final result = await remoteDataSource.getProducts();
      return Right(result);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
