class Activity {
  const Activity({
    required this.title,
    required this.detail,
    required this.date,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    final action = (json['action'] as String? ?? 'activity').replaceAll(
      '_',
      ' ',
    );
    final title = action
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return Activity(
      title: title,
      detail: '',
      date: json['created_at'] as String? ?? '',
    );
  }

  final String title;
  final String detail;
  final String date;
}
