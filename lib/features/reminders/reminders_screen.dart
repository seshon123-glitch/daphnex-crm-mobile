import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/date_time_picker_fields.dart';
import '../../core/widgets/workspace_banner.dart';
import '../../models/client.dart';
import '../../models/job.dart';
import '../../models/reminder.dart';
import '../../services/crm_api.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.api, this.client});

  final CrmApi api;
  final Client? client;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder>? _reminders;
  String? _error;
  int? _completingId;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final reminders = await widget.api.fetchReminders(
        clientId: widget.client?.id,
      );
      if (mounted) {
        setState(() => _reminders = reminders);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _addReminder() async {
    setState(() => _isCreating = true);
    try {
      final clients = widget.client == null
          ? await widget.api.fetchClients()
          : <Client>[widget.client!];
      final jobs = await widget.api.fetchJobs(clientId: widget.client?.id);
      if (!mounted) return;
      if (clients.isEmpty) {
        _showMessage(
          'Add a CRM client before creating a reminder.',
          isError: true,
        );
        return;
      }
      final request = await _showCreateDialog(clients, jobs);
      if (request == null || !mounted) return;
      await widget.api.createReminder(request);
      if (!mounted) return;
      _showMessage('Reminder created successfully.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<CreateReminderRequest?> _showCreateDialog(
    List<Client> clients,
    List<Job> jobs,
  ) async {
    return showDialog<CreateReminderRequest>(
      context: context,
      builder: (_) => _CreateReminderDialog(
        clients: clients,
        jobs: jobs,
        lockedClient: widget.client,
      ),
    );
  }

  Future<void> _openReminder(Reminder reminder) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReminderDetailScreen(
          api: widget.api,
          reminder: reminder,
          lockedClient: widget.client,
        ),
      ),
    );
    await _load();
  }

  Future<void> _complete(Reminder reminder) async {
    setState(() => _completingId = reminder.id);
    try {
      final updated = await widget.api.completeReminder(reminder.id);
      if (!mounted) return;
      setState(() {
        final index = _reminders!.indexWhere((item) => item.id == reminder.id);
        if (index >= 0) _reminders![index] = updated;
      });
      _showMessage('Reminder marked as completed.');
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _completingId = null);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _reminders;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.client == null
              ? 'Reminders'
              : '${widget.client!.name} reminders',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addReminderButton'),
        heroTag: 'reminders-add-reminder-fab',
        onPressed: _isCreating ? null : _addReminder,
        icon: _isCreating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Add reminder'),
      ),
      body: Column(
        children: [
          if (widget.client == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: PremiumPageBanner(
                session: widget.api.currentSession,
                title: 'Reminders',
                subtitle:
                    'Keep follow-ups visible across the workspace, with client-linked reminders also available inside each client workspace.',
                icon: Icons.notifications_none_rounded,
                metrics: {
                  'Scope': 'Tenant',
                  'Status': 'Live',
                },
              ),
            ),
          Expanded(
            child: _error != null && reminders == null
                ? ErrorStateView(message: _error!, onRetry: _load)
                : reminders == null
                ? const LoadingView(label: 'Loading reminders…')
                : reminders.isEmpty
                ? const EmptyStateView(
                    message: 'No reminders yet',
                    icon: Icons.notifications_none_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: reminders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reminder = reminders[index];
                        final isBusy = _completingId == reminder.id;
                        return Card(
                          child: ListTile(
                            key: Key('reminder-${reminder.id}'),
                            onTap: () => _openReminder(reminder),
                            leading: CircleAvatar(
                              backgroundColor: reminder.isCompleted
                                  ? const Color(0xFFE9F8F2)
                                  : AppColors.lightBlue,
                              child: Icon(
                                reminder.isCompleted
                                    ? Icons.check_rounded
                                    : Icons.notifications_none_rounded,
                                color: reminder.isCompleted
                                    ? const Color(0xFF10A874)
                                    : AppColors.blue,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            trailing: isBusy
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    tooltip: reminder.isCompleted
                                        ? 'Reminder completed'
                                        : 'Complete reminder',
                                    onPressed: reminder.isCompleted
                                        ? null
                                        : () => _complete(reminder),
                                    icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                    ),
                                  ),
                            title: Text(
                              '${index + 1}. ${reminder.title}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: reminder.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: reminder.isCompleted
                                    ? AppColors.muted
                                    : AppColors.text,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                reminder.isCompleted
                                    ? 'Completed'
                                    : reminder.due,
                                style: TextStyle(
                                  color: reminder.isCompleted
                                      ? const Color(0xFF10A874)
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class ReminderDetailScreen extends StatefulWidget {
  const ReminderDetailScreen({
    super.key,
    required this.api,
    required this.reminder,
    this.lockedClient,
  });

  final CrmApi api;
  final Reminder reminder;
  final Client? lockedClient;

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  late Reminder _reminder;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reminder = widget.reminder;
  }

  Future<void> _edit() async {
    setState(() => _busy = true);
    try {
      final clients = widget.lockedClient == null
          ? await widget.api.fetchClients()
          : <Client>[widget.lockedClient!];
      final jobs = await widget.api.fetchJobs(
        clientId: widget.lockedClient?.id,
      );
      if (!mounted) return;
      final request = await showDialog<CreateReminderRequest>(
        context: context,
        builder: (_) => _CreateReminderDialog(
          clients: clients,
          jobs: jobs,
          lockedClient: widget.lockedClient,
          initialReminder: _reminder,
        ),
      );
      if (request == null) return;
      final updated = await widget.api.updateReminder(_reminder.id, request);
      if (!mounted) return;
      setState(() => _reminder = updated);
      _message('Reminder updated.');
    } catch (error) {
      if (mounted) _message(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setCompleted(bool completed) async {
    setState(() => _busy = true);
    try {
      final updated = completed
          ? await widget.api.completeReminder(_reminder.id)
          : await widget.api.updateReminder(
              _reminder.id,
              _requestFromReminder(_reminder, status: 'pending'),
            );
      if (!mounted) return;
      setState(() => _reminder = updated);
      _message(completed ? 'Reminder completed.' : 'Reminder reopened.');
    } catch (error) {
      if (mounted) _message(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('Delete "${_reminder.title}"? This cannot be undone.'),
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
    setState(() => _busy = true);
    try {
      await widget.api.deleteReminder(_reminder.id);
      if (!mounted) return;
      _message('Reminder deleted.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _message(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Reminder detail')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reminder.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(_label(_reminder.status))),
                        Chip(label: Text(_label(_reminder.priority))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DetailTile(
              label: 'Client',
              value: widget.lockedClient?.name ?? _reminder.clientName,
            ),
            _DetailTile(
              label: 'Linked project',
              value: _reminder.projectName.isNotEmpty
                  ? _reminder.projectName
                  : _reminder.projectId > 0
                  ? 'Project #${_reminder.projectId}'
                  : 'Not provided',
            ),
            _DetailTile(label: 'Date', value: _reminder.date),
            _DetailTile(label: 'Time', value: _reminder.time),
            _DetailTile(label: 'Priority', value: _label(_reminder.priority)),
            _DetailTile(label: 'Status', value: _label(_reminder.status)),
            _DetailTile(label: 'Description', value: _reminder.description),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('editReminderButton'),
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('toggleReminderButton'),
              onPressed: _busy
                  ? null
                  : () => _setCompleted(!_reminder.isCompleted),
              icon: Icon(
                _reminder.isCompleted
                    ? Icons.replay_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(_reminder.isCompleted ? 'Reopen' : 'Complete'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('deleteReminderButton'),
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateReminderDialog extends StatefulWidget {
  const _CreateReminderDialog({
    required this.clients,
    required this.jobs,
    required this.lockedClient,
    this.initialReminder,
  });

  final List<Client> clients;
  final List<Job> jobs;
  final Client? lockedClient;
  final Reminder? initialReminder;

  @override
  State<_CreateReminderDialog> createState() => _CreateReminderDialogState();
}

class _CreateReminderDialogState extends State<_CreateReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _descriptionController;
  late int _clientId;
  int _projectId = 0;
  String _priority = 'medium';
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    final initialReminder = widget.initialReminder;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _clientId =
        widget.lockedClient?.id ??
        initialReminder?.clientId ??
        widget.clients.first.id;
    _projectId = initialReminder?.projectId ?? 0;
    _priority = initialReminder?.priority ?? 'medium';
    _status = initialReminder?.status ?? 'pending';
    _titleController = TextEditingController(
      text: initialReminder?.title ?? '',
    );
    _timeController = TextEditingController(
      text: initialReminder?.time ?? '09:00',
    );
    _descriptionController = TextEditingController(
      text: initialReminder?.description ?? '',
    );
    _dateController = TextEditingController(
      text: initialReminder?.date ?? formatCrmDate(tomorrow),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CreateReminderRequest(
        clientId: _clientId,
        projectId: _projectId,
        title: _titleController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        priority: _priority,
        status: _status,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  List<Job> get _clientJobs =>
      widget.jobs.where((job) => job.clientId == _clientId).toList();

  @override
  Widget build(BuildContext context) {
    final jobs = _clientJobs;
    if (_projectId != 0 && !jobs.any((job) => job.id == _projectId)) {
      _projectId = 0;
    }
    return AlertDialog(
      title: Text(
        widget.initialReminder == null ? 'New reminder' : 'Edit reminder',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.lockedClient == null) ...[
                DropdownButtonFormField<int>(
                  key: const Key('reminderClientField'),
                  initialValue: _clientId,
                  decoration: const InputDecoration(labelText: 'Client *'),
                  items: widget.clients
                      .map(
                        (client) => DropdownMenuItem(
                          value: client.id,
                          child: Text(client.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _clientId = value;
                      _projectId = 0;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<int>(
                key: const Key('reminderProjectField'),
                initialValue: _projectId,
                decoration: const InputDecoration(labelText: 'Project'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('No linked project'),
                  ),
                  ...jobs.map(
                    (job) =>
                        DropdownMenuItem(value: job.id, child: Text(job.title)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _projectId = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('newReminderField'),
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title *',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a reminder title'
                    : null,
              ),
              const SizedBox(height: 12),
              DatePickerFormField(
                key: const Key('reminderDateField'),
                controller: _dateController,
                labelText: 'Reminder Date *',
                validator: (value) =>
                    value != null &&
                        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
                    ? null
                    : 'Use YYYY-MM-DD',
              ),
              const SizedBox(height: 12),
              TimePickerFormField(
                key: const Key('reminderTimeField'),
                controller: _timeController,
                labelText: 'Reminder Time',
                validator: (value) =>
                    value != null && RegExp(r'^\d{2}:\d{2}$').hasMatch(value)
                    ? null
                    : 'Use HH:MM',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('reminderPriorityField'),
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('reminderStatusField'),
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('reminderDescriptionField'),
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancelAddReminder'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirmAddReminder'),
          onPressed: _submit,
          child: Text(widget.initialReminder == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(
        label,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      subtitle: Text(
        value.trim().isEmpty ? 'Not provided' : value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

CreateReminderRequest _requestFromReminder(
  Reminder reminder, {
  String? status,
}) => CreateReminderRequest(
  clientId: reminder.clientId,
  projectId: reminder.projectId,
  title: reminder.title,
  date: reminder.date,
  time: reminder.time,
  priority: reminder.priority,
  status: status ?? reminder.status,
  description: reminder.description,
);

String _label(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
