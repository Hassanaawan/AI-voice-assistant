import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fyp_voice/main.dart'; // For themeNotifier

class AboutScreen extends StatefulWidget {
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = themeNotifier.value == ThemeMode.dark;
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode') ?? 'light';
    setState(() {
      isDarkMode = savedTheme == 'dark';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Smart University Assistant',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'This app is designed to assist university students with reminders, queries, and other smart assistant features to improve productivity and learning.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Divider(color: theme.dividerColor, thickness: 1),
                  SizedBox(height: 16),
                  _buildInfoRow('Version', '1.0.0'),
                  SizedBox(height: 12),
                  _buildInfoRow('Developer', 'Your Name'),
                  SizedBox(height: 12),
                  _buildInfoRow('Contact', 'support@example.com'),
                  SizedBox(height: 24),
                  Text(
                    'Thank you for using our app!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Text(value, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
