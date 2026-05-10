import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_l10n.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notification_history') ?? '[]';
    try {
      final list = json.decode(raw) as List;
      return list.cast<Map<String, dynamic>>().reversed.toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notification_history') ?? '[]';
    List list;
    try {
      list = json.decode(raw) as List;
    } catch (_) {
      list = [];
    }
    list.add({
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
    });
    if (list.length > 50) list = list.sublist(list.length - 50);
    await prefs.setString('notification_history', json.encode(list));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.messageCenter)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(l10n.noMessages, style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final time = DateTime.tryParse(n['time'] as String? ?? '');
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(n['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n['body'] != null) Text(n['body'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (time != null) Text(
                      '${time.year}/${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
