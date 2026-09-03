import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task_item.dart';
import '../../state/task_provider.dart';
import '../../widgets/comic_panel.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(taskErrorProvider, (previous, message) {
      if (message == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      ref.read(taskErrorProvider.notifier).state = null;
    });

    final tasks = ref.watch(filteredTaskProvider);
    final allTasks = ref.watch(taskProvider);
    final filter = ref.watch(taskFilterProvider);
    final categories =
        allTasks
            .map((task) => task.category)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();

    void updateFilter(TaskFilter value) {
      ref.read(taskFilterProvider.notifier).state = value;
    }

    return Column(
      children: [
        _TaskFilters(
          filter: filter,
          categories: categories,
          onChanged: updateFilter,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: tasks.isEmpty
              ? const Center(child: Text('No tasks match these filters'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Dismissible(
                      key: ValueKey(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(taskProvider.notifier).deleteTask(task.id);
                      },
                      child: ComicPanel(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TaskFormScreen(task: task),
                              ),
                            );
                          },
                          leading: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD200),
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Checkbox(
                              value: task.completed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              onChanged: (_) {
                                ref
                                    .read(taskProvider.notifier)
                                    .toggleComplete(task.id);
                              },
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: task.completed
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: Text(_formatDueDate(task.dueAt)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PriorityIndicator(priority: task.priority),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDueDate(DateTime? dueAt) {
    if (dueAt == null) return 'No due date';

    final day = dueAt.day.toString().padLeft(2, '0');
    final month = dueAt.month.toString().padLeft(2, '0');
    final hour = dueAt.hour.toString().padLeft(2, '0');
    final minute = dueAt.minute.toString().padLeft(2, '0');
    return 'Due $day/$month/${dueAt.year} at $hour:$minute';
  }
}

class _TaskFilters extends StatelessWidget {
  const _TaskFilters({
    required this.filter,
    required this.categories,
    required this.onChanged,
  });

  final TaskFilter filter;
  final List<String> categories;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            key: const ValueKey('task-search-field'),
            decoration: const InputDecoration(
              hintText: 'Search tasks',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) =>
                onChanged(filter.copyWith(searchQuery: value)),
          ),
          const SizedBox(height: 8),
          _ChipRow(
            children: [
              ChoiceChip(
                label: const Text('All priorities'),
                selected: filter.priority == null,
                onSelected: (_) => onChanged(filter.copyWith(priority: null)),
              ),
              ...TaskPriority.values.map(
                (priority) => ChoiceChip(
                  label: Text(priority.name),
                  selected: filter.priority == priority,
                  onSelected: (_) =>
                      onChanged(filter.copyWith(priority: priority)),
                ),
              ),
            ],
          ),
          _ChipRow(
            children: [
              ChoiceChip(
                label: const Text('All categories'),
                selected: filter.category == null,
                onSelected: (_) => onChanged(filter.copyWith(category: null)),
              ),
              ...categories.map(
                (category) => ChoiceChip(
                  label: Text(category),
                  selected: filter.category == category,
                  onSelected: (_) =>
                      onChanged(filter.copyWith(category: category)),
                ),
              ),
            ],
          ),
          _ChipRow(
            children: [
              ChoiceChip(
                label: const Text('All statuses'),
                selected: filter.completed == null,
                onSelected: (_) => onChanged(filter.copyWith(completed: null)),
              ),
              ChoiceChip(
                label: const Text('Pending'),
                selected: filter.completed == false,
                onSelected: (_) => onChanged(filter.copyWith(completed: false)),
              ),
              ChoiceChip(
                label: const Text('Completed'),
                selected: filter.completed == true,
                onSelected: (_) => onChanged(filter.copyWith(completed: true)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  const _PriorityIndicator({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.low => const Color(0xFFE0E0E0),
      TaskPriority.medium => const Color(0xFFFFD200),
      TaskPriority.high => const Color(0xFFEC1E79),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        priority.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF111111),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
