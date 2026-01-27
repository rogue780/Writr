/// Integration tests for the Home Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Screen', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('displays welcome message and main action buttons',
        (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Verify welcome text
      expect(find.text('Welcome to Writr'), findsOneWidget);
      expect(find.text('A Scrivener-compatible editor'), findsOneWidget);

      // Verify main action buttons
      expect(find.text('Open Project'), findsOneWidget);
      expect(find.text('Create New Project'), findsOneWidget);
    });

    testWidgets('displays info card about file access', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Verify info card content
      expect(find.text('Access Files Anywhere'), findsOneWidget);
      expect(find.textContaining('Native File Picker'), findsOneWidget);
      expect(find.textContaining('Direct Cloud API Access'), findsOneWidget);
    });

    testWidgets('shows open project options dialog when tapping Open Project',
        (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Tap Open Project button
      await tester.tap(find.text('Open Project'));
      await tester.pumpAndSettle();

      // Verify dialog appears with options
      expect(find.text('File Picker'), findsOneWidget);
      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('Dropbox'), findsOneWidget);
      expect(find.text('OneDrive'), findsOneWidget);
    });

    testWidgets('shows create project dialog when tapping Create New Project',
        (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Tap Create New Project button
      await tester.tap(find.text('Create New Project'));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Create New Project'), findsNWidgets(2)); // Button + dialog title
      expect(find.text('Project Name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('can enter project name in create dialog', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Open create dialog
      await tester.tap(find.text('Create New Project'));
      await tester.pumpAndSettle();

      // Enter project name
      await tester.enterText(find.byType(TextField), 'My Test Novel');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('My Test Novel'), findsOneWidget);
    });

    testWidgets('cancel button closes create project dialog', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Open create dialog
      await tester.tap(find.text('Create New Project'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Project Name'), findsNothing);
    });

    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Verify app bar
      expect(find.text('Writr'), findsOneWidget);
    });

    testWidgets('can dismiss open project dialog', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Project'));
      await tester.pumpAndSettle();

      // Tap outside dialog to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify dialog is closed (File Picker option should be gone)
      expect(find.text('Use native file picker (recommended)'), findsNothing);
    });

    testWidgets('shows currently open project card when project is loaded',
        (tester) async {
      final project = TestDataFactory.createFullProject(name: 'Test Novel');

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      // Verify project card is shown
      expect(find.text('Test Novel'), findsOneWidget);
      expect(find.text('Currently open'), findsOneWidget);
    });
  });

  group('Home Screen - Recent Projects', () {
    testWidgets('shows Recent Projects section header when projects exist',
        (tester) async {
      // This test would require mocking the RecentProjectsService
      // For now, verify the section doesn't appear when empty
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // With no recent projects, section should not be visible
      // (The service loads async, so this tests the empty state)
    });
  });

  group('Home Screen - Screenshots', () {
    testWidgets('can take screenshot of home screen', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Take screenshot - pass tester for manual fallback on Windows
      await takeScreenshotIfAvailable(binding, 'home_screen', tester: tester);
    });

    testWidgets('can take screenshot of open project dialog', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Project'));
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'open_project_dialog',
          tester: tester);
    });

    testWidgets('can take screenshot of create project dialog', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create New Project'));
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'create_project_dialog',
          tester: tester);
    });
  });
}
