class ApiException implements Exception {
  final String message;
  final String? prefix;
  final int? statusCode;

  ApiException({
    required this.message,
    this.prefix,
    this.statusCode,
  });

  @override
  String toString() {
    return "${prefix != null ? '$prefix: ' : ''}$message";
  }
}

class BadRequestException extends ApiException {
  BadRequestException({required String message, int? statusCode})
      : super(
          message: message,
          prefix: 'Bad Request',
          statusCode: statusCode ?? 400,
        );
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({required String message, int? statusCode})
      : super(
          message: message,
          prefix: 'Unauthorized',
          statusCode: statusCode ?? 401,
        );
}

class ForbiddenException extends ApiException {
  ForbiddenException({required String message, int? statusCode})
      : super(
          message: message,
          prefix: 'Forbidden',
          statusCode: statusCode ?? 403,
        );
}

class NotFoundException extends ApiException {
  NotFoundException({required String message, int? statusCode})
      : super(
          message: message,
          prefix: 'Not Found',
          statusCode: statusCode ?? 404,
        );
}

class ServerException extends ApiException {
  ServerException({required String message, int? statusCode})
      : super(
          message: message,
          prefix: 'Server Error',
          statusCode: statusCode ?? 500,
        );
}

class ConnectionException extends ApiException {
  ConnectionException({required String message})
      : super(
          message: message,
          prefix: 'Connection Error',
        );
}

class TimeoutException extends ApiException {
  TimeoutException({required String message})
      : super(
          message: message,
          prefix: 'Request Timeout',
          statusCode: 408,
        );
}

class ValidationException extends ApiException {
  ValidationException({required String message})
      : super(
          message: message,
          prefix: 'Validation Error',
          statusCode: 422,
        );
}