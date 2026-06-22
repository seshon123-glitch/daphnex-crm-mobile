import '../models/activity.dart';
import '../models/client.dart';
import '../models/dashboard_data.dart';
import '../models/reminder.dart';

abstract final class MockCrmService {
  /// Development-only fallback used when the dashboard API is unreachable.
  static const dashboardFallback = DashboardData(
    totalClients: 48,
    activeJobs: 12,
    pendingInvoices: 7,
    upcomingReminders: 5,
    isFallback: true,
  );

  /// Retained for development previews and offline tests only.
  static const clients = <Client>[
    Client(
      id: 1,
      name: 'Olivia Bennett',
      email: 'olivia@northstar.co.uk',
      phone: '+44 7700 900123',
      company: 'Northstar Studio',
      notes: 'Prefers email updates. Reviewing a quarterly support package.',
      activities: [
        Activity(
          title: 'Proposal Sent',
          detail: 'Website care plan',
          date: 'Today, 10:30',
        ),
      ],
    ),
    Client(
      id: 2,
      name: 'Marcus Chen',
      email: 'marcus@brightline.io',
      phone: '+44 7700 900456',
      company: 'Brightline Digital',
      notes: 'Monthly retainer client.',
    ),
  ];

  static const reminders = <Reminder>[
    Reminder(
      id: 1,
      title: 'Follow up with Olivia',
      date: '2026-06-22',
      time: '14:00',
      status: 'pending',
      clientId: 1,
    ),
  ];
}
