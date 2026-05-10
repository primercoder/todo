# TODO App

一款面向 Android 14+ 的健康习惯培养与日程管理应用。帮助用户养成良好健康习惯，同时提供灵活的日程管理功能。

## 功能特性

### 🏠 概览
- 展示当天所有待办事项（健康计划 + 日程安排）
- 支持按类别（健康/日程/全部）和完成度筛选
- 点击事项即可切换完成状态
- 显示完成进度条
- 查看历史记录（最近一周汇总）

### ❤️ 健康
- 管理每日健康习惯（饮水、跑步、远眺等）
- 内置 8 项参考健康项目，一键添加
- 支持自定义健康项目
- 每个项目可设置建议值、备注、提醒时间
- 支持拖拽排序
- 健康计划每天自动刷新

### 📅 日程
- 管理特定日期的日程安排
- 内置 8 项学习类参考项目
- 支持自定义日程，指定日期
- 每个日程可设置描述、备注、提醒时间
- 日程仅在指定日期显示在概览页

### ⚙️ 设置
- 5 种主题风格（明亮/暗黑/花园/海洋/日落）
- 自定义默认提醒时间（默认 20:00）
- 自定义每日总结时间（默认 23:00）
- 数据导出/导入（JSON 文件）
- 详细使用帮助

### 🔔 通知
- 每项任务独立提醒
- 每日固定时间发送总结（含鼓励语句）
- 零点自动刷新通知
- 后台运行，即使 App 未打开也能推送

## 技术栈

| 技术 | 说明 |
|------|------|
| Flutter 3.38+ | 跨平台框架 |
| Provider | 状态管理 |
| SQLite (sqflite) | 本地数据库 |
| flutter_local_notifications | 通知推送 |
| SharedPreferences | 轻量配置存储 |

## 构建要求

- Flutter SDK 3.38+
- Android SDK 34+
- JDK 17-24（推荐 JDK 21）
- Gradle 8.14+

## 构建步骤

```bash
# 安装依赖
flutter pub get

# 设置 Java 版本（重要！JDK 25 与 Gradle 8.14 不兼容）
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# 构建 APK
flutter build apk --debug

# 构建 Release APK
flutter build apk --release
```

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── database/
│   └── database_helper.dart     # 数据库操作
├── models/                      # 数据模型
├── providers/                   # 状态管理
├── services/
│   └── notification_service.dart # 通知服务
├── pages/                       # 页面
├── widgets/                     # 组件
└── utils/                       # 工具函数
```

## 开发说明

- 预设健康项目和日程项目在 `lib/utils/constants.dart` 中定义
- 数据库在首次启动时自动创建并填充预设数据
- 主题定义在 `lib/utils/theme.dart`
- 通知系统使用 `flutter_local_notifications` 的 zonedSchedule 实现定时推送

## 图标

App 图标使用 [历钟图标 by paomedia (Arnaud)](
https://icon-icons.com/zh/authors/143-paomedia-arnaud) on 
[Icon-Icons.com](https://icon-icons.com/zh/)

## License

MIT
