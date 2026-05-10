import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../database/database_helper.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final DatabaseHelper _db = DatabaseHelper();

  bool _initialized = false;

  late GlobalKey<NavigatorState> navigatorKey;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      navigatorKey.currentState?.pushNamed(response.payload!);
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {}

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return true;
    }
    return false;
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          '任务提醒',
          channelDescription: '健康计划和日程安排提醒',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/overview',
    );
  }

  Future<void> scheduleSummaryNotification(int hour, int minute) async {
    const summaryId = 999999;
    await _plugin.cancel(summaryId);

    final summary = await _calculateTodaysSummary();

    await _plugin.zonedSchedule(
      summaryId,
      '📋 今日总结',
      summary,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          '每日总结',
          channelDescription: '每天定时发送完成情况总结',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/overview',
    );
  }

  Future<String> _calculateTodaysSummary() async {
    final today = todayDate();

    final healthItems = await _db.getActiveHealthItems();
    final scheduleItems = await _db.getScheduleItemsForDate(today);

    int total = healthItems.length + scheduleItems.length;
    int completed = 0;

    for (final h in healthItems) {
      final record = await _db.getDailyRecord(today, 'health', h.id!);
      if (record?.completed == true) completed++;
    }
    for (final s in scheduleItems) {
      final record = await _db.getDailyRecord(today, 'schedule', s.id!);
      if (record?.completed == true) completed++;
    }

    final rate = total > 0 ? completed / total : 0.0;
    final encouragement = getEncouragementMessage(rate);

    final buffer = StringBuffer();
    buffer.writeln(encouragement);
    buffer.writeln('完成情况: $completed/$total');

    if (completed < total && total > 0) {
      buffer.writeln('未完成项:');
      for (final h in healthItems) {
        final record = await _db.getDailyRecord(today, 'health', h.id!);
        if (record?.completed != true) {
          buffer.writeln('  ❌ ${h.name}');
        }
      }
      for (final s in scheduleItems) {
        final record = await _db.getDailyRecord(today, 'schedule', s.id!);
        if (record?.completed != true) {
          buffer.writeln('  ❌ ${s.name}');
        }
      }
    }

    await _db.saveHistorySummary(today, total, completed, buffer.toString());

    return buffer.toString();
  }

  Future<void> scheduleMidnightRefresh() async {
    const refreshId = 999998;
    await _plugin.cancel(refreshId);

    await _plugin.zonedSchedule(
      refreshId,
      '🔄 新的一天',
      '新的一天开始啦！健康计划已刷新，今天也要加油哦~',
      _nextInstanceOfTime(0, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'midnight_refresh',
          '每日刷新',
          channelDescription: '每日零点刷新通知',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskReminder(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  Future<void> cancelSummary() async {
    await _plugin.cancel(999999);
  }

  Future<void> cancelMidnightRefresh() async {
    await _plugin.cancel(999998);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
