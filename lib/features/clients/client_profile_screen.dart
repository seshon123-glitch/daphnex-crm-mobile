import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state_view.dart';
import '../../models/client.dart';
import '../../services/crm_api.dart';

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
      appBar: AppBar(title: const Text('Client profile')),
      body: _error != null
          ? ErrorStateView(message: _error!, onRetry: _load)
          : _profile == null
          ? const LoadingView(label: 'Loading client profile…')
          : _ProfileContent(client: _profile!),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.client});

  final Client client;

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
        const SizedBox(height: 22),
        Card(
          child: Column(
            children: [
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
                icon: Icons.business_outlined,
                label: 'Company',
                value: client.company,
              ),
            ],
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
