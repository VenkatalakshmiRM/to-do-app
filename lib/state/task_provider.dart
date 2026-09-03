import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_item.dart';
import '../services/local_database.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

final taskErrorProvider = StateProvider<String?>((ref) => null);

final taskProvider = StateNotifierProvider<TaskNotifier, List<TaskItem>>((ref) {
  final notifier = TaskNotifier(
    client: SupabaseService.isInitialized ? Supabase.instance.client : null,
    database: SupabaseService.isInitialized
        ? ref.watch(localDatabaseProvider)
        : null,
    notificationScheduler: LocalNotificationService.instance,
    errorCallback: (message) {
      ref.read(taskErrorProvider.notifier).state = message;
    },
  );
  unawaited(notifier.initialize());
  return notifier;
});

final taskFilterProvider = StateProvider<TaskFilter>(
  (ref) => const TaskFilter(),
);

final filteredTaskProvider = Provider<List<TaskItem>>((ref) {
  final tasks = ref.watch(taskProvider);
  final filter = ref.watch(taskFilterProvider);
  final query = filter.searchQuery.trim().toLowerCase();

  return List.unmodifiable(
    tasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          (task.description?.toLowerCase().contains(query) ?? false);
      final matchesPriority =
          filter.priority == null || task.priority == filter.priority;
      final matchesCategory =
          filter.category == null || task.category == filter.category;
      final matchesCompletion =
          filter.completed == null || task.completed == filter.completed;
      return matchesSearch &&
          matchesPriority &&
          matchesCategory &&
          matchesCompletion;
    }),
  );
});

class TaskFilter {
  const TaskFilter({
    this.searchQuery = '',
    this.priority,
    this.category,
    this.completed,
  });

  final String searchQuery;
  final TaskPriority? priority;
  final String? category;
  final bool? completed;

  TaskFilter copyWith({
    String? searchQuery,
    Object? priority = _filterUnset,
    Object? category = _filterUnset,
    Object? completed = _filterUnset,
  }) {
    return TaskFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      priority: identical(priority, _filterUnset)
          ? this.priority
          : priority as TaskPriority?,
      category: identical(category, _filterUnset)
          ? this.category
          : category as String?,
      completed: identical(completed, _filterUnset)
          ? this.completed
          : completed as bool?,
    );
  }
}

const _filterUnset = Object();

class TaskNotifier extends StateNotifier<List<TaskItem>> {
  TaskNotifier({
    this.client,
    this.database,
    List<TaskItem>? initialTasks,
    this.errorCallback,
    NotificationScheduler? notificationScheduler,
  }) : notificationScheduler =
           notificationScheduler ?? LocalNotificationService.instance,
       super(List.unmodifiable(initialTasks ?? const [])) {
    _authSubscription = client?.auth.onAuthStateChange.listen((authState) {
      if (authState.session == null) {
        unawaited(this.notificationScheduler.reconcileTasks(const []));
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
      final cachedTasks = await cache.readTasks(userId);
      if (!mounted) return;
      state = List.unmodifiable(cachedTasks);
      await notificationScheduler.reconcileTasks(state);
    } catch (error, stackTrace) {
      _reportFailure('load cached tasks', error, stackTrace);
    }

    unawaited(fetchTasks());
  }

  Future<void> fetchTasks() async {
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const [];
      return;
    }

    try {
      final rows = await supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      if (!mounted) return;
      state = List.unmodifiable(rows.map(_taskFromRow));
      await notificationScheduler.reconcileTasks(state);
      await _cacheState(userId);
    } catch (error, stackTrace) {
      _reportFailure('load tasks', error, stackTrace);
    }
  }

  Future<void> addTask(TaskItem task) async {
    state = List.unmodifiable([...state, task]);
    await notificationScheduler.scheduleTask(task);
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = List.unmodifiable(state.where((item) => item.id != task.id));
      await notificationScheduler.cancelTask(task.id);
      errorCallback?.call('Sign in before adding a task.');
      return;
    }
    await _cacheState(userId);

    try {
      final row = await supabase
          .from('tasks')
          .insert(_taskInsertRow(task, userId))
          .select()
          .single();
      if (!mounted) return;
      final savedTask = _taskFromRow(row);
      state = List.unmodifiable([
        for (final item in state)
          if (item.id == task.id) savedTask else item,
      ]);
      await _cacheState(userId);
    } catch (error, stackTrace) {
      if (mounted) {
        state = List.unmodifiable(state.where((item) => item.id != task.id));
        await notificationScheduler.cancelTask(task.id);
        await _cacheState(userId);
      }
      _reportFailure('add the task', error, stackTrace);
    }
  }

  Future<void> updateTask(TaskItem task) async {
    final index = state.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    final previous = state[index];

    state = List.unmodifiable([
      for (final item in state)
        if (item.id == task.id) task else item,
    ]);
    await notificationScheduler.scheduleTask(task);
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _restoreTask(previous);
      await notificationScheduler.scheduleTask(previous);
      errorCallback?.call('Sign in before updating a task.');
      return;
    }
    await _cacheState(userId);

    try {
      await supabase
          .from('tasks')
          .update(_taskUpdateRow(task))
          .eq('id', task.id)
          .eq('user_id', userId);
    } catch (error, stackTrace) {
      _restoreTask(previous);
      await notificationScheduler.scheduleTask(previous);
      await _cacheState(userId);
      _reportFailure('update the task', error, stackTrace);
    }
  }

  Future<void> toggleComplete(String id) async {
    if (!state.any((item) => item.id == id)) return;
    final task = state.singleWhere((item) => item.id == id);
    await updateTask(
      task.copyWith(completed: !task.completed, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteTask(String id) async {
    final index = state.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final removed = state[index];

    state = List.unmodifiable(state.where((item) => item.id != id));
    await notificationScheduler.cancelTask(id);
    final supabase = client;
    if (supabase == null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _restoreDeletedTask(removed, index);
      await notificationScheduler.scheduleTask(removed);
      errorCallback?.call('Sign in before deleting a task.');
      return;
    }
    await _cacheState(userId);

    try {
      await supabase.from('tasks').delete().eq('id', id).eq('user_id', userId);
    } catch (error, stackTrace) {
      _restoreDeletedTask(removed, index);
      await notificationScheduler.scheduleTask(removed);
      await _cacheState(userId);
      _reportFailure('delete the task', error, stackTrace);
    }
  }

  void _restoreTask(TaskItem task) {
    if (!mounted) return;
    state = List.unmodifiable([
      for (final item in state)
        if (item.id == task.id) task else item,
    ]);
  }

  void _restoreDeletedTask(TaskItem task, int index) {
    if (!mounted || state.any((item) => item.id == task.id)) return;
    final restored = [...state];
    restored.insert(index.clamp(0, restored.length), task);
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
      await cache.replaceTasks(userId, state);
    } catch (error, stackTrace) {
      _reportFailure('update the task cache', error, stackTrace);
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}

TaskItem _taskFromRow(Map<String, dynamic> row) {
  final dueAt = row['due_at'] as String?;
  return TaskItem(
    id: row['id'] as String,
    title: row['title'] as String,
    description: row['description'] as String?,
    completed: row['completed'] as bool,
    priority: TaskPriority.values.byName(row['priority'] as String),
    category: row['category'] as String?,
    dueAt: dueAt == null ? null : DateTime.parse(dueAt),
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
  );
}

Map<String, dynamic> _taskInsertRow(TaskItem task, String userId) {
  return {
    'user_id': userId,
    ..._taskUpdateRow(task),
    'created_at': task.createdAt.toIso8601String(),
  };
}

Map<String, dynamic> _taskUpdateRow(TaskItem task) {
  return {
    'title': task.title,
    'description': task.description,
    'completed': task.completed,
    'priority': task.priority.name,
    'category': task.category,
    'due_at': task.dueAt?.toIso8601String(),
    'updated_at': task.updatedAt.toIso8601String(),
  };
}
