import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_item.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class HealthProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  List<HealthItem> _allItems = [];
  List<HealthItem> _activeItems = [];
  bool _isLoading = false;

  List<HealthItem> get allItems => _allItems;
  List<HealthItem> get activeItems => _activeItems;
  bool get isLoading => _isLoading;

  Future<bool> get _isZh async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('locale_code') ?? 'zh') == 'zh';
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _allItems = await _db.getAllHealthItems();
    _activeItems = await _db.getActiveHealthItems();
    _isLoading = false;
    notifyListeners();
  }

  bool hasDuplicateName(String name, {int? excludeId}) {
    return _activeItems.any((i) => i.name == name && i.id != excludeId);
  }

  Future<bool> addItem(HealthItem item) async {
    if (hasDuplicateName(item.name)) return false;
    final id = await _db.insertHealthItem(item);
    final newItem = item.copyWith(id: id);
    _allItems.add(newItem);
    if (newItem.isActive) {
      _activeItems.add(newItem);
      await _scheduleReminder(newItem);
    }
    notifyListeners();
    return true;
  }

  Future<void> updateItem(HealthItem item) async {
    await _db.updateHealthItem(item);
    await _scheduleReminder(item);
    await loadItems();
  }

  Future<void> toggleActive(int id) async {
    final index = _allItems.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = _allItems[index];
    final updated = item.copyWith(isActive: !item.isActive);
    await _db.updateHealthItem(updated);
    if (updated.isActive) {
      _activeItems.add(updated);
      await _scheduleReminder(updated);
    } else {
      _activeItems.removeWhere((i) => i.id == id);
      await _notificationService.cancelTaskReminder(id + 10000);
    }
    _allItems[index] = updated;
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteHealthItem(id);
    _allItems.removeWhere((i) => i.id == id);
    _activeItems.removeWhere((i) => i.id == id);
    await _notificationService.cancelTaskReminder(id + 10000);
    notifyListeners();
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final item = _activeItems.removeAt(oldIndex);
    _activeItems.insert(newIndex, item);
    for (int i = 0; i < _activeItems.length; i++) {
      final updated = _activeItems[i].copyWith(sortOrder: i);
      await _db.updateHealthItem(updated);
    }
    notifyListeners();
  }

  Future<void> _scheduleReminder(HealthItem item) async {
    if (item.reminderEnabled && item.id != null) {
      final parts = item.reminderTime.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 20;
        final minute = int.tryParse(parts[1]) ?? 0;
        final isZh = await _isZh;
        final title = isZh ? '💪 健康提醒' : '💪 Health Reminder';
        final body = _buildHealthReminderBody(item.name, item.defaultValue, isZh);
        await _notificationService.scheduleTaskReminder(
          id: item.id! + 10000, title: title, body: body,
          hour: hour, minute: minute,
        );
      }
    } else if (item.id != null) {
      await _notificationService.cancelTaskReminder(item.id! + 10000);
    }
  }

  Future<void> rescheduleReminder(HealthItem item) async {
    await _scheduleReminder(item);
  }

  String _buildHealthReminderBody(String name, String defaultValue, bool isZh) {
    if (isZh) {
      final msgs = [
        '该完成「$name」啦！${defaultValue.isNotEmpty ? "目标$defaultValue，" : ""}动起来，身体会感谢你的~ 🏃',
        '「$name」时间到！${defaultValue.isNotEmpty ? "小目标$defaultValue，" : ""}今天也要元气满满哦！✨',
        '别忘了「$name」！${defaultValue.isNotEmpty ? "$defaultValue在等你，" : ""}坚持就是胜利！💯',
        '「$name」该打卡了！${defaultValue.isNotEmpty ? "完成$defaultValue，" : ""}你已经很棒了！🌟',
        '「$name」提醒！${defaultValue.isNotEmpty ? "$defaultValue搞起来，" : ""}好习惯成就好人生！🔥',
      ];
      return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
    }
    final msgs = [
      'Time for "$name"! ${defaultValue.isNotEmpty ? "Target: $defaultValue. " : ""}Your body will thank you~ 🏃',
      '"$name" time! ${defaultValue.isNotEmpty ? "Aim for $defaultValue. " : ""}Stay energetic! ✨',
      'Don\'t forget "$name"! ${defaultValue.isNotEmpty ? "$defaultValue awaits. " : ""}Persistence wins! 💯',
      '"$name" check-in! ${defaultValue.isNotEmpty ? "Complete $defaultValue, " : ""}You\'re doing great! 🌟',
      '"$name" reminder! ${defaultValue.isNotEmpty ? "Go for $defaultValue, " : ""}Good habits = good life! 🔥',
    ];
    return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
  }
}
