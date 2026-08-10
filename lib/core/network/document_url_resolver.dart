import '../config/api_config.dart';

abstract final class DocumentUrlResolver {
  static final Set<String> _developmentHosts = {
    'localhost',
    '127.0.0.1',
    '::1',
    'daphnex-crm.local',
  };

  static Uri resolve(String value, {Uri? runtimeApiBase}) {
    final raw = value.trim();
    if (raw.isEmpty) {
      throw const FormatException('Document URL is empty.');
    }
    if (raw.startsWith('//')) {
      throw const FormatException('Document URL must not be scheme-relative.');
    }

    final runtime = runtimeApiBase ?? Uri.parse(ApiConfig.baseUrl);
    if (!_isHttp(runtime) || runtime.host.isEmpty) {
      throw const FormatException('Runtime API URL is invalid.');
    }

    final parsed = Uri.tryParse(raw);
    if (parsed == null) {
      throw const FormatException('Document URL is invalid.');
    }

    if (!parsed.hasScheme) {
      final path = raw.startsWith('/') ? raw : '/$raw';
      return _origin(runtime).resolve(path);
    }

    if (!_isHttp(parsed) || parsed.host.isEmpty) {
      throw const FormatException('Document URL must use HTTP or HTTPS.');
    }

    if (!_isDevelopmentHost(parsed.host)) return parsed;

    return Uri(
      scheme: runtime.scheme,
      host: runtime.host,
      port: runtime.hasPort ? runtime.port : null,
      path: parsed.path,
      query: parsed.hasQuery ? parsed.query : null,
      fragment: parsed.hasFragment ? parsed.fragment : null,
    );
  }

  static bool _isHttp(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

  static bool _isDevelopmentHost(String host) {
    final normalized = host.toLowerCase();
    return _developmentHosts.contains(normalized);
  }

  static Uri _origin(Uri uri) => Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: '/',
  );
}
