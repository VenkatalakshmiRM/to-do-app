import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/assignment_item.dart';
import '../../models/task_item.dart';
import '../../state/assignment_provider.dart';
import '../../state/task_provider.dart';
import '../../widgets/comic_panel.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents(
      ref.watch(taskProvider),
      ref.watch(assignmentProvider),
    );
    final selectedEvents = events[_dayKey(_selectedDay)] ?? const [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ComicPanel(
            padding: const EdgeInsets.all(8),
            child: TableCalendar<_CalendarEntry>(
              key: const ValueKey('due-calendar'),
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: (day) => events[_dayKey(day)] ?? const [],
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              headerStyle: const HeaderStyle(formatButtonVisible: false),
              calendarStyle: CalendarStyle(
                defaultDecoration: _dayDecoration(Colors.white),
                weekendDecoration: _dayDecoration(const Color(0xFFF2F2F0)),
                outsideDecoration: _dayDecoration(const Color(0xFFDDDDDD)),
                todayDecoration: _dayDecoration(const Color(0xFFFFD200)),
                selectedDecoration: _dayDecoration(const Color(0xFFEC1E79)),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
                todayTextStyle: const TextStyle(
                  color: Color(0xFF111111),
                  fontWeight: FontWeight.w900,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFF111111), width: 1),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _selectedDateLabel(_selectedDay),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: selectedEvents.isEmpty
              ? const Center(child: Text('Nothing due on this day'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: selectedEvents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];
                    return ComicPanel(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            border: Border.all(
                              color: const Color(0xFF111111),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(event.icon, color: Colors.white),
                        ),
                        title: Text(event.title),
                        subtitle: Text(
                          '${event.type} • ${_formatTime(event.dueAt)}',
                        ),
                        trailing: Text(event.stateLabel),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Map<DateTime, List<_CalendarEntry>> _buildEvents(
    List<TaskItem> tasks,
    List<AssignmentItem> assignments,
  ) {
    final events = <DateTime, List<_CalendarEntry>>{};

    for (final task in tasks) {
      final dueAt = task.dueAt;
      if (dueAt == null) continue;
      events
          .putIfAbsent(_dayKey(dueAt), () => [])
          .add(
            _CalendarEntry(
              title: task.title,
              type: 'Task',
              dueAt: dueAt,
              stateLabel: task.completed ? 'Completed' : 'Pending',
              icon: Icons.check_circle_outline,
            ),
          );
    }

    for (final assignment in assignments) {
      events
          .putIfAbsent(_dayKey(assignment.deadline), () => [])
          .add(
            _CalendarEntry(
              title: assignment.title,
              type: 'Assignment',
              dueAt: assignment.deadline,
              stateLabel: _statusLabel(assignment.status),
              icon: Icons.assignment_outlined,
            ),
          );
    }

    for (final dayEvents in events.values) {
      dayEvents.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    }
    return events;
  }

  DateTime _dayKey(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }

  String _selectedDateLabel(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _statusLabel(AssignmentStatus status) {
    return switch (status) {
      AssignmentStatus.pending => 'Pending',
      AssignmentStatus.submitted => 'Submitted',
      AssignmentStatus.overdue => 'Overdue',
    };
  }

  BoxDecoration _dayDecoration(Color color) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: const Color(0xFF111111), width: 1.5),
      borderRadius: BorderRadius.circular(4),
    );
  }
}

class _CalendarEntry {
  const _CalendarEntry({
    required this.title,
    required this.type,
    required this.dueAt,
    required this.stateLabel,
    required this.icon,
  });

  final String title;
  final String type;
  final DateTime dueAt;
  final String stateLabel;
  final IconData icon;
}
