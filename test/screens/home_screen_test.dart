import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/assignment_item.dart';
import 'package:student_task_hub/models/task_item.dart';
import 'package:student_task_hub/screens/home/home_screen.dart';
import 'package:student_task_hub/state/assignment_provider.dart';
import 'package:student_task_hub/state/task_provider.dart';

void main() {
  testWidgets('shows today, upcoming, and completion progress', (tester) async {
    final now = DateTime.now();
    final tasks = [
      TaskItem(
        id: 'today',
        title: 'Today dashboard task',
        completed: false,
        priority: TaskPriority.high,
        dueAt: DateTime(now.year, now.month, now.day, 18),
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'completed',
        title: 'Previously completed task',
        completed: true,
        priority: TaskPriority.low,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    AssignmentItem assignment(String id, String title, DateTime deadline) {
      return AssignmentItem(
        id: id,
        title: title,
        subject: 'Testing',
        platform: AssignmentPlatform.manual,
        deadline: deadline,
        status: AssignmentStatus.pending,
        priority: AssignmentPriority.medium,
        reminderTimes: const [],
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProvider.overrideWith((ref) => TaskNotifier(initialTasks: tasks)),
          assignmentProvider.overrideWith(
            (ref) => AssignmentNotifier(
              initialAssignments: [
                assignment(
                  'soon',
                  'Upcoming dashboard assignment',
                  now.add(const Duration(days: 2)),
                ),
                assignment(
                  'later',
                  'Later dashboard assignment',
                  now.add(const Duration(days: 8)),
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    expect(find.text('Today dashboard task'), findsOneWidget);
    expect(find.text('Upcoming dashboard assignment'), findsOneWidget);
    expect(find.text('Later dashboard assignment'), findsNothing);
    expect(find.text('1 of 2 tasks completed'), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byKey(const ValueKey('task-completion-progress')),
          )
          .value,
      0.5,
    );
  });
}
