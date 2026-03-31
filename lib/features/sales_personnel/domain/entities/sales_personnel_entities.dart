class SalesPersonnelProfile {
  final String id;
  final String userId;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? gmail;
  final double totalKmTraveled;
  final int totalTimeSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  SalesPersonnelProfile({
    required this.id,
    required this.userId,
    this.latitude,
    this.longitude,
    this.address,
    this.gmail,
    required this.totalKmTraveled,
    required this.totalTimeSpent,
    required this.createdAt,
    required this.updatedAt,
  });
}

class SalesActivity {
  final String id;
  final String salesPersonnelId;
  final String customerName;
  final String businessName;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String? address;
  final String? visitingCardImage;
  final List<String> businessImages;
  final String? notes;
  final DateTime startTime;
  final DateTime? endTime;
  final int? timeSpent;
  final DateTime createdAt;

  SalesActivity({
    required this.id,
    required this.salesPersonnelId,
    required this.customerName,
    required this.businessName,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.address,
    this.visitingCardImage,
    required this.businessImages,
    this.notes,
    required this.startTime,
    this.endTime,
    this.timeSpent,
    required this.createdAt,
  });
}

class SalesLead {
  final String id;
  final String salesPersonnelId;
  final String customerName;
  final String businessName;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String? address;
  final String? visitingCardImage;
  final String? leadType;
  final String status;
  final String? notes;
  final DateTime createdAt;

  SalesLead({
    required this.id,
    required this.salesPersonnelId,
    required this.customerName,
    required this.businessName,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.address,
    this.visitingCardImage,
    this.leadType,
    required this.status,
    this.notes,
    required this.createdAt,
  });
}

class SalesExpense {
  final String id;
  final String salesPersonnelId;
  final String expenseType;
  final double? amount;
  final String? description;
  final List<String> receiptImages;
  final DateTime expenseDate;
  final DateTime createdAt;

  SalesExpense({
    required this.id,
    required this.salesPersonnelId,
    required this.expenseType,
    this.amount,
    this.description,
    required this.receiptImages,
    required this.expenseDate,
    required this.createdAt,
  });
}

class SalesPersonnelStats {
  final int totalActivities;
  final int totalLeads;
  final int totalExpenseCount;
  final int totalTimeSpent;
  final double totalExpenseAmount;

  SalesPersonnelStats({
    required this.totalActivities,
    required this.totalLeads,
    required this.totalExpenseCount,
    required this.totalTimeSpent,
    required this.totalExpenseAmount,
  });
}
