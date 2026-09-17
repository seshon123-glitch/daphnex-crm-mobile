import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/date_time_picker_fields.dart';
import '../../core/widgets/workspace_banner.dart';
import '../../models/client.dart';
import '../../models/invoice.dart';
import '../../models/job.dart';
import '../../models/project_expense.dart';
import '../../services/crm_api.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key, required this.api, this.client});

  final CrmApi api;
  final Client? client;

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
      final jobs = await widget.api.fetchJobs(
        status: _status,
        clientId: widget.client?.id,
      );
      if (mounted) {
        setState(() => _jobs = jobs);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _createJob() async {
    final clients = widget.client == null
        ? await widget.api.fetchClients()
        : <Client>[widget.client!];
    if (!mounted) return;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a client before creating a job.')),
      );
      return;
    }
    final result = await showDialog<_JobFormResult>(
      context: context,
      builder: (_) => _JobDialog(clients: clients, lockedClient: widget.client),
    );
    if (result == null) return;
    try {
      await widget.api.createJob(
        CreateJobRequest(
          clientId: result.clientId,
          title: result.title,
          description: result.description,
          notes: result.notes,
          status: result.status,
          priority: result.priority,
          type: result.type,
          estimatedValue: result.estimatedValue,
          expenseAmount: result.expenseAmount,
          expenseNotes: result.expenseNotes,
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
      appBar: AppBar(
        title: Text(
          widget.client == null
              ? 'Jobs / Projects'
              : '${widget.client!.name} jobs',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createJobButton'),
        heroTag: 'jobs-add-job-fab',
        onPressed: _createJob,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Job / Project'),
      ),
      body: Column(
        children: [
          if (widget.client == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: WorkspaceBanner(session: widget.api.currentSession),
            ),
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
                              '${index + 1}. ${job.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              [
                                if (widget.client == null) job.clientName,
                                job.status,
                                if (job.deadline.isNotEmpty)
                                  'Deadline ${job.deadline}',
                              ].join('\n'),
                            ),
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

class ClientProjectExpensesScreen extends StatefulWidget {
  const ClientProjectExpensesScreen({
    super.key,
    required this.api,
    required this.client,
  });

  final CrmApi api;
  final Client client;

  @override
  State<ClientProjectExpensesScreen> createState() =>
      _ClientProjectExpensesScreenState();
}

class _ClientProjectExpensesScreenState
    extends State<ClientProjectExpensesScreen> {
  List<Job>? _jobs;
  List<ProjectExpense>? _expenses;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({
    ProjectExpense? ensureVisible,
    Job? ensureVisibleJob,
  }) async {
    setState(() => _error = null);
    try {
      final jobs = await widget.api.fetchJobs(clientId: widget.client.id);
      final loadedExpenses = await _loadClientProjectExpenses(jobs);
      final expenses = _withEnsuredExpense(
        loadedExpenses,
        ensureVisible,
        ensureVisibleJob,
      );
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _expenses = expenses;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<List<ProjectExpense>> _loadClientProjectExpenses(
    List<Job> jobs,
  ) async {
    final expenses = <ProjectExpense>[];
    for (final job in jobs) {
      final projectExpenses = await widget.api.fetchProjectExpenses(
        projectId: job.id,
      );
      expenses.addAll(
        projectExpenses
            .where(
              (expense) =>
                  expense.projectId == 0 || expense.projectId == job.id,
            )
            .map((expense) => _expenseForClientProject(expense, job)),
      );
    }
    return expenses;
  }

  Future<void> _addExpense() async {
    final jobs = _jobs ?? const <Job>[];
    if (jobs.isEmpty) return;
    final job = await showDialog<Job>(
      context: context,
      builder: (_) => _ProjectSelectionDialog(jobs: jobs),
    );
    if (job == null) return;
    final request = await showDialog<CreateProjectExpenseRequest>(
      context: context,
      builder: (_) => const _ExpenseDialog(),
    );
    if (request == null) return;
    try {
      final created = await widget.api.createJobExpense(job.id, request);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense saved.')));
      await _load(ensureVisible: created, ensureVisibleJob: job);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save expense: $error')));
    }
  }

  ProjectExpense _expenseForClientProject(ProjectExpense expense, Job job) =>
      ProjectExpense(
        id: expense.id,
        clientId: widget.client.id,
        clientName: expense.clientName.isNotEmpty
            ? expense.clientName
            : widget.client.name,
        projectId: job.id,
        projectName: expense.projectName.isNotEmpty
            ? expense.projectName
            : job.title,
        expenseDate: expense.expenseDate,
        description: expense.description,
        amount: expense.amount,
        currency: expense.currency,
      );

  List<ProjectExpense> _withEnsuredExpense(
    List<ProjectExpense> expenses,
    ProjectExpense? ensureVisible,
    Job? ensureVisibleJob,
  ) {
    Job? job = ensureVisibleJob;
    if (ensureVisible != null) {
      if (job == null || job.id != ensureVisible.projectId) {
        for (final candidate in _jobs ?? const <Job>[]) {
          if (candidate.id == ensureVisible.projectId) {
            job = candidate;
            break;
          }
        }
      }
    }
    if (ensureVisible == null ||
        job == null ||
        expenses.any((expense) => expense.id == ensureVisible.id)) {
      return expenses;
    }

    return <ProjectExpense>[
      ...expenses,
      _expenseForClientProject(ensureVisible, job),
    ];
  }

  Future<void> _openExpense(ProjectExpense expense) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectExpenseDetailScreen(
          api: widget.api,
          initialExpense: expense,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _jobs;
    final expenses = _expenses;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.client.name} expenses')),
      floatingActionButton: jobs == null || jobs.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('clientAddProjectExpenseButton'),
              heroTag: 'client-project-expenses-add',
              onPressed: _addExpense,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
            ),
      body: _error != null && jobs == null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : jobs == null || expenses == null
          ? const LoadingView(label: 'Loading project expenses…')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Project Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.client.name} expenses are saved directly against the selected project and do not affect Turnover.',
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (jobs.isEmpty)
                    const EmptyStateView(
                      message:
                          'No projects available. Create a project before adding project expenses.',
                      icon: Icons.work_outline_rounded,
                    )
                  else if (expenses.isEmpty)
                    const EmptyStateView(
                      message:
                          'No project expenses recorded for this client yet.',
                      icon: Icons.payments_outlined,
                    )
                  else
                    ...expenses.asMap().entries.map((entry) {
                      final expense = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            key: Key('clientProjectExpense-${expense.id}'),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lightBlue,
                              child: Text(
                                '${entry.key + 1}.',
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(expense.description),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (expense.projectName.isNotEmpty)
                                  Text(expense.projectName),
                                if (expense.expenseDate.isNotEmpty)
                                  Text(expense.expenseDate),
                              ],
                            ),
                            trailing: Text(
                              moneyFromMinorUnits(
                                expense.amount,
                                currency: expense.currency,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            isThreeLine: expense.projectName.isNotEmpty,
                            onTap: () => _openExpense(expense),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _ProjectSelectionDialog extends StatelessWidget {
  const _ProjectSelectionDialog({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Select project'),
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project *',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return ListTile(
                  key: Key('selectExpenseProject-${job.id}'),
                  title: Text(job.title),
                  subtitle: Text(job.status),
                  onTap: () => Navigator.pop(context, job),
                );
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
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
      if (mounted) {
        setState(() => _job = job);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              complete
                  ? 'Job / project marked complete.'
                  : 'Job / project reopened.',
            ),
          ),
        );
        await _load();
      }
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

  Future<void> _editJob() async {
    final job = _job;
    if (job == null) return;
    try {
      final clients = [
        Client(
          id: job.clientId,
          name: job.clientName,
          email: '',
          phone: '',
          company: job.clientName,
        ),
      ];
      final result = await showDialog<_JobFormResult>(
        context: context,
        builder: (_) => _JobDialog(
          clients: clients,
          lockedClient: clients.first,
          initialJob: job,
        ),
      );
      if (result == null) return;
      final updated = await widget.api.updateJob(
        job.id,
        CreateJobRequest(
          clientId: result.clientId,
          title: result.title,
          description: result.description,
          notes: result.notes,
          status: result.status,
          priority: result.priority,
          type: result.type,
          estimatedValue: result.estimatedValue,
          expenseAmount: result.expenseAmount,
          expenseNotes: result.expenseNotes,
          startDate: result.startDate,
          deadline: result.deadline,
        ),
      );
      if (mounted) {
        setState(() => _job = updated);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Job / project updated.')));
        await _load();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update job: $error')));
    }
  }

  Future<void> _openExpenses() async {
    final job = _job;
    if (job == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectExpensesScreen(api: widget.api, job: job),
      ),
    );
  }

  Future<void> _deleteJob() async {
    final job = _job;
    if (job == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete job / project?'),
        content: Text('Delete "${job.title}"? This cannot be undone.'),
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
      await widget.api.deleteJob(job.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job / project deleted.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete job: $error')));
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
                        _row('Project type', job.type),
                        _row('Priority', job.priority),
                        _row('Estimated value', job.estimatedValue),
                        _row('Start date', job.startDate),
                        _row('Deadline', job.deadline),
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
                  key: const Key('editJobButton'),
                  onPressed: _editJob,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Job / Project'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('projectExpensesButton'),
                  onPressed: _openExpenses,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Project Expenses'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _addNotes,
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Add notes'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('deleteJobButton'),
                  onPressed: _deleteJob,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Job / Project'),
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

class ProjectExpensesScreen extends StatefulWidget {
  const ProjectExpensesScreen({
    super.key,
    required this.api,
    required this.job,
  });

  final CrmApi api;
  final Job job;

  @override
  State<ProjectExpensesScreen> createState() => _ProjectExpensesScreenState();
}

class _ProjectExpensesScreenState extends State<ProjectExpensesScreen> {
  List<ProjectExpense>? _expenses;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final expenses = await widget.api.fetchProjectExpenses(
        clientId: widget.job.clientId,
        projectId: widget.job.id,
      );
      if (mounted) setState(() => _expenses = expenses);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _addExpense() async {
    final request = await showDialog<CreateProjectExpenseRequest>(
      context: context,
      builder: (_) => const _ExpenseDialog(),
    );
    if (request == null) return;
    try {
      await widget.api.createJobExpense(widget.job.id, request);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense saved.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save expense: $error')));
    }
  }

  Future<void> _openExpense(ProjectExpense expense) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectExpenseDetailScreen(
          api: widget.api,
          initialExpense: expense,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Project Expenses')),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('addProjectExpenseButton'),
      heroTag: 'project-expenses-add',
      onPressed: _addExpense,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Expense'),
    ),
    body: _error != null
        ? ErrorStateView(message: _error!, onRetry: _load)
        : _expenses == null
        ? const LoadingView(label: 'Loading project expenses…')
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.job.clientName} · expenses are tracked as individual financial records and do not affect Turnover.',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_expenses!.isEmpty)
                  const EmptyStateView(
                    message: 'No project expenses yet.',
                    icon: Icons.receipt_long_outlined,
                  )
                else
                  ..._expenses!.asMap().entries.map((entry) {
                    final expense = entry.value;
                    return Card(
                      child: ListTile(
                        key: Key('projectExpense-${expense.id}'),
                        leading: CircleAvatar(child: Text('${entry.key + 1}')),
                        title: Text(expense.description),
                        subtitle: Text(
                          [
                            expense.expenseDate,
                            if (expense.projectName.isNotEmpty)
                              expense.projectName,
                          ].join('\n'),
                        ),
                        isThreeLine: expense.projectName.isNotEmpty,
                        trailing: Text(
                          moneyFromMinorUnits(
                            expense.amount,
                            currency: expense.currency,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        onTap: () => _openExpense(expense),
                      ),
                    );
                  }),
              ],
            ),
          ),
  );
}

class ProjectExpenseDetailScreen extends StatefulWidget {
  const ProjectExpenseDetailScreen({
    super.key,
    required this.api,
    required this.initialExpense,
  });

  final CrmApi api;
  final ProjectExpense initialExpense;

  @override
  State<ProjectExpenseDetailScreen> createState() =>
      _ProjectExpenseDetailScreenState();
}

class _ProjectExpenseDetailScreenState
    extends State<ProjectExpenseDetailScreen> {
  late ProjectExpense _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.initialExpense;
  }

  Future<void> _edit() async {
    final request = await showDialog<CreateProjectExpenseRequest>(
      context: context,
      builder: (_) => _ExpenseDialog(initialExpense: _expense),
    );
    if (request == null) return;
    try {
      final updated = await widget.api.updateProjectExpense(
        _expense.id,
        request,
      );
      if (mounted) {
        setState(() => _expense = updated);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expense updated.')));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update expense: $error')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'Delete this project expense? This cannot be undone.',
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
      await widget.api.deleteProjectExpense(_expense.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense deleted.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete expense: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Expense Detail')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Date', _expense.expenseDate),
                _detailRow('Description', _expense.description),
                _detailRow(
                  'Amount',
                  moneyFromMinorUnits(
                    _expense.amount,
                    currency: _expense.currency,
                  ),
                ),
                _detailRow('Project', _expense.projectName),
                _detailRow('Client', _expense.clientName),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('editProjectExpenseButton'),
          onPressed: _edit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Expense'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('deleteProjectExpenseButton'),
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete Expense'),
        ),
      ],
    ),
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        Text(value.isEmpty ? 'Not set' : value),
      ],
    ),
  );
}

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog({this.initialExpense});

  final ProjectExpense? initialExpense;

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _date;
  late final TextEditingController _description;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    final expense = widget.initialExpense;
    _date = TextEditingController(text: expense?.expenseDate ?? '');
    _description = TextEditingController(text: expense?.description ?? '');
    _amount = TextEditingController(
      text: expense == null ? '' : (expense.amount / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _date.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _amountValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    final parsed = num.tryParse(trimmed);
    if (parsed == null || parsed <= 0) return 'Enter an amount above zero';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CreateProjectExpenseRequest(
        expenseDate: _date.text,
        description: _description.text,
        amount: _amount.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initialExpense == null ? 'Add Expense' : 'Edit Expense'),
    content: SizedBox(
      width: double.maxFinite,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DatePickerFormField(
                key: const Key('expenseDateField'),
                controller: _date,
                labelText: 'Date *',
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('expenseDescriptionField'),
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Expense Description *',
                ),
                minLines: 2,
                maxLines: 4,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('expenseAmountField'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount *'),
                validator: _amountValidator,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Save')),
    ],
  );
}

class _JobDialog extends StatefulWidget {
  const _JobDialog({
    required this.clients,
    required this.lockedClient,
    this.initialJob,
  });

  final List<Client> clients;
  final Client? lockedClient;
  final Job? initialJob;

  @override
  State<_JobDialog> createState() => _JobDialogState();
}

class _JobDialogState extends State<_JobDialog> {
  static const _priorities = ['low', 'medium', 'high', 'urgent'];
  static const _statuses = [
    'lead',
    'quote_sent',
    'awaiting_deposit',
    'in_progress',
    'testing',
    'revision',
    'completed',
    'cancelled',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _estimatedValue = TextEditingController();
  final _start = TextEditingController();
  final _deadline = TextEditingController();
  late int _clientId;
  String _type = 'other';
  String _priority = 'medium';
  String _status = 'lead';

  @override
  void initState() {
    super.initState();
    final job = widget.initialJob;
    _clientId =
        widget.lockedClient?.id ?? job?.clientId ?? widget.clients.first.id;
    if (job != null) {
      _title.text = job.title;
      _description.text = job.description;
      _notes.text = job.notes;
      _estimatedValue.text = job.estimatedValue;
      _start.text = job.startDate;
      _deadline.text = job.deadline;
      _type = job.type.isEmpty ? 'other' : job.type;
      _priority = _priorities.contains(job.priority) ? job.priority : 'medium';
      _status = _statuses.contains(job.status) ? job.status : 'lead';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    _estimatedValue.dispose();
    _start.dispose();
    _deadline.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _JobFormResult(
        clientId: _clientId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        notes: _notes.text.trim(),
        type: _type,
        priority: _priority,
        status: _status,
        estimatedValue: _estimatedValue.text.trim(),
        expenseAmount: '',
        expenseNotes: '',
        startDate: _start.text.trim(),
        deadline: _deadline.text.trim(),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _moneyOrEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = num.tryParse(trimmed);
    if (parsed == null || parsed < 0) return 'Enter a valid amount';
    return null;
  }

  String? _dateOrEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)
        ? null
        : 'Use YYYY-MM-DD';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initialJob == null ? 'Create job / project' : 'Edit job / project',
    ),
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
                  key: const Key('jobClientField'),
                  initialValue: _clientId,
                  decoration: const InputDecoration(labelText: 'Client *'),
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
                    if (value != null) setState(() => _clientId = value);
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: const Key('jobTitleField'),
                controller: _title,
                decoration: const InputDecoration(labelText: 'Project Title *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('jobPriorityField'),
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
              DropdownButtonFormField<String>(
                key: const Key('jobStatusField'),
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
                key: const Key('jobEstimatedValueField'),
                controller: _estimatedValue,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Estimated Project Value',
                ),
                validator: _moneyOrEmpty,
              ),
              const SizedBox(height: 12),
              DatePickerFormField(
                key: const Key('jobStartDateField'),
                controller: _start,
                labelText: 'Start Date',
                validator: _dateOrEmpty,
              ),
              const SizedBox(height: 12),
              DatePickerFormField(
                key: const Key('jobDeadlineField'),
                controller: _deadline,
                labelText: 'Deadline',
                validator: _dateOrEmpty,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Project Description / Job Brief',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Internal Notes'),
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
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.initialJob == null ? 'Create' : 'Save'),
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
    required this.type,
    required this.priority,
    required this.status,
    required this.estimatedValue,
    required this.expenseAmount,
    required this.expenseNotes,
    required this.startDate,
    required this.deadline,
  });

  final int clientId;
  final String title;
  final String description;
  final String notes;
  final String type;
  final String priority;
  final String status;
  final String estimatedValue;
  final String expenseAmount;
  final String expenseNotes;
  final String startDate;
  final String deadline;
}

String _label(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
