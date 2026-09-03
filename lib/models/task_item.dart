enum TaskPriority { low, medium, high }

const _unset = Object();

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.completed,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.category,
    this.dueAt,
  });

  final String id;
  final String title;
  final String? description;
  final bool completed;
  final TaskPriority priority;
  final String? category;
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskItem copyWith({
    String? id,
    String? title,
    Object? description = _unset,
    bool? completed,
    TaskPriority? priority,
    Object? category = _unset,
    Object? dueAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      category: identical(category, _unset)
          ? this.category
          : category as String?,
      dueAt: identical(dueAt, _unset) ? this.dueAt : dueAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool,
      priority: TaskPriority.values.byName(json['priority'] as String),
      category: json['category'] as String?,
      dueAt: _dateTimeFromJson(json['dueAt']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'priority': priority.name,
      'category': category,
      'dueAt': dueAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    return value == null ? null : DateTime.parse(value as String);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskItem &&
            other.id == id &&
            other.title == title &&
            other.description == description &&
            other.completed == completed &&
            other.priority == priority &&
            other.category == category &&
            other.dueAt == dueAt &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    completed,
    priority,
    category,
    dueAt,
    createdAt,
    updatedAt,
  );
}
