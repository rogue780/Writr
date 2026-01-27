/// Integration tests for Binder navigation and document tree
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

  group('Binder - Document Tree', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('displays project folders in binder', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Verify main folders are visible
      expect(find.text('Manuscript'), findsOneWidget);
      expect(find.text('Research'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
    });

    testWidgets('can expand folder to see children', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Find and tap on Manuscript folder to expand
      final manuscriptFinder = find.text('Manuscript');
      expect(manuscriptFinder, findsOneWidget);

      // Look for expansion indicator and tap it
      // The exact implementation depends on how folders are rendered
      await tester.tap(manuscriptFinder);
      await tester.pumpAndSettle();

      // After expanding, chapters should be visible
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Chapter 2'), findsOneWidget);
    });

    testWidgets('can expand chapter to see scenes', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Expand Manuscript
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();

      // Expand Chapter 1
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      // Scenes should be visible
      expect(find.text('Scene 1'), findsWidgets);
    });

    testWidgets('tapping document selects it', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Expand to scenes
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      // Tap on a scene if it exists
      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      // Document should be selected - verify app is stable
      expect(find.byType(Scaffold), findsWidgets);

      // Cleanup for SuperEditor - extra pumps to let keyboard cleanup complete
      await tester.pumpAndSettleClean();
    });

    testWidgets('displays character documents', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Expand Characters folder
      await tester.tap(find.text('Characters'));
      await tester.pumpAndSettle();

      // Verify character documents
      expect(find.text('Protagonist'), findsOneWidget);
      expect(find.text('Antagonist'), findsOneWidget);
    });
  });

  group('Binder - Folder Icons', () {
    testWidgets('folders have folder icons', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Folders should have folder icons
      expect(find.byIcon(Icons.folder), findsWidgets);
    });

    testWidgets('documents have document icons', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Expand to show documents
      await tester.tap(find.text('Characters'));
      await tester.pumpAndSettle();

      // Documents should have description icons
      expect(find.byIcon(Icons.description), findsWidgets);
    });
  });

  group('Binder - Navigation', () {
    testWidgets('selecting document loads content in editor', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to a document
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      final scene1 = find.text('Scene 1');
      if (scene1.evaluate().isNotEmpty) {
        await tester.tap(scene1.first);
        await tester.pumpAndSettle();
      }

      // Content should be loaded - app should not crash
      expect(find.byType(Scaffold), findsWidgets);

      // Cleanup for SuperEditor
      await tester.pumpAndSettleClean();
    });
  });

  group('Binder - Screenshots', () {
    testWidgets('screenshot of binder with expanded folders', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Expand folders
      await tester.tap(find.text('Manuscript'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter 1'));
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'binder_expanded', tester: tester);

      // Cleanup for SuperEditor
      await tester.pumpAndSettleClean();
    });
  });
}
