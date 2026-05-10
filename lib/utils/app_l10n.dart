import 'package:flutter/material.dart';

class AppL10n {
  final Locale locale;
  AppL10n(this.locale);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  bool get isZh => locale.languageCode == 'zh';

  String get appTitle => 'TODO';
  String get overview => isZh ? '概览' : 'Overview';
  String get health => isZh ? '健康' : 'Health';
  String get schedule => isZh ? '日程' : 'Schedule';
  String get settings => isZh ? '设置' : 'Settings';

  String get todayOverview => isZh ? '今日概览' : "Today's Overview";
  String get healthPlan => isZh ? '健康计划' : 'Health Plan';
  String get schedulePlan => isZh ? '日程安排' : 'Schedule';
  String get completionProgress => isZh ? '完成进度' : 'Progress';
  String get category => isZh ? '类别' : 'Category';
  String get completion => isZh ? '完成度' : 'Completion';
  String get all => isZh ? '全部' : 'All';
  String get completed => isZh ? '已完成' : 'Completed';
  String get incomplete => isZh ? '未完成' : 'Incomplete';
  String get recentWeek => isZh ? '📊 最近一周' : '📊 Recent Week';
  String get noHistory => isZh ? '暂无历史记录' : 'No history yet';
  String get noTasks => isZh ? '今天还没有待办事项哦' : 'No tasks for today';
  String get addFromTabs => isZh ? '去「健康」或「日程」页添加吧~' : 'Go to Health or Schedule to add some~';
  String get filter => isZh ? '筛选' : 'Filter';
  String get history => isZh ? '历史记录' : 'History';
  String get selectDate => isZh ? '选择查看日期' : 'Select date';

  String get healthTitle => isZh ? '健康计划' : 'Health Plan';
  String get noHealthPlan => isZh ? '还没有健康计划' : 'No health plans yet';
  String get addHealthHint => isZh ? '点击右下角「+」或右上角灯泡添加吧~' : 'Tap + or the bulb icon to add~';
  String get presetHealth => isZh ? '📋 参考健康项目' : '📋 Health Templates';
  String get addHealthDesc => isZh ? '点击添加推荐的健康习惯' : 'Tap to add recommended habits';
  String get editHealth => isZh ? '编辑健康计划' : 'Edit Health Plan';
  String get addNewHealth => isZh ? '添加健康计划' : 'Add Health Plan';
  String get itemName => isZh ? '项目名称' : 'Item Name';
  String get suggestedValue => isZh ? '建议值' : 'Suggested Value';
  String get notes => isZh ? '备注' : 'Notes';
  String get enableReminder => isZh ? '开启提醒' : 'Enable Reminder';
  String get reminderTime => isZh ? '提醒时间' : 'Reminder Time';
  String get save => isZh ? '保存修改' : 'Save';
  String get add => isZh ? '添加计划' : 'Add';
  String get confirmDelete => isZh ? '确认删除' : 'Confirm Delete';
  String get deleteHealthConfirm => isZh ? '确定要删除「{name}」吗？\n相关的历史记录也会被删除哦~' : 'Delete "{name}"?\nRelated history will also be removed~';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get delete => isZh ? '删除' : 'Delete';
  String get added => isZh ? '已添加到健康计划' : 'Added to health plan';
  String get nameRequired => isZh ? '名称不能为空哦~' : 'Name cannot be empty~';
  String get edit => isZh ? '编辑' : 'Edit';
  String get presetProjects => isZh ? '参考项目' : 'Templates';
  String get change => isZh ? '更改' : 'Change';
  String get description => isZh ? '描述' : 'Description';
  String get scheduleDate => isZh ? '日程日期' : 'Schedule Date';
  String get today => isZh ? '今天' : 'Today';

  String get scheduleTitle => isZh ? '日程安排' : 'Schedule';
  String get noSchedule => isZh ? '还没有日程安排' : 'No schedules yet';
  String get addScheduleHint => isZh ? '点击右下角「+」或右上角灯泡添加吧~' : 'Tap + or the bulb icon to add~';
  String get presetSchedule => isZh ? '📚 学习日程参考' : '📚 Study Templates';
  String get addScheduleDesc => isZh ? '点击添加推荐的日程安排' : 'Tap to add recommended schedules';
  String get editSchedule => isZh ? '编辑日程' : 'Edit Schedule';
  String get addNewSchedule => isZh ? '添加日程' : 'Add Schedule';
  String get scheduleName => isZh ? '日程名称' : 'Schedule Name';
  String get deleteScheduleConfirm => isZh ? '确定要删除「{name}」日程吗？\n相关记录也会被删除哦~' : 'Delete "{name}"?\nRelated records will also be removed~';
  String get addedSchedule => isZh ? '已添加到今日日程' : 'Added to today\'s schedule';
  String get noteHint => isZh ? '给自己留个提醒吧~' : 'Leave a note for yourself~';

  String get settingsTitle => isZh ? '设置' : 'Settings';
  String get themeSection => isZh ? '🎨 主题风格' : '🎨 Theme';
  String get lightTheme => isZh ? '明亮' : 'Light';
  String get darkTheme => isZh ? '暗黑' : 'Dark';
  String get gardenTheme => isZh ? '花园' : 'Garden';
  String get oceanTheme => isZh ? '海洋' : 'Ocean';
  String get sunsetTheme => isZh ? '日落' : 'Sunset';
  String get notificationSection => isZh ? '🔔 提醒设置' : '🔔 Notifications';
  String get notificationToggle => isZh ? '启用通知' : 'Enable Notifications';
  String get notificationDesc => isZh ? '关闭后所有提醒和总结将不会发送' : 'Disable all reminders and summaries';
  String get defaultReminderTimeLabel => isZh ? '默认提醒时间' : 'Default Reminder Time';
  String get defaultReminderDesc => isZh ? '新项目的默认提醒时间' : 'Default time for new items';
  String get summaryTimeLabel => isZh ? '每日总结时间' : 'Daily Summary Time';
  String get summaryDesc => isZh ? '每天此时发送完成情况总结' : 'Send daily summary at this time';
  String get dataSection => isZh ? '💾 数据管理' : '💾 Data';
  String get exportData => isZh ? '导出数据' : 'Export Data';
  String get exportDesc => isZh ? '将健康计划和日程导出为JSON文件' : 'Export plans as JSON file';
  String get importData => isZh ? '导入数据' : 'Import Data';
  String get importDesc => isZh ? '从备份文件恢复数据' : 'Restore from backup file';
  String get otherSection => isZh ? 'ℹ️ 其他' : 'ℹ️ Other';
  String get help => isZh ? '使用帮助' : 'Help';
  String get helpDesc => isZh ? '了解App的详细使用方式' : 'Learn how to use the app';
  String get exportSuccess => isZh ? '数据导出成功！' : 'Data exported!';
  String get exportFailed => isZh ? '导出失败' : 'Export failed';
  String get importSuccess => isZh ? '数据导入成功！' : 'Data imported!';
  String get importFailed => isZh ? '导入失败' : 'Import failed';
  String get invalidFormat => isZh ? '文件格式不正确' : 'Invalid file format';
  String get languageSection => isZh ? '🌐 语言' : '🌐 Language';
  String get chinese => isZh ? '简体中文' : 'Simplified Chinese';
  String get english => 'English';
  String get todoSlogan => isZh ? '助你养成好习惯 ✨' : 'Build good habits ✨';

  // Help text
  String get helpTitle => isZh ? '📖 使用帮助' : '📖 Help';
  String get helpGotIt => isZh ? '知道了' : 'Got it';
  String get helpContent => isZh
      ? '''🏠 概览
查看当天所有待办事项，分为「健康计划」和「日程安排」两部分。点击事项左侧复选框即可标记完成。支持按类别和完成度筛选，点击右上角可查看历史记录。

❤️ 健康
管理每日健康习惯。点击「+」添加自定义计划，点击灯泡图标查看推荐项目（如饮水、跑步、远眺等）。每个项目可设置提醒时间和备注。健康计划每天自动刷新。

📅 日程
管理特定日期的日程安排。设置日程名称、日期、提醒时间等。日程仅在指定日期显示在概览页面。点击灯泡图标可查看学习类推荐项目。

⚙️ 设置
设置主题风格（明亮/暗黑/花园/海洋/日落）、默认提醒时间（默认20:00）、每日总结时间（默认23:00）。支持数据导出导入备份。支持切换界面语言。

🔔 提醒
开启提醒后，App会在设定时间发送通知。每日总结会在设定时间汇总当天完成情况，并送上鼓励语句。即使App未运行也会发送通知（需授权通知权限）。

🔄 刷新
每天00:00自动刷新：健康计划重新开始计数，日程根据日期自动显示/隐藏。历史记录可在概览页右上角查看。'''
      : '''🏠 Overview
View all daily tasks, divided into "Health Plan" and "Schedule". Tap to mark complete. Filter by category and completion status. View history in the top right.

❤️ Health
Manage daily health habits. Tap "+" to add custom plans. Tap the bulb to see templates (water, running, etc.). Set reminders and notes for each item. Plans refresh daily.

📅 Schedule
Manage date-specific schedules. Set name, date, reminder time. Schedules only appear on the specified date. Templates include study-related items.

⚙️ Settings
Choose theme (Light/Dark/Garden/Ocean/Sunset). Set default reminder time (20:00) and summary time (23:00). Export/import data. Switch interface language.

🔔 Notifications
Receive reminders at set times. Daily summary with encouragement messages. Works in background (requires notification permission).

🔄 Refresh
Auto-refresh at midnight: health plans reset, schedules show/hide by date. Check history in Overview.''';

  // Notification messages
  String healthReminderTitle(String name) =>
      isZh ? '💪 健康提醒' : '💪 Health Reminder';
  String healthReminderBody(String name, String defaultValue) {
    if (isZh) {
      final msgs = [
        '该完成「$name」啦！${defaultValue.isNotEmpty ? "目标: $defaultValue，" : ""}动起来，身体会感谢你的~ 🏃',
        '「$name」时间到！${defaultValue.isNotEmpty ? "小目标$defaultValue，" : ""}今天也要元气满满哦！✨',
        '别忘了「$name」！${defaultValue.isNotEmpty ? "$defaultValue在等你，" : ""}坚持就是胜利！💯',
        '「$name」该打卡了！${defaultValue.isNotEmpty ? "完成$defaultValue，" : ""}你已经很棒了！🌟',
      ];
      return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
    }
    final msgs = [
      'Time for "$name"! ${defaultValue.isNotEmpty ? "Target: $defaultValue. " : ""}Your body will thank you~ 🏃',
      '"$name" time! ${defaultValue.isNotEmpty ? "Aim for $defaultValue. " : ""}Stay energetic today! ✨',
      'Don\'t forget "$name"! ${defaultValue.isNotEmpty ? "$defaultValue awaits. " : ""}Persistence wins! 💯',
      '"$name" check-in! ${defaultValue.isNotEmpty ? "Complete $defaultValue, " : ""}You\'re doing great! 🌟',
    ];
    return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
  }

  String scheduleReminderTitle(String name) =>
      isZh ? '📅 日程提醒' : '📅 Schedule Reminder';
  String scheduleReminderBody(String name, String description) {
    if (isZh) {
      final msgs = [
        '「$name」到时间啦！${description.isNotEmpty ? description : "别忘记哦~"} 📚',
        '该开始「$name」了！${description.isNotEmpty ? description : "拖延是最大的时间小偷哦~"} ⏰',
        '「$name」提醒！${description.isNotEmpty ? description : "完成任务的感觉超棒的！"} 🎯',
        '「$name」的时刻到了！${description.isNotEmpty ? description : "今天进步一点点~"} 🚀',
      ];
      return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
    }
    final msgs = [
      '"$name" is up! ${description.isNotEmpty ? description : "Don\'t forget~"} 📚',
      'Time for "$name"! ${description.isNotEmpty ? description : "Procrastination is the thief of time~"} ⏰',
      '"$name" reminder! ${description.isNotEmpty ? description : "Completing tasks feels great!"} 🎯',
      '"$name" time! ${description.isNotEmpty ? description : "One step forward today~"} 🚀',
    ];
    return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
  }

  String midnightRefreshTitle() =>
      isZh ? '🔄 新的一天' : '🔄 New Day';
  String midnightRefreshBody() =>
      isZh ? '新的一天开始啦！健康计划已刷新，今天也要加油哦~' : 'New day! Plans refreshed, let\'s go~';

  // Encouragement messages
  String getEncouragement(double rate) {
    if (isZh) {
      if (rate >= 1.0) {
        final msgs = [
          '太棒了！今天全部完成了！你是效率之王！👑',
          '完美收官！看看这满屏的勾勾，多么令人满足~',
          '全垒打！今天没有一项任务能逃过你的魔爪！💪',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.8) {
        final msgs = [
          '非常不错！你已经完成了大部分任务，继续保持！',
          '优秀的表现！就差那么一丁点儿了，明天加油！',
          '八分圆满已经很厉害啦，剩下的留给明天的自己吧~',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.5) {
        final msgs = [
          '完成了过半的任务，已经是个不错的开始了！',
          '一半已搞定，剩下的也别放弃哦，慢慢来~',
          '进度过半！继续前进，完成的就是赚到的！',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate > 0) {
        final msgs = [
          '万里长征第一步，今天已经起跑了，明天会更好！',
          '做一点也是做，比昨天的自己更进步了一点呢~',
          '好的开始是成功的一半，你今天已经成功了一半！',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else {
        final msgs = [
          '今天全部未完成？没关系，明天的太阳照常升起！',
          '零完成不丢人，真正的勇士敢于面对空白的todo！',
          '今天是养精蓄锐的一天，明天必定火力全开！',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      }
    } else {
      if (rate >= 1.0) {
        final msgs = [
          'Amazing! All completed today! You\'re the king of productivity! 👑',
          'Perfect finish! Look at all those checkmarks, so satisfying~',
          'Home run! No task escaped your grasp today! 💪',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.8) {
        final msgs = [
          'Great job! You completed most tasks, keep it up!',
          'Excellent performance! Just a bit more, go for it tomorrow!',
          '80% is already impressive, leave the rest for tomorrow~',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate >= 0.5) {
        final msgs = [
          'Halfway there, a great start!',
          'Half done, don\'t give up on the rest, take your time~',
          'Over halfway! Keep going, every completed task counts!',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else if (rate > 0) {
        final msgs = [
          'First step taken! You\'ve started, tomorrow will be better!',
          'Doing something is better than nothing, you\'re improving~',
          'A good start is half the battle, you\'re halfway there!',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      } else {
        final msgs = [
          'Nothing completed today? No worries, the sun rises again tomorrow!',
          'Zero completions isn\'t shameful, facing an empty todo takes courage!',
          'A day of rest, tomorrow you\'ll come back stronger!',
        ];
        return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
      }
    }
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppL10n> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
