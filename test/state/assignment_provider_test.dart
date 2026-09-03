import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/assignment_item.dart';
import 'package:student_task_hub/state/assignment_provider.dart';

void main() {
  group('AssignmentNotifier', () {
    test('starts with assignments from different platforms', () {
      final notifier = AssignmentNotifier(
        initialAssignments: _sampleAssignments(),
      );
      addTearDown(notifier.dispose);

      expect(notifier.state, hasLength(2));
      expect(notifier.state.map((item) => item.platform).toSet(), {
        AssignmentPlatform.vtop,
        AssignmentPlatform.neocolab,
      });
    });

    test('adds, updates, and deletes an assignment', () async {
      final notifier = AssignmentNotifier(
        initialAssignments: _sampleAssignments(),
      );
      addTearDown(notifier.dispose);
      final initialCount = notifier.state.length;
      final assignment = AssignmentItem(
        id: 'new-assignment',
        title: 'Write project proposal',
        subject: 'Software Engineering',
        platform: AssignmentPlatform.moodle,
        deadline: DateTime.utc(2026, 8, 28, 17),
        status: AssignmentStatus.pending,
        priority: AssignmentPriority.medium,
        reminderTimes: [DateTime.utc(2026, 8, 27, 17)],
      );

      await notifier.addAssignment(assignment);

      expect(notifier.state, hasLength(initialCount + 1));
      expect(notifier.state.last, assignment);

      final updated = assignment.copyWith(
        status: AssignmentStatus.submitted,
        priority: AssignmentPriority.low,
      );
      await notifier.updateAssignment(updated);

      expect(
        notifier.state.singleWhere((item) => item.id == assignment.id),
        updated,
      );

      await notifier.deleteAssignment(assignment.id);

      expect(notifier.state, hasLength(initialCount));
      expect(notifier.state.any((item) => item.id == assignment.id), isFalse);
    });

    test('derived provider filters without changing the base list', () {
      final container = ProviderContainer(
        overrides: [
          assignmentProvider.overrideWith(
            (ref) =>
                AssignmentNotifier(initialAssignments: _sampleAssignments()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final originalCount = container.read(assignmentProvider).length;

      container
          .read(assignmentFilterProvider.notifier)
          .state = const AssignmentFilter(
        searchQuery: 'python',
        platform: AssignmentPlatform.neocolab,
        status: AssignmentStatus.pending,
      );

      final filtered = container.read(filteredAssignmentProvider);
      expect(filtered, hasLength(1));
      expect(filtered.single.title, 'Complete Python practice set');
      expect(container.read(assignmentProvider), hasLength(originalCount));
    });
  });
}

List<AssignmentItem> _sampleAssignments() {
  return [
    AssignmentItem(
      id: 'sample-assignment-1',
      title: 'Submit data structures lab',
      subject: 'Data Structures',
      platform: AssignmentPlatform.vtop,
      deadline: DateTime(2026, 8, 20, 23, 59),
      status: AssignmentStatus.pending,
      priority: AssignmentPriority.high,
      reminderTimes: const [],
    ),
    AssignmentItem(
      id: 'sample-assignment-2',
      title: 'Complete Python practice set',
      subject: 'Programming',
      platform: AssignmentPlatform.neocolab,
      deadline: DateTime(2026, 8, 22, 18),
      status: AssignmentStatus.pending,
      priority: AssignmentPriority.medium,
      reminderTimes: const [],
    ),
  ];
}
