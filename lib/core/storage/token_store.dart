import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<void> writeToken(String token);
  Future<String?> readToken();
  Future<void> deleteToken();
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'daphnex_crm_bearer_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
