import 'package:flutter/material.dart';
import '../models/schedule_item.dart';
import '../database/database_helper.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<ScheduleItem> _allItems = [];
  List<ScheduleItem> _todayItems = [];
  bool _isLoading = false;

  List<ScheduleItem> get allItems => _allItems;
  List<ScheduleItem> get todayItems => _todayItems;
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _allItems = await _db.getAllScheduleItems();
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    _todayItems = await _db.getScheduleItemsForDate(dateStr);

    _isLoading = false;
    notifyListeners();
  }

  Future<List<ScheduleItem>> getItemsForDate(String date) async {
    return await _db.getScheduleItemsForDate(date);
  }

  Future<void> addItem(ScheduleItem item) async {
    final id = await _db.insertScheduleItem(item);
    final newItem = item.copyWith(id: id);
    _allItems.insert(0, newItem);
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (newItem.scheduleDate == dateStr) {
      _todayItems.add(newItem);
    }
    notifyListeners();
  }

  Future<void> updateItem(ScheduleItem item) async {
    await _db.updateScheduleItem(item);
    await loadItems();
  }

  Future<void> toggleActive(int id) async {
    final index = _allItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = _allItems[index];
    final updated = item.copyWith(isActive: !item.isActive);
    await _db.updateScheduleItem(updated);

    _allItems[index] = updated;
    if (updated.isActive) {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (updated.scheduleDate == dateStr) {
        _todayItems.add(updated);
      }
    } else {
      _todayItems.removeWhere((i) => i.id == id);
    }
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteScheduleItem(id);
    _allItems.removeWhere((i) => i.id == id);
    _todayItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
