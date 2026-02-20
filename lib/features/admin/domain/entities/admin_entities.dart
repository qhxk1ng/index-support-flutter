import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final bool isVerified;
  final DateTime createdAt;
  final CustomerProfileEntity? customerProfile;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.isVerified,
    required this.createdAt,
    this.customerProfile,
  });

  @override
  List<Object?> get props => [id, name, phoneNumber, email, isVerified, createdAt, customerProfile];
}

class CustomerProfileEntity extends Equatable {
  final double? latitude;
  final double? longitude;
  final String? address;

  const CustomerProfileEntity({
    this.latitude,
    this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class FieldPersonnelEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final double? latitude;
  final double? longitude;
  final double? totalKmTraveled;
  final bool isActive;
  final DateTime? lastActive;
  final double? currentLatitude;
  final double? currentLongitude;

  const FieldPersonnelEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.latitude,
    this.longitude,
    this.totalKmTraveled,
    required this.isActive,
    this.lastActive,
    this.currentLatitude,
    this.currentLongitude,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        email,
        latitude,
        longitude,
        totalKmTraveled,
        isActive,
        lastActive,
        currentLatitude,
        currentLongitude,
      ];
}

class InstallerEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final bool isVerified;
  final DateTime createdAt;
  final InstallerProfileEntity? installerProfile;
  final bool hasActiveTask;

  const InstallerEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.isVerified,
    required this.createdAt,
    this.installerProfile,
    required this.hasActiveTask,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phoneNumber,
        email,
        isVerified,
        createdAt,
        installerProfile,
        hasActiveTask,
      ];
}

class InstallerProfileEntity extends Equatable {
  final double? latitude;
  final double? longitude;
  final String? address;

  const InstallerProfileEntity({
    this.latitude,
    this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class AdminComplaintEntity extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String description;
  final double latitude;
  final double longitude;
  final String? address;
  final List<String>? images;
  final String status;
  final String? technicianId;
  final String? technicianName;
  final bool journeyStarted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminComplaintEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.images,
    required this.status,
    this.technicianId,
    this.technicianName,
    required this.journeyStarted,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        customerPhone,
        description,
        latitude,
        longitude,
        address,
        images,
        status,
        technicianId,
        technicianName,
        journeyStarted,
        createdAt,
        updatedAt,
      ];
}

class DashboardStatsEntity extends Equatable {
  final int totalCustomers;
  final int totalWarranties;
  final int totalComplaints;
  final int completedComplaints;
  final int totalInstallers;
  final int totalFieldPersonnel;
  final int pendingApprovals;

  const DashboardStatsEntity({
    required this.totalCustomers,
    required this.totalWarranties,
    required this.totalComplaints,
    required this.completedComplaints,
    required this.totalInstallers,
    required this.totalFieldPersonnel,
    required this.pendingApprovals,
  });

  @override
  List<Object> get props => [
        totalCustomers,
        totalWarranties,
        totalComplaints,
        completedComplaints,
        totalInstallers,
        totalFieldPersonnel,
        pendingApprovals,
      ];
}
