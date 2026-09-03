import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/models/assignment_item.dart';
import 'package:student_task_hub/screens/assignments/assignment_list_screen.dart';
import 'package:student_task_hub/state/assignment_provider.dart';

void main() {
  testWidgets('renders grouped assignments and their badges', (tester) async {
    await tester.pumpWidget(_assignmentListApp());

    expect(find.text('Data Structures'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);
    expect(find.text('Lab report'), findsOneWidget);
    expect(find.text('Practice set'), findsOneWidget);
    final rows = find.byType(ListTile);
    expect(
      find.descendant(of: rows, matching: find.text('VTOP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rows, matching: find.text('NeoColab')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rows, matching: find.text('pending')),
      findsNWidgets(2),
    );
  });

  testWidgets('swipe deletes an assignment', (tester) async {
    await tester.pumpWidget(_assignmentListApp());

    await tester.drag(find.text('Lab report'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Lab report'), findsNothing);
    expect(find.text('Data Structures'), findsNothing);
    expect(find.text('Practice set'), findsOneWidget);
  });
}

Widget _assignmentListApp() {
  return ProviderScope(
    overrides: [
      assignmentProvider.overrideWith(
        (ref) => AssignmentNotifier(initialAssignments: _assignments()),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: AssignmentListScreen())),
  );
}

List<AssignmentItem> _assignments() {
  return [
    AssignmentItem(
      id: 'assignment-1',
      title: 'Lab report',
      subject: 'Data Structures',
      platform: AssignmentPlatform.vtop,
      deadline: DateTime(2026, 8, 20, 23, 59),
      status: AssignmentStatus.pending,
      priority: AssignmentPriority.high,
      reminderTimes: const [],
    ),
    AssignmentItem(
      id: 'assignment-2',
      title: 'Practice set',
      subject: 'Programming',
      platform: AssignmentPlatform.neocolab,
      deadline: DateTime(2026, 8, 22, 18),
      status: AssignmentStatus.pending,
      priority: AssignmentPriority.medium,
      reminderTimes: const [],
    ),
  ];
}
