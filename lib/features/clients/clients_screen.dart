import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/client.dart';
import '../../services/crm_api.dart';
import 'client_profile_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client>? _clients;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final clients = await widget.api.fetchClients();
      if (mounted) setState(() => _clients = clients);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  List<Client> get _filteredClients {
    final query = _query.toLowerCase().trim();
    final clients = _clients ?? const <Client>[];
    if (query.isEmpty) return clients;
    return clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
          client.company.toLowerCase().contains(query) ||
          client.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              key: const Key('clientSearch'),
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search clients',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: _error != null && _clients == null
                ? ErrorStateView(message: _error!, onRetry: _load)
                : _clients == null
                ? const LoadingView(label: 'Loading clients…')
                : clients.isEmpty
                ? EmptyStateView(
                    message: _query.isEmpty
                        ? 'No clients yet'
                        : 'No clients found',
                    icon: Icons.people_outline_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: clients.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _ClientCard(api: widget.api, client: clients[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.api, required this.client});

  final CrmApi api;
  final Client client;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      key: Key('client-${client.id}'),
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ClientProfileScreen(api: api, client: client),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.lightBlue,
              child: Text(
                client.initials,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    client.company,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    client.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
