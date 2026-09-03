import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/assignment_item.dart';

void main() {
  final deadline = DateTime.utc(2026, 8, 25, 17, 30);
  final lastSyncedAt = DateTime.utc(2026, 8, 16, 10);
  final reminders = [
    DateTime.utc(2026, 8, 24, 17, 30),
    DateTime.utc(2026, 8, 25, 9),
  ];

  AssignmentItem createAssignment() => AssignmentItem(
    id: 'assignment-1',
    title: 'Submit lab report',
    subject: 'Physics',
    description: 'Upload the final PDF',
    platform: AssignmentPlatform.moodle,
    deadline: deadline,
    status: AssignmentStatus.pending,
    priority: AssignmentPriority.high,
    externalUrl: 'https://example.edu/assignment/1',
    sourceIdentifier: 'moodle-1',
    reminderTimes: reminders,
    lastSyncedAt: lastSyncedAt,
  );

  group('AssignmentItem', () {
    test('copyWith changes selected values and preserves the rest', () {
      final original = createAssignment();
      final newDeadline = DateTime.utc(2026, 8, 26, 17, 30);

      final changed = original.copyWith(
        title: 'Submit revised lab report',
        description: null,
        deadline: newDeadline,
        status: AssignmentStatus.submitted,
        priority: AssignmentPriority.medium,
        externalUrl: null,
      );

      expect(changed.id, original.id);
      expect(changed.title, 'Submit revised lab report');
      expect(changed.subject, original.subject);
      expect(changed.description, isNull);
      expect(changed.platform, original.platform);
      expect(changed.deadline, newDeadline);
      expect(changed.status, AssignmentStatus.submitted);
      expect(changed.priority, AssignmentPriority.medium);
      expect(changed.externalUrl, isNull);
      expect(changed.sourceIdentifier, original.sourceIdentifier);
      expect(changed.reminderTimes, original.reminderTimes);
      expect(changed.lastSyncedAt, original.lastSyncedAt);
      expect(original.status, AssignmentStatus.pending);
    });

    test('JSON round-trip recreates an equal assignment', () {
      final original = createAssignment();

      final restored = AssignmentItem.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.hashCode, original.hashCode);
    });
  });
}
