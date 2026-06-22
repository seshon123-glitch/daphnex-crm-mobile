import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final hasSession = await _api.hasSession();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = hasSession;
      _isCheckingSession = false;
    });
  }

  Future<void> _logout() async {
    await _api.logout();
    if (mounted) setState(() => _isAuthenticated = false);
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
              onLogin: () => setState(() => _isAuthenticated = true),
            ),
    );
  }
}
