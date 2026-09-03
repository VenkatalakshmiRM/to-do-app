enum AssignmentPlatform { manual, vtop, neocolab, moodle, vitol, other }

enum AssignmentStatus { pending, submitted, overdue }

enum AssignmentPriority { low, medium, high }

const _unset = Object();

class AssignmentItem {
  AssignmentItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.platform,
    required this.deadline,
    required this.status,
    required this.priority,
    required List<DateTime> reminderTimes,
    this.description,
    this.externalUrl,
    this.sourceIdentifier,
    this.lastSyncedAt,
  }) : reminderTimes = List.unmodifiable(reminderTimes);

  final String id;
  final String title;
  final String subject;
  final String? description;
  final AssignmentPlatform platform;
  final DateTime deadline;
  final AssignmentStatus status;
  final AssignmentPriority priority;
  final String? externalUrl;
  final String? sourceIdentifier;
  final List<DateTime> reminderTimes;
  final DateTime? lastSyncedAt;

  AssignmentItem copyWith({
    String? id,
    String? title,
    String? subject,
    Object? description = _unset,
    AssignmentPlatform? platform,
    DateTime? deadline,
    AssignmentStatus? status,
    AssignmentPriority? priority,
    Object? externalUrl = _unset,
    Object? sourceIdentifier = _unset,
    List<DateTime>? reminderTimes,
    Object? lastSyncedAt = _unset,
  }) {
    return AssignmentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      platform: platform ?? this.platform,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      externalUrl: identical(externalUrl, _unset)
          ? this.externalUrl
          : externalUrl as String?,
      sourceIdentifier: identical(sourceIdentifier, _unset)
          ? this.sourceIdentifier
          : sourceIdentifier as String?,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      lastSyncedAt: identical(lastSyncedAt, _unset)
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
    );
  }

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String?,
      platform: AssignmentPlatform.values.byName(json['platform'] as String),
      deadline: DateTime.parse(json['deadline'] as String),
      status: AssignmentStatus.values.byName(json['status'] as String),
      priority: AssignmentPriority.values.byName(json['priority'] as String),
      externalUrl: json['externalUrl'] as String?,
      sourceIdentifier: json['sourceIdentifier'] as String?,
      reminderTimes: (json['reminderTimes'] as List<dynamic>)
          .map((value) => DateTime.parse(value as String))
          .toList(),
      lastSyncedAt: _dateTimeFromJson(json['lastSyncedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'platform': platform.name,
      'deadline': deadline.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'externalUrl': externalUrl,
      'sourceIdentifier': sourceIdentifier,
      'reminderTimes': reminderTimes
          .map((reminder) => reminder.toIso8601String())
          .toList(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    return value == null ? null : DateTime.parse(value as String);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssignmentItem &&
            other.id == id &&
            other.title == title &&
            other.subject == subject &&
            other.description == description &&
            other.platform == platform &&
            other.deadline == deadline &&
            other.status == status &&
            other.priority == priority &&
            other.externalUrl == externalUrl &&
            other.sourceIdentifier == sourceIdentifier &&
            _dateTimeListsEqual(other.reminderTimes, reminderTimes) &&
            other.lastSyncedAt == lastSyncedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    subject,
    description,
    platform,
    deadline,
    status,
    priority,
    externalUrl,
    sourceIdentifier,
    Object.hashAll(reminderTimes),
    lastSyncedAt,
  );

  static bool _dateTimeListsEqual(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
