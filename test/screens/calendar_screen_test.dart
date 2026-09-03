import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/assignment_item.dart';
import 'package:student_task_hub/models/task_item.dart';
import 'package:student_task_hub/screens/calendar/calendar_screen.dart';
import 'package:student_task_hub/state/assignment_provider.dart';
import 'package:student_task_hub/state/task_provider.dart';

void main() {
  testWidgets('shows tasks and assignments due on the selected day', (
    tester,
  ) async {
    final now = DateTime.now();
    final task = TaskItem(
      id: 'today-task',
      title: 'Today task',
      completed: false,
      priority: TaskPriority.medium,
      dueAt: DateTime(now.year, now.month, now.day, 10),
      createdAt: now,
      updatedAt: now,
    );
    final assignment = AssignmentItem(
      id: 'today-assignment',
      title: 'Today assignment',
      subject: 'Testing',
      platform: AssignmentPlatform.manual,
      deadline: DateTime(now.year, now.month, now.day, 14),
      status: AssignmentStatus.pending,
      priority: AssignmentPriority.high,
      reminderTimes: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProvider.overrideWith(
            (ref) => TaskNotifier(initialTasks: [task]),
          ),
          assignmentProvider.overrideWith(
            (ref) => AssignmentNotifier(initialAssignments: [assignment]),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CalendarScreen())),
      ),
    );

    expect(find.byKey(const ValueKey('due-calendar')), findsOneWidget);
    expect(find.text('Today task'), findsOneWidget);
    expect(find.text('Today assignment'), findsOneWidget);
    expect(find.text('Task • 10:00'), findsOneWidget);
    expect(find.text('Assignment • 14:00'), findsOneWidget);
  });
}
