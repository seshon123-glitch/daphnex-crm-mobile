import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/errors/api_exception.dart';
import '../core/storage/token_store.dart';
import '../models/client.dart';
import '../models/dashboard_data.dart';
import '../models/reminder.dart';

class CrmApiService {
  CrmApiService({http.Client? client, TokenStore? tokenStore})
    : _client = client ?? http.Client(),
      _tokenStore = tokenStore ?? const SecureTokenStore();

  static const _timeout = Duration(seconds: 15);
  final http.Client _client;
  final TokenStore _tokenStore;

  Future<bool> hasSession() async {
    final token = await _tokenStore.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _send(
      () => _client.post(
        ApiConfig.endpoint('login'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
      authenticated: false,
    );
    final data = _decodeObject(response);
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('The CRM returned an invalid login response.');
    }
    await _tokenStore.writeToken(token);
  }

  Future<void> logout() => _tokenStore.deleteToken();

  Future<DashboardData> fetchDashboard() async {
    final response = await _authenticatedGet('dashboard');
    return DashboardData.fromJson(_decodeObject(response));
  }

  Future<List<Client>> fetchClients() async {
    final response = await _authenticatedGet('clients?per_page=100');
    return _decodeItems(response).map(Client.fromJson).toList(growable: false);
  }

  Future<Client> fetchClient(int id) async {
    final response = await _authenticatedGet('clients/$id');
    return Client.fromJson(_decodeObject(response));
  }

  Future<List<Reminder>> fetchReminders() async {
    final response = await _authenticatedGet('reminders?per_page=100');
    return _decodeItems(
      response,
    ).map(Reminder.fromJson).toList(growable: false);
  }

  Future<Reminder> createReminder(CreateReminderRequest request) async {
    final response = await _authenticatedPost('reminders', request.toJson());
    return Reminder.fromJson(_decodeObject(response));
  }

  Future<Reminder> completeReminder(int id) async {
    final response = await _authenticatedPost(
      'reminders/$id/complete',
      const {},
    );
    return Reminder.fromJson(_decodeObject(response));
  }

  Future<http.Response> _authenticatedGet(String path) async {
    final headers = await _authenticatedHeaders();
    return _send(() => _client.get(ApiConfig.endpoint(path), headers: headers));
  }

  Future<http.Response> _authenticatedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _authenticatedHeaders();
    return _send(
      () => _client.post(
        ApiConfig.endpoint(path),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please log in to continue.', statusCode: 401);
    }
    return {..._jsonHeaders, 'Authorization': 'Bearer $token'};
  }

  Future<http.Response> _send(
    Future<http.Response> Function() operation, {
    bool authenticated = true,
  }) async {
    try {
      final response = await operation().timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      if (authenticated && response.statusCode == 401) {
        await _tokenStore.deleteToken();
      }
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The CRM took too long to respond.');
    } on http.ClientException {
      throw const ApiException(
        'The CRM is unreachable. Check your connection and local host mapping.',
      );
    } on FormatException {
      throw const ApiException('The CRM returned an unreadable response.');
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }
    return decoded;
  }

  List<Map<String, dynamic>> _decodeItems(http.Response response) {
    final items = _decodeObject(response)['items'];
    if (items is! List<dynamic>) {
      throw const FormatException('Expected a JSON item collection.');
    }
    return items.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String?;
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      // Fall through to a stable client-side message.
    }
    return 'The CRM request failed (${response.statusCode}).';
  }

  static const _jsonHeaders = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
