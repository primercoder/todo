class ScheduleItem {
  final int? id;
  final String name;
  final String icon;
  final String category; // 'preset' or 'custom'
  final String description;
  final String notes;
  final String scheduleDate; // YYYY-MM-DD
  final bool reminderEnabled;
  final String reminderTime;
  final bool isActive;
  final String createdAt;

  ScheduleItem({
    this.id,
    required this.name,
    required this.icon,
    required this.category,
    this.description = '',
    this.notes = '',
    required this.scheduleDate,
    this.reminderEnabled = false,
    this.reminderTime = '20:00',
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'category': category,
      'description': description,
      'notes': notes,
      'schedule_date': scheduleDate,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      category: map['category'] as String,
      description: map['description'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      scheduleDate: map['schedule_date'] as String,
      reminderEnabled: (map['reminder_enabled'] as int?) == 1,
      reminderTime: map['reminder_time'] as String? ?? '20:00',
      isActive: (map['is_active'] as int?) == 1,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  ScheduleItem copyWith({
    int? id,
    String? name,
    String? icon,
    String? category,
    String? description,
    String? notes,
    String? scheduleDate,
    bool? reminderEnabled,
    String? reminderTime,
    bool? isActive,
    String? createdAt,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
