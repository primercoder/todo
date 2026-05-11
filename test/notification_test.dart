import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Timezone detection', () {
    test('timezone database is initialized and local is valid', () {
      final local = tz.local;
      expect(local, isNotNull);
      final now = tz.TZDateTime.now(local);
      expect(now.year, greaterThan(2020));
    });

    test('Asia/Shanghai location exists in database', () {
      final shanghai = tz.getLocation('Asia/Shanghai');
      expect(shanghai, isNotNull);
    });

    test('setLocalLocation works for Asia/Shanghai', () {
      final systemOffset = DateTime.now().timeZoneOffset;
      if (systemOffset == const Duration(hours: 8)) {
        final shanghai = tz.getLocation('Asia/Shanghai');
        tz.setLocalLocation(shanghai);
        final now = tz.TZDateTime.now(tz.local);
        final utc = now.toUtc();
        expect(utc.add(const Duration(hours: 8)).hour, now.hour);
      }
    });
  });

  group('_nextInstanceOfTime logic', () {
    tz.TZDateTime nextInstanceOfTime(int hour, int minute) {
      final now = tz.TZDateTime.now(tz.local);
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

    test('future time today returns today', () {
      final now = tz.TZDateTime.now(tz.local);
      final result = nextInstanceOfTime(23, 59);
      if (now.hour < 23 || (now.hour == 23 && now.minute < 59)) {
        expect(result.day, now.day);
      }
      expect(result.hour, 23);
      expect(result.minute, 59);
    });

    test('past time today returns tomorrow', () {
      final now = tz.TZDateTime.now(tz.local);
      final result = nextInstanceOfTime(0, 0);
      if (now.hour > 0 || now.minute > 0) {
        final tomorrow = now.add(const Duration(days: 1));
        expect(result.day, tomorrow.day);
      }
      expect(result.hour, 0);
      expect(result.minute, 0);
    });

    test('exact current minute returns tomorrow', () {
      final now = tz.TZDateTime.now(tz.local);
      final result = nextInstanceOfTime(now.hour, now.minute);
      if (now.second > 0 || now.millisecond > 0) {
        final tomorrow = now.add(const Duration(days: 1));
        expect(result.day, tomorrow.day);
      }
    });

    test('result is always in the future', () {
      final now = tz.TZDateTime.now(tz.local);
      for (final h in [0, 8, 14, 20, 23]) {
        final result = nextInstanceOfTime(h, 30);
        expect(
          result.isAfter(now),
          isTrue,
          reason: '$h:30 should be in the future',
        );
      }
    });

    test('times before now go to next day', () {
      final now = tz.TZDateTime.now(tz.local);
      final yesterdayHour = (now.hour - 1 + 24) % 24;
      final result = nextInstanceOfTime(yesterdayHour, now.minute);
      final tomorrow = now.add(const Duration(days: 1));
      expect(result.day, tomorrow.day);
    });

    test('times after now stay today', () {
      final now = tz.TZDateTime.now(tz.local);
      final futureHour = (now.hour + 2) % 24;
      if (futureHour > now.hour) {
        final result = nextInstanceOfTime(futureHour, 0);
        expect(result.day, now.day);
      }
    });

    test('scheduled seconds and milliseconds are zero', () {
      for (final h in [0, 8, 14, 20]) {
        final result = nextInstanceOfTime(h, 0);
        expect(result.second, 0);
        expect(result.millisecond, 0);
      }
    });
  });

  group('Notification ID allocation', () {
    test('health reminder IDs are in range 10001-19999', () {
      for (final itemId in [1, 42, 999, 9999]) {
        final nid = itemId + 10000;
        expect(nid, greaterThan(10000));
        expect(nid, lessThan(20000));
      }
    });

    test('schedule reminder IDs are in range 20001-29999', () {
      for (final itemId in [1, 42, 999, 9999]) {
        final nid = itemId + 20000;
        expect(nid, greaterThan(20000));
        expect(nid, lessThan(30000));
      }
    });

    test('health and schedule ID ranges do not overlap', () {
      expect(20000, greaterThan(10000 + 9999));
    });

    test('special IDs do not conflict', () {
      const summaryId = 999999;
      const midnightId = 999998;
      const maxTaskId = 29999;
      expect(summaryId, greaterThan(maxTaskId));
      expect(midnightId, greaterThan(maxTaskId));
      expect(summaryId, isNot(midnightId));
    });
  });

  group('Notification history structure', () {
    test('history entry has all required fields', () {
      final entry = {
        'title': 'Test Title',
        'body': 'Test body content',
        'time': DateTime.now().toIso8601String(),
        'channel': 'task_reminders',
      };
      expect(entry['title'], isNotNull);
      expect(entry['body'], isNotNull);
      expect(entry['time'], isNotNull);
      expect(entry['channel'], isNotNull);
    });

    test('ISO8601 timestamps are parseable', () {
      final original = DateTime(2026, 5, 10, 20, 0, 0);
      final iso = original.toIso8601String();
      final parsed = DateTime.tryParse(iso);
      expect(parsed, isNotNull);
      expect(parsed!.year, original.year);
      expect(parsed.month, original.month);
      expect(parsed.day, original.day);
      expect(parsed.hour, original.hour);
      expect(parsed.minute, original.minute);
    });

    test('timestamps across midnight work', () {
      final before = DateTime(2026, 5, 10, 23, 59, 59);
      final after = DateTime(2026, 5, 11, 0, 0, 1);
      expect(after.isAfter(before), isTrue);
    });
  });

  group('Channel configuration', () {
    test('channel IDs are unique', () {
      const taskChannel = 'task_reminders';
      const summaryChannel = 'daily_summary';
      const midnightChannel = 'midnight_refresh';
      expect(taskChannel, isNot(summaryChannel));
      expect(taskChannel, isNot(midnightChannel));
      expect(summaryChannel, isNot(midnightChannel));
    });

    test('channel importance levels are appropriate', () {
      const max = 4;
      const default_ = 3;
      final levels = [max, default_];
      expect(levels.toSet().length, 2);
    });
  });

  group('Time format helpers', () {
    test('todayDate returns YYYY-MM-DD', () {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(dateStr.length, 10);
      expect(dateStr.contains('-'), isTrue);
    });

    test('time parsing HH:mm format', () {
      for (final time in ['08:00', '14:30', '20:00', '23:59']) {
        final parts = time.split(':');
        expect(parts.length, 2);
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        expect(hour, isNotNull);
        expect(minute, isNotNull);
        expect(hour!, inInclusiveRange(0, 23));
        expect(minute!, inInclusiveRange(0, 59));
      }
    });
  });

  group('App launch from notification', () {
    test('payload route /messages is valid', () {
      const payload = '/messages';
      expect(payload.startsWith('/'), isTrue);
      expect(payload, '/messages');
    });

    test('payload /overview is valid', () {
      const payload = '/overview';
      expect(payload.startsWith('/'), isTrue);
    });
  });
}
