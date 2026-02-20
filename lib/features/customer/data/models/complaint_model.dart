import '../../domain/entities/complaint_entity.dart';

class ComplaintModel extends ComplaintEntity {
  const ComplaintModel({
    required super.id,
    super.ticketNumber,
    required super.customerId,
    required super.description,
    required super.latitude,
    required super.longitude,
    super.address,
    required super.status,
    super.technicianId,
    required super.journeyStarted,
    required super.createdAt,
    required super.updatedAt,
    super.assignments,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      ticketNumber: json['ticketNumber'] as int?,
      customerId: json['customerId'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      status: json['status'] as String,
      technicianId: json['technicianId'] as String?,
      journeyStarted: json['journeyStarted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      assignments: json['assignments'] != null
          ? (json['assignments'] as List)
              .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'technicianId': technicianId,
      'journeyStarted': journeyStarted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class AssignmentModel extends AssignmentEntity {
  const AssignmentModel({
    required super.id,
    required super.complaintId,
    required super.technicianId,
    required super.assignedAt,
    super.acceptedAt,
    super.completedAt,
    required super.status,
    super.technician,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      complaintId: json['complaintId'] as String,
      technicianId: json['technicianId'] as String,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      status: json['status'] as String,
      technician: json['technician'] != null
          ? TechnicianModel.fromJson(json['technician'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TechnicianModel extends TechnicianEntity {
  const TechnicianModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }
}
