class HealthItem {
  final int? id;
  final String name;
  final String icon;
  final String category; // 'preset' or 'custom'
  final String description;
  final String defaultValue;
  final String notes;
  final bool reminderEnabled;
  final String reminderTime;
  final bool isActive;
  final int sortOrder;
  final String createdAt;

  HealthItem({
    this.id,
    required this.name,
    required this.icon,
    required this.category,
    this.description = '',
    this.defaultValue = '',
    this.notes = '',
    this.reminderEnabled = false,
    this.reminderTime = '20:00',
    this.isActive = true,
    this.sortOrder = 0,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'category': category,
      'description': description,
      'default_value': defaultValue,
      'notes': notes,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  factory HealthItem.fromMap(Map<String, dynamic> map) {
    return HealthItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      category: map['category'] as String,
      description: map['description'] as String? ?? '',
      defaultValue: map['default_value'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      reminderEnabled: (map['reminder_enabled'] as int?) == 1,
      reminderTime: map['reminder_time'] as String? ?? '20:00',
      isActive: (map['is_active'] as int?) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  HealthItem copyWith({
    int? id,
    String? name,
    String? icon,
    String? category,
    String? description,
    String? defaultValue,
    String? notes,
    bool? reminderEnabled,
    String? reminderTime,
    bool? isActive,
    int? sortOrder,
    String? createdAt,
  }) {
    return HealthItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
