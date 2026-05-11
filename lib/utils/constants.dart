import 'dart:convert';

List<Map<String, String>> presetHealthItems = [
  {
    'name': '饮水',
    'icon': 'water_drop',
    'description': '每天饮用充足的水分，建议成年人每日饮水量约1500-2000ml',
    'defaultValue': '2000ml',
  },
  {
    'name': '跑步',
    'icon': 'directions_run',
    'description': '每天坚持跑步，建议每次3-5公里，有助于心肺健康',
    'defaultValue': '5公里',
  },
  {
    'name': '远眺',
    'icon': 'visibility',
    'description': '每工作/学习45分钟后远眺5分钟，缓解视疲劳',
    'defaultValue': '5分钟',
  },
  {
    'name': '晨间拉伸',
    'icon': 'self_improvement',
    'description': '早晨起床后进行5-10分钟全身拉伸，激活身体',
    'defaultValue': '10分钟',
  },
  {
    'name': '冥想',
    'icon': 'meditation',
    'description': '每天冥想10-15分钟，缓解压力，提升专注力',
    'defaultValue': '10分钟',
  },
  {
    'name': '睡眠',
    'icon': 'bedtime',
    'description': '保证每天7-8小时充足睡眠，23点前入睡为佳',
    'defaultValue': '8小时',
  },
  {
    'name': '水果摄入',
    'icon': 'eco',
    'description': '每天摄入适量水果，补充维生素和膳食纤维',
    'defaultValue': '200g',
  },
  {
    'name': '步数',
    'icon': 'directions_walk',
    'description': '每天行走8000-10000步，保持基本运动量',
    'defaultValue': '8000步',
  },
];

List<Map<String, String>> presetScheduleItems = [
  {'name': '晨读', 'icon': 'menu_book', 'description': '早晨阅读30分钟，可选择外语文章或专业知识书籍'},
  {'name': '背单词', 'icon': 'spellcheck', 'description': '每日背诵20-30个新单词，长期积累词汇量'},
  {'name': '课堂笔记整理', 'icon': 'edit_note', 'description': '整理当天课堂笔记，加深记忆理解'},
  {'name': '作业时间', 'icon': 'assignment', 'description': '集中精力完成当天作业，建议使用番茄工作法'},
  {'name': '复习', 'icon': 'replay', 'description': '复习当天所学内容，巩固知识点'},
  {'name': '编程练习', 'icon': 'code', 'description': '每天练习一道算法题或一个编程实践'},
  {'name': '课题研究', 'icon': 'biotech', 'description': '每日推进课题研究进度，阅读文献或做实验'},
  {
    'name': '学习新技能',
    'icon': 'lightbulb',
    'description': '每天抽出时间学习一项新技能，如乐器、绘画等',
  },
];

const String appName = 'TODO';
const String defaultReminderTime = '20:00';
const String defaultSummaryTime = '23:00';

const String dbName = 'todo_app.db';
const int dbVersion = 1;

String todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String formatDate(String dateStr) {
  final parts = dateStr.split('-');
  if (parts.length == 3) {
    return '${parts[0]}/${parts[1]}/${parts[2]}';
  }
  return dateStr;
}

List<String> encouragementMessages(double completionRate) {
  if (completionRate >= 1.0) {
    return [
      '太棒了！今天全部完成了！你是效率之王！👑',
      '完美收官！看看这满屏的勾勾，多么令人满足~',
      '全垒打！今天没有一项任务能逃过你的魔爪！💪',
    ];
  } else if (completionRate >= 0.8) {
    return [
      '非常不错！你已经完成了大部分任务，继续保持！',
      '优秀的表现！就差那么一丁点儿了，明天加油！',
      '八分圆满已经很厉害啦，剩下的留给明天的自己吧~',
    ];
  } else if (completionRate >= 0.5) {
    return [
      '完成了过半的任务，已经是个不错的开始了！',
      '一半已搞定，剩下的也别放弃哦，慢慢来~',
      '进度过半！继续前进，完成的就是赚到的！',
    ];
  } else if (completionRate > 0) {
    return [
      '万里长征第一步，今天已经起跑了，明天会更好！',
      '做一点也是做，比昨天的自己更进步了一点呢~',
      '好的开始是成功的一半，你今天已经成功了一半！',
    ];
  } else {
    return [
      '今天全部未完成？没关系，明天的太阳照常升起！',
      '零完成不丢人，真正的勇士敢于面对空白的todo！',
      '今天是养精蓄锐的一天，明天必定火力全开！',
    ];
  }
}

String getEncouragementMessage(double completionRate) {
  final msgs = encouragementMessages(completionRate);
  return msgs[DateTime.now().millisecondsSinceEpoch % msgs.length];
}

Map<String, dynamic> appDataToJson({
  required List<Map<String, dynamic>> healthItems,
  required List<Map<String, dynamic>> scheduleItems,
  required Map<String, String> settings,
}) {
  return {
    'version': 1,
    'exportDate': DateTime.now().toIso8601String(),
    'healthItems': healthItems,
    'scheduleItems': scheduleItems,
    'settings': settings,
  };
}

Map<String, dynamic>? parseAppDataJson(String jsonStr) {
  try {
    return json.decode(jsonStr) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
