import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assignment_item.dart';
import '../models/task_item.dart';

part 'local_database.g.dart';

class LocalTasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get priority => text()();
  TextColumn get category => text().nullable()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get subject => text()();
  TextColumn get description => text().nullable()();
  TextColumn get platform => text()();
  DateTimeColumn get deadline => dateTime()();
  TextColumn get status => text()();
  TextColumn get priority => text()();
  TextColumn get externalUrl => text().nullable()();
  TextColumn get sourceIdentifier => text().nullable()();
  TextColumn get reminderTimes => text().withDefault(const Constant('[]'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalTasks, LocalAssignments])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(driftDatabase(name: 'campus_todo'));

  LocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<TaskItem>> readTasks(String userId) async {
    final rows =
        await (select(localTasks)
              ..where((row) => row.userId.equals(userId))
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return rows
        .map(
          (row) => TaskItem(
            id: row.id,
            title: row.title,
            description: row.description,
            completed: row.completed,
            priority: TaskPriority.values.byName(row.priority),
            category: row.category,
            dueAt: row.dueAt?.toUtc(),
            createdAt: row.createdAt.toUtc(),
            updatedAt: row.updatedAt.toUtc(),
          ),
        )
        .toList();
  }

  Future<void> replaceTasks(String userId, List<TaskItem> tasks) async {
    await transaction(() async {
      await (delete(
        localTasks,
      )..where((row) => row.userId.equals(userId))).go();
      await batch((batch) {
        batch.insertAll(
          localTasks,
          tasks.map((task) => _taskCompanion(task, userId)).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<List<AssignmentItem>> readAssignments(String userId) async {
    final rows =
        await (select(localAssignments)
              ..where((row) => row.userId.equals(userId))
              ..orderBy([(row) => OrderingTerm.asc(row.deadline)]))
            .get();
    return rows
        .map(
          (row) => AssignmentItem(
            id: row.id,
            title: row.title,
            subject: row.subject,
            description: row.description,
            platform: AssignmentPlatform.values.byName(row.platform),
            deadline: row.deadline.toUtc(),
            status: AssignmentStatus.values.byName(row.status),
            priority: AssignmentPriority.values.byName(row.priority),
            externalUrl: row.externalUrl,
            sourceIdentifier: row.sourceIdentifier,
            reminderTimes: (jsonDecode(row.reminderTimes) as List<dynamic>)
                .map((value) => DateTime.parse(value as String))
                .toList(),
            lastSyncedAt: row.lastSyncedAt?.toUtc(),
          ),
        )
        .toList();
  }

  Future<void> replaceAssignments(
    String userId,
    List<AssignmentItem> assignments,
  ) async {
    await transaction(() async {
      await (delete(
        localAssignments,
      )..where((row) => row.userId.equals(userId))).go();
      await batch((batch) {
        batch.insertAll(
          localAssignments,
          assignments
              .map((assignment) => _assignmentCompanion(assignment, userId))
              .toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  LocalTasksCompanion _taskCompanion(TaskItem task, String userId) {
    return LocalTasksCompanion.insert(
      id: task.id,
      userId: userId,
      title: task.title,
      description: Value(task.description),
      completed: Value(task.completed),
      priority: task.priority.name,
      category: Value(task.category),
      dueAt: Value(task.dueAt),
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }

  LocalAssignmentsCompanion _assignmentCompanion(
    AssignmentItem assignment,
    String userId,
  ) {
    return LocalAssignmentsCompanion.insert(
      id: assignment.id,
      userId: userId,
      title: assignment.title,
      subject: assignment.subject,
      description: Value(assignment.description),
      platform: assignment.platform.name,
      deadline: assignment.deadline,
      status: assignment.status.name,
      priority: assignment.priority.name,
      externalUrl: Value(assignment.externalUrl),
      sourceIdentifier: Value(assignment.sourceIdentifier),
      reminderTimes: Value(
        jsonEncode(
          assignment.reminderTimes
              .map((value) => value.toIso8601String())
              .toList(),
        ),
      ),
      lastSyncedAt: Value(assignment.lastSyncedAt),
    );
  }
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final database = LocalDatabase();
  ref.onDispose(database.close);
  return database;
});
