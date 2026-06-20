import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/navigation/home_shell.dart';

class DaphnexCrmApp extends StatefulWidget {
  const DaphnexCrmApp({super.key});

  @override
  State<DaphnexCrmApp> createState() => _DaphnexCrmAppState();
}

class _DaphnexCrmAppState extends State<DaphnexCrmApp> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daphnex CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _isAuthenticated
          ? HomeShell(onLogout: () => setState(() => _isAuthenticated = false))
          : LoginScreen(onLogin: () => setState(() => _isAuthenticated = true)),
    );
  }
}
