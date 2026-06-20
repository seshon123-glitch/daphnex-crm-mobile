import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Good morning', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
          Text('Daphnex CRM'),
        ]),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: CircleAvatar(backgroundColor: AppColors.lightBlue, child: Text('DS', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.navy, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Business overview', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Everything is moving\nin the right direction.', style: TextStyle(color: Colors.white, fontSize: 24, height: 1.25, fontWeight: FontWeight.w800)),
              SizedBox(height: 18),
              Row(children: [Icon(Icons.trending_up_rounded, color: Color(0xFF9BE6BE), size: 18), SizedBox(width: 6), Text('12% growth this month', style: TextStyle(color: Colors.white))]),
            ]),
          ),
          const SizedBox(height: 24),
          Text('At a glance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.16,
            children: const [
              _StatCard(label: 'Total Clients', value: '48', icon: Icons.people_rounded, color: AppColors.blue),
              _StatCard(label: 'Active Jobs', value: '12', icon: Icons.work_outline_rounded, color: Color(0xFF7B61D1)),
              _StatCard(label: 'Pending Invoices', value: '7', icon: Icons.receipt_long_outlined, color: Color(0xFFF59E0B)),
              _StatCard(label: 'Upcoming Reminders', value: '5', icon: Icons.notifications_active_outlined, color: Color(0xFF10A874)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Today', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              leading: const CircleAvatar(backgroundColor: AppColors.lightBlue, child: Icon(Icons.call_outlined, color: AppColors.blue)),
              title: const Text('Client follow-up', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Olivia Bennett · 2:00 PM'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
