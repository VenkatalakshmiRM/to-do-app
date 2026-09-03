import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/task_item.dart';
import 'package:student_task_hub/screens/tasks/task_list_screen.dart';
import 'package:student_task_hub/state/task_provider.dart';

void main() {
  testWidgets('renders tasks and toggles completion', (tester) async {
    await tester.pumpWidget(_taskListApp());

    expect(find.text('Read chapter'), findsOneWidget);
    expect(find.text('Submit notes'), findsOneWidget);
    expect(find.text('Due 18/08/2026 at 17:30'), findsOneWidget);

    final firstCheckbox = find.byType(Checkbox).first;
    expect(tester.widget<Checkbox>(firstCheckbox).value, isFalse);

    await tester.tap(firstCheckbox);
    await tester.pump();

    expect(tester.widget<Checkbox>(firstCheckbox).value, isTrue);
  });

  testWidgets('swipe deletes a task', (tester) async {
    await tester.pumpWidget(_taskListApp());

    await tester.drag(find.text('Read chapter'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Read chapter'), findsNothing);
    expect(find.text('Submit notes'), findsOneWidget);
  });
}

Widget _taskListApp() {
  return ProviderScope(
    overrides: [
      taskProvider.overrideWith((ref) => TaskNotifier(initialTasks: _tasks())),
    ],
    child: const MaterialApp(home: Scaffold(body: TaskListScreen())),
  );
}

List<TaskItem> _tasks() {
  final createdAt = DateTime(2026, 8, 16, 8);
  return [
    TaskItem(
      id: 'task-1',
      title: 'Read chapter',
      completed: false,
      priority: TaskPriority.medium,
      category: 'Study',
      dueAt: DateTime(2026, 8, 18, 17, 30),
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
    TaskItem(
      id: 'task-2',
      title: 'Submit notes',
      completed: false,
      priority: TaskPriority.high,
      category: 'College',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  ];
}
