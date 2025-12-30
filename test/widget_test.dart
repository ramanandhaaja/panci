// Basic widget tests for the Panci shared canvas application.
//
// These tests verify the core UI screens and navigation flow.

import 'package:flutter_test/flutter_test.dart';

import 'package:panci/main.dart';

void main() {
  testWidgets('App starts with home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PanciApp());

    // Verify that the home screen is displayed
    expect(find.text('Shared Canvas'), findsWidgets);
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Join or Create Canvas'), findsOneWidget);
  });

  testWidgets('Navigation to join screen works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PanciApp());

    // Tap the "Join or Create Canvas" button
    await tester.tap(find.text('Join or Create Canvas'));
    await tester.pumpAndSettle();

    // Verify that the join screen is displayed
    expect(find.text('Join or Create Canvas'), findsWidgets);
    expect(find.text('Canvas ID'), findsOneWidget);
    expect(find.text('Join Canvas'), findsOneWidget);
    expect(find.text('Create New Canvas'), findsOneWidget);
  });
}
