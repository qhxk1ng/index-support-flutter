import '../../domain/entities/admin_entities.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.email,
    required super.isVerified,
    required super.createdAt,
    super.customerProfile,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      isVerified: json['isVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customerProfile: json['customerProfile'] != null
          ? CustomerProfileModel.fromJson(json['customerProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CustomerProfileModel extends CustomerProfileEntity {
  const CustomerProfileModel({
    super.latitude,
    super.longitude,
    super.address,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      address: json['address'] as String?,
    );
  }
}

class FieldPersonnelModel extends FieldPersonnelEntity {
  const FieldPersonnelModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.email,
    super.latitude,
    super.longitude,
    super.totalKmTraveled,
    required super.isActive,
    super.lastActive,
    super.currentLatitude,
    super.currentLongitude,
  });

  factory FieldPersonnelModel.fromJson(Map<String, dynamic> json) {
    return FieldPersonnelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      totalKmTraveled: json['totalKmTraveled'] != null ? (json['totalKmTraveled'] as num).toDouble() : null,
      isActive: json['isActive'] == true,
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive'] as String) : null,
      currentLatitude: json['currentLatitude'] != null ? (json['currentLatitude'] as num).toDouble() : null,
      currentLongitude: json['currentLongitude'] != null ? (json['currentLongitude'] as num).toDouble() : null,
    );
  }
}

class InstallerModel extends InstallerEntity {
  const InstallerModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.email,
    required super.isVerified,
    required super.createdAt,
    super.installerProfile,
    required super.hasActiveTask,
  });

  factory InstallerModel.fromJson(Map<String, dynamic> json) {
    return InstallerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      isVerified: json['isVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      installerProfile: json['installerProfile'] != null
          ? InstallerProfileModel.fromJson(json['installerProfile'] as Map<String, dynamic>)
          : null,
      hasActiveTask: json['assignments'] != null && (json['assignments'] as List).isNotEmpty,
    );
  }
}

class InstallerProfileModel extends InstallerProfileEntity {
  const InstallerProfileModel({
    super.latitude,
    super.longitude,
    super.address,
  });

  factory InstallerProfileModel.fromJson(Map<String, dynamic> json) {
    return InstallerProfileModel(
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      address: json['address'] as String?,
    );
  }
}

class AdminComplaintModel extends AdminComplaintEntity {
  const AdminComplaintModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.customerPhone,
    required super.description,
    required super.latitude,
    required super.longitude,
    super.address,
    super.images,
    required super.status,
    super.technicianId,
    super.technicianName,
    required super.journeyStarted,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminComplaintModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final assignments = json['assignments'] as List?;
    final technician = assignments != null && assignments.isNotEmpty
        ? (assignments[0]['technician'] as Map<String, dynamic>?)
        : null;

    return AdminComplaintModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: customer?['name'] as String? ?? 'Unknown',
      customerPhone: customer?['phoneNumber'] as String? ?? '',
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      images: json['images'] != null ? List<String>.from(json['images'] as List) : null,
      status: json['status'] as String,
      technicianId: json['technicianId'] as String?,
      technicianName: technician?['name'] as String?,
      journeyStarted: json['journeyStarted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    required super.totalCustomers,
    required super.totalWarranties,
    required super.totalComplaints,
    required super.completedComplaints,
    required super.totalInstallers,
    required super.totalFieldPersonnel,
    required super.pendingApprovals,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalCustomers: json['totalCustomers'] as int,
      totalWarranties: json['totalWarranties'] as int,
      totalComplaints: json['totalComplaints'] as int,
      completedComplaints: json['completedComplaints'] as int,
      totalInstallers: json['totalInstallers'] as int,
      totalFieldPersonnel: json['totalFieldPersonnel'] as int,
      pendingApprovals: json['pendingApprovals'] as int,
    );
  }
}
