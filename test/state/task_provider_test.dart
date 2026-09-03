import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/task_item.dart';
import 'package:student_task_hub/state/task_provider.dart';

void main() {
  group('TaskNotifier', () {
    test('adds, toggles, and deletes a task', () async {
      final notifier = TaskNotifier();
      addTearDown(notifier.dispose);
      final initialCount = notifier.state.length;
      final now = DateTime.utc(2026, 8, 16, 12);
      final task = TaskItem(
        id: 'new-task',
        title: 'Read chapter five',
        completed: false,
        priority: TaskPriority.medium,
        createdAt: now,
        updatedAt: now,
      );

      await notifier.addTask(task);

      expect(notifier.state, hasLength(initialCount + 1));
      expect(notifier.state.last, task);

      await notifier.toggleComplete(task.id);

      final toggled = notifier.state.singleWhere((item) => item.id == task.id);
      expect(toggled.completed, isTrue);
      expect(toggled.updatedAt, isNot(task.updatedAt));

      await notifier.deleteTask(task.id);

      expect(notifier.state, hasLength(initialCount));
      expect(notifier.state.any((item) => item.id == task.id), isFalse);
    });

    test('derived provider filters without changing the base list', () {
      final now = DateTime.utc(2026, 8, 16);
      final container = ProviderContainer(
        overrides: [
          taskProvider.overrideWith(
            (ref) => TaskNotifier(
              initialTasks: [
                TaskItem(
                  id: 'filtered-task',
                  title: 'Prepare lab notes',
                  completed: false,
                  priority: TaskPriority.high,
                  category: 'Assignments',
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final originalCount = container.read(taskProvider).length;

      container.read(taskFilterProvider.notifier).state = const TaskFilter(
        priority: TaskPriority.high,
        category: 'Assignments',
        completed: false,
      );

      final filtered = container.read(filteredTaskProvider);
      expect(filtered, hasLength(1));
      expect(filtered.single.title, 'Prepare lab notes');
      expect(container.read(taskProvider), hasLength(originalCount));
    });
  });
}
