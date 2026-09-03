import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/assignment_item.dart';
import '../models/task_item.dart';

abstract interface class NotificationScheduler {
  Future<void> scheduleTask(TaskItem task);
  Future<void> cancelTask(String taskId);
  Future<void> scheduleAssignment(AssignmentItem assignment);
  Future<void> cancelAssignment(String assignmentId);
  Future<void> reconcileTasks(List<TaskItem> tasks);
  Future<void> reconcileAssignments(List<AssignmentItem> assignments);
}

class LocalNotificationService implements NotificationScheduler {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    if (kIsWeb) return false;

    try {
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      );
      final initialized = await _plugin.initialize(settings: settings) ?? false;
      if (!initialized) return false;

      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
      _initialized = true;
      debugPrint('Local notifications initialized.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Local notifications could not be initialized: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<void> scheduleTask(TaskItem task) async {
    await cancelTask(task.id);
    final dueAt = task.dueAt;
    if (!_initialized || task.completed || dueAt == null) return;
    await _schedule(
      id: _notificationId('task:${task.id}'),
      title: 'Task due',
      body: task.title,
      scheduledAt: dueAt,
      payload: 'task:${task.id}',
    );
  }

  @override
  Future<void> cancelTask(String taskId) =>
      _cancel(_notificationId('task:$taskId'));

  @override
  Future<void> scheduleAssignment(AssignmentItem assignment) async {
    await cancelAssignment(assignment.id);
    if (!_initialized ||
        assignment.status != AssignmentStatus.pending ||
        assignment.reminderTimes.isEmpty) {
      return;
    }

    for (var index = 0; index < assignment.reminderTimes.length; index++) {
      final reminder = assignment.reminderTimes[index];
      if (reminder.isAfter(assignment.deadline)) continue;
      await _schedule(
        id: _notificationId('assignment:${assignment.id}:$index'),
        title: 'Assignment reminder',
        body: '${assignment.title} • ${assignment.subject}',
        scheduledAt: reminder,
        payload: 'assignment:${assignment.id}',
      );
    }
  }

  @override
  Future<void> cancelAssignment(String assignmentId) async {
    if (!_initialized) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload == 'assignment:$assignmentId') {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> reconcileTasks(List<TaskItem> tasks) async {
    await _cancelPayloadsWithPrefix('task:');
    for (final task in tasks) {
      await scheduleTask(task);
    }
  }

  @override
  Future<void> reconcileAssignments(List<AssignmentItem> assignments) async {
    await _cancelPayloadsWithPrefix('assignment:');
    for (final assignment in assignments) {
      await scheduleAssignment(assignment);
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    if (!_initialized || !scheduledAt.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'campus_reminders',
            'Campus reminders',
            channelDescription: 'Task and assignment deadline reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not schedule local notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      debugPrint('Could not cancel local notification: $error');
    }
  }

  Future<void> _cancelPayloadsWithPrefix(String prefix) async {
    if (!_initialized) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(prefix) ?? false) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  int _notificationId(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
