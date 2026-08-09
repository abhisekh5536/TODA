import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_app/main.dart';

Future<void> addTask(WidgetTester tester, String title) async {
  await tester.tap(find.byIcon(Icons.add_rounded).last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, title);
  await tester.tap(find.text('Add task').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state and adds a new todo', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('No tasks yet'), findsOneWidget);

    await addTask(tester, 'Write tests');

    expect(find.text('No tasks yet'), findsNothing);
    expect(find.text('Write tests'), findsOneWidget);
  });

  testWidgets('toggles a todo as completed', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    await addTask(tester, 'Buy groceries');

    final tile = find.ancestor(
      of: find.text('Buy groceries'),
      matching: find.byType(Dismissible),
    );

    await tester.tap(find.descendant(
      of: tile,
      matching: find.byIcon(Icons.check_rounded),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
  });
}