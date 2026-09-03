import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/assignment_item.dart';
import 'package:student_task_hub/models/task_item.dart';
import 'package:student_task_hub/services/local_database.dart';

void main() {
  test('round-trips user tasks and assignments through Drift', () async {
    final database = LocalDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    const userId = 'user-1';
    final task = TaskItem(
      id: 'task-1',
      title: 'Cached task',
      description: 'Available before the network refresh',
      completed: true,
      priority: TaskPriority.high,
      category: 'College',
      dueAt: DateTime.utc(2026, 8, 20, 18),
      createdAt: DateTime.utc(2026, 8, 16, 8),
      updatedAt: DateTime.utc(2026, 8, 16, 9),
    );
    final assignment = AssignmentItem(
      id: 'assignment-1',
      title: 'Cached assignment',
      subject: 'Databases',
      description: 'Drift round-trip',
      platform: AssignmentPlatform.moodle,
      deadline: DateTime.utc(2026, 8, 24, 17),
      status: AssignmentStatus.pending,
      priority: AssignmentPriority.medium,
      externalUrl: 'https://example.edu/assignment/1',
      sourceIdentifier: 'source-1',
      reminderTimes: [
        DateTime.utc(2026, 8, 23, 17),
        DateTime.utc(2026, 8, 24, 9),
      ],
      lastSyncedAt: DateTime.utc(2026, 8, 16, 10),
    );

    await database.replaceTasks(userId, [task]);
    await database.replaceAssignments(userId, [assignment]);

    final cachedTask = (await database.readTasks(userId)).single;
    final cachedAssignment = (await database.readAssignments(userId)).single;
    expect(cachedTask.toJson(), task.toJson());
    expect(cachedAssignment.toJson(), assignment.toJson());
    expect(await database.readTasks('another-user'), isEmpty);
    expect(await database.readAssignments('another-user'), isEmpty);
  });
}
