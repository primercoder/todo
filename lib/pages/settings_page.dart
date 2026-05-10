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
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: '选择时间',
      cancelText: '取消',
      confirmText: '确认',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导出成功！'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), behavior: SnackBarBehavior.floating),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件格式不正确'), behavior: SnackBarBehavior.floating),
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
        context.read<HealthProvider>().loadItems();
        context.read<ScheduleProvider>().loadItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导入成功！'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📖 使用帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏠 概览', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('查看当天所有待办事项，分为「健康计划」和「日程安排」两部分。点击事项左侧复选框即可标记完成。支持按类别和完成度筛选，点击右上角可查看历史记录。'),
              SizedBox(height: 12),
              Text('❤️ 健康', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('管理每日健康习惯。点击「+」添加自定义计划，点击灯泡图标查看推荐项目（如饮水、跑步、远眺等）。每个项目可设置提醒时间和备注。健康计划每天自动刷新。'),
              SizedBox(height: 12),
              Text('📅 日程', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('管理特定日期的日程安排。设置日程名称、日期、提醒时间等。日程仅在指定日期显示在概览页面。点击灯泡图标可查看学习类推荐项目。'),
              SizedBox(height: 12),
              Text('⚙️ 设置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('设置主题风格（明亮/暗黑/花园/海洋/日落）、默认提醒时间（默认20:00）、每日总结时间（默认23:00）。支持数据导出导入备份。'),
              SizedBox(height: 12),
              Text('🔔 提醒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('开启提醒后，App会在设定时间发送通知。每日总结会在设定时间汇总当天完成情况，并送上鼓励语句。即使App未运行也会发送通知（需授权通知权限）。'),
              SizedBox(height: 12),
              Text('🔄 刷新', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('每天00:00自动刷新：健康计划重新开始计数，日程根据日期自动显示/隐藏。历史记录可在概览页右上角查看。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: FadeTransition(
        opacity: _animation,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // Theme Section
            _buildSectionHeader('🎨 主题风格'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    _buildThemeOption(
                      '明亮',
                      'light',
                      Icons.light_mode,
                      settings.themeName,
                      () => settings.setTheme('light'),
                    ),
                    _buildThemeOption(
                      '暗黑',
                      'dark',
                      Icons.dark_mode,
                      settings.themeName,
                      () => settings.setTheme('dark'),
                    ),
                    _buildThemeOption(
                      '花园',
                      'garden',
                      Icons.local_florist,
                      settings.themeName,
                      () => settings.setTheme('garden'),
                    ),
                    _buildThemeOption(
                      '海洋',
                      'ocean',
                      Icons.water,
                      settings.themeName,
                      () => settings.setTheme('ocean'),
                    ),
                    _buildThemeOption(
                      '日落',
                      'sunset',
                      Icons.wb_sunny,
                      settings.themeName,
                      () => settings.setTheme('sunset'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notification Settings
            _buildSectionHeader('🔔 提醒设置'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('启用通知'),
                      subtitle: const Text('关闭后所有提醒和总结将不会发送'),
                      value: settings.notificationsEnabled,
                      onChanged: settings.setNotificationsEnabled,
                      secondary: const Icon(Icons.notifications),
                    ),
                    ListTile(
                      leading: const Icon(Icons.alarm),
                      title: const Text('默认提醒时间'),
                      subtitle: Text('新项目的默认提醒时间'),
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
                      title: const Text('每日总结时间'),
                      subtitle: const Text('每天此时发送完成情况总结'),
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
            _buildSectionHeader('💾 数据管理'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text('导出数据'),
                      subtitle: const Text('将健康计划和日程导出为JSON文件'),
                      onTap: _exportData,
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('导入数据'),
                      subtitle: const Text('从备份文件恢复数据'),
                      onTap: _importData,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Language
            _buildSectionHeader('🌐 语言 / Language'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('简体中文'),
                      trailing: settings.localeCode == 'zh'
                          ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                          : null,
                      onTap: () => settings.setLocale('zh'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('English'),
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
            _buildSectionHeader('ℹ️ 其他'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('使用帮助'),
                  subtitle: const Text('了解App的详细使用方式'),
                  onTap: _showHelpDialog,
                ),
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'TODO v1.0.0',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
            Center(
              child: Text(
                '助你养成好习惯 ✨',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
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
