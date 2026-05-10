import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/settings_provider.dart';
import '../providers/health_provider.dart';
import '../providers/schedule_provider.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/app_l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(String currentTime, ValueChanged<String> onTimePicked) async {
    final l10n = AppL10n.of(context);
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: l10n.selectTime,
      cancelText: l10n.cancelLabel,
      confirmText: l10n.confirmLabel,
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimePicked(timeStr);
    }
  }

  Future<void> _exportData() async {
    try {
      final db = DatabaseHelper();
      final healthItems = await db.exportHealthItems();
      final scheduleItems = await db.exportScheduleItems();
      final settings = context.read<SettingsProvider>();
      final settingsMap = await settings.getSettingsMap();

      final data = appDataToJson(
        healthItems: healthItems,
        scheduleItems: scheduleItems,
        settings: settingsMap,
      );

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/todo_backup_${todayDate()}.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'TODO App 数据备份',
      );

      if (mounted) {
        final l10n = AppL10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportSuccess), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppL10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString())), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = parseAppDataJson(jsonStr);

      if (data == null) {
        if (mounted) {
          final l10n = AppL10n.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.invalidFormat), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }

      final db = DatabaseHelper();

      if (data.containsKey('healthItems')) {
        await db.importHealthItems(List<Map<String, dynamic>>.from(data['healthItems'] as List));
      }
      if (data.containsKey('scheduleItems')) {
        await db.importScheduleItems(List<Map<String, dynamic>>.from(data['scheduleItems'] as List));
      }
      if (data.containsKey('settings') && data['settings'] is Map) {
        final settings = context.read<SettingsProvider>();
        await settings.restoreSettings(Map<String, String>.from(data['settings'] as Map));
      }

      if (mounted) {
        final l10n = AppL10n.of(context);
        context.read<HealthProvider>().loadItems();
        context.read<ScheduleProvider>().loadItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importSuccess), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppL10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFailed(e.toString())), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showHelpDialog() {
    final l10n = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.helpTitle),
        content: SingleChildScrollView(
          child: Text(l10n.helpContent, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.helpGotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: FadeTransition(
        opacity: _animation,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _buildSectionHeader(l10n.themeSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    _buildThemeOption(
                      l10n.lightTheme, 'light', Icons.light_mode,
                      settings.themeName, () => settings.setTheme('light'),
                    ),
                    _buildThemeOption(
                      l10n.darkTheme, 'dark', Icons.dark_mode,
                      settings.themeName, () => settings.setTheme('dark'),
                    ),
                    _buildThemeOption(
                      l10n.gardenTheme, 'garden', Icons.local_florist,
                      settings.themeName, () => settings.setTheme('garden'),
                    ),
                    _buildThemeOption(
                      l10n.oceanTheme, 'ocean', Icons.water,
                      settings.themeName, () => settings.setTheme('ocean'),
                    ),
                    _buildThemeOption(
                      l10n.sunsetTheme, 'sunset', Icons.wb_sunny,
                      settings.themeName, () => settings.setTheme('sunset'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notification Settings
            _buildSectionHeader(l10n.notificationSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.notificationToggle),
                      subtitle: Text(l10n.notificationOffDesc),
                      value: settings.notificationsEnabled,
                      onChanged: settings.setNotificationsEnabled,
                      secondary: const Icon(Icons.notifications),
                    ),
                    ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(l10n.defaultReminderTimeLabel),
                      subtitle: Text(l10n.defaultReminderDesc),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          settings.defaultReminderTime,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      onTap: () => _pickTime(
                        settings.defaultReminderTime,
                        settings.setDefaultReminderTime,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.summarize),
                      title: Text(l10n.summaryTimeLabel),
                      subtitle: Text(l10n.summaryDesc),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          settings.defaultSummaryTime,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      onTap: () => _pickTime(
                        settings.defaultSummaryTime,
                        settings.setDefaultSummaryTime,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data Management
            _buildSectionHeader(l10n.dataSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: Text(l10n.exportDataLabel),
                      subtitle: Text(l10n.exportDesc),
                      onTap: _exportData,
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: Text(l10n.importDataLabel),
                      subtitle: Text(l10n.importDesc),
                      onTap: _importData,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Language
            _buildSectionHeader(l10n.languageSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.chineseLabel),
                      trailing: settings.localeCode == 'zh'
                          ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                          : null,
                      onTap: () => settings.setLocale('zh'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.englishLabel),
                      trailing: settings.localeCode == 'en'
                          ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                          : null,
                      onTap: () => settings.setLocale('en'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Help
            _buildSectionHeader(l10n.otherSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(l10n.helpLabel),
                  subtitle: Text(l10n.helpDesc),
                  onTap: _showHelpDialog,
                ),
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text('TODO v1.0.0', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ),
            Center(
              child: Text(l10n.todoSlogan, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeOption(String name, String value, IconData icon, String current, VoidCallback onTap) {
    final isSelected = value == current;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : null),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
      onTap: onTap,
    );
  }
}
