import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/crm_notification.dart';
import '../../services/crm_api.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.api});

  final CrmApi api;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<CrmNotification>? _notifications;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final notifications = await widget.api.fetchNotifications();
      if (mounted) setState(() => _notifications = notifications);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _markRead(CrmNotification notification) async {
    try {
      await widget.api.markNotificationRead(notification.id);
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
      appBar: AppBar(title: const Text('Notifications')),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : _notifications == null
          ? const LoadingView(label: 'Loading notifications…')
          : _notifications!.isEmpty
          ? const EmptyStateView(
              message: 'No notifications found.',
              icon: Icons.mark_email_unread_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemCount: _notifications!.length,
                itemBuilder: (context, index) {
                  final notification = _notifications![index];
                  final related = notification.related.entries
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join(' • ');
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.read
                            ? const Color(0xFFE5E7EB)
                            : AppColors.lightBlue,
                        child: Icon(
                          notification.read
                              ? Icons.mark_email_read_outlined
                              : Icons.mark_email_unread_outlined,
                          color: notification.read
                              ? AppColors.muted
                              : AppColors.blue,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${notification.message}\n${related.isEmpty ? notification.type : related}',
                      ),
                      isThreeLine: true,
                      trailing: notification.read
                          ? null
                          : TextButton(
                              onPressed: () => _markRead(notification),
                              child: const Text('Read'),
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
