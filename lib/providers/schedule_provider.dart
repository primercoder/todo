import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_item.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  List<ScheduleItem> _allItems = [];
  List<ScheduleItem> _todayItems = [];
  bool _isLoading = false;

  List<ScheduleItem> get allItems => _allItems;
  List<ScheduleItem> get todayItems => _todayItems;
  bool get isLoading => _isLoading;

  Future<bool> get _isZh async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('locale_code') ?? 'zh') == 'zh';
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _allItems = await _db.getAllScheduleItems();
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    _todayItems = await _db.getScheduleItemsForDate(dateStr);
    _isLoading = false;
    notifyListeners();
  }

  Future<List<ScheduleItem>> getItemsForDate(String date) async {
    return await _db.getScheduleItemsForDate(date);
  }

  bool hasDuplicate(String name, String date, {int? excludeId}) {
    return _allItems.any(
      (i) => i.name == name && i.scheduleDate == date && i.id != excludeId,
    );
  }

  Future<bool> addItem(ScheduleItem item) async {
    if (hasDuplicate(item.name, item.scheduleDate)) return false;
    final id = await _db.insertScheduleItem(item);
    final newItem = item.copyWith(id: id);
    _allItems.insert(0, newItem);
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (newItem.scheduleDate == dateStr) {
      _todayItems.add(newItem);
    }
    await _scheduleReminder(newItem);
    notifyListeners();
    return true;
  }

  Future<void> updateItem(ScheduleItem item) async {
    await _db.updateScheduleItem(item);
    await _scheduleReminder(item);
    await loadItems();
  }

  Future<void> toggleActive(int id) async {
    final index = _allItems.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = _allItems[index];
    final updated = item.copyWith(isActive: !item.isActive);
    await _db.updateScheduleItem(updated);
    if (!updated.isActive) {
      _allItems.removeAt(index);
      _todayItems.removeWhere((i) => i.id == id);
      await _notificationService.cancelTaskReminder(id + 20000);
    } else {
      _allItems[index] = updated;
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (updated.scheduleDate == dateStr) {
        _todayItems.add(updated);
      }
      await _scheduleReminder(updated);
    }
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteScheduleItem(id);
    _allItems.removeWhere((i) => i.id == id);
    _todayItems.removeWhere((i) => i.id == id);
    await _notificationService.cancelTaskReminder(id + 20000);
    notifyListeners();
  }

  Future<void> _scheduleReminder(ScheduleItem item) async {
    if (item.reminderEnabled && item.id != null) {
      final timeParts = item.reminderTime.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 20;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final isZh = await _isZh;
        final title = isZh ? '📅 日程提醒' : '📅 Schedule Reminder';
        final body = _buildScheduleReminderBody(
          item.name,
          item.description,
          isZh,
        );
        await _notificationService.scheduleTaskReminder(
          id: item.id! + 20000,
          title: title,
          body: body,
          hour: hour,
          minute: minute,
        );
      }
    } else if (item.id != null) {
      await _notificationService.cancelTaskReminder(item.id! + 20000);
    }
  }

  Future<void> rescheduleReminder(ScheduleItem item) async {
    await _scheduleReminder(item);
  }

  String _buildScheduleReminderBody(
    String name,
    String description,
    bool isZh,
  ) {
    if (isZh) {
      final msgs = [
        '「$name」到时间啦！${description.isNotEmpty ? description : "别忘记哦~"} 📚',
        '该开始「$name」了！${description.isNotEmpty ? description : "拖延是最大的时间小偷哦~"} ⏰',
        '「$name」提醒！${description.isNotEmpty ? description : "完成任务的感觉超棒的！"} 🎯',
        '「$name」的时刻到了！${description.isNotEmpty ? description : "今天进步一点点~"} 🚀',
        '嘿嘿，「$name」该上线了！${description.isNotEmpty ? description : "干完这一票你就是最靓的仔！"} 😎',
      ];
      return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
    }
    final msgs = [
      '"$name" is up! ${description.isNotEmpty ? description : "Don't forget~"} 📚',
      'Time for "$name"! ${description.isNotEmpty ? description : "Procrastination is the thief of time~"} ⏰',
      '"$name" reminder! ${description.isNotEmpty ? description : "Completing tasks feels great!"} 🎯',
      '"$name" time! ${description.isNotEmpty ? description : "One step forward today~"} 🚀',
      'Hey, "$name" is calling! ${description.isNotEmpty ? description : "Let's crush this one!"} 😎',
    ];
    return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
  }
}
