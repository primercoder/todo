import 'package:flutter/material.dart';

class AppL10n {
  final Locale locale;
  AppL10n(this.locale);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  bool get isZh => locale.languageCode == 'zh';

  String get appTitle => 'TODO';

  // Bottom nav
  String get overview => isZh ? '概览' : 'Overview';
  String get health => isZh ? '健康' : 'Health';
  String get schedule => isZh ? '日程' : 'Schedule';
  String get settings => isZh ? '设置' : 'Settings';

  // Overview
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
  String get addFromTabs =>
      isZh ? '去「健康」或「日程」页添加吧~' : 'Go to Health or Schedule to add some~';
  String get filter => isZh ? '筛选' : 'Filter';
  String get historyLabel => isZh ? '历史记录' : 'History';
  String get selectDate => isZh ? '选择查看日期' : 'Select date';
  String get cancelLabel => isZh ? '取消' : 'Cancel';
  String get confirmLabel => isZh ? '确认' : 'Confirm';
  String get presetLabel => isZh ? '系统推荐' : 'Preset';
  String get customLabel => isZh ? '自定义' : 'Custom';
  String get descriptionLabel => isZh ? '描述' : 'Description';
  String get suggestedValueLabel => isZh ? '建议值' : 'Suggested';
  String get notesLabel => isZh ? '备注' : 'Notes';
  String get reminderTimeLabel => isZh ? '提醒时间' : 'Reminder';
  String get statusLabel => isZh ? '完成状态' : 'Status';
  String get completedStatus => isZh ? '✅ 已完成' : '✅ Done';
  String get incompleteStatus => isZh ? '⏳ 未完成' : '⏳ Pending';
  String get scheduleDateLabel => isZh ? '日程日期' : 'Date';

  // Health page
  String get healthTitle => isZh ? '健康计划' : 'Health Plan';
  String get noHealthPlan => isZh ? '还没有健康计划' : 'No health plans yet';
  String get addHealthHint =>
      isZh ? '点击右下角「+」或右上角灯泡添加吧~' : 'Tap + or the bulb icon to add~';
  String get presetHealthTitle => isZh ? '📋 参考健康项目' : '📋 Health Templates';
  String get presetHealthDesc =>
      isZh ? '点击添加推荐的健康习惯' : 'Tap to add recommended habits';
  String get editHealth => isZh ? '编辑健康计划' : 'Edit Health Plan';
  String get addNewHealth => isZh ? '添加健康计划' : 'Add Health Plan';
  String get itemName => isZh ? '项目名称' : 'Name';
  String get itemNameHint => isZh ? '例如：每天喝8杯水' : 'e.g. Drink 8 cups of water';
  String get suggestedValueHint =>
      isZh ? '例如：2000ml / 5公里' : 'e.g. 2000ml / 5km';
  String get notesHint => isZh ? '给自己留个小贴士吧~' : 'Leave a note for yourself~';
  String get enableReminder => isZh ? '开启提醒' : 'Enable Reminder';
  String reminderDesc(String time) => isZh ? '提醒时间: $time' : 'Reminder: $time';
  String get reminderOffDesc =>
      isZh ? '在设定时间发送通知提醒你' : 'Send notification at set time';
  String get save => isZh ? '保存修改' : 'Save Changes';
  String get add => isZh ? '添加计划' : 'Add Plan';
  String get delete => isZh ? '删除' : 'Delete';
  String get edit => isZh ? '编辑' : 'Edit';
  String get nameRequired => isZh ? '名称不能为空哦~' : 'Name cannot be empty~';
  String duplicateHealth(String name) =>
      isZh ? '「$name」已经存在，请勿重复添加~' : '"$name" already exists!';
  String addedToHealth(String name) =>
      isZh ? '「$name」已添加到健康计划' : '"$name" added to health plan';
  String confirmDeleteHealth(String name) => isZh
      ? '确定要删除「$name」吗？\n相关的历史记录也会被删除哦~'
      : 'Delete "$name"?\nRelated history will also be removed~';
  String get deleteTitle => isZh ? '确认删除' : 'Confirm Delete';

  // Schedule page
  String get scheduleTitle => isZh ? '日程安排' : 'Schedule';
  String get noSchedule => isZh ? '还没有日程安排' : 'No schedules yet';
  String get addScheduleHint =>
      isZh ? '点击右下角「+」或右上角灯泡添加吧~' : 'Tap + or the bulb icon to add~';
  String get presetScheduleTitle => isZh ? '📚 学习日程参考' : '📚 Study Templates';
  String get presetScheduleDesc =>
      isZh ? '点击添加推荐的日程安排' : 'Tap to add recommended schedules';
  String get editSchedule => isZh ? '编辑日程' : 'Edit Schedule';
  String get addNewSchedule => isZh ? '添加日程' : 'Add Schedule';
  String get scheduleName => isZh ? '日程名称' : 'Schedule Name';
  String get scheduleNameHint => isZh ? '例如：背50个单词' : 'e.g. Memorize 50 words';
  String get descriptionHint =>
      isZh ? '简要说明这个日程要做什么' : 'Brief description of this schedule';
  String get changeDate => isZh ? '更改' : 'Change';
  String duplicateSchedule(String name, String date) =>
      isZh ? '「$name」在$date已存在，请勿重复添加~' : '"$name" already exists on $date!';
  String addedToSchedule(String name) =>
      isZh ? '「$name」已添加到今日日程' : '"$name" added to today';
  String confirmDeleteSchedule(String name) => isZh
      ? '确定要删除「$name」日程吗？\n相关记录也会被删除哦~'
      : 'Delete "$name"?\nRelated records will also be removed~';
  String get todayLabel => isZh ? '今天' : 'Today';

  // Settings page
  String get settingsTitle => isZh ? '设置' : 'Settings';
  String get themeSection => isZh ? '🎨 主题风格' : '🎨 Theme';
  String get lightTheme => isZh ? '明亮' : 'Light';
  String get darkTheme => isZh ? '暗黑' : 'Dark';
  String get gardenTheme => isZh ? '花园' : 'Garden';
  String get oceanTheme => isZh ? '海洋' : 'Ocean';
  String get sunsetTheme => isZh ? '日落' : 'Sunset';
  String get notificationSection => isZh ? '🔔 提醒设置' : '🔔 Notifications';
  String get notificationToggle => isZh ? '启用通知' : 'Enable Notifications';
  String get notificationOffDesc =>
      isZh ? '关闭后所有提醒和总结将不会发送' : 'Disable all reminders and summaries';
  String get defaultReminderTimeLabel =>
      isZh ? '默认提醒时间' : 'Default Reminder Time';
  String get defaultReminderDesc =>
      isZh ? '新项目的默认提醒时间' : 'Default time for new items';
  String get summaryTimeLabel => isZh ? '每日总结时间' : 'Daily Summary Time';
  String get summaryDesc =>
      isZh ? '每天此时发送完成情况总结' : 'Send daily summary at this time';
  String get dataSection => isZh ? '💾 数据管理' : '💾 Data';
  String get exportDataLabel => isZh ? '导出数据' : 'Export Data';
  String get exportDesc =>
      isZh ? '将健康计划和日程导出为JSON文件' : 'Export plans as JSON file';
  String get importDataLabel => isZh ? '导入数据' : 'Import Data';
  String get importDesc => isZh ? '从备份文件恢复数据' : 'Restore from backup file';
  String get otherSection => isZh ? 'ℹ️ 其他' : 'ℹ️ Other';
  String get helpLabel => isZh ? '使用帮助' : 'Help';
  String get helpDesc => isZh ? '了解App的详细使用方式' : 'Learn how to use the app';
  String exportFailed(String e) => isZh ? '导出失败: $e' : 'Export failed: $e';
  String get exportSuccess => isZh ? '数据导出成功！' : 'Data exported!';
  String get importSuccess => isZh ? '数据导入成功！' : 'Data imported!';
  String importFailed(String e) => isZh ? '导入失败: $e' : 'Import failed: $e';
  String get invalidFormat => isZh ? '文件格式不正确' : 'Invalid file format';
  String get languageSection => isZh ? '🌐 语言 / Language' : '🌐 Language';
  String get chineseLabel => isZh ? '简体中文' : 'Simplified Chinese';
  String get englishLabel => isZh ? 'English' : 'English';
  String get todoSlogan => isZh ? '助你养成好习惯 ✨' : 'Build good habits ✨';
  String get selectTime => isZh ? '选择时间' : 'Select Time';
  String get messageCenter => isZh ? '消息中心' : 'Messages';
  String get noMessages => isZh ? '暂无消息' : 'No messages';
  String get bellTooltip => isZh ? '消息' : 'Messages';
  String get confirmDeleteTitle => isZh ? '确认删除' : 'Confirm Delete';

  // Help dialog
  String get helpTitle => isZh ? '📖 使用帮助' : '📖 Help';
  String get helpGotIt => isZh ? '知道了' : 'Got it';
  String get helpContent => isZh
      ? '''🏠 概览
查看当天所有待办事项，分为「健康计划」和「日程安排」两部分。点击右侧圆圈标记完成，点击其他区域查看详情。支持按类别和完成度筛选，点击右上角可查看历史记录。

❤️ 健康
管理每日健康习惯。点击「+」添加自定义计划，点击灯泡图标查看推荐项目（如饮水、跑步、远眺等）。每个项目可设置提醒时间和备注。健康计划每天自动刷新。

📅 日程
管理特定日期的日程安排。设置日程名称、日期、提醒时间等。日程仅在指定日期显示在概览页面。点击灯泡图标可查看学习类推荐项目。

⚙️ 设置
设置主题风格（明亮/暗黑/花园/海洋/日落）、默认提醒时间（默认20:00）、每日总结时间（默认23:00）。支持数据导出导入备份。支持切换界面语言。

🔔 提醒
开启提醒后，App会在设定时间发送通知。每日总结会在设定时间汇总当天完成情况，并送上鼓励语句。即使App未运行也会发送通知（需授权通知权限）。已完成的项会自动取消提醒。

🔄 刷新
每天00:00自动刷新：健康计划重新开始计数，日程根据日期自动显示/隐藏。历史记录可在概览页右上角查看。'''
      : '''🏠 Overview
View all daily tasks, divided into "Health Plan" and "Schedule". Tap the circle to mark complete, tap elsewhere for details. Filter by category and completion. View history in top right.

❤️ Health
Manage daily health habits. Tap "+" to add custom plans. Tap bulb for templates (water, running, etc.). Set reminders and notes for each item.

📅 Schedule
Manage date-specific schedules. Set name, date, reminder time. Schedules only appear on the specified date. Templates include study-related items.

⚙️ Settings
Choose theme (Light/Dark/Garden/Ocean/Sunset). Set default reminder time (20:00) and summary time (23:00). Export/import data. Switch language.

🔔 Notifications
Receive reminders at set times. Daily summary with encouragement. Works in background (requires notification permission). Completed items auto-cancel reminders.

🔄 Refresh
Auto-refresh at midnight: health plans reset, schedules show/hide by date. Check history in Overview.''';

  // Preset health items (localized)
  List<Map<String, String>> get presetHealthItems => [
    {
      'name': isZh ? '饮水' : 'Drink Water',
      'icon': 'water_drop',
      'description': isZh
          ? '每天饮用充足的水分，建议成年人每日饮水量约1500-2000ml'
          : 'Drink enough water daily, about 1500-2000ml for adults',
      'defaultValue': '2000ml',
    },
    {
      'name': isZh ? '跑步' : 'Running',
      'icon': 'directions_run',
      'description': isZh
          ? '每天坚持跑步，建议每次3-5公里，有助于心肺健康'
          : 'Run daily, recommend 3-5km each time',
      'defaultValue': '5km',
    },
    {
      'name': isZh ? '远眺' : 'Eye Rest',
      'icon': 'visibility',
      'description': isZh
          ? '每工作/学习45分钟后远眺5分钟，缓解视疲劳'
          : 'Look into the distance 5min after every 45min of work',
      'defaultValue': '5min',
    },
    {
      'name': isZh ? '晨间拉伸' : 'Stretching',
      'icon': 'self_improvement',
      'description': isZh
          ? '早晨起床后进行5-10分钟全身拉伸，激活身体'
          : '5-10 min full body stretch in the morning',
      'defaultValue': '10min',
    },
    {
      'name': isZh ? '冥想' : 'Meditation',
      'icon': 'self_improvement',
      'description': isZh
          ? '每天冥想10-15分钟，缓解压力，提升专注力'
          : 'Meditate 10-15min daily to reduce stress',
      'defaultValue': '10min',
    },
    {
      'name': isZh ? '睡眠' : 'Sleep',
      'icon': 'bedtime',
      'description': isZh
          ? '保证每天7-8小时充足睡眠，23点前入睡为佳'
          : 'Get 7-8 hours of sleep, best before 11pm',
      'defaultValue': '8h',
    },
    {
      'name': isZh ? '水果摄入' : 'Fruits',
      'icon': 'eco',
      'description': isZh
          ? '每天摄入适量水果，补充维生素和膳食纤维'
          : 'Eat fruits daily for vitamins and fiber',
      'defaultValue': '200g',
    },
    {
      'name': isZh ? '步数' : 'Steps',
      'icon': 'directions_walk',
      'description': isZh
          ? '每天行走8000-10000步，保持基本运动量'
          : 'Walk 8000-10000 steps daily',
      'defaultValue': '8000 steps',
    },
  ];

  // Preset schedule items (localized)
  List<Map<String, String>> get presetScheduleItems => [
    {
      'name': isZh ? '晨读' : 'Morning Reading',
      'icon': 'menu_book',
      'description': isZh
          ? '早晨阅读30分钟，可选择外语文章或专业知识书籍'
          : 'Read 30min in the morning',
    },
    {
      'name': isZh ? '背单词' : 'Vocabulary',
      'icon': 'spellcheck',
      'description': isZh
          ? '每日背诵20-30个新单词，长期积累词汇量'
          : 'Memorize 20-30 new words daily',
    },
    {
      'name': isZh ? '课堂笔记整理' : 'Notes Review',
      'icon': 'edit_note',
      'description': isZh
          ? '整理当天课堂笔记，加深记忆理解'
          : 'Organize class notes for better retention',
    },
    {
      'name': isZh ? '作业时间' : 'Homework',
      'icon': 'assignment',
      'description': isZh
          ? '集中精力完成当天作业，建议使用番茄工作法'
          : 'Focus on homework, try Pomodoro technique',
    },
    {
      'name': isZh ? '复习' : 'Review',
      'icon': 'replay',
      'description': isZh ? '复习当天所学内容，巩固知识点' : 'Review what you learned today',
    },
    {
      'name': isZh ? '编程练习' : 'Coding',
      'icon': 'code',
      'description': isZh
          ? '每天练习一道算法题或一个编程实践'
          : 'Practice one algorithm or coding exercise daily',
    },
    {
      'name': isZh ? '课题研究' : 'Research',
      'icon': 'biotech',
      'description': isZh
          ? '每日推进课题研究进度，阅读文献或做实验'
          : 'Advance research, read papers or experiment',
    },
    {
      'name': isZh ? '学习新技能' : 'New Skill',
      'icon': 'lightbulb',
      'description': isZh
          ? '每天抽出时间学习一项新技能，如乐器、绘画等'
          : 'Learn a new skill like instrument, painting',
    },
  ];

  // Task card tooltip
  String get tapToView => isZh ? '点击查看详情' : 'Tap to view details';
  String get tapToToggle => isZh ? '点击切换完成状态' : 'Tap to toggle completion';

  // Filter tooltips
  String get filterTooltip => isZh ? '筛选' : 'Filter';
  String get filterOffTooltip => isZh ? '关闭筛选' : 'Close filter';
  String get historyTooltip => isZh ? '历史记录' : 'History';
  String get presetProjectsTooltip => isZh ? '参考项目' : 'Templates';
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
