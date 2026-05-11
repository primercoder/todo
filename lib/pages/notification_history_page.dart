import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_l10n.dart';
import '../utils/theme.dart';
import '../services/notification_service.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().clearUnread();
      if (mounted) setState(() {});
    });
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notification_history') ?? '[]';
    try {
      final list = json.decode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_history', '[]');
    await NotificationService().clearUnread();
    setState(() {});
  }

  String _formatTime(String? isoStr) {
    if (isoStr == null) return '';
    final t = DateTime.tryParse(isoStr);
    if (t == null) return '';
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messageCenter),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _clearAll(),
            tooltip: l10n.isZh ? '全部清除' : 'Clear All',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMessages,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final title = n['title'] as String? ?? '';
              final body = n['body'] as String? ?? '';
              final timeStr = _formatTime(n['time'] as String?);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ExpansionTile(
                  initiallyExpanded: _expandedIndex == index,
                  onExpansionChanged: (expanded) {
                    setState(() => _expandedIndex = expanded ? index : null);
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    timeStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          body,
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
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
