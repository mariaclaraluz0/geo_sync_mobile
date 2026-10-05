class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.retryAfter});

  final String message;
  final int? statusCode;
  final Duration? retryAfter;

  @override
  String toString() => message;
}

class ApiConnectionException extends ApiException {
  const ApiConnectionException(super.message);
}

class LocalStorageException extends ApiException {
  const LocalStorageException(super.message);
}
