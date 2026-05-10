class DailyRecord {
  final int? id;
  final String date; // YYYY-MM-DD
  final String itemType; // 'health' or 'schedule'
  final int itemId;
  final bool completed;
  final String? completedAt;

  DailyRecord({
    this.id,
    required this.date,
    required this.itemType,
    required this.itemId,
    this.completed = false,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'item_type': itemType,
      'item_id': itemId,
      'completed': completed ? 1 : 0,
      'completed_at': completedAt,
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      itemType: map['item_type'] as String,
      itemId: map['item_id'] as int,
      completed: (map['completed'] as int?) == 1,
      completedAt: map['completed_at'] as String?,
    );
  }

  DailyRecord copyWith({
    int? id,
    String? date,
    String? itemType,
    int? itemId,
    bool? completed,
    String? completedAt,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
