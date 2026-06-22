class DashboardData {
  const DashboardData({
    required this.totalClients,
    required this.activeJobs,
    required this.pendingInvoices,
    required this.upcomingReminders,
    this.isFallback = false,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalClients: (json['total_clients'] as num?)?.toInt() ?? 0,
      activeJobs: (json['active_jobs'] as num?)?.toInt() ?? 0,
      pendingInvoices: (json['pending_invoices'] as num?)?.toInt() ?? 0,
      upcomingReminders: (json['upcoming_reminders'] as num?)?.toInt() ?? 0,
    );
  }

  final int totalClients;
  final int activeJobs;
  final int pendingInvoices;
  final int upcomingReminders;
  final bool isFallback;
}
