import 'package:dio/dio.dart';
import '../../error/error_mapper.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Extract clean human-readable message from response if available
    final extractedMessage = ErrorMapper.extractDioMessage(err);

    // Create a normalized DioException with the message preserved
    final normalizedException = err.copyWith(
      message: extractedMessage ?? err.message,
    );

    handler.next(normalizedException);
  }
}
