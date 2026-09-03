import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assignment_item.dart';
import '../../models/task_item.dart';
import '../../state/assignment_provider.dart';
import '../../state/task_provider.dart';
import '../../widgets/comic_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final assignments = ref.watch(assignmentProvider);
    final now = DateTime.now();
    final todayTasks =
        tasks
            .where((task) => task.dueAt != null && _isSameDay(task.dueAt!, now))
            .toList()
          ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final upcomingLimit = now.add(const Duration(days: 7));
    final upcomingAssignments =
        assignments
            .where(
              (assignment) =>
                  !assignment.deadline.isBefore(now) &&
                  !assignment.deadline.isAfter(upcomingLimit),
            )
            .toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final completedCount = tasks.where((task) => task.completed).length;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(
          'Your day, at a glance',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        const _IllustrationBanner(),
        const SizedBox(height: 16),
        _ProgressCard(
          completedCount: completedCount,
          totalCount: tasks.length,
          progress: progress,
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: "Today's tasks", count: todayTasks.length),
        const SizedBox(height: 8),
        if (todayTasks.isEmpty)
          const _EmptyCard(message: 'No tasks due today')
        else
          ...todayTasks.map((task) => _TaskCard(task: task)),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Upcoming assignments',
          count: upcomingAssignments.length,
        ),
        const SizedBox(height: 4),
        Text(
          'Due in the next 7 days',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (upcomingAssignments.isEmpty)
          const _EmptyCard(message: 'No assignments due soon')
        else
          ...upcomingAssignments.map(
            (assignment) => _AssignmentCard(assignment: assignment),
          ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completedCount,
    required this.totalCount,
    required this.progress,
  });

  final int completedCount;
  final int totalCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  key: const ValueKey('task-completion-progress'),
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('$completedCount of $totalCount tasks completed'),
                const SizedBox(height: 4),
                Text(
                  'Keep the momentum going!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Badge(label: Text('$count')),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _SoftIcon(
          icon: task.completed ? Icons.check_rounded : Icons.schedule_rounded,
          accent: task.completed,
        ),
        title: Text(task.title),
        subtitle: Text(
          'Due ${_formatTime(task.dueAt!)} • ${task.priority.name}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});

  final AssignmentItem assignment;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const _SoftIcon(icon: Icons.assignment_outlined, accent: true),
        title: Text(assignment.title),
        subtitle: Text(
          '${assignment.subject} • ${_formatDateTime(assignment.deadline)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.accent});

  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    );
  }
}

class _IllustrationBanner extends StatelessWidget {
  const _IllustrationBanner();

  @override
  Widget build(BuildContext context) {
    // TODO: replace with illustration asset.
    return ComicPanel(
      child: SizedBox(
        height: 150,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E88E5), Color(0xFFFFD200)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 24,
                top: 22,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD7A8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Positioned(
                left: -20,
                right: -20,
                bottom: -42,
                child: Icon(
                  Icons.landscape_rounded,
                  size: 190,
                  color: Color(0xFF385A70),
                ),
              ),
              Positioned(
                left: 20,
                top: 20,
                child: Text(
                  'Make today count',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      padding: const EdgeInsets.all(20),
      child: Center(child: Text(message)),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year} at ${_formatTime(value)}';
}
