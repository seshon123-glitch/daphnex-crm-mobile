enum ApiErrorCategory {
  validationProblem,
  sessionExpired,
  accessRemoved,
  featureUnavailable,
  limitReached,
  accountInactive,
  notFound,
  conflict,
  rateLimited,
  networkProblem,
  temporaryServiceProblem,
  unknown,
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.category = ApiErrorCategory.unknown,
    this.endpoint,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final ApiErrorCategory category;
  final Uri? endpoint;
  final String? responseBody;

  bool get isAuthenticationError =>
      category == ApiErrorCategory.sessionExpired ||
      category == ApiErrorCategory.accessRemoved ||
      statusCode == 401 ||
      statusCode == 403;

  bool get shouldClearSession =>
      category == ApiErrorCategory.sessionExpired ||
      category == ApiErrorCategory.accessRemoved ||
      category == ApiErrorCategory.accountInactive;

  @override
  String toString() => message;
}
