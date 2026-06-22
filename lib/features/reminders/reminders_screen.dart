import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/client.dart';
import '../../models/reminder.dart';
import '../../services/crm_api.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.api});

  final CrmApi api;

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
      final reminders = await widget.api.fetchReminders();
      if (mounted) setState(() => _reminders = reminders);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _addReminder() async {
    setState(() => _isCreating = true);
    try {
      final clients = await widget.api.fetchClients();
      if (!mounted) return;
      if (clients.isEmpty) {
        _showMessage(
          'Add a CRM client before creating a reminder.',
          isError: true,
        );
        return;
      }
      final request = await _showCreateDialog(clients);
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

  Future<CreateReminderRequest?> _showCreateDialog(List<Client> clients) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateController = TextEditingController(
      text:
          '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}',
    );
    var clientId = clients.first.id;
    final result = await showDialog<CreateReminderRequest>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New reminder'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    key: const Key('reminderClientField'),
                    initialValue: clientId,
                    decoration: const InputDecoration(labelText: 'Client'),
                    items: clients
                        .map(
                          (client) => DropdownMenuItem(
                            value: client.id,
                            child: Text(client.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => clientId = value ?? clientId),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('newReminderField'),
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Reminder title',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a reminder title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('reminderDateField'),
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) =>
                        value != null &&
                            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
                        ? null
                        : 'Use YYYY-MM-DD',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmAddReminder'),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  CreateReminderRequest(
                    clientId: clientId,
                    title: titleController.text.trim(),
                    date: dateController.text.trim(),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    dateController.dispose();
    return result;
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
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addReminderButton'),
        onPressed: _isCreating ? null : _addReminder,
        icon: _isCreating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Add reminder'),
      ),
      body: _error != null && reminders == null
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
                    child: CheckboxListTile(
                      key: Key('reminder-${reminder.id}'),
                      value: reminder.isCompleted,
                      onChanged: reminder.isCompleted || isBusy
                          ? null
                          : (_) => _complete(reminder),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.blue,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      secondary: isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      title: Text(
                        reminder.title,
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
                          reminder.isCompleted ? 'Completed' : reminder.due,
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
    );
  }
}
