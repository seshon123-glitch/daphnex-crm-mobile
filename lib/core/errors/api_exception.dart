class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.endpoint,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final Uri? endpoint;
  final String? responseBody;

  bool get isAuthenticationError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}
