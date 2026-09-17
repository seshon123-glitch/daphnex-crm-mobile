import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/client.dart';
import '../../services/crm_api.dart';
import '../documents/documents_screen.dart';
import '../invoices/invoices_screen.dart';
import '../jobs/jobs_screen.dart';
import '../quotes/quotes_screen.dart';
import '../reminders/reminders_screen.dart';
import '../tasks/tasks_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({
    super.key,
    required this.api,
    required this.client,
  });

  final CrmApi api;
  final Client client;

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  Client? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profile = await widget.api.fetchClient(widget.client.id);
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client profile'),
        actions: [
          if (_profile != null)
            IconButton(
              key: const Key('editClientButton'),
              tooltip: 'Edit client',
              onPressed: _edit,
              icon: const Icon(Icons.edit_rounded),
            ),
          if (_profile != null)
            IconButton(
              key: const Key('deleteClientButton'),
              tooltip: 'Delete client',
              onPressed: _deleteClient,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : _profile == null
          ? const LoadingView(label: 'Loading client profile…')
          : _ProfileContent(
              api: widget.api,
              client: _profile!,
              onEdit: _edit,
              onDelete: _deleteClient,
            ),
    );
  }

  Future<void> _edit() async {
    final profile = _profile;
    if (profile == null) return;
    final request = await showDialog<CreateClientRequest>(
      context: context,
      builder: (_) => _ClientEditDialog(client: profile),
    );
    if (request == null) return;
    try {
      final updated = await widget.api.updateClient(profile.id, request);
      if (mounted) setState(() => _profile = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Client updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update client: $error')),
      );
    }
  }

  Future<void> _deleteClient() async {
    final profile = _profile;
    if (profile == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text(
          'Delete "${profile.company.isEmpty ? profile.name : profile.company}"? '
          'Daphnex CRM will block this if related projects, tasks, reminders, '
          'invoices, payments or documents still exist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteClient(profile.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Client deleted.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client could not be deleted: $error')),
      );
    }
  }
}

class _ClientEditDialog extends StatefulWidget {
  const _ClientEditDialog({required this.client});

  final Client client;

  @override
  State<_ClientEditDialog> createState() => _ClientEditDialogState();
}

class _ClientEditDialogState extends State<_ClientEditDialog> {
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
    final request = CreateClientRequest.fromClient(widget.client);
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit client'),
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
                key: const Key('editClientFirstNameField'),
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'First Name *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientLastNameField'),
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Last Name *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientCompanyField'),
                controller: _company,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 16),
              const _FormGroupHeader('Contact'),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientEmailField'),
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: _emailOrEmpty,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientPhoneField'),
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientWebsiteField'),
                controller: _website,
                decoration: const InputDecoration(labelText: 'Website'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('editClientStatusField'),
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 16),
              const _FormGroupHeader('Address'),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientAddressLine1Field'),
                controller: _addressLine1,
                decoration: const InputDecoration(labelText: 'Address Line 1'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientAddressLine2Field'),
                controller: _addressLine2,
                decoration: const InputDecoration(labelText: 'Address Line 2'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientCityField'),
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientCountyStateField'),
                controller: _countyState,
                decoration: const InputDecoration(labelText: 'County/State'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientPostcodeField'),
                controller: _postcode,
                decoration: const InputDecoration(labelText: 'Postcode'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientCountryField'),
                controller: _country,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 16),
              const _FormGroupHeader('Notes'),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editClientNotesField'),
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
        key: const Key('cancelEditClient'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('saveEditClient'),
        onPressed: _submit,
        child: const Text('Save'),
      ),
    ],
  );
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.api,
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  final CrmApi api;
  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.blue,
            child: Text(
              client.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          client.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          client.company,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Center(
          child: FilledButton.icon(
            key: const Key('viewClientProfileButton'),
            onPressed: () => _push(
              context,
              _ClientFullProfileScreen(
                client: client,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
            icon: const Icon(Icons.badge_outlined),
            label: const Text('View Profile'),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Client workspace',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _WorkspaceGrid(
          children: [
            _WorkspaceTile(
              key: const Key('clientProjectsTile'),
              icon: Icons.work_outline_rounded,
              label: 'Projects / Jobs',
              onTap: () => _push(context, JobsScreen(api: api, client: client)),
            ),
            _WorkspaceTile(
              key: const Key('clientTasksTile'),
              icon: Icons.task_alt_outlined,
              label: 'Tasks',
              onTap: () =>
                  _push(context, TasksScreen(api: api, client: client)),
            ),
            _WorkspaceTile(
              key: const Key('clientRemindersTile'),
              icon: Icons.notifications_none_rounded,
              label: 'Reminders',
              onTap: () =>
                  _push(context, RemindersScreen(api: api, client: client)),
            ),
            _WorkspaceTile(
              key: const Key('clientExpensesTile'),
              icon: Icons.payments_outlined,
              label: 'Project Expenses',
              onTap: () => _push(
                context,
                ClientProjectExpensesScreen(api: api, client: client),
              ),
            ),
            _WorkspaceTile(
              key: const Key('clientQuotesTile'),
              icon: Icons.request_quote_outlined,
              label: 'Quotes',
              onTap: () =>
                  _push(context, QuotesScreen(api: api, client: client)),
            ),
            _WorkspaceTile(
              key: const Key('clientInvoicesTile'),
              icon: Icons.receipt_long_outlined,
              label: 'Invoices',
              onTap: () =>
                  _push(context, InvoicesScreen(api: api, client: client)),
            ),
            _WorkspaceTile(
              key: const Key('clientDocumentsTile'),
              icon: Icons.folder_copy_outlined,
              label: 'Documents',
              onTap: () => _push(
                context,
                DocumentsScreen(api: api, clientId: client.id),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Notes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              client.notes.isEmpty ? 'No notes available.' : client.notes,
              style: const TextStyle(height: 1.5, color: AppColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Recent activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (client.activities.isEmpty)
          const Text(
            'No recent activity.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          ...client.activities.asMap().entries.map((entry) {
            final activity = entry.value;
            final isLast = entry.key == client.activities.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFFDCE7F5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (activity.detail.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              activity.detail,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            activity.date,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _ClientFullProfileScreen extends StatelessWidget {
  const _ClientFullProfileScreen({
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Client profile details')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Card(
          child: Column(
            children: [
              _DetailTile(
                icon: Icons.person_outline_rounded,
                label: 'First Name',
                value: client.firstName,
              ),
              const Divider(height: 1, indent: 62),
              _DetailTile(
                icon: Icons.person_outline_rounded,
                label: 'Last Name',
                value: client.lastName,
              ),
              const Divider(height: 1, indent: 62),
              _DetailTile(
                icon: Icons.business_outlined,
                label: 'Company',
                value: client.company,
              ),
              const Divider(height: 1, indent: 62),
              _DetailTile(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: client.email,
              ),
              const Divider(height: 1, indent: 62),
              _DetailTile(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: client.phone,
              ),
              const Divider(height: 1, indent: 62),
              _DetailTile(
                icon: Icons.verified_user_outlined,
                label: 'Status',
                value: client.status,
              ),
              const Divider(height: 1, indent: 62),
              _DetailTile(
                icon: Icons.language_rounded,
                label: 'Website',
                value: client.website,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _addressRow('Address Line 1', client.addressLine1),
                _addressRow('Address Line 2', client.addressLine2),
                _addressRow('City', client.city),
                _addressRow('County / State', client.countyState),
                _addressRow('Postcode', client.postcode),
                _addressRow('Country', client.country, isLast: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Notes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              client.notes.isEmpty ? 'Not provided' : client.notes,
              style: const TextStyle(height: 1.5, color: AppColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('profileEditClientButton'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Edit Client'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('profileDeleteClientButton'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete'),
        ),
      ],
    ),
  );
}

Widget _addressRow(String label, String value, {bool isLast = false}) =>
    Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.trim().isEmpty ? 'Not provided' : value.trim(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

class _WorkspaceGrid extends StatelessWidget {
  const _WorkspaceGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.35,
    children: children,
  );
}

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.blue),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.blue, size: 20),
    ),
    title: Text(
      label,
      style: const TextStyle(color: AppColors.muted, fontSize: 12),
    ),
    subtitle: Text(
      value.isEmpty ? 'Not provided' : value,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
