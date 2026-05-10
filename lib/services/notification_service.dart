import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:convert';
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

  Future<String> _getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('locale_code') ?? 'zh';
  }

  bool _isZh(String localeCode) => localeCode == 'zh';

  Future<void> _saveNotificationRecord(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notification_history') ?? '[]';
    List list;
    try {
      list = json.decode(raw) as List;
    } catch (_) {
      list = [];
    }
    list.add({'title': title, 'body': body, 'time': DateTime.now().toIso8601String()});
    if (list.length > 50) list = list.sublist(list.length - 50);
    await prefs.setString('notification_history', json.encode(list));
  }

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
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          playSound: true,
          category: AndroidNotificationCategory.reminder,
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
    await _saveNotificationRecord(title, body);
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
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          playSound: true,
          category: AndroidNotificationCategory.recommendation,
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
    await _saveNotificationRecord('📋 今日总结', summary);
  }

  Future<String> _calculateTodaysSummary() async {
    final today = todayDate();
    final localeCode = await _getLocaleCode();
    final isZh = _isZh(localeCode);

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
    final encouragement = _getSummaryEncouragement(rate, isZh);

    final buffer = StringBuffer();
    buffer.writeln(encouragement);
    buffer.writeln(isZh ? '完成情况: $completed/$total' : 'Completion: $completed/$total');

    if (completed < total && total > 0) {
      buffer.writeln(isZh ? '未完成项:' : 'Incomplete:');
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

  String _getSummaryEncouragement(double rate, bool isZh) {
    if (isZh) {
      if (rate >= 1.0) {
        final msgs = [
          '太棒了！今天全部完成了！你是效率之王！👑',
          '完美收官！看看这满屏的勾勾，多么令人满足~',
          '全垒打！今天没有一项任务能逃过你的魔爪！💪',
          '满分通关！你这效率，连闪电侠都得甘拜下风！⚡',
          '任务清空！此刻你比刚出炉的面包还要优秀！🍞',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.8) {
        final msgs = [
          '非常不错！你已经完成了大部分任务，继续保持！',
          '优秀的表现！就差那么一丁点儿了，明天加油！',
          '八分圆满已经很厉害啦，剩下的留给明天的自己吧~',
          '差一步美满，但你已经击败了全国80%的用户！🏆',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.5) {
        final msgs = [
          '完成了过半的任务，已经是个不错的开始了！',
          '一半已搞定，剩下的也别放弃哦，慢慢来~',
          '进度过半！继续前进，完成的就是赚到的！',
          '过半啦！就像吃了一半的西瓜，最甜的还在后面！🍉',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate > 0) {
        final msgs = [
          '万里长征第一步，今天已经起跑了，明天会更好！',
          '做一点也是做，比昨天的自己更进步了一点呢~',
          '好的开始是成功的一半，你今天已经成功了一半！',
          '打破零蛋！每一个完成的勾都是一个小胜利！✌️',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else {
        final msgs = [
          '今天全部未完成？没关系，明天的太阳照常升起！',
          '零完成不丢人，真正的勇士敢于面对空白的todo！',
          '今天是养精蓄锐的一天，明天必定火力全开！',
          '今日休舱日！休眠是为了更好的爆发，理解的~ 😴',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      }
    } else {
      if (rate >= 1.0) {
        final msgs = [
          'Amazing! All completed! You\'re the productivity king! 👑',
          'Perfect finish! All checkmarks, so satisfying~',
          'Grand slam! Nothing escaped you today! 💪',
          'Flawless victory! Even The Flash would envy your speed! ⚡',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.8) {
        final msgs = [
          'Great job! Most tasks done, keep it up!',
          'Excellent! Just a tiny bit left for tomorrow!',
          '80% is impressive, save some for later~',
          'Almost there! You\'re in the top tier! 🏆',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.5) {
        final msgs = [
          'Halfway there, a solid start!',
          'Half done, don\'t give up, pace yourself~',
          'Over halfway! Every check counts!',
          'Half a watermelon done, the sweetest half awaits! 🍉',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate > 0) {
        final msgs = [
          'First step taken! Tomorrow will be better!',
          'Something is better than nothing, you\'re improving~',
          'A good start is half the battle!',
          'Broke the zero! Every checkmark is a victory! ✌️',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else {
        final msgs = [
          'Nothing done? No worries, the sun rises again!',
          'Zero completions takes courage to face!',
          'Resting today, full power tomorrow!',
          'Recharge day! Downtime is productive too~ 😴',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      }
    }
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
          priority: Priority.low,
          visibility: NotificationVisibility.public,
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
