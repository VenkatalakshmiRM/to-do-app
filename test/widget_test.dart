import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/app.dart';
import 'package:student_task_hub/models/assignment_item.dart';
import 'package:student_task_hub/models/task_item.dart';
import 'package:student_task_hub/state/assignment_provider.dart';
import 'package:student_task_hub/state/task_provider.dart';

void main() {
  testWidgets('switches between shell tabs', (tester) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('Home'), findsWidgets);

    await tester.tap(find.text('Assignments').last);
    await tester.pump();

    expect(find.text('Assignments'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pump();

    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('tasks tab toggles and deletes tasks', (tester) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.text('Tasks'));
    await tester.pump();

    expect(find.text('Review today’s classes'), findsOneWidget);
    expect(find.text('Prepare lab notes'), findsOneWidget);
    expect(find.text('Buy stationery'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);

    await tester.drag(
      find.text('Review today’s classes'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review today’s classes'), findsNothing);
  });

  testWidgets('tasks can be added and edited through the form', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Study algorithms',
    );
    await tester.tap(find.byKey(const ValueKey('save-task-button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Study algorithms'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Study algorithms'), findsOneWidget);

    await tester.tap(find.text('Study algorithms'));
    await tester.pumpAndSettle();
    expect(find.text('Edit task'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Study data structures',
    );
    await tester.tap(find.byKey(const ValueKey('save-task-button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Study data structures'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Study data structures'), findsOneWidget);
    expect(find.text('Study algorithms'), findsNothing);
  });

  testWidgets('task synchronization errors show a snackbar', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('task-search-field'))),
    );
    container.read(taskErrorProvider.notifier).state =
        'Could not update the task. Please try again.';
    await tester.pump();

    expect(
      find.text('Could not update the task. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('assignments are grouped and can be added and edited', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Assignments'));
    await tester.pumpAndSettle();

    expect(find.text('Data Structures'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);
    expect(find.text('VTOP'), findsWidgets);
    expect(find.text('NeoColab'), findsWidgets);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('New assignment'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('assignment-title-field')),
      'Submit design document',
    );
    await tester.enterText(
      find.byKey(const ValueKey('assignment-subject-field')),
      'Software Engineering',
    );
    final saveButton = find.byKey(const ValueKey('save-assignment-button'));
    await tester.scrollUntilVisible(
      saveButton,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Submit design document'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Software Engineering'), findsOneWidget);
    expect(find.text('Submit design document'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit design document'));
    await tester.pumpAndSettle();
    expect(find.text('Assignment details'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('assignment-title-field')),
      'Submit final design document',
    );
    await tester.scrollUntilVisible(
      saveButton,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Submit final design document'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Submit final design document'), findsOneWidget);
    expect(find.text('Submit design document'), findsNothing);
  });

  testWidgets('assignment synchronization errors show a snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Assignments'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('assignment-search-field'))),
    );
    container.read(assignmentErrorProvider.notifier).state =
        'Could not update the assignment. Please try again.';
    await tester.pump();

    expect(
      find.text('Could not update the assignment. Please try again.'),
      findsOneWidget,
    );
  });
}

Widget _testApp() {
  return ProviderScope(
    overrides: [
      taskProvider.overrideWith(
        (ref) => TaskNotifier(initialTasks: _sampleTasks()),
      ),
      assignmentProvider.overrideWith(
        (ref) => AssignmentNotifier(initialAssignments: _sampleAssignments()),
      ),
    ],
    child: const App(),
  );
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

List<TaskItem> _sampleTasks() {
  return [
    TaskItem(
      id: 'sample-task-1',
      title: 'Review today’s classes',
      completed: false,
      priority: TaskPriority.medium,
      category: 'College',
      dueAt: DateTime(2026, 8, 16, 18),
      createdAt: DateTime(2026, 8, 16, 8),
      updatedAt: DateTime(2026, 8, 16, 8),
    ),
    TaskItem(
      id: 'sample-task-2',
      title: 'Prepare lab notes',
      completed: false,
      priority: TaskPriority.high,
      category: 'Assignments',
      dueAt: DateTime(2026, 8, 17, 17),
      createdAt: DateTime(2026, 8, 16, 8),
      updatedAt: DateTime(2026, 8, 16, 8),
    ),
    TaskItem(
      id: 'sample-task-3',
      title: 'Buy stationery',
      completed: true,
      priority: TaskPriority.low,
      category: 'Personal',
      createdAt: DateTime(2026, 8, 15, 12),
      updatedAt: DateTime(2026, 8, 16, 9),
    ),
  ];
}
