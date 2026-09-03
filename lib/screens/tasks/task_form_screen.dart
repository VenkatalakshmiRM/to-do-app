import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task_item.dart';
import '../../state/task_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskItem? task;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late TaskPriority _priority;
  DateTime? _dueAt;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _categoryController = TextEditingController(text: task?.category ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _dueAt = task?.dueAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit task' : 'New task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const ValueKey('task-title-field'),
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.name),
                    ),
                  )
                  .toList(),
              onChanged: (priority) {
                if (priority != null) setState(() => _priority = priority);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Due date and time'),
              subtitle: Text(_formatDueDate(_dueAt)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dueAt != null)
                    IconButton(
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() => _dueAt = null),
                      icon: const Icon(Icons.clear),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _pickDueDateTime,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('save-task-button'),
              onPressed: _save,
              child: Text(_isEditing ? 'Update task' : 'Add task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final initial = _dueAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = widget.task;
    final task = TaskItem(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _nullableText(_descriptionController.text),
      completed: existing?.completed ?? false,
      priority: _priority,
      category: _nullableText(_categoryController.text),
      dueAt: _dueAt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(taskProvider.notifier);
    if (_isEditing) {
      notifier.updateTask(task);
    } else {
      notifier.addTask(task);
    }
    Navigator.of(context).pop();
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDueDate(DateTime? dueAt) {
    if (dueAt == null) return 'Not set';
    final day = dueAt.day.toString().padLeft(2, '0');
    final month = dueAt.month.toString().padLeft(2, '0');
    final hour = dueAt.hour.toString().padLeft(2, '0');
    final minute = dueAt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dueAt.year} at $hour:$minute';
  }
}
