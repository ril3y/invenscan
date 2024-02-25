class ServerApiException implements Exception {
  final String message;
  final int? statusCode;

  ServerApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ServerApiException: $message (Status code: $statusCode)';
    }
    return 'ServerApiException: $message';
  }
}
