import 'package:flutter/material.dart';
import 'package:fyp_voice/mainscreens/aboutScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_voice/main.dart'; // Access to themeNotifier

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _clearCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Cache cleared successfully!")));
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Clear Cache"),
            content: Text("Are you sure you want to clear all app data?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearCache();
                },
                child: Text("Clear"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 18,
                  ),
                ),
                Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      themeNotifier.value =
                          value ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
              ],
            ),
            Divider(),
            ListTile(
              title: Text(
                'About',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 18,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
            ),
            ListTile(
              title: Text(
                'Clear Cache',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 18,
                ),
              ),
              trailing: Icon(Icons.delete_forever, color: Colors.red),
              onTap: _confirmClearCache,
            ),
          ],
        ),
      ),
    );
  }
}
