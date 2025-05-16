import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fyp_voice/reminderHelper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Reminder {
  final String title;
  final String time;

  Reminder({required this.title, required this.time});
}

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  _ReminderListScreenState createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  final List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderList = prefs.getStringList('reminders') ?? [];

    final loadedReminders = <Reminder>[];

    final skipPhrases = [
      "add reminder",
      "set a reminder",
      "remind me",
      "create reminder",
      "schedule reminder",
    ];

    for (final r in reminderList) {
      try {
        final map = jsonDecode(r);
        if (map is Map<String, dynamic> &&
            map.containsKey('title') &&
            map.containsKey('time')) {
          final title = (map['title'] as String).toLowerCase().trim();

          if (skipPhrases.any((phrase) => title == phrase)) {
            continue; // skip default phrases
          }

          loadedReminders.add(Reminder(title: map['title'], time: map['time']));
        }
      } catch (e) {
        debugPrint("Error decoding reminder: $e");
      }
    }

    setState(() {
      _reminders
        ..clear()
        ..addAll(loadedReminders);
    });
  }

  void _addOrEditReminder({Reminder? reminder, int? index}) {
    final titleController = TextEditingController(text: reminder?.title ?? "");

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(reminder == null ? "Add Reminder" : "Edit Reminder"),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: InputDecoration(hintText: "Reminder text"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final text = titleController.text.trim();
                if (text.isEmpty) return;

                setState(() {
                  final now = DateFormat('EEEE, h:mm a').format(DateTime.now());
                  final newReminder = Reminder(title: text, time: now);

                  if (index != null) {
                    _reminders[index] = newReminder;
                  } else {
                    _reminders.add(newReminder);
                  }
                });
                saveReminderExternally;
                Navigator.pop(context);
              },
              child: Text(reminder == null ? "Add" : "Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteReminder(int index) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Reminder"),
          content: const Text("Are you sure you want to delete this reminder?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _reminders.removeAt(index);
                });
                saveReminderExternally;
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        centerTitle: true,
        elevation: 2,
      ),
      body:
          _reminders.isEmpty
              ? Center(
                child: Text(
                  "No reminders yet.",
                  style: theme.textTheme.bodyLarge,
                ),
              )
              : ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (_, i) {
                  final reminder = _reminders[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(reminder.title),
                      subtitle: Text(reminder.time),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueAccent,
                            ),
                            onPressed:
                                () => _addOrEditReminder(
                                  reminder: reminder,
                                  index: i,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteReminder(i),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditReminder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
