import 'package:flutter/material.dart';

typedef CrmDatePicker =
    Future<DateTime?> Function(
      BuildContext context,
      DateTime initialDate,
      DateTime firstDate,
      DateTime lastDate,
    );

typedef CrmTimePicker =
    Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initialTime);

class DatePickerFormField extends StatelessWidget {
  const DatePickerFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.validator,
    this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  static CrmDatePicker? debugPickerOverride;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      showCursor: false,
      keyboardType: TextInputType.none,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: const Icon(Icons.expand_more_rounded),
      ),
      validator: validator,
      onTap: () => _pickDate(context),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final form = Form.maybeOf(context);
    final current = _parseDate(controller.text) ?? DateTime.now();
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    final picker = debugPickerOverride ?? _showNativeDatePicker;
    final picked = await picker(context, current, first, last);
    if (picked == null) return;
    final value = formatCrmDate(picked);
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    onChanged?.call(value);
    form?.validate();
  }

  static Future<DateTime?> _showNativeDatePicker(
    BuildContext context,
    DateTime initialDate,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}

class TimePickerFormField extends StatelessWidget {
  const TimePickerFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;

  static CrmTimePicker? debugPickerOverride;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      showCursor: false,
      keyboardType: TextInputType.none,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.schedule_outlined),
        suffixIcon: const Icon(Icons.expand_more_rounded),
      ),
      validator: validator,
      onTap: () => _pickTime(context),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final form = Form.maybeOf(context);
    final picker = debugPickerOverride ?? _showNativeTimePicker;
    final picked = await picker(
      context,
      _parseTime(controller.text) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    final value = formatCrmTime(picked);
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    onChanged?.call(value);
    form?.validate();
  }

  static Future<TimeOfDay?> _showNativeTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
  ) {
    return showTimePicker(context: context, initialTime: initialTime);
  }
}

DateTime? _parseDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

TimeOfDay? _parseTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String formatCrmDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String formatCrmTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
