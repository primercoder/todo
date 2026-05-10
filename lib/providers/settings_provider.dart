import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class SettingsProvider extends ChangeNotifier {
  String _themeName = 'light';
  String _defaultReminderTime = '20:00';
  String _defaultSummaryTime = '23:00';
  bool _notificationsEnabled = true;

  String get themeName => _themeName;
  String get defaultReminderTime => _defaultReminderTime;
  String get defaultSummaryTime => _defaultSummaryTime;
  bool get notificationsEnabled => _notificationsEnabled;

  ThemeData get theme => AppTheme.getTheme(_themeName);

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeName = prefs.getString('theme_name') ?? 'light';
    _defaultReminderTime = prefs.getString('default_reminder_time') ?? '20:00';
    _defaultSummaryTime = prefs.getString('default_summary_time') ?? '23:00';
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    if (_themeName == themeName) return;
    _themeName = themeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_name', themeName);
    notifyListeners();
  }

  Future<void> setDefaultReminderTime(String time) async {
    if (_defaultReminderTime == time) return;
    _defaultReminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_reminder_time', time);
    notifyListeners();
  }

  Future<void> setDefaultSummaryTime(String time) async {
    if (_defaultSummaryTime == time) return;
    _defaultSummaryTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_summary_time', time);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<Map<String, String>> getSettingsMap() async {
    return {
      'theme_name': _themeName,
      'default_reminder_time': _defaultReminderTime,
      'default_summary_time': _defaultSummaryTime,
      'notifications_enabled': _notificationsEnabled.toString(),
    };
  }

  Future<void> restoreSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    if (settings.containsKey('theme_name')) {
      _themeName = settings['theme_name'] as String;
      await prefs.setString('theme_name', _themeName);
    }
    if (settings.containsKey('default_reminder_time')) {
      _defaultReminderTime = settings['default_reminder_time'] as String;
      await prefs.setString('default_reminder_time', _defaultReminderTime);
    }
    if (settings.containsKey('default_summary_time')) {
      _defaultSummaryTime = settings['default_summary_time'] as String;
      await prefs.setString('default_summary_time', _defaultSummaryTime);
    }
    if (settings.containsKey('notifications_enabled')) {
      _notificationsEnabled = settings['notifications_enabled'].toString() == 'true';
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
    }
    notifyListeners();
  }
}
