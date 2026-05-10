import 'package:flutter/material.dart';
import '../models/health_item.dart';
import '../models/schedule_item.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class OverviewProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  List<HealthItem> _healthItems = [];
  List<ScheduleItem> _scheduleItems = [];
  Map<int, bool> _healthCompletion = {};
  Map<int, bool> _scheduleCompletion = {};

  String _currentDate = todayDate();
  String _categoryFilter = 'all';
  String _completionFilter = 'all';

  bool _isLoading = false;

  List<HealthItem> get healthItems => _healthItems;
  List<ScheduleItem> get scheduleItems => _scheduleItems;
  Map<int, bool> get healthCompletion => _healthCompletion;
  Map<int, bool> get scheduleCompletion => _scheduleCompletion;
  String get currentDate => _currentDate;
  String get categoryFilter => _categoryFilter;
  String get completionFilter => _completionFilter;
  bool get isLoading => _isLoading;

  List<HealthItem> get filteredHealthItems {
    var items = List<HealthItem>.from(_healthItems);
    if (_completionFilter == 'completed') {
      items = items.where((h) => _healthCompletion[h.id] == true).toList();
    } else if (_completionFilter == 'incomplete') {
      items = items.where((h) => _healthCompletion[h.id] != true).toList();
    }
    return items;
  }

  List<ScheduleItem> get filteredScheduleItems {
    var items = List<ScheduleItem>.from(_scheduleItems);
    if (_completionFilter == 'completed') {
      items = items.where((s) => _scheduleCompletion[s.id] == true).toList();
    } else if (_completionFilter == 'incomplete') {
      items = items.where((s) => _scheduleCompletion[s.id] != true).toList();
    }
    return items;
  }

  int get totalTasks => _healthItems.length + _scheduleItems.length;

  int get completedTasks {
    int count = 0;
    for (final h in _healthItems) {
      if (_healthCompletion[h.id] == true) count++;
    }
    for (final s in _scheduleItems) {
      if (_scheduleCompletion[s.id] == true) count++;
    }
    return count;
  }

  double get completionRate {
    if (totalTasks == 0) return 0;
    return completedTasks / totalTasks;
  }

  Future<void> loadData({String? date}) async {
    final targetDate = date ?? _currentDate;
    _isLoading = true;
    notifyListeners();
    _healthItems = await _db.getActiveHealthItems();
    _scheduleItems = await _db.getScheduleItemsForDate(targetDate);
    _healthCompletion = {};
    _scheduleCompletion = {};
    for (final h in _healthItems) {
      final record = await _db.getDailyRecord(targetDate, 'health', h.id!);
      _healthCompletion[h.id!] = record?.completed ?? false;
    }
    for (final s in _scheduleItems) {
      final record = await _db.getDailyRecord(targetDate, 'schedule', s.id!);
      _scheduleCompletion[s.id!] = record?.completed ?? false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setDate(String date) async {
    _currentDate = date;
    await loadData();
  }

  Future<void> toggleHealthCompletion(int itemId) async {
    await _db.toggleCompletion(_currentDate, 'health', itemId);
    final nowCompleted = !(_healthCompletion[itemId] ?? false);
    _healthCompletion[itemId] = nowCompleted;

    if (nowCompleted) {
      await _notificationService.cancelTaskReminder(itemId + 10000);
    } else {
      final item = _healthItems.firstWhere((h) => h.id == itemId,
          orElse: () => _healthItems.first);
      if (item.reminderEnabled) {
        final parts = item.reminderTime.split(':');
        if (parts.length == 2) {
          await _notificationService.scheduleTaskReminder(
            id: item.id! + 10000,
            title: '健康提醒',
            body: '该完成「${item.name}」啦！',
            hour: int.tryParse(parts[0]) ?? 20,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> toggleScheduleCompletion(int itemId) async {
    await _db.toggleCompletion(_currentDate, 'schedule', itemId);
    final nowCompleted = !(_scheduleCompletion[itemId] ?? false);
    _scheduleCompletion[itemId] = nowCompleted;

    if (nowCompleted) {
      await _notificationService.cancelTaskReminder(itemId + 20000);
    } else {
      final item = _scheduleItems.firstWhere((s) => s.id == itemId,
          orElse: () => _scheduleItems.first);
      if (item.reminderEnabled) {
        final parts = item.reminderTime.split(':');
        if (parts.length == 2) {
          await _notificationService.scheduleTaskReminder(
            id: item.id! + 20000,
            title: '日程提醒',
            body: '「${item.name}」到时间啦！',
            hour: int.tryParse(parts[0]) ?? 20,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }
    notifyListeners();
  }

  void setCategoryFilter(String filter) {
    _categoryFilter = filter;
    notifyListeners();
  }

  void setCompletionFilter(String filter) {
    _completionFilter = filter;
    notifyListeners();
  }

  Future<void> initializeToday() async {
    await _db.initializeDailyRecords(_currentDate);
    await loadData();
  }
}
