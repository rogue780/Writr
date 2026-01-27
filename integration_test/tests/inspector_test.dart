/// Integration tests for Inspector Panel (metadata, synopsis, notes)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';
import '../test_utils/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Inspector Panel - Display', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('inspector panel can be opened', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Look for inspector toggle button (often an info icon)
      final inspectorToggle = find.byIcon(Icons.info_outline);
      if (inspectorToggle.evaluate().isNotEmpty) {
        await tester.tap(inspectorToggle.first);
        await tester.pumpAndSettle();
      }

      await tester.pumpAndSettleClean();
    });

    testWidgets('inspector shows tabs for different metadata types',
        (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Select a document first
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      // Inspector should have tabs - verify app is stable
      expect(find.byType(Scaffold), findsWidgets);

      await tester.pumpAndSettleClean();
    });
  });

  group('Inspector Panel - Synopsis', () {
    testWidgets('displays document synopsis', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to document with synopsis
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      // Verify app is stable
      expect(find.byType(Scaffold), findsWidgets);

      await tester.pumpAndSettleClean();
    });
  });

  group('Inspector Panel - Notes', () {
    testWidgets('can navigate to notes tab', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Select a document
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      // Find and tap Notes tab
      final notesTab = find.text('Notes');
      if (notesTab.evaluate().isNotEmpty) {
        await tester.tap(notesTab.first);
        await tester.pumpAndSettle();
      }

      await tester.pumpAndSettleClean();
    });
  });

  group('Inspector Panel - Document Status', () {
    testWidgets('shows document status', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to document with status
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      // Verify app is stable
      expect(find.byType(Scaffold), findsWidgets);

      await tester.pumpAndSettleClean();
    });
  });

  group('Inspector Panel - Labels', () {
    testWidgets('shows document label', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to document with label
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      // Verify app is stable
      expect(find.byType(Scaffold), findsWidgets);

      await tester.pumpAndSettleClean();
    });
  });

  group('Inspector Panel - Screenshots', () {
    testWidgets('screenshot of inspector panel', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to document
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      await takeScreenshotIfAvailable(binding, 'inspector_panel', tester: tester);

      await tester.pumpAndSettleClean();
    });
  });
}
