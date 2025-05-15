import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveReminderExternally(String title) async {
  final prefs = await SharedPreferences.getInstance();
  final reminderList = prefs.getStringList('reminders') ?? [];

  final now = DateTime.now();
  final formattedTime = DateFormat('EEEE, h:mm a').format(now);

  final newReminder = jsonEncode({'title': title, 'time': formattedTime});

  // Append to the list
  reminderList.add(newReminder);

  await prefs.setStringList('reminders', reminderList);
}
