import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../database/database_helper.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _db = DatabaseHelper();

  bool _initialized = false;
  bool _channelsCreated = false;
  NotificationResponse? _pendingCallbackResponse;

  late GlobalKey<NavigatorState> navigatorKey;

  Future<String> _getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('locale_code') ?? 'zh';
  }

  bool _isZh(String localeCode) => localeCode == 'zh';

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _hasRecordedNotificationToday(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final recorded = prefs.getStringList('recorded_notifications') ?? [];
    return recorded.contains('$id:$_todayStr');
  }

  Future<void> _markNotificationRecordedToday(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final recorded = prefs.getStringList('recorded_notifications') ?? [];
    recorded.add('$id:$_todayStr');
    if (recorded.length > 500) recorded.removeRange(0, recorded.length - 500);
    await prefs.setStringList('recorded_notifications', recorded);
  }

  Future<void> _saveNotificationRecord(
    String title,
    String body, {
    required String channel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notification_history') ?? '[]';
    List list;
    try {
      list = json.decode(raw) as List;
    } catch (_) {
      list = [];
    }
    list.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'channel': channel,
    });
    if (list.length > 100) list = list.sublist(0, 100);
    await prefs.setString('notification_history', json.encode(list));
    await _incrementUnread();
  }

  Future<void> _storeNotificationDetail(
    int id,
    String title,
    String body,
    String channel,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notification_detail_$id',
      json.encode({'title': title, 'body': body, 'channel': channel}),
    );
  }

  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notification_unread') ?? 0;
  }

  Future<void> _incrementUnread() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('notification_unread') ?? 0) + 1;
    await prefs.setInt('notification_unread', count);
  }

  Future<void> clearUnread() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_unread', 0);
  }

  // ---- Scheduled notifications metadata ----

  Future<void> _saveScheduledNotification(
    int id,
    String title,
    String body,
    String channel,
    int hour,
    int minute,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('scheduled_notifications_meta') ?? '{}';
    final map = json.decode(raw) as Map<String, dynamic>;
    map[id.toString()] = {
      'title': title,
      'body': body,
      'channel': channel,
      'hour': hour,
      'minute': minute,
    };
    await prefs.setString('scheduled_notifications_meta', json.encode(map));
  }

  Future<void> _removeScheduledNotification(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('scheduled_notifications_meta') ?? '{}';
    final map = json.decode(raw) as Map<String, dynamic>;
    map.remove(id.toString());
    await prefs.setString('scheduled_notifications_meta', json.encode(map));
  }

  Future<Map<int, Map<String, dynamic>>> _getAllScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('scheduled_notifications_meta') ?? '{}';
    final map = json.decode(raw) as Map<String, dynamic>;
    return map.map(
      (key, value) => MapEntry(int.parse(key), value as Map<String, dynamic>),
    );
  }

  /// Called periodically (every 30s) while app is alive.
  /// Saves notification records to message center when scheduled time arrives.
  Future<void> checkAndSavePendingNotifications() async {
    final now = DateTime.now();
    final scheduled = await _getAllScheduledNotifications();

    for (final entry in scheduled.entries) {
      final id = entry.key;
      final data = entry.value;
      final hour = data['hour'] as int;
      final minute = data['minute'] as int;

      if (now.hour == hour && now.minute == minute) {
        if (!await _hasRecordedNotificationToday(id)) {
          final title = data['title'] as String? ?? '';
          final body = data['body'] as String? ?? '';
          final channel = data['channel'] as String? ?? 'task_reminders';
          await _saveNotificationRecord(title, body, channel: channel);
          await _markNotificationRecordedToday(id);
        }
      }
    }
  }

  /// Called on app start/resume to catch notifications that fired while app was away.
  Future<void> catchUpMissedNotifications() async {
    final now = DateTime.now();
    final scheduled = await _getAllScheduledNotifications();

    for (final entry in scheduled.entries) {
      final id = entry.key;
      final data = entry.value;
      final hour = data['hour'] as int;
      final minute = data['minute'] as int;

      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduledTime.isBefore(now) &&
          !await _hasRecordedNotificationToday(id)) {
        final title = data['title'] as String? ?? '';
        final body = data['body'] as String? ?? '';
        final channel = data['channel'] as String? ?? 'task_reminders';
        await _saveNotificationRecord(title, body, channel: channel);
        await _markNotificationRecordedToday(id);
      }
    }
  }

  // ---- Initialization ----

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final systemOffset = DateTime.now().timeZoneOffset;
    if (systemOffset == const Duration(hours: 8)) {
      try {
        final shanghai = tz.getLocation('Asia/Shanghai');
        tz.setLocalLocation(shanghai);
      } catch (_) {}
    }

    _initialized = true;
  }

  Future<void> ensureChannels() async {
    if (_channelsCreated) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'task_reminders',
          '任务提醒',
          description: '健康计划和日程安排提醒',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_summary',
          '每日总结',
          description: '每天定时发送完成情况总结',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'midnight_refresh',
          '每日刷新',
          description: '每日零点刷新通知',
          importance: Importance.defaultImportance,
        ),
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // If app was launched from a notification, record the pending payload
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null) {
        String? payload;
        try {
          payload =
              (details as dynamic).notificationResponse?.payload as String?;
        } catch (_) {
          try {
            payload = (details as dynamic).payload as String?;
          } catch (_) {}
        }
        if (payload != null && payload.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'pending_notification',
            json.encode({
              'id': (details as dynamic).notificationResponse?.id ?? 0,
              'payload': payload,
            }),
          );
        }
      }
    } catch (_) {}

    _channelsCreated = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    _pendingCallbackResponse = response;

    // Ensure tapped notification is recorded in history if detail exists.
    () async {
      try {
        final id = response.id ?? 0;
        final prefs = await SharedPreferences.getInstance();
        final detailRaw = prefs.getString('notification_detail_$id');
        if (detailRaw != null && detailRaw.isNotEmpty) {
          try {
            final detail = json.decode(detailRaw) as Map<String, dynamic>;
            final title = detail['title'] as String? ?? '';
            final body = detail['body'] as String? ?? '';
            final channel = detail['channel'] as String? ?? 'task_reminders';
            if (!await _hasRecordedNotificationToday(id)) {
              await _saveNotificationRecord(title, body, channel: channel);
              await _markNotificationRecordedToday(id);
            }
          } catch (_) {}
        }
      } catch (_) {}
    }();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      processPendingNotification();
    });
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Background callback: persist pending payload so main isolate can process it on startup.
    try {
      final payload = response.payload;
      final id = response.id ?? 0;
      SharedPreferences.getInstance().then((prefs) async {
        try {
          await prefs.setString(
            'pending_notification',
            json.encode({'id': id, 'payload': payload ?? ''}),
          );
        } catch (_) {}

        try {
          // If we have stored details for this id, also persist it into the
          // notification history so the message center shows the notification
          // even if the app is not yet resumed.
          final detailRaw = prefs.getString('notification_detail_$id');
          if (detailRaw != null && detailRaw.isNotEmpty) {
            try {
              final detail = json.decode(detailRaw) as Map<String, dynamic>;
              final title = detail['title'] as String? ?? '';
              final body = detail['body'] as String? ?? '';
              final channel = detail['channel'] as String? ?? 'task_reminders';

              final now = DateTime.now();
              final todayStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              final recorded =
                  prefs.getStringList('recorded_notifications') ?? [];
              final key = '$id:$todayStr';
              if (!recorded.contains(key)) {
                final rawHistory =
                    prefs.getString('notification_history') ?? '[]';
                List list;
                try {
                  list = json.decode(rawHistory) as List;
                } catch (_) {
                  list = [];
                }
                list.insert(0, {
                  'title': title,
                  'body': body,
                  'time': DateTime.now().toIso8601String(),
                  'channel': channel,
                });
                if (list.length > 100) list = list.sublist(0, 100);
                await prefs.setString(
                  'notification_history',
                  json.encode(list),
                );

                recorded.add(key);
                if (recorded.length > 500) {
                  recorded.removeRange(0, recorded.length - 500);
                }
                await prefs.setStringList('recorded_notifications', recorded);

                final count = (prefs.getInt('notification_unread') ?? 0) + 1;
                await prefs.setInt('notification_unread', count);
              }
            } catch (_) {}
          }
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> processPendingNotification() async {
    NotificationResponse? response = _pendingCallbackResponse;
    _pendingCallbackResponse = null;

    String? payload;

    if (response != null) {
      payload = response.payload;
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final pend = prefs.getString('pending_notification');
        if (pend != null && pend.isNotEmpty) {
          try {
            final map = json.decode(pend) as Map<String, dynamic>;
            payload = map['payload'] as String?;
          } catch (_) {}
          await prefs.remove('pending_notification');
        }
      } catch (_) {}
    }

    if (payload == null || payload.isEmpty) {
      return;
    }

    await catchUpMissedNotifications();
    final nav = navigatorKey.currentState;
    nav?.pushNamed(payload);
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {}
      return true;
    }
    return false;
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const id = 0;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
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
      payload: '/messages',
    );
    await _storeNotificationDetail(id, title, body, 'task_reminders');
    await _saveNotificationRecord(title, body, channel: 'task_reminders');
  }

  static const _taskReminderDetails = NotificationDetails(
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
  );

  Future<void> _scheduleTaskAlarm({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Cancel any existing schedule with same id to avoid duplicates
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _taskReminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/messages',
    );
    await _storeNotificationDetail(id, title, body, 'task_reminders');
    await _saveScheduledNotification(
      id,
      title,
      body,
      'task_reminders',
      hour,
      minute,
    );
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _scheduleTaskAlarm(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    );
  }

  Future<void> scheduleSummaryNotification(int hour, int minute) async {
    const summaryId = 999999;
    await _plugin.cancel(id: summaryId);

    final summary = await _calculateTodaysSummary();

    await _plugin.zonedSchedule(
      id: summaryId,
      title: '今日总结',
      body: summary,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
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
      payload: '/messages',
    );
    await _storeNotificationDetail(summaryId, '今日总结', summary, 'daily_summary');
    await _saveScheduledNotification(
      summaryId,
      '今日总结',
      summary,
      'daily_summary',
      hour,
      minute,
    );
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
    buffer.writeln(
      isZh ? '完成情况: $completed/$total' : 'Completion: $completed/$total',
    );

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
          '太棒了！今天全部完成了！你是效率之王！',
          '完美收官！看看这满屏的勾勾，多么令人满足~',
          '全垒打！今天没有一项任务能逃过你的魔爪！',
          '满分通关！你这效率，连闪电侠都得甘拜下风！',
          '任务清空！此刻你比刚出炉的面包还要优秀！',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.8) {
        final msgs = [
          '非常不错！你已经完成了大部分任务，继续保持！',
          '优秀的表现！就差那么一丁点儿了，明天加油！',
          '八分圆满已经很厉害啦，剩下的留给明天的自己吧~',
          '差一步美满，但你已经击败了全国80%的用户！',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.5) {
        final msgs = [
          '完成了过半的任务，已经是个不错的开始了！',
          '一半已搞定，剩下的也别放弃哦，慢慢来~',
          '进度过半！继续前进，完成的就是赚到的！',
          '过半啦！就像吃了一半的西瓜，最甜的还在后面！',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate > 0) {
        final msgs = [
          '万里长征第一步，今天已经起跑了，明天会更好！',
          '做一点也是做，比昨天的自己更进步了一点呢~',
          '好的开始是成功的一半，你今天已经成功了一半！',
          '打破零蛋！每一个完成的勾都是一个小胜利！',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else {
        final msgs = [
          '今天全部未完成？没关系，明天的太阳照常升起！',
          '零完成不丢人，真正的勇士敢于面对空白的todo！',
          '今天是养精蓄锐的一天，明天必定火力全开！',
          '今日休舱日！休眠是为了更好的爆发，理解的~',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      }
    } else {
      if (rate >= 1.0) {
        final msgs = [
          'Amazing! All completed! You\'re the productivity king!',
          'Perfect finish! All checkmarks, so satisfying~',
          'Grand slam! Nothing escaped you today!',
          'Flawless victory! Even The Flash would envy your speed!',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.8) {
        final msgs = [
          'Great job! Most tasks done, keep it up!',
          'Excellent! Just a tiny bit left for tomorrow!',
          '80% is impressive, save some for later~',
          'Almost there! You\'re in the top tier!',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.5) {
        final msgs = [
          'Halfway there, a solid start!',
          'Half done, don\'t give up, pace yourself~',
          'Over halfway! Every check counts!',
          'Half a watermelon done, the sweetest half awaits!',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate > 0) {
        final msgs = [
          'First step taken! Tomorrow will be better!',
          'Something is better than nothing, you\'re improving~',
          'A good start is half the battle!',
          'Broke the zero! Every checkmark is a victory!',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else {
        final msgs = [
          'Nothing done? No worries, the sun rises again!',
          'Zero completions takes courage to face!',
          'Resting today, full power tomorrow!',
          'Recharge day! Downtime is productive too~',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      }
    }
  }

  Future<void> scheduleMidnightRefresh() async {
    const refreshId = 999998;
    await _plugin.cancel(id: refreshId);

    const title = '新的一天';
    const body = '新的一天开始啦！健康计划已刷新，今天也要加油哦~';
    await _plugin.zonedSchedule(
      id: refreshId,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(0, 0),
      notificationDetails: const NotificationDetails(
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
    );
    await _storeNotificationDetail(refreshId, title, body, 'midnight_refresh');
    await _saveScheduledNotification(
      refreshId,
      title,
      body,
      'midnight_refresh',
      0,
      0,
    );
  }

  Future<void> cancelTaskReminder(int id) async {
    await _plugin.cancel(id: id);
    await _removeScheduledNotification(id);
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('scheduled_notifications_meta', '{}');
    } catch (_) {}
  }

  Future<void> cancelSummary() async {
    await _plugin.cancel(id: 999999);
    await _removeScheduledNotification(999999);
  }

  Future<void> cancelMidnightRefresh() async {
    await _plugin.cancel(id: 999998);
    await _removeScheduledNotification(999998);
  }

  Future<void> rescheduleAllReminders() async {
    final localeCode = await _getLocaleCode();
    final isZh = _isZh(localeCode);

    final healthItems = await _db.getActiveHealthItems();
    for (final h in healthItems) {
      if (h.reminderEnabled && h.id != null) {
        final parts = h.reminderTime.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 20;
          final minute = int.tryParse(parts[1]) ?? 0;
          await _scheduleTaskAlarm(
            id: h.id! + 10000,
            title: isZh ? '健康提醒' : 'Health Reminder',
            body: isZh
                ? '该完成「${h.name}」啦！动起来，身体会感谢你的~'
                : 'Time for "${h.name}"! Your body will thank you~',
            hour: hour,
            minute: minute,
          );
        }
      }
    }

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final scheduleItems = await _db.getScheduleItemsForDate(dateStr);
    for (final s in scheduleItems) {
      if (s.reminderEnabled && s.id != null) {
        final parts = s.reminderTime.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 20;
          final minute = int.tryParse(parts[1]) ?? 0;
          await _scheduleTaskAlarm(
            id: s.id! + 20000,
            title: isZh ? '日程提醒' : 'Schedule Reminder',
            body: isZh
                ? '「${s.name}」到时间啦！别忘记哦~'
                : '"${s.name}" is up! Don\'t forget~',
            hour: hour,
            minute: minute,
          );
        }
      }
    }
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
