import 'package:dio/dio.dart';
import '../../error/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = _extractErrorMessage(err.response?.data);
        
        switch (statusCode) {
          case 400:
            throw ValidationException(message ?? 'Invalid request');
          case 401:
            throw UnauthorizedException(message ?? 'Unauthorized access');
          case 403:
            throw UnauthorizedException(message ?? 'Access forbidden');
          case 404:
            throw ServerException(message ?? 'Resource not found', statusCode);
          case 500:
          case 502:
          case 503:
            throw ServerException(message ?? 'Server error occurred', statusCode);
          default:
            throw ServerException(message ?? 'An error occurred', statusCode);
        }
      
      case DioExceptionType.cancel:
        throw NetworkException('Request cancelled');
      
      case DioExceptionType.unknown:
        if (err.error.toString().contains('SocketException')) {
          throw NetworkException('No internet connection');
        }
        throw NetworkException('An unexpected error occurred');
      
      default:
        throw NetworkException('Network error occurred');
    }
  }
  
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    
    return data.toString();
  }
}
