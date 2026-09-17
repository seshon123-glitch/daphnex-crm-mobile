import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/date_time_picker_fields.dart';
import '../../core/widgets/workspace_banner.dart';
import '../../models/client.dart';
import '../../models/crm_task.dart';
import '../../models/job.dart';
import '../../services/crm_api.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.api, this.client});

  final CrmApi api;
  final Client? client;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<CrmTask>? _tasks;
  String? _error;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final tasks = await widget.api.fetchTasks(clientId: widget.client?.id);
      if (mounted) {
        setState(() => _tasks = tasks);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _createTask() async {
    setState(() => _creating = true);
    try {
      final clients = widget.client == null
          ? await widget.api.fetchClients()
          : <Client>[widget.client!];
      final jobs = await widget.api.fetchJobs(clientId: widget.client?.id);
      if (!mounted) return;
      if (clients.isEmpty) {
        _message('Add a client before creating a task.', isError: true);
        return;
      }
      final request = await showDialog<CreateTaskRequest>(
        context: context,
        builder: (_) => _TaskDialog(
          clients: clients,
          jobs: jobs,
          lockedClient: widget.client,
        ),
      );
      if (request == null) return;
      await widget.api.createTask(request);
      if (!mounted) return;
      _message('Task created.');
      await _load();
    } catch (error) {
      if (mounted) _message('Task could not be saved: $error', isError: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _openTask(CrmTask task) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          api: widget.api,
          task: task,
          lockedClient: widget.client,
        ),
      ),
    );
    await _load();
  }

  Future<void> _deleteTask(CrmTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
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
    setState(() => _creating = true);
    try {
      await widget.api.deleteTask(task.id);
      if (!mounted) return;
      _message('Task deleted.');
      await _load();
    } catch (error) {
      if (mounted) _message('Task could not be deleted: $error', isError: true);
    } finally {
      if (mounted) setState(() => _creating = false);
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
    final client = widget.client;
    final tasks = _tasks;
    return Scaffold(
      appBar: AppBar(
        title: Text(client == null ? 'Tasks' : '${client.name} tasks'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createTaskButton'),
        heroTag: 'tasks-add-task-fab',
        onPressed: _creating ? null : _createTask,
        icon: const Icon(Icons.add_task_rounded),
        label: Text(_creating ? 'Saving…' : 'Task'),
      ),
      body: Column(
        children: [
          if (client == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: WorkspaceBanner(session: widget.api.currentSession),
            ),
          Expanded(
            child: _error != null && tasks == null
                ? ErrorStateView(
                    message:
                        'Real Task endpoints are required for mobile parity. $_error',
                    onRetry: _load,
                  )
                : tasks == null
                ? const LoadingView(label: 'Loading tasks…')
                : tasks.isEmpty
                ? const EmptyStateView(
                    message: 'No tasks found.',
                    icon: Icons.task_alt_outlined,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          child: ListTile(
                            key: Key('task-${task.id}'),
                            onTap: () => _openTask(task),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lightBlue,
                              child: Text(
                                '${index + 1}.',
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (client == null) task.clientName,
                                if (task.projectName.isNotEmpty)
                                  task.projectName,
                                task.status,
                                if (task.dueDate.isNotEmpty)
                                  'Due ${task.dueDate}',
                              ].join('\n'),
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Delete task',
                              onPressed: () => _deleteTask(task),
                              icon: const Icon(Icons.delete_outline_rounded),
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

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.api,
    required this.task,
    this.lockedClient,
  });

  final CrmApi api;
  final CrmTask task;
  final Client? lockedClient;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late CrmTask _task;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
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
      final request = await showDialog<CreateTaskRequest>(
        context: context,
        builder: (_) => _TaskDialog(
          clients: clients,
          jobs: jobs,
          lockedClient: widget.lockedClient,
          initialTask: _task,
        ),
      );
      if (request == null) return;
      final updated = await widget.api.updateTask(_task.id, request);
      if (!mounted) return;
      setState(() => _task = updated);
      _message('Task updated.');
    } catch (error) {
      if (mounted) _message('Task could not be saved: $error', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setCompleted(bool completed) async {
    setState(() => _busy = true);
    try {
      final updated = await widget.api.updateTask(
        _task.id,
        _requestFromTask(_task, status: completed ? 'completed' : 'pending'),
      );
      if (!mounted) return;
      setState(() => _task = updated);
      _message(completed ? 'Task completed.' : 'Task reopened.');
    } catch (error) {
      if (mounted) _message('Task could not be updated: $error', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${_task.title}"? This cannot be undone.'),
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
      await widget.api.deleteTask(_task.id);
      if (!mounted) return;
      _message('Task deleted.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _message('Task could not be deleted: $error', isError: true);
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
    final isCompleted = _task.status == 'completed';
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Task detail')),
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
                      _task.title,
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
                        Chip(label: Text(_label(_task.status))),
                        Chip(label: Text(_label(_task.priority))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DetailTile(label: 'Client', value: _task.clientName),
            _DetailTile(
              label: 'Linked project',
              value: _task.projectName.isEmpty
                  ? 'Not provided'
                  : _task.projectName,
            ),
            _DetailTile(label: 'Assigned to', value: _task.assignedTo),
            _DetailTile(label: 'Due date', value: _task.dueDate),
            _DetailTile(label: 'Priority', value: _label(_task.priority)),
            _DetailTile(label: 'Status', value: _label(_task.status)),
            _DetailTile(label: 'Description', value: _task.description),
            _DetailTile(label: 'Internal notes', value: _task.internalNotes),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('editTaskButton'),
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('toggleTaskButton'),
              onPressed: _busy ? null : () => _setCompleted(!isCompleted),
              icon: Icon(
                isCompleted
                    ? Icons.replay_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(isCompleted ? 'Reopen' : 'Complete'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('deleteTaskButton'),
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

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    required this.clients,
    required this.jobs,
    required this.lockedClient,
    this.initialTask,
  });

  final List<Client> clients;
  final List<Job> jobs;
  final Client? lockedClient;
  final CrmTask? initialTask;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  static const _priorities = ['low', 'medium', 'high', 'urgent'];
  static const _statuses = ['pending', 'in_progress', 'completed'];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _assignedUserId = TextEditingController();
  final _dueDate = TextEditingController();
  final _description = TextEditingController();
  final _internalNotes = TextEditingController();
  late int _clientId;
  int _projectId = 0;
  String _priority = 'medium';
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    _clientId =
        widget.lockedClient?.id ??
        initialTask?.clientId ??
        widget.clients.first.id;
    _projectId = initialTask?.projectId ?? 0;
    _priority = initialTask?.priority ?? 'medium';
    _status = initialTask?.status ?? 'pending';
    _title.text = initialTask?.title ?? '';
    _assignedUserId.text =
        initialTask?.assignedUserId == null || initialTask!.assignedUserId <= 0
        ? ''
        : initialTask.assignedUserId.toString();
    _dueDate.text = initialTask?.dueDate ?? '';
    _description.text = initialTask?.description ?? '';
    _internalNotes.text = initialTask?.internalNotes ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _assignedUserId.dispose();
    _dueDate.dispose();
    _description.dispose();
    _internalNotes.dispose();
    super.dispose();
  }

  List<Job> get _clientJobs =>
      widget.jobs.where((job) => job.clientId == _clientId).toList();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CreateTaskRequest(
        clientId: _clientId,
        projectId: _projectId,
        assignedUserId: int.tryParse(_assignedUserId.text.trim()) ?? 0,
        title: _title.text.trim(),
        dueDate: _dueDate.text.trim(),
        priority: _priority,
        status: _status,
        description: _description.text.trim(),
        internalNotes: _internalNotes.text.trim(),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _dateOrEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)
        ? null
        : 'Use YYYY-MM-DD';
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _clientJobs;
    if (_projectId != 0 && !jobs.any((job) => job.id == _projectId)) {
      _projectId = 0;
    }
    return AlertDialog(
      title: Text(widget.initialTask == null ? 'Add task' : 'Edit task'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.lockedClient == null) ...[
                  DropdownButtonFormField<int>(
                    key: const Key('taskClientField'),
                    initialValue: _clientId,
                    decoration: const InputDecoration(labelText: 'Client'),
                    items: widget.clients
                        .map(
                          (client) => DropdownMenuItem(
                            value: client.id,
                            child: Text(
                              client.company.isEmpty
                                  ? client.name
                                  : client.company,
                            ),
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
                  key: const Key('taskProjectField'),
                  initialValue: _projectId,
                  decoration: const InputDecoration(labelText: 'Project'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('No linked project'),
                    ),
                    ...jobs.map(
                      (job) => DropdownMenuItem(
                        value: job.id,
                        child: Text(job.title),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _projectId = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('taskTitleField'),
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Task Title *'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DatePickerFormField(
                  key: const Key('taskDueDateField'),
                  controller: _dueDate,
                  labelText: 'Due Date',
                  validator: _dateOrEmpty,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('taskPriorityField'),
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: _priorities
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_label(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('taskDescriptionField'),
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  key: const Key('taskMoreOptions'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('More Options'),
                  children: [
                    TextFormField(
                      key: const Key('taskAssignedToField'),
                      controller: _assignedUserId,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Assigned To',
                        helperText:
                            'Optional user ID until mobile team selector is added.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('taskStatusField'),
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _statuses
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_label(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('taskInternalNotesField'),
                      controller: _internalNotes,
                      decoration: const InputDecoration(
                        labelText: 'Internal Notes',
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancelTaskForm'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveTaskForm'),
          onPressed: _submit,
          child: Text(widget.initialTask == null ? 'Create' : 'Save'),
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

CreateTaskRequest _requestFromTask(CrmTask task, {String? status}) =>
    CreateTaskRequest(
      clientId: task.clientId,
      projectId: task.projectId,
      assignedUserId: task.assignedUserId,
      title: task.title,
      dueDate: task.dueDate,
      priority: task.priority,
      status: status ?? task.status,
      description: task.description,
      internalNotes: task.internalNotes,
    );

String _label(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
