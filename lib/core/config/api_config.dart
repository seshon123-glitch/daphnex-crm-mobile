abstract final class ApiConfig {
  /// Override at build/run time with:
  /// --dart-define=DAPHNEX_CRM_API_URL=https://crm.daphnex.co.uk/wp-json/daphnex-crm/v1/
  static const baseUrl = String.fromEnvironment(
    'DAPHNEX_CRM_API_URL',
    defaultValue: 'http://daphnex-crm.local/wp-json/daphnex-crm/v1/',
  );

  static Uri endpoint(String path) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBase).resolve(path);
  }
}
