import '../../domain/entities/sales_personnel_entities.dart';

class SalesPersonnelProfileModel extends SalesPersonnelProfile {
  SalesPersonnelProfileModel({
    required super.id,
    required super.userId,
    super.latitude,
    super.longitude,
    super.address,
    super.gmail,
    required super.totalKmTraveled,
    required super.totalTimeSpent,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SalesPersonnelProfileModel.fromJson(Map<String, dynamic> json) {
    return SalesPersonnelProfileModel(
      id: json['id'],
      userId: json['userId'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
      gmail: json['gmail'],
      totalKmTraveled: (json['totalKmTraveled'] ?? 0).toDouble(),
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'gmail': gmail,
    };
  }
}

class SalesActivityModel extends SalesActivity {
  SalesActivityModel({
    required super.id,
    required super.salesPersonnelId,
    required super.customerName,
    required super.businessName,
    required super.phoneNumber,
    required super.latitude,
    required super.longitude,
    super.address,
    super.visitingCardImage,
    required super.businessImages,
    super.notes,
    required super.startTime,
    super.endTime,
    super.timeSpent,
    required super.createdAt,
  });

  factory SalesActivityModel.fromJson(Map<String, dynamic> json) {
    return SalesActivityModel(
      id: json['id'],
      salesPersonnelId: json['salesPersonnelId'],
      customerName: json['customerName'],
      businessName: json['businessName'],
      phoneNumber: json['phoneNumber'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      visitingCardImage: json['visitingCardImage'],
      businessImages: List<String>.from(json['businessImages'] ?? []),
      notes: json['notes'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      timeSpent: json['timeSpent'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'visitingCardImage': visitingCardImage,
      'businessImages': businessImages,
      'notes': notes,
    };
  }
}

class SalesLeadModel extends SalesLead {
  SalesLeadModel({
    required super.id,
    required super.salesPersonnelId,
    required super.customerName,
    required super.businessName,
    required super.phoneNumber,
    required super.latitude,
    required super.longitude,
    super.address,
    super.visitingCardImage,
    super.leadType,
    required super.status,
    super.notes,
    required super.createdAt,
  });

  factory SalesLeadModel.fromJson(Map<String, dynamic> json) {
    return SalesLeadModel(
      id: json['id'],
      salesPersonnelId: json['salesPersonnelId'],
      customerName: json['customerName'],
      businessName: json['businessName'] ?? '',
      phoneNumber: json['phoneNumber'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      visitingCardImage: json['visitingCardImage'],
      leadType: json['leadType'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'visitingCardImage': visitingCardImage,
      'leadType': leadType,
      'notes': notes,
    };
  }
}

class SalesExpenseModel extends SalesExpense {
  SalesExpenseModel({
    required super.id,
    required super.salesPersonnelId,
    required super.expenseType,
    super.amount,
    super.description,
    required super.receiptImages,
    required super.expenseDate,
    required super.createdAt,
  });

  factory SalesExpenseModel.fromJson(Map<String, dynamic> json) {
    return SalesExpenseModel(
      id: json['id'],
      salesPersonnelId: json['salesPersonnelId'],
      expenseType: json['expenseType'],
      amount: json['amount']?.toDouble(),
      description: json['description'],
      receiptImages: List<String>.from(json['receiptImages'] ?? []),
      expenseDate: DateTime.parse(json['expenseDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseType': expenseType,
      'amount': amount,
      'description': description,
      'receiptImages': receiptImages,
      'expenseDate': expenseDate.toIso8601String(),
    };
  }
}

class SalesPersonnelStatsModel extends SalesPersonnelStats {
  SalesPersonnelStatsModel({
    required super.totalActivities,
    required super.totalLeads,
    required super.totalExpenseCount,
    required super.totalTimeSpent,
    required super.totalExpenseAmount,
  });

  factory SalesPersonnelStatsModel.fromJson(Map<String, dynamic> json) {
    final expenseStats = json['expenseStats'] as Map<String, dynamic>?;
    return SalesPersonnelStatsModel(
      totalActivities: json['totalActivities'] ?? 0,
      totalLeads: json['totalLeads'] ?? 0,
      totalExpenseCount: json['totalExpenses'] ?? 0,
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      totalExpenseAmount: (expenseStats?['totalAmount'] ?? 0).toDouble(),
    );
  }
}
