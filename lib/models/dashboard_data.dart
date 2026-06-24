class DashboardData {
  const DashboardData({
    required this.totalClients,
    required this.activeJobs,
    required this.pendingInvoices,
    required this.upcomingReminders,
    this.completedJobs = 0,
    this.unpaidInvoices = 0,
    this.outstandingInvoiceAmount = 0,
    this.unreadNotifications = 0,
    this.isFallback = false,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalClients: (json['total_clients'] as num?)?.toInt() ?? 0,
      activeJobs: (json['active_jobs'] as num?)?.toInt() ?? 0,
      pendingInvoices: (json['pending_invoices'] as num?)?.toInt() ?? 0,
      upcomingReminders: (json['upcoming_reminders'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      unpaidInvoices: (json['unpaid_invoices'] as num?)?.toInt() ?? 0,
      outstandingInvoiceAmount:
          (json['outstanding_invoice_amount'] as num?)?.toInt() ?? 0,
      unreadNotifications: (json['unread_notifications'] as num?)?.toInt() ?? 0,
    );
  }

  final int totalClients;
  final int activeJobs;
  final int pendingInvoices;
  final int upcomingReminders;
  final int completedJobs;
  final int unpaidInvoices;
  final int outstandingInvoiceAmount;
  final int unreadNotifications;
  final bool isFallback;
}
