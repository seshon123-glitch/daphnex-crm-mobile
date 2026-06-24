import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/job.dart';
import '../../services/crm_api.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  List<Job>? _jobs;
  String? _error;
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final jobs = await widget.api.fetchJobs(status: _status);
      if (mounted) setState(() => _jobs = jobs);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _createJob() async {
    final result = await showDialog<_JobFormResult>(
      context: context,
      builder: (_) => const _JobDialog(),
    );
    if (result == null) return;
    try {
      await widget.api.createJob(
        CreateJobRequest(
          clientId: result.clientId,
          title: result.title,
          description: result.description,
          notes: result.notes,
          startDate: result.startDate,
          deadline: result.deadline,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job created.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs / Projects')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createJobButton'),
        onPressed: _createJob,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Job / Project'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'active', label: Text('Active')),
                ButtonSegment(value: 'completed', label: Text('Done')),
              ],
              selected: {_status},
              onSelectionChanged: (value) {
                setState(() {
                  _status = value.first;
                  _jobs = null;
                });
                _load();
              },
            ),
          ),
          Expanded(
            child: _error != null
                ? ErrorStateView(message: _error!, onRetry: _load)
                : _jobs == null
                ? const LoadingView(label: 'Loading jobs / projects…')
                : _jobs!.isEmpty
                ? const EmptyStateView(
                    message: 'No jobs / projects found.',
                    icon: Icons.work_outline_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: _jobs!.length,
                      itemBuilder: (context, index) {
                        final job = _jobs![index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              job.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text('${job.clientName}\n${job.status}'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => JobDetailScreen(
                                      api: widget.api,
                                      job: job,
                                    ),
                                  ),
                                )
                                .then((_) => _load()),
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

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.api, required this.job});

  final CrmApi api;
  final Job job;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Job? _job;
  String? _error;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final job = await widget.api.fetchJob(widget.job.id);
      if (mounted) setState(() => _job = job);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _completeOrReopen(bool complete) async {
    try {
      final job = complete
          ? await widget.api.completeJob(widget.job.id)
          : await widget.api.reopenJob(widget.job.id);
      if (mounted) setState(() => _job = job);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _addNotes() async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => const _NotesDialog(),
    );
    if (notes == null || notes.trim().isEmpty) return;
    try {
      final job = await widget.api.addJobNotes(widget.job.id, notes);
      if (mounted) setState(() => _job = job);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return Scaffold(
      appBar: AppBar(title: const Text('Job / project detail')),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : job == null
          ? const LoadingView(label: 'Loading job / project…')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  job.clientName,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Status', job.status),
                        _row('Start date', job.startDate),
                        _row(
                          'Completed',
                          job.completionDate ?? 'Not completed',
                        ),
                        _row('Description', job.description),
                        _row(
                          'Notes',
                          job.notes.isEmpty ? 'No notes.' : job.notes,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _completeOrReopen(true),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _completeOrReopen(false),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Reopen'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _addNotes,
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Add notes'),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Recent activity',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                if (job.recentActivity.isEmpty)
                  const Text(
                    'No recent activity.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  ...job.recentActivity.map(
                    (item) => ListTile(title: Text(item)),
                  ),
              ],
            ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        Text(value.isEmpty ? 'Not set' : value),
      ],
    ),
  );
}

class _JobDialog extends StatefulWidget {
  const _JobDialog();

  @override
  State<_JobDialog> createState() => _JobDialogState();
}

class _JobDialogState extends State<_JobDialog> {
  final _clientId = TextEditingController(text: '1');
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _start = TextEditingController();
  final _deadline = TextEditingController();

  @override
  void dispose() {
    _clientId.dispose();
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    _start.dispose();
    _deadline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create job / project'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _clientId,
            decoration: const InputDecoration(labelText: 'Client ID'),
          ),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Job / project title'),
          ),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          TextField(
            controller: _start,
            decoration: const InputDecoration(
              labelText: 'Start date YYYY-MM-DD',
            ),
          ),
          TextField(
            controller: _deadline,
            decoration: const InputDecoration(labelText: 'Deadline YYYY-MM-DD'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _JobFormResult(
            clientId: int.tryParse(_clientId.text) ?? 0,
            title: _title.text,
            description: _description.text,
            notes: _notes.text,
            startDate: _start.text,
            deadline: _deadline.text,
          ),
        ),
        child: const Text('Create'),
      ),
    ],
  );
}

class _NotesDialog extends StatefulWidget {
  const _NotesDialog();

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add job / project notes'),
    content: TextField(
      controller: _notes,
      minLines: 3,
      maxLines: 5,
      decoration: const InputDecoration(labelText: 'Notes'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _notes.text),
        child: const Text('Save'),
      ),
    ],
  );
}

class _JobFormResult {
  const _JobFormResult({
    required this.clientId,
    required this.title,
    required this.description,
    required this.notes,
    required this.startDate,
    required this.deadline,
  });

  final int clientId;
  final String title;
  final String description;
  final String notes;
  final String startDate;
  final String deadline;
}
