import 'package:flutter/material.dart';
import '../models/health_item.dart';
import '../database/database_helper.dart';

class HealthProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<HealthItem> _allItems = [];
  List<HealthItem> _activeItems = [];
  bool _isLoading = false;

  List<HealthItem> get allItems => _allItems;
  List<HealthItem> get activeItems => _activeItems;
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _allItems = await _db.getAllHealthItems();
    _activeItems = await _db.getActiveHealthItems();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(HealthItem item) async {
    final id = await _db.insertHealthItem(item);
    final newItem = item.copyWith(id: id);
    _allItems.add(newItem);
    if (newItem.isActive) {
      _activeItems.add(newItem);
    }
    notifyListeners();
  }

  Future<void> updateItem(HealthItem item) async {
    await _db.updateHealthItem(item);
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
    } else {
      _activeItems.removeWhere((i) => i.id == id);
    }
    _allItems[index] = updated;
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteHealthItem(id);
    _allItems.removeWhere((i) => i.id == id);
    _activeItems.removeWhere((i) => i.id == id);
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
}
