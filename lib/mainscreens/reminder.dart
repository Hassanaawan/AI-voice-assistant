import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    setState(() {
      _reminders.clear();
      _reminders.addAll(
        reminderList.map((r) {
          final map = jsonDecode(r);
          return Reminder(title: map['title'], time: map['time']);
        }).toList(),
      );
    });
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderList =
        _reminders
            .map((r) => jsonEncode({'title': r.title, 'time': r.time}))
            .toList();
    await prefs.setStringList('reminders', reminderList);
  }

  void _addReminder() async {
    final newReminder = await _showReminderDialog();
    if (newReminder != null) {
      setState(() {
        _reminders.add(newReminder);
      });
      _saveReminders();
    }
  }

  void _editReminder(int index) async {
    final updatedReminder = await _showReminderDialog(
      reminder: _reminders[index],
    );
    if (updatedReminder != null) {
      setState(() {
        _reminders[index] = updatedReminder;
      });
      _saveReminders();
    }
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    _saveReminders();
  }

  Future<Reminder?> _showReminderDialog({Reminder? reminder}) {
    final TextEditingController _titleController = TextEditingController(
      text: reminder?.title ?? '',
    );

    return showDialog<Reminder>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            reminder == null ? 'Add Reminder' : 'Edit Reminder',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          content: TextField(
            controller: _titleController,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Enter reminder title',
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isNotEmpty) {
                  final time = DateFormat(
                    'EEEE, h:mm a',
                  ).format(DateTime.now());
                  Navigator.pop(context, Reminder(title: title, time: time));
                }
              },
              child: Text(
                reminder == null ? 'Add' : 'Update',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child:
                  _reminders.isEmpty
                      ? const Center(
                        child: Text(
                          'No reminders yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = _reminders[index];
                          return GestureDetector(
                            onTap: () => _editReminder(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reminder.title,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'SF Pro Text',
                                          ),
                                        ),
                                        Text(
                                          reminder.time,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14.0,
                                            fontFamily: 'SF Pro Text',
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _deleteReminder(index);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8.0),
                  Text(
                    'Add Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Reminder {
  String title;
  String time;

  Reminder({required this.title, required this.time});
}
