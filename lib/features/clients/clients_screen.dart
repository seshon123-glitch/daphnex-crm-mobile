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

  Future<void> _addClient() async {
    final request = await showDialog<CreateClientRequest>(
      context: context,
      builder: (_) => const _ClientFormDialog(),
    );
    if (request == null) return;
    try {
      await widget.api.createClient(request);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Client created.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create client: $error')),
      );
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
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addClientButton'),
        onPressed: _addClient,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Client'),
      ),
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
                      itemBuilder: (context, index) => _ClientCard(
                        api: widget.api,
                        client: clients[index],
                        onChanged: _load,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.api,
    required this.client,
    required this.onChanged,
  });

  final CrmApi api;
  final Client client;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      key: Key('client-${client.id}'),
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ClientProfileScreen(api: api, client: client),
          ),
        );
        onChanged();
      },
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

class _ClientFormDialog extends StatefulWidget {
  const _ClientFormDialog();

  @override
  State<_ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<_ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _company;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    const request = CreateClientRequest(firstName: '', lastName: '');
    _firstName = TextEditingController(text: request.firstName);
    _lastName = TextEditingController(text: request.lastName);
    _company = TextEditingController(text: request.companyName);
    _email = TextEditingController(text: request.email);
    _phone = TextEditingController(text: request.phone);
    _website = TextEditingController(text: request.website);
    _notes = TextEditingController(text: request.notes);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CreateClientRequest(
        firstName: _firstName.text,
        lastName: _lastName.text,
        companyName: _company.text,
        email: _email.text,
        phone: _phone.text,
        website: _website.text,
        notes: _notes.text,
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _emailOrEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)
        ? null
        : 'Enter a valid email';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New client'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('clientFirstNameField'),
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientLastNameField'),
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientCompanyField'),
                  controller: _company,
                  decoration: const InputDecoration(labelText: 'Company'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientEmailField'),
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailOrEmpty,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientPhoneField'),
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientWebsiteField'),
                  controller: _website,
                  decoration: const InputDecoration(labelText: 'Website'),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientNotesField'),
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancelClientForm'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveClientForm'),
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
