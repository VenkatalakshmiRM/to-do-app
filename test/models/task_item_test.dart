import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/task_item.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 16, 9);
  final updatedAt = DateTime.utc(2026, 8, 16, 10);
  final dueAt = DateTime.utc(2026, 8, 20, 17, 30);

  TaskItem createTask() => TaskItem(
    id: 'task-1',
    title: 'Submit assignment',
    description: 'Upload the PDF before the deadline',
    completed: false,
    priority: TaskPriority.high,
    category: 'College',
    dueAt: dueAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  group('TaskItem', () {
    test('copyWith changes selected values and preserves the rest', () {
      final original = createTask();
      final changedAt = DateTime.utc(2026, 8, 17);

      final changed = original.copyWith(
        title: 'Submit revised assignment',
        description: null,
        completed: true,
        priority: TaskPriority.medium,
        updatedAt: changedAt,
      );

      expect(changed.id, original.id);
      expect(changed.title, 'Submit revised assignment');
      expect(changed.description, isNull);
      expect(changed.completed, isTrue);
      expect(changed.priority, TaskPriority.medium);
      expect(changed.category, original.category);
      expect(changed.dueAt, original.dueAt);
      expect(changed.createdAt, original.createdAt);
      expect(changed.updatedAt, changedAt);
      expect(original.completed, isFalse);
    });

    test('JSON round-trip recreates an equal task', () {
      final original = createTask();

      final restored = TaskItem.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.hashCode, original.hashCode);
    });
  });
}
