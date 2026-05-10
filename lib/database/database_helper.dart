import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_item.dart';
import '../models/schedule_item.dart';
import '../models/daily_record.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'custom',
        description TEXT DEFAULT '',
        default_value TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        reminder_enabled INTEGER DEFAULT 0,
        reminder_time TEXT DEFAULT '20:00',
        is_active INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'custom',
        description TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        schedule_date TEXT NOT NULL,
        reminder_enabled INTEGER DEFAULT 0,
        reminder_time TEXT DEFAULT '20:00',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        completed INTEGER DEFAULT 0,
        completed_at TEXT,
        UNIQUE(date, item_type, item_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE history_summaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        total_count INTEGER DEFAULT 0,
        completed_count INTEGER DEFAULT 0,
        summary_text TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await _insertPresetHealthItems(db);
    await _insertPresetScheduleItems(db);
  }

  Future<void> _insertPresetHealthItems(Database db) async {
    for (int i = 0; i < presetHealthItems.length; i++) {
      final item = presetHealthItems[i];
      await db.insert('health_items', {
        'name': item['name'],
        'icon': item['icon'],
        'category': 'preset',
        'description': item['description'] ?? '',
        'default_value': item['defaultValue'] ?? '',
        'notes': '',
        'reminder_enabled': 0,
        'reminder_time': defaultReminderTime,
        'is_active': 0,
        'sort_order': i,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _insertPresetScheduleItems(Database db) async {
    for (int i = 0; i < presetScheduleItems.length; i++) {
      final item = presetScheduleItems[i];
      await db.insert('schedule_items', {
        'name': item['name'],
        'icon': item['icon'],
        'category': 'preset',
        'description': item['description'] ?? '',
        'notes': '',
        'schedule_date': todayDate(),
        'reminder_enabled': 0,
        'reminder_time': defaultReminderTime,
        'is_active': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ---- Health Items ----

  Future<List<HealthItem>> getActiveHealthItems() async {
    final db = await database;
    final maps = await db.query(
      'health_items',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => HealthItem.fromMap(m)).toList();
  }

  Future<List<HealthItem>> getAllHealthItems() async {
    final db = await database;
    final maps = await db.query('health_items', orderBy: 'sort_order ASC');
    return maps.map((m) => HealthItem.fromMap(m)).toList();
  }

  Future<int> insertHealthItem(HealthItem item) async {
    final db = await database;
    return await db.insert('health_items', item.toMap());
  }

  Future<int> updateHealthItem(HealthItem item) async {
    final db = await database;
    return await db.update(
      'health_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteHealthItem(int id) async {
    final db = await database;
    await db.delete('daily_records', where: 'item_type = ? AND item_id = ?', whereArgs: ['health', id]);
    return await db.delete('health_items', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Schedule Items ----

  Future<List<ScheduleItem>> getScheduleItemsForDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'schedule_items',
      where: 'is_active = ? AND schedule_date = ?',
      whereArgs: [1, date],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => ScheduleItem.fromMap(m)).toList();
  }

  Future<List<ScheduleItem>> getAllScheduleItems() async {
    final db = await database;
    final maps = await db.query(
      'schedule_items',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'schedule_date DESC, created_at ASC',
    );
    return maps.map((m) => ScheduleItem.fromMap(m)).toList();
  }

  Future<int> insertScheduleItem(ScheduleItem item) async {
    final db = await database;
    return await db.insert('schedule_items', item.toMap());
  }

  Future<int> updateScheduleItem(ScheduleItem item) async {
    final db = await database;
    return await db.update(
      'schedule_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteScheduleItem(int id) async {
    final db = await database;
    await db.delete('daily_records', where: 'item_type = ? AND item_id = ?', whereArgs: ['schedule', id]);
    return await db.delete('schedule_items', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Daily Records ----

  Future<DailyRecord?> getDailyRecord(String date, String itemType, int itemId) async {
    final db = await database;
    final maps = await db.query(
      'daily_records',
      where: 'date = ? AND item_type = ? AND item_id = ?',
      whereArgs: [date, itemType, itemId],
    );
    return maps.isNotEmpty ? DailyRecord.fromMap(maps.first) : null;
  }

  Future<List<DailyRecord>> getDailyRecordsForDate(String date) async {
    final db = await database;
    final maps = await db.query('daily_records', where: 'date = ?', whereArgs: [date]);
    return maps.map((m) => DailyRecord.fromMap(m)).toList();
  }

  Future<void> toggleCompletion(String date, String itemType, int itemId) async {
    final db = await database;
    final existing = await getDailyRecord(date, itemType, itemId);
    if (existing != null) {
      await db.update(
        'daily_records',
        {
          'completed': existing.completed ? 0 : 1,
          'completed_at': existing.completed ? null : DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      await db.insert('daily_records', {
        'date': date,
        'item_type': itemType,
        'item_id': itemId,
        'completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> initializeDailyRecords(String date) async {
    final db = await database;
    final healthItems = await getActiveHealthItems();
    for (final item in healthItems) {
      final existing = await getDailyRecord(date, 'health', item.id!);
      if (existing == null) {
        await db.insert('daily_records', {
          'date': date,
          'item_type': 'health',
          'item_id': item.id,
          'completed': 0,
        });
      }
    }
    final scheduleItems = await getScheduleItemsForDate(date);
    for (final item in scheduleItems) {
      final existing = await getDailyRecord(date, 'schedule', item.id!);
      if (existing == null) {
        await db.insert('daily_records', {
          'date': date,
          'item_type': 'schedule',
          'item_id': item.id,
          'completed': 0,
        });
      }
    }
  }

  // ---- History Summaries ----

  Future<Map<String, dynamic>?> getHistorySummary(String date) async {
    final db = await database;
    final maps = await db.query('history_summaries', where: 'date = ?', whereArgs: [date]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllHistorySummaries() async {
    final db = await database;
    return await db.query('history_summaries', orderBy: 'date DESC');
  }

  Future<void> saveHistorySummary(String date, int totalCount, int completedCount, String summaryText) async {
    final db = await database;
    await db.insert(
      'history_summaries',
      {
        'date': date,
        'total_count': totalCount,
        'completed_count': completedCount,
        'summary_text': summaryText,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---- Export / Import ----

  Future<List<Map<String, dynamic>>> exportHealthItems() async {
    final db = await database;
    return await db.query('health_items', where: 'is_active = 1');
  }

  Future<List<Map<String, dynamic>>> exportScheduleItems() async {
    final db = await database;
    return await db.query('schedule_items', where: 'is_active = 1');
  }

  Future<void> importHealthItems(List<Map<String, dynamic>> items) async {
    final db = await database;
    for (final item in items) {
      item.remove('id');
      await db.insert('health_items', item, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> importScheduleItems(List<Map<String, dynamic>> items) async {
    final db = await database;
    for (final item in items) {
      item.remove('id');
      await db.insert('schedule_items', item, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
