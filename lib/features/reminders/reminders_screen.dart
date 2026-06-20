import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/reminder.dart';
import '../../services/mock_crm_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final List<Reminder> _reminders = MockCrmService.createReminders();

  Future<void> _addReminder() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New reminder'),
        content: TextField(key: const Key('newReminderField'), controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'What do you need to do?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty) {
      setState(() => _reminders.add(Reminder(title: title, due: 'New · No due date')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(key: const Key('addReminderButton'), onPressed: _addReminder, icon: const Icon(Icons.add_rounded), label: const Text('Add reminder')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _reminders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reminder = _reminders[index];
          return Card(child: CheckboxListTile(
            key: Key('reminder-$index'),
            value: reminder.isCompleted,
            onChanged: (value) => setState(() => reminder.isCompleted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.blue,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            title: Text(reminder.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: reminder.isCompleted ? TextDecoration.lineThrough : null, color: reminder.isCompleted ? AppColors.muted : AppColors.text)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(reminder.isCompleted ? 'Completed' : reminder.due, style: TextStyle(color: reminder.isCompleted ? const Color(0xFF10A874) : AppColors.muted))),
          ));
        },
      ),
    );
  }
}
