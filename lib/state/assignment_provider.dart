import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assignment_item.dart';
import '../services/local_database.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

final assignmentErrorProvider = StateProvider<String?>((ref) => null);

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, List<AssignmentItem>>((ref) {
      final notifier = AssignmentNotifier(
        client: SupabaseService.isInitialized ? Supabase.instance.client : null,
        database: SupabaseService.isInitialized
            ? ref.watch(localDatabaseProvider)
            : null,
        notificationScheduler: LocalNotificationService.instance,
        errorCallback: (message) {
          ref.read(assignmentErrorProvider.notifier).state = message;
        },
      );
      unawaited(notifier.initialize());
      return notifier;
    });

final assignmentFilterProvider = StateProvider<AssignmentFilter>(
  (ref) => const AssignmentFilter(),
);

final filteredAssignmentProvider = Provider<List<AssignmentItem>>((ref) {
  final assignments = ref.watch(assignmentProvider);
  final filter = ref.watch(assignmentFilterProvider);
  final query = filter.searchQuery.trim().toLowerCase();

  return List.unmodifiable(
    assignments.where((assignment) {
      final matchesSearch =
          query.isEmpty ||
          assignment.title.toLowerCase().contains(query) ||
          assignment.subject.toLowerCase().contains(query) ||
          (assignment.description?.toLowerCase().contains(query) ?? false);
      final matchesPriority =
          filter.priority == null || assignment.priority == filter.priority;
      final matchesPlatform =
          filter.platform == null || assignment.platform == filter.platform;
      final matchesStatus =
          filter.status == null || assignment.status == filter.status;
      return matchesSearch &&
          matchesPriority &&
          matchesPlatform &&
          matchesStatus;
    }),
  );
});

class AssignmentFilter {
  const AssignmentFilter({
    this.searchQuery = '',
    this.priority,
    this.platform,
    this.status,
  });

  final String searchQuery;
  final AssignmentPriority? priority;
  final AssignmentPlatform? platform;
  final AssignmentStatus? status;

  AssignmentFilter copyWith({
    String? searchQuery,
    Object? priority = _filterUnset,
    Object? platform = _filterUnset,
    Object? status = _filterUnset,
  }) {
    return AssignmentFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      priority: identical(priority, _filterUnset)
          ? this.priority
          : priority as AssignmentPriority?,
      platform: identical(platform, _filterUnset)
          ? this.platform
          : platform as AssignmentPlatform?,
      status: identical(status, _filterUnset)
          ? this.status
          : status as AssignmentStatus?,
    );
  }
}

const _filterUnset = Object();

class AssignmentNotifier extends StateNotifier<List<AssignmentItem>> {
  AssignmentNotifier({
    this.client,
    this.database,
    List<AssignmentItem>? initialAssignments,
    this.errorCallback,
    NotificationScheduler? notificationScheduler,
  }) : notificationScheduler =
           notificationScheduler ?? LocalNotificationService.instance,
       super(List.unmodifiable(initialAssignments ?? const [])) {
    _authSubscription = client?.auth.onAuthStateChange.listen((authState) {
      if (authState.session == null) {
        unawaited(this.notificationScheduler.reconcileAssignments(const []));
        state = const [];
      } else {
        unawaited(initialize());
      }
    });
  }

  final SupabaseClient? client;
  final LocalDatabase? database;
  final ValueChanged<String>? errorCallback;
  final NotificationScheduler notificationScheduler;
  StreamSubscription<AuthState>? _authSubscription;

  Future<void> initialize() async {
    final userId = client?.auth.currentUser?.id;
    final cache = database;
    if (userId == null || cache == null) return;

    try {
      final cachedAssignments = await cache.readAssignments(userId);
      if (!mounted) return;
      state = List.unmodifiable(cachedAssignments);
      await notificationScheduler.reconcileAssignments(state);
    } catch (error, stackTrace) {
      _reportFailure('load cached assignments', error, stackTrace);
    }

    unawaited(fetchAssignments());
  }

  Future<void> fetchAssignments() async {
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const [];
      return;
    }

    try {
      final rows = await supabase
          .from('assignments')
          .select()
          .eq('user_id', userId)
          .order('deadline');
      if (!mounted) return;
      state = List.unmodifiable(rows.map(_assignmentFromRow));
      await notificationScheduler.reconcileAssignments(state);
      await _cacheState(userId);
    } catch (error, stackTrace) {
      _reportFailure('load assignments', error, stackTrace);
    }
  }

  Future<void> addAssignment(AssignmentItem assignment) async {
    state = List.unmodifiable([...state, assignment]);
    await notificationScheduler.scheduleAssignment(assignment);
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = List.unmodifiable(
        state.where((item) => item.id != assignment.id),
      );
      await notificationScheduler.cancelAssignment(assignment.id);
      errorCallback?.call('Sign in before adding an assignment.');
      return;
    }
    await _cacheState(userId);

    try {
      final row = await supabase
          .from('assignments')
          .insert(_assignmentInsertRow(assignment, userId))
          .select()
          .single();
      if (!mounted) return;
      final savedAssignment = _assignmentFromRow(row);
      state = List.unmodifiable([
        for (final item in state)
          if (item.id == assignment.id) savedAssignment else item,
      ]);
      await _cacheState(userId);
    } catch (error, stackTrace) {
      if (mounted) {
        state = List.unmodifiable(
          state.where((item) => item.id != assignment.id),
        );
        await notificationScheduler.cancelAssignment(assignment.id);
        await _cacheState(userId);
      }
      _reportFailure('add the assignment', error, stackTrace);
    }
  }

  Future<void> updateAssignment(AssignmentItem assignment) async {
    final index = state.indexWhere((item) => item.id == assignment.id);
    if (index == -1) return;
    final previous = state[index];

    state = List.unmodifiable([
      for (final item in state)
        if (item.id == assignment.id) assignment else item,
    ]);
    await notificationScheduler.scheduleAssignment(assignment);
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _restoreAssignment(previous);
      await notificationScheduler.scheduleAssignment(previous);
      errorCallback?.call('Sign in before updating an assignment.');
      return;
    }
    await _cacheState(userId);

    try {
      await supabase
          .from('assignments')
          .update(_assignmentUpdateRow(assignment))
          .eq('id', assignment.id)
          .eq('user_id', userId);
    } catch (error, stackTrace) {
      _restoreAssignment(previous);
      await notificationScheduler.scheduleAssignment(previous);
      await _cacheState(userId);
      _reportFailure('update the assignment', error, stackTrace);
    }
  }

  Future<void> deleteAssignment(String id) async {
    final index = state.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final removed = state[index];

    state = List.unmodifiable(state.where((item) => item.id != id));
    await notificationScheduler.cancelAssignment(id);
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _restoreDeletedAssignment(removed, index);
      await notificationScheduler.scheduleAssignment(removed);
      errorCallback?.call('Sign in before deleting an assignment.');
      return;
    }
    await _cacheState(userId);

    try {
      await supabase
          .from('assignments')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (error, stackTrace) {
      _restoreDeletedAssignment(removed, index);
      await notificationScheduler.scheduleAssignment(removed);
      await _cacheState(userId);
      _reportFailure('delete the assignment', error, stackTrace);
    }
  }

  void _restoreAssignment(AssignmentItem assignment) {
    if (!mounted) return;
    state = List.unmodifiable([
      for (final item in state)
        if (item.id == assignment.id) assignment else item,
    ]);
  }

  void _restoreDeletedAssignment(AssignmentItem assignment, int index) {
    if (!mounted || state.any((item) => item.id == assignment.id)) return;
    final restored = [...state];
    restored.insert(index.clamp(0, restored.length), assignment);
    state = List.unmodifiable(restored);
  }

  void _reportFailure(String action, Object error, StackTrace stackTrace) {
    debugPrint('Failed to $action: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (mounted) errorCallback?.call('Could not $action. Please try again.');
  }

  Future<void> _cacheState(String userId) async {
    final cache = database;
    if (cache == null) return;
    try {
      await cache.replaceAssignments(userId, state);
    } catch (error, stackTrace) {
      _reportFailure('update the assignment cache', error, stackTrace);
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}

AssignmentItem _assignmentFromRow(Map<String, dynamic> row) {
  final lastSyncedAt = row['last_synced_at'] as String?;
  final reminderTimes = row['reminder_times'] as List<dynamic>? ?? const [];
  return AssignmentItem(
    id: row['id'] as String,
    title: row['title'] as String,
    subject: row['subject'] as String,
    description: row['description'] as String?,
    platform: AssignmentPlatform.values.byName(row['platform'] as String),
    deadline: DateTime.parse(row['deadline'] as String),
    status: AssignmentStatus.values.byName(row['status'] as String),
    priority: AssignmentPriority.values.byName(row['priority'] as String),
    externalUrl: row['external_url'] as String?,
    sourceIdentifier: row['source_identifier'] as String?,
    reminderTimes: reminderTimes
        .map((value) => DateTime.parse(value as String))
        .toList(),
    lastSyncedAt: lastSyncedAt == null ? null : DateTime.parse(lastSyncedAt),
  );
}

Map<String, dynamic> _assignmentInsertRow(
  AssignmentItem assignment,
  String userId,
) {
  return {'user_id': userId, ..._assignmentUpdateRow(assignment)};
}

Map<String, dynamic> _assignmentUpdateRow(AssignmentItem assignment) {
  return {
    'title': assignment.title,
    'subject': assignment.subject,
    'description': assignment.description,
    'platform': assignment.platform.name,
    'deadline': assignment.deadline.toIso8601String(),
    'status': assignment.status.name,
    'priority': assignment.priority.name,
    'external_url': assignment.externalUrl,
    'source_identifier': assignment.sourceIdentifier,
    'reminder_times': assignment.reminderTimes
        .map((value) => value.toIso8601String())
        .toList(),
    'last_synced_at': assignment.lastSyncedAt?.toIso8601String(),
  };
}
