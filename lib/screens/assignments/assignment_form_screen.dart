import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/assignment_item.dart';
import '../../state/assignment_provider.dart';

class AssignmentFormScreen extends ConsumerStatefulWidget {
  const AssignmentFormScreen({super.key, this.assignment});

  final AssignmentItem? assignment;

  @override
  ConsumerState<AssignmentFormScreen> createState() =>
      _AssignmentFormScreenState();
}

class _AssignmentFormScreenState extends ConsumerState<AssignmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _externalUrlController;
  late final TextEditingController _sourceIdentifierController;
  late AssignmentPlatform _platform;
  late AssignmentStatus _status;
  late AssignmentPriority _priority;
  late DateTime _deadline;
  late List<DateTime> _reminderTimes;
  DateTime? _lastSyncedAt;

  bool get _isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    _titleController = TextEditingController(text: assignment?.title ?? '');
    _subjectController = TextEditingController(text: assignment?.subject ?? '');
    _descriptionController = TextEditingController(
      text: assignment?.description ?? '',
    );
    _externalUrlController = TextEditingController(
      text: assignment?.externalUrl ?? '',
    );
    _sourceIdentifierController = TextEditingController(
      text: assignment?.sourceIdentifier ?? '',
    );
    _platform = assignment?.platform ?? AssignmentPlatform.manual;
    _status = assignment?.status ?? AssignmentStatus.pending;
    _priority = assignment?.priority ?? AssignmentPriority.medium;
    _deadline =
        assignment?.deadline ?? DateTime.now().add(const Duration(days: 1));
    _reminderTimes = List.of(assignment?.reminderTimes ?? const []);
    _lastSyncedAt = assignment?.lastSyncedAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _externalUrlController.dispose();
    _sourceIdentifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Assignment details' : 'New assignment'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete assignment',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const ValueKey('assignment-title-field'),
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: _requiredText,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('assignment-subject-field'),
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: _requiredText,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssignmentPlatform>(
              initialValue: _platform,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: AssignmentPlatform.values
                  .map(
                    (platform) => DropdownMenuItem(
                      value: platform,
                      child: Text(_platformLabel(platform)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _platform = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssignmentStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: AssignmentStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssignmentPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: AssignmentPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 8),
            _DateTimeTile(
              title: 'Deadline',
              value: _deadline,
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _externalUrlController,
              decoration: const InputDecoration(labelText: 'External URL'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceIdentifierController,
              decoration: const InputDecoration(labelText: 'Source identifier'),
            ),
            const SizedBox(height: 20),
            Text(
              'Reminder times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_reminderTimes.isEmpty) const Text('No reminders'),
            ..._reminderTimes.indexed.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_formatDateTime(entry.$2)),
                trailing: IconButton(
                  tooltip: 'Remove reminder',
                  onPressed: () {
                    setState(() => _reminderTimes.removeAt(entry.$1));
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _addReminder,
              icon: const Icon(Icons.alarm_add_outlined),
              label: const Text('Add reminder'),
            ),
            const SizedBox(height: 12),
            _DateTimeTile(
              title: 'Last synced at (optional)',
              value: _lastSyncedAt,
              onTap: _pickLastSyncedAt,
              onClear: _lastSyncedAt == null
                  ? null
                  : () => setState(() => _lastSyncedAt = null),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('save-assignment-button'),
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Add assignment'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  Future<void> _pickDeadline() async {
    final value = await _pickDateTime(_deadline);
    if (value != null) setState(() => _deadline = value);
  }

  Future<void> _addReminder() async {
    final value = await _pickDateTime(
      _deadline.subtract(const Duration(days: 1)),
    );
    if (value != null) {
      setState(() {
        _reminderTimes = [..._reminderTimes, value]..sort();
      });
    }
  }

  Future<void> _pickLastSyncedAt() async {
    final value = await _pickDateTime(_lastSyncedAt ?? DateTime.now());
    if (value != null) setState(() => _lastSyncedAt = value);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.assignment;
    final now = DateTime.now();
    final assignment = AssignmentItem(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim(),
      description: _nullableText(_descriptionController.text),
      platform: _platform,
      deadline: _deadline,
      status: _status,
      priority: _priority,
      externalUrl: _nullableText(_externalUrlController.text),
      sourceIdentifier: _nullableText(_sourceIdentifierController.text),
      reminderTimes: _reminderTimes,
      lastSyncedAt: _lastSyncedAt,
    );
    final notifier = ref.read(assignmentProvider.notifier);
    if (_isEditing) {
      notifier.updateAssignment(assignment);
    } else {
      notifier.addAssignment(assignment);
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    ref
        .read(assignmentProvider.notifier)
        .deleteAssignment(widget.assignment!.id);
    Navigator.of(context).pop();
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.title,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String title;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(title),
      subtitle: Text(value == null ? 'Not set' : _formatDateTime(value!)),
      trailing: onClear == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
      onTap: onTap,
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
