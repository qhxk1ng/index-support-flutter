import 'package:equatable/equatable.dart';

class ComplaintEntity extends Equatable {
  final String id;
  final int? ticketNumber;
  final String customerId;
  final String description;
  final double latitude;
  final double longitude;
  final String? address;
  final String status;
  final String? technicianId;
  final bool journeyStarted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AssignmentEntity>? assignments;

  const ComplaintEntity({
    required this.id,
    this.ticketNumber,
    required this.customerId,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.status,
    this.technicianId,
    required this.journeyStarted,
    required this.createdAt,
    required this.updatedAt,
    this.assignments,
  });

  @override
  List<Object?> get props => [
        id,
        ticketNumber,
        customerId,
        description,
        latitude,
        longitude,
        address,
        status,
        technicianId,
        journeyStarted,
        createdAt,
        updatedAt,
        assignments,
      ];
}

class AssignmentEntity extends Equatable {
  final String id;
  final String complaintId;
  final String technicianId;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String status;
  final TechnicianEntity? technician;

  const AssignmentEntity({
    required this.id,
    required this.complaintId,
    required this.technicianId,
    required this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    required this.status,
    this.technician,
  });

  @override
  List<Object?> get props => [
        id,
        complaintId,
        technicianId,
        assignedAt,
        acceptedAt,
        completedAt,
        status,
        technician,
      ];
}

class TechnicianEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;

  const TechnicianEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [id, name, phoneNumber];
}
