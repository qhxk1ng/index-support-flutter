class AppConstants {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String activeRoleKey = 'active_role';
  static const String isLoggedInKey = 'is_logged_in';
  
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  
  static const String jsonContentType = 'application/json';
  static const String multipartContentType = 'multipart/form-data';
  
  // Mapbox - Load from environment or use placeholder
  // Set MAPBOX_ACCESS_TOKEN in your environment
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '', // Will be set at runtime
  );
}

class ApiEndpoints {
  static const String register = '/auth/register';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String setPassword = '/auth/set-password';
  static const String login = '/auth/login';
  static const String adminLogin = '/auth/admin-login';
  static const String logout = '/auth/logout';
  
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String switchRole = '/users/switch-role';
  static const String addRole = '/users/add-role';
  static const String changePassword = '/users/change-password';
  
  static const String registerWarranty = '/customer/warranty/register';
  static const String getWarranties = '/customer/warranties';
  static const String raiseComplaint = '/customer/complaint';
  static const String getComplaints = '/customer/complaints';
  static String getComplaintDetails(String id) => '/customer/complaint/$id';
  
  static const String getAssignments = '/installer/assignments';
  static const String createInstallation = '/installer/installation';
  static const String getInstallations = '/installer/installations';
  static const String checkWarranty = '/installer/check-warranty';
  
  static const String startVisit = '/field-personnel/visit/start';
  static String endVisit(String id) => '/field-personnel/visit/end/$id';
  static const String getVisits = '/field-personnel/visits';
  static const String getStats = '/field-personnel/stats';
  
  static const String dashboard = '/admin/dashboard';
  static const String adminComplaints = '/admin/complaints';
  static String assignComplaint(String id) => '/admin/complaint/$id/assign';
  static const String getTechnicians = '/admin/technicians';
  static String getTechnicianLocation(String id) => '/admin/technician/$id/location';
  static String getComplaintTracking(String id) => '/admin/complaint/$id/track';
  static const String adminInstallations = '/admin/installations';
  static String approveInstallation(String id) => '/admin/installation/$id/approve';
  static const String fieldVisits = '/admin/field-visits';
  static const String reports = '/admin/reports';
  
  static const String createProduct = '/warranty/product';
  static const String getProducts = '/warranty/products';
  static const String uploadSerialNumbers = '/warranty/serial-numbers/upload';
  static const String addSerialNumbers = '/warranty/serial-numbers';
  static String getSerialNumbers(String productId) => '/warranty/serial-numbers/$productId';
  
  static const String pendingJobs = '/complaints/pending-jobs';
  static String acceptAssignment(String id) => '/complaints/$id/accept';
  static String declineAssignment(String id) => '/complaints/$id/decline';
  static String startJourney(String id) => '/complaints/$id/start-journey';
  static String completeComplaint(String id) => '/complaints/$id/complete';
  
  static const String notifications = '/complaints/notifications';
  static const String markNotificationsRead = '/complaints/notifications/read';
  
  static const String logLocation = '/location/log';
  static const String locationHistory = '/location/history';
}

class UserRole {
  static const String admin = 'ADMIN';
  static const String customer = 'CUSTOMER';
  static const String installer = 'INSTALLER';
  static const String fieldPersonnel = 'FIELD_PERSONNEL';
  
  static List<String> get allRoles => [admin, customer, installer, fieldPersonnel];
}

class ComplaintStatus {
  static const String pending = 'PENDING';
  static const String assigned = 'ASSIGNED';
  static const String accepted = 'ACCEPTED';
  static const String inProgress = 'IN_PROGRESS';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}

class AssignmentStatus {
  static const String pending = 'PENDING';
  static const String accepted = 'ACCEPTED';
  static const String rejected = 'REJECTED';
  static const String completed = 'COMPLETED';
}

class CustomerType {
  static const String customer = 'CUSTOMER';
  static const String dealer = 'DEALER';
}
