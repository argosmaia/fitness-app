sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Sua sessão expirou.']);
}

final class ValidationException extends AppException {
  const ValidationException(super.message, [this.fields = const {}]);
  final Map<String, dynamic> fields;
}

final class ServerException extends AppException {
  const ServerException(super.message, this.statusCode);
  final int? statusCode;
}
