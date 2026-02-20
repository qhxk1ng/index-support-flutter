import 'package:dio/dio.dart';
import '../../constants/app_constants.dart';
import '../../utils/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService = StorageService();
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();
    
    if (token != null && token.isNotEmpty) {
      options.headers[AppConstants.authorizationHeader] = 
          '${AppConstants.bearerPrefix} $token';
    }
    
    handler.next(options);
  }
}
