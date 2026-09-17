import 'package:flutter/material.dart';

import '../../services/crm_api.dart';
import '../clients/clients_screen.dart';
import '../more/more_screen.dart';
import '../outstanding/outstanding_screen.dart';
import '../reminders/reminders_screen.dart';
import '../revenue/revenue_screen.dart';
import 'commercial_navigation.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api, required this.onLogout});

  final CrmApi api;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  CommercialNavSection _section = CommercialNavSection.clients;

  int get _selectedIndex => CommercialNavSection.values.indexOf(_section);

  void _select(CommercialNavSection section) {
    setState(() => _section = section);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api.currentSession?.tenant.id !=
        widget.api.currentSession?.tenant.id) {
      _section = CommercialNavSection.clients;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ClientsScreen(api: widget.api),
      RemindersScreen(api: widget.api),
      OutstandingScreen(
        api: widget.api,
        active: _section == CommercialNavSection.outstanding,
      ),
      RevenueScreen(
        api: widget.api,
        active: _section == CommercialNavSection.turnover,
      ),
      MoreScreen(
        api: widget.api,
        onLogout: widget.onLogout,
        rootTitle: 'Settings',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        key: const Key('commercialBottomNavigation'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            _select(CommercialNavSection.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active_rounded),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Outstanding',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats_rounded),
            label: 'Turnover',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
