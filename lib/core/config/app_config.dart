class AppConfig {
  static const String appName = 'Index Care';
  static const String baseUrl = 'http://indexinformatics.com:5000';
  static const String apiVersion = '/api';
  
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;
  
  static const int maxFileSize = 10485760;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  
  static const double defaultLatitude = 0.0;
  static const double defaultLongitude = 0.0;
  
  static const int locationUpdateInterval = 30000;
  
  static String get fullBaseUrl => '$baseUrl$apiVersion';
}
