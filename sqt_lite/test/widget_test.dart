// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sqlite_drift_demo/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts
    expect(find.text('SQLite vs Drift Demo'), findsOneWidget);

    // Verify navigation tabs exist
    expect(find.text('SQLite'), findsOneWidget);
    expect(find.text('Drift'), findsOneWidget);
    expect(find.text('Performance'), findsOneWidget);
  });
}