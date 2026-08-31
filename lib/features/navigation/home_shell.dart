import 'package:flutter/material.dart';

import '../../services/crm_api.dart';
import '../dashboard/dashboard_screen.dart';
import '../files/files_hub_screen.dart';
import '../finance/finance_hub_screen.dart';
import '../more/more_screen.dart';
import '../work/work_hub_screen.dart';
import 'commercial_navigation.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api, required this.onLogout});

  final CrmApi api;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  CommercialNavSection _section = CommercialNavSection.dashboard;

  int get _selectedIndex => CommercialNavSection.values.indexOf(_section);

  void _select(CommercialNavSection section) {
    setState(() => _section = section);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api.currentSession?.tenant.id !=
        widget.api.currentSession?.tenant.id) {
      _section = CommercialNavSection.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        api: widget.api,
        onOpenClients: () => _select(CommercialNavSection.work),
        onOpenTasks: () => _select(CommercialNavSection.work),
        onOpenMore: () => _select(CommercialNavSection.more),
      ),
      WorkHubScreen(api: widget.api),
      FinanceHubScreen(api: widget.api),
      FilesHubScreen(api: widget.api),
      MoreScreen(
        api: widget.api,
        onLogout: widget.onLogout,
        onOpenWork: () => _select(CommercialNavSection.work),
        onOpenFinance: () => _select(CommercialNavSection.finance),
        onOpenFiles: () => _select(CommercialNavSection.files),
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
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspaces_outline),
            selectedIcon: Icon(Icons.workspaces_rounded),
            label: 'Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy_rounded),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
