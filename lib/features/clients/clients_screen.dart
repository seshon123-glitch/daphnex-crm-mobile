import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/workspace_banner.dart';
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
    final clients = List<Client>.of(_clients ?? const <Client>[])
      ..sort(
        (left, right) => _sortName(
          left,
        ).toLowerCase().compareTo(_sortName(right).toLowerCase()),
      );
    if (query.isEmpty) return clients;
    return clients
        .where(
          (client) => [
            client.firstName,
            client.lastName,
            client.name,
            client.company,
            client.phone,
            client.email,
          ].any((value) => value.toLowerCase().contains(query)),
        )
        .toList();
  }

  String _sortName(Client client) =>
      client.name.trim().isNotEmpty ? client.name.trim() : client.company.trim();

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addClientButton'),
        heroTag: 'clients-add-client-fab',
        onPressed: _addClient,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Client'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: PremiumPageBanner(
              session: widget.api.currentSession,
              title: 'Clients',
              subtitle:
                  'Find people and companies quickly, then open each client workspace for projects, tasks, quotes, invoices and documents.',
              icon: Icons.people_outline_rounded,
              metrics: {'Search': 'Name', 'Workspace': 'Isolated'},
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              key: const Key('clientSearch'),
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name, company, phone or email',
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
                        ordinal: index + 1,
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
    required this.ordinal,
    required this.api,
    required this.client,
    required this.onChanged,
  });

  final int ordinal;
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
                '$ordinal.',
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

class _FormGroupHeader extends StatelessWidget {
  const _FormGroupHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _countyState;
  late final TextEditingController _postcode;
  late final TextEditingController _country;
  late final TextEditingController _notes;
  String _status = 'active';

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
    _addressLine1 = TextEditingController(text: request.addressLine1);
    _addressLine2 = TextEditingController(text: request.addressLine2);
    _city = TextEditingController(text: request.city);
    _countyState = TextEditingController(text: request.countyState);
    _postcode = TextEditingController(text: request.postcode);
    _country = TextEditingController(text: request.country);
    _notes = TextEditingController(text: request.notes);
    _status = request.status;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _countyState.dispose();
    _postcode.dispose();
    _country.dispose();
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
        status: _status,
        addressLine1: _addressLine1.text,
        addressLine2: _addressLine2.text,
        city: _city.text,
        countyState: _countyState.text,
        postcode: _postcode.text,
        country: _country.text,
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
                const _FormGroupHeader('Name'),
                TextFormField(
                  key: const Key('clientFirstNameField'),
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First Name *'),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientLastNameField'),
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last Name *'),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientCompanyField'),
                  controller: _company,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                const _FormGroupHeader('Contact'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientEmailField'),
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailOrEmpty,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientPhoneField'),
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
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
                DropdownButtonFormField<String>(
                  key: const Key('clientStatusField'),
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 16),
                const _FormGroupHeader('Address'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientAddressLine1Field'),
                  controller: _addressLine1,
                  decoration: const InputDecoration(labelText: 'Address'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientCityField'),
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City / Town'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientPostcodeField'),
                  controller: _postcode,
                  decoration: const InputDecoration(labelText: 'Postcode'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  key: const Key('clientMoreAddressDetails'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text('More address details'),
                  children: [
                    TextFormField(
                      key: const Key('clientCountyStateField'),
                      controller: _countyState,
                      decoration: const InputDecoration(
                        labelText: 'County / State / Region',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('clientCountryField'),
                      controller: _country,
                      decoration: const InputDecoration(labelText: 'Country'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('clientAddressLine2Field'),
                      controller: _addressLine2,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _FormGroupHeader('Notes'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('clientNotesField'),
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional notes about this client',
                  ),
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
