class MockAuthService {
  const MockAuthService();

  /// Future integration point: replace with the CRM authentication endpoint
  /// and store tokens using secure platform storage.
  Future<bool> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return email.trim().isNotEmpty && password.isNotEmpty;
  }
}
