class Reminder {
  Reminder({required this.title, required this.due, this.isCompleted = false});

  final String title;
  final String due;
  bool isCompleted;
}
