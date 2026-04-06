import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReminders = false;
  bool _budgetAlerts = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminders = prefs.getBool('dailyReminders') ?? false;
      _budgetAlerts = prefs.getBool('budgetAlerts') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyReminders', _dailyReminders);
    await prefs.setBool('budgetAlerts', _budgetAlerts);
  }

  Future<void> _toggleDailyReminders(bool value) async {
    setState(() => _dailyReminders = value);
    await _saveSettings();

    if (value) {
      await _notificationService.scheduleDailyReminder();
    } else {
      await _notificationService.cancelDailyReminder();
    }
  }

  Future<void> _toggleBudgetAlerts(bool value) async {
    setState(() => _budgetAlerts = value);
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1A6B6B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A6B6B),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: SwitchListTile(
              title: const Text('Daily Expense Reminders'),
              subtitle: const Text(
                  'Get reminded to add your expenses every day at 8 PM'),
              value: _dailyReminders,
              onChanged: _toggleDailyReminders,
              activeColor: const Color(0xFF1A6B6B),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: SwitchListTile(
              title: const Text('Budget Alerts'),
              subtitle: const Text(
                  'Get notified when you exceed your monthly budget'),
              value: _budgetAlerts,
              onChanged: _toggleBudgetAlerts,
              activeColor: const Color(0xFF1A6B6B),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A6B6B),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EconoSmart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A6B6B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Smart Money Manager helps you track your expenses, manage budgets, and make informed financial decisions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
