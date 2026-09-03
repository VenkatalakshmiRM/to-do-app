import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assignment_item.dart';
import '../../state/assignment_provider.dart';
import '../../widgets/comic_panel.dart';
import 'assignment_form_screen.dart';

class AssignmentListScreen extends ConsumerWidget {
  const AssignmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(assignmentErrorProvider, (previous, message) {
      if (message == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      ref.read(assignmentErrorProvider.notifier).state = null;
    });

    final assignments = ref.watch(filteredAssignmentProvider);
    final filter = ref.watch(assignmentFilterProvider);

    final grouped = <String, List<AssignmentItem>>{};
    for (final assignment in assignments) {
      grouped.putIfAbsent(assignment.subject, () => []).add(assignment);
    }
    final subjects = grouped.keys.toList()..sort();
    for (final assignments in grouped.values) {
      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));
    }

    void updateFilter(AssignmentFilter value) {
      ref.read(assignmentFilterProvider.notifier).state = value;
    }

    return Column(
      children: [
        _AssignmentFilters(filter: filter, onChanged: updateFilter),
        const SizedBox(height: 4),
        Expanded(
          child: assignments.isEmpty
              ? const Center(child: Text('No assignments match these filters'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return _SubjectGroup(
                      subject: subject,
                      assignments: grouped[subject]!,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AssignmentFilters extends StatelessWidget {
  const _AssignmentFilters({required this.filter, required this.onChanged});

  final AssignmentFilter filter;
  final ValueChanged<AssignmentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            key: const ValueKey('assignment-search-field'),
            decoration: const InputDecoration(
              hintText: 'Search assignments',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) =>
                onChanged(filter.copyWith(searchQuery: value)),
          ),
          const SizedBox(height: 8),
          _FilterChipRow(
            children: [
              ChoiceChip(
                label: const Text('All priorities'),
                selected: filter.priority == null,
                onSelected: (_) => onChanged(filter.copyWith(priority: null)),
              ),
              ...AssignmentPriority.values.map(
                (priority) => ChoiceChip(
                  label: Text(priority.name),
                  selected: filter.priority == priority,
                  onSelected: (_) =>
                      onChanged(filter.copyWith(priority: priority)),
                ),
              ),
            ],
          ),
          _FilterChipRow(
            children: [
              ChoiceChip(
                label: const Text('All platforms'),
                selected: filter.platform == null,
                onSelected: (_) => onChanged(filter.copyWith(platform: null)),
              ),
              ...AssignmentPlatform.values.map(
                (platform) => ChoiceChip(
                  label: Text(_platformLabel(platform)),
                  selected: filter.platform == platform,
                  onSelected: (_) =>
                      onChanged(filter.copyWith(platform: platform)),
                ),
              ),
            ],
          ),
          _FilterChipRow(
            children: [
              ChoiceChip(
                label: const Text('All statuses'),
                selected: filter.status == null,
                onSelected: (_) => onChanged(filter.copyWith(status: null)),
              ),
              ...AssignmentStatus.values.map(
                (status) => ChoiceChip(
                  label: Text(status.name),
                  selected: filter.status == status,
                  onSelected: (_) => onChanged(filter.copyWith(status: status)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.children});

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

class _SubjectGroup extends StatelessWidget {
  const _SubjectGroup({required this.subject, required this.assignments});

  final String subject;
  final List<AssignmentItem> assignments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
              subject,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...assignments.map(
            (assignment) => Dismissible(
              key: ValueKey(assignment.id),
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
                ProviderScope.containerOf(context)
                    .read(assignmentProvider.notifier)
                    .deleteAssignment(assignment.id);
              },
              child: ComicPanel(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AssignmentFormScreen(assignment: assignment),
                      ),
                    );
                  },
                  title: Text(assignment.title),
                  subtitle: Text('Due ${_formatDateTime(assignment.deadline)}'),
                  leading: _PlatformBadge(platform: assignment.platform),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusBadge(status: assignment.status),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.platform});

  final AssignmentPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _platformLabel(platform),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AssignmentStatus.pending => const Color(0xFFFFD200),
      AssignmentStatus.submitted => const Color(0xFF1E88E5),
      AssignmentStatus.overdue => const Color(0xFFE53935),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status == AssignmentStatus.pending
              ? const Color(0xFF111111)
              : Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _platformLabel(AssignmentPlatform platform) {
  return switch (platform) {
    AssignmentPlatform.manual => 'Manual',
    AssignmentPlatform.vtop => 'VTOP',
    AssignmentPlatform.neocolab => 'NeoColab',
    AssignmentPlatform.moodle => 'Moodle',
    AssignmentPlatform.vitol => 'VITOL',
    AssignmentPlatform.other => 'Other',
  };
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} at $hour:$minute';
}
