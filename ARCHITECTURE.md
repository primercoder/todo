# TODO App 架构设计文档

## 1. 项目概述

TODO 是一款面向 Android 14+ 的健康习惯培养与日程管理应用。核心目标是帮助用户养成良好健康习惯，同时提供灵活的日程管理功能。

## 2. 技术选型

| 技术栈 | 选择 | 说明 |
|-------|------|------|
| 跨平台框架 | Flutter 3.38+ | 参考 LocalSend 方案，便于未来跨平台扩展 |
| 状态管理 | Provider | 轻量级，适合中等规模应用 |
| 本地数据库 | SQLite (sqflite) | 持久化存储健康计划、日程和历史记录 |
| 本地配置 | SharedPreferences | 存储主题、提醒时间等轻量设置 |
| 通知系统 | flutter_local_notifications | 支持定时提醒、每日总结推送 |
| 平台适配 | Android 14+ (API 34+) | minSdk=34, targetSdk=36 |

## 3. 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Overview │  │  Health  │  │ Schedule │  │ Settings │   │
│  │   Page   │  │   Page   │  │   Page   │  │   Page   │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │              │              │              │        │
│  ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐   │
│  │ Overview │  │  Health  │  │ Schedule │  │ Settings │   │
│  │ Provider │  │ Provider │  │ Provider │  │ Provider │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
├─────────────────────────────────────────────────────────────┤
│                      Service Layer                          │
│  ┌──────────────────────┐  ┌──────────────────────────────┐ │
│  │ Notification Service │  │    Database Helper (SQLite)   │ │
│  │  - 提醒通知           │  │    - health_items             │ │
│  │  - 每日总结           │  │    - schedule_items           │ │
│  │  - 零点刷新           │  │    - daily_records            │ │
│  └──────────────────────┘  │    - history_summaries        │ │
│                             └──────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │  HealthItem  │ │ ScheduleItem │ │ DailyRecord  │        │
│  │    Model     │ │    Model     │ │    Model     │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 4. 数据模型

### HealthItem (健康计划)
| 字段 | 类型 | 说明 |
|-----|------|------|
| id | int | 主键自增 |
| name | String | 项目名称 |
| icon | String | 图标标识 |
| category | String | preset/custom |
| description | String | 描述说明 |
| defaultValue | String | 建议值（如2000ml） |
| notes | String | 用户备注 |
| reminderEnabled | bool | 是否开启提醒 |
| reminderTime | String | 提醒时间 HH:mm |
| isActive | bool | 是否激活 |
| sortOrder | int | 排序权重 |
| createdAt | String | 创建时间 |

### ScheduleItem (日程安排)
| 字段 | 类型 | 说明 |
|-----|------|------|
| id | int | 主键自增 |
| name | String | 日程名称 |
| icon | String | 图标标识 |
| category | String | preset/custom |
| description | String | 描述说明 |
| notes | String | 用户备注 |
| scheduleDate | String | 日程日期 YYYY-MM-DD |
| reminderEnabled | bool | 是否开启提醒 |
| reminderTime | String | 提醒时间 HH:mm |
| isActive | bool | 是否激活 |
| createdAt | String | 创建时间 |

### DailyRecord (每日完成记录)
| 字段 | 类型 | 说明 |
|-----|------|------|
| id | int | 主键自增 |
| date | String | 日期 YYYY-MM-DD |
| itemType | String | health/schedule |
| itemId | int | 关联项目ID |
| completed | bool | 是否完成 |
| completedAt | String | 完成时间 |

### HistorySummary (历史总结)
| 字段 | 类型 | 说明 |
|-----|------|------|
| id | int | 主键自增 |
| date | String | 日期 |
| totalCount | int | 总任务数 |
| completedCount | int | 完成数 |
| summaryText | String | 总结文本 |

## 5. 核心流程

### 5.1 数据刷新流程

```
┌──────────────┐     00:00触发     ┌──────────────┐
│  午夜刷新     │ ───────────────→ │  检查当天日期  │
│  (00:00)     │                   └──────┬───────┘
└──────────────┘                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ 加载所有激活健康项  │
                                 │ (每天自动刷新)      │
                                 └────────┬─────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ 按日期匹配日程项    │
                                 │ (仅匹配当天日期)    │
                                 └────────┬─────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ 初始化daily_records│
                                 │ 全部默认未完成      │
                                 └──────────────────┘
```

### 5.2 每日总结流程

```
┌──────────────┐     23:00触发     ┌──────────────┐
│  总结通知     │ ───────────────→ │  查询当日记录  │
│  (23:00)     │                   └──────┬───────┘
└──────────────┘                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ 计算完成率         │
                                 │ completed/total   │
                                 └────────┬─────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ 生成鼓励语句       │
                                 │ (根据完成率分级)    │
                                 └────────┬─────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ 保存历史总结       │
                                 │ → history_summaries│
                                 └────────┬─────────┘
                                          │
                                          ▼
                                 ┌──────────────────┐
                                 │ 发送通知           │
                                 └──────────────────┘
```

### 5.3 概览页交互流程

```
用户打开概览页
      │
      ▼
┌──────────────┐
│ 初始化当天数据  │
└──────┬───────┘
       │
       ▼
┌──────────────┐    ┌──────────────┐
│ 加载激活健康项  │    │ 加载当天日程项  │
└──────┬───────┘    └──────┬───────┘
       │                   │
       └────────┬──────────┘
                ▼
       ┌────────────────┐
       │ 查询完成状态    │
       │ (daily_records) │
       └────────┬───────┘
                ▼
       ┌────────────────┐
       │ 显示任务卡片     │
       │ (支持分类筛选)   │
       └────────┬───────┘
                ▼
       ┌────────────────┐
       │ 用户点击勾选     │
       │ → 更新完成状态   │
       └────────────────┘
```

## 6. 通知系统

### 通知类型
1. **任务提醒** - 每项健康计划/日程可设定独立提醒时间
2. **每日总结** - 默认 23:00，可自定义，汇总当日完成情况
3. **零点刷新** - 00:00，通知用户新的一天开始

### 后台运行机制
- 使用 `flutter_local_notifications` 的 `zonedSchedule` 实现定时通知
- `androidScheduleMode: inexactAllowWhileIdle` 确保在低电模式下也能触发
- AndroidManifest 已配置 `RECEIVE_BOOT_COMPLETED` 权限，设备重启后恢复通知
- `ScheduledNotificationBootReceiver` 确保重启后通知调度恢复

## 7. 预设数据

### 健康项目预设
饮水、跑步、远眺、晨间拉伸、冥想、睡眠、水果摄入、步数（共8项）

### 日程项目预设
晨读、背单词、课堂笔记整理、作业时间、复习、编程练习、课题研究、学习新技能（共8项）

## 8. 主题系统

支持 5 种主题风格：
- 明亮 (light) - 默认，清新蓝白配色
- 暗黑 (dark) - 夜间模式
- 花园 (garden) - 绿色系
- 海洋 (ocean) - 蓝色系
- 日落 (sunset) - 橙色系

## 9. 文件结构

```
lib/
├── main.dart                    # 应用入口，路由配置
├── database/
│   └── database_helper.dart     # SQLite 数据库操作
├── models/
│   ├── health_item.dart         # 健康计划模型
│   ├── schedule_item.dart       # 日程安排模型
│   └── daily_record.dart        # 每日记录模型
├── providers/
│   ├── overview_provider.dart   # 概览页状态管理
│   ├── health_provider.dart     # 健康页状态管理
│   ├── schedule_provider.dart   # 日程页状态管理
│   └── settings_provider.dart   # 设置页状态管理
├── services/
│   └── notification_service.dart # 通知服务
├── pages/
│   ├── overview_page.dart       # 概览页
│   ├── health_page.dart         # 健康页
│   ├── schedule_page.dart       # 日程页
│   └── settings_page.dart       # 设置页
├── widgets/
│   ├── task_card.dart           # 任务卡片组件
│   └── filter_bar.dart          # 筛选栏组件
└── utils/
    ├── constants.dart           # 常量和工具函数
    └── theme.dart               # 主题定义
```

## 10. Git 工作流

```
main
  ├── feat: 初始化TODO应用项目
  ├── fix: 修复Android构建配置
  └── (后续迭代提交)
```
