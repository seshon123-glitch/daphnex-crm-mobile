import 'package:flutter/material.dart';

import 'core/errors/api_exception.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/navigation/home_shell.dart';
import 'repositories/live_crm_repository.dart';
import 'services/crm_api.dart';

class DaphnexCrmApp extends StatefulWidget {
  const DaphnexCrmApp({super.key, this.api});

  final CrmApi? api;

  @override
  State<DaphnexCrmApp> createState() => _DaphnexCrmAppState();
}

class _DaphnexCrmAppState extends State<DaphnexCrmApp> {
  late final CrmApi _api = widget.api ?? LiveCrmRepository();
  bool _isCheckingSession = true;
  bool _isAuthenticated = false;
  String? _sessionMessage;

  @override
  void initState() {
    super.initState();
    _api.setSessionInvalidatedHandler(_handleSessionInvalidated);
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    bool hasSession = false;
    String? message;
    try {
      hasSession = await _api.hasSession();
    } on ApiException catch (error) {
      message = error.message;
    } catch (_) {
      message =
          'The live CRM server could not be reached. Please log in again when your connection is available.';
    }
    if (!mounted) return;
    setState(() {
      _isAuthenticated = hasSession;
      _isCheckingSession = false;
      _sessionMessage = message;
    });
  }

  Future<void> _logout() async {
    await _api.logout();
    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _sessionMessage = null;
      });
    }
  }

  void _handleSessionInvalidated(Object error) {
    if (!mounted) return;
    setState(() {
      _isAuthenticated = false;
      _sessionMessage = error.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daphnex CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _isCheckingSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isAuthenticated
          ? HomeShell(api: _api, onLogout: _logout)
          : LoginScreen(
              api: _api,
              initialMessage: _sessionMessage,
              onLogin: () => setState(() => _isAuthenticated = true),
            ),
    );
  }
}
