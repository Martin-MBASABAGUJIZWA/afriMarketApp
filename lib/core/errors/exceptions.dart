abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network connection failed'])
      : super(message, code: 'network_error');
}

class ServerException extends AppException {
  ServerException([String message = 'Server error occurred'])
      : super(message, code: 'server_error');
}

class AuthException extends AppException {
  AuthException(String message) : super(message, code: 'auth_error');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, code: 'validation_error');
}

class StorageException extends AppException {
  StorageException([String message = 'Storage operation failed'])
      : super(message, code: 'storage_error');
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found'])
      : super(message, code: 'not_found');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized access'])
      : super(message, code: 'unauthorized');
}

class CacheException extends AppException {
  CacheException([String message = 'Cache operation failed'])
      : super(message, code: 'cache_error');
}
