import '../models/activity.dart';
import '../models/client.dart';
import '../models/reminder.dart';

abstract final class MockCrmService {
  /// Future integration point: replace these fixtures with REST API responses.
  static const clients = <Client>[
    Client(
      name: 'Olivia Bennett',
      email: 'olivia@northstar.co.uk',
      phone: '+44 7700 900123',
      company: 'Northstar Studio',
      notes: 'Prefers email updates. Reviewing a quarterly support package.',
      initials: 'OB',
      activities: [
        Activity(title: 'Proposal sent', detail: 'Website care plan', date: 'Today, 10:30'),
        Activity(title: 'Call completed', detail: 'Discussed Q3 priorities', date: '18 Jun'),
        Activity(title: 'Client added', detail: 'Imported from enquiry', date: '12 Jun'),
      ],
    ),
    Client(
      name: 'Marcus Chen',
      email: 'marcus@brightline.io',
      phone: '+44 7700 900456',
      company: 'Brightline Digital',
      notes: 'Monthly retainer client. Next review scheduled for July.',
      initials: 'MC',
      activities: [
        Activity(title: 'Invoice paid', detail: 'Invoice #1048', date: 'Yesterday'),
        Activity(title: 'Meeting booked', detail: 'Monthly review', date: '15 Jun'),
      ],
    ),
    Client(
      name: 'Amelia Foster',
      email: 'amelia@foundryhome.com',
      phone: '+44 7700 900789',
      company: 'Foundry Home',
      notes: 'Interested in a customer loyalty programme later this year.',
      initials: 'AF',
      activities: [
        Activity(title: 'Note added', detail: 'Loyalty discovery brief', date: '17 Jun'),
        Activity(title: 'Email opened', detail: 'Welcome sequence', date: '14 Jun'),
      ],
    ),
    Client(
      name: 'Noah Williams',
      email: 'noah@oakandstone.uk',
      phone: '+44 7700 901012',
      company: 'Oak & Stone',
      notes: 'Send project progress each Friday afternoon.',
      initials: 'NW',
      activities: [
        Activity(title: 'Task completed', detail: 'Brand asset upload', date: '19 Jun'),
      ],
    ),
  ];

  static List<Reminder> createReminders() => [
    Reminder(title: 'Follow up with Olivia', due: 'Today · 2:00 PM'),
    Reminder(title: 'Send Brightline invoice', due: 'Tomorrow · 9:00 AM'),
    Reminder(title: 'Prepare Oak & Stone update', due: 'Friday · 3:30 PM'),
  ];
}
