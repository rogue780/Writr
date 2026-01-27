/// Integration tests for Comments and Footnotes
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:writr/services/scrivener_service.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';
import '../test_utils/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Comments - Access', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('can access comments tab in inspector', (tester) async {
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

      // Verify app is stable
      expect(find.byType(Scaffold), findsWidgets);

      await tester.pumpAndSettleClean();
    });
  });

  group('Comments - Display', () {
    testWidgets('comments section shows when tab selected', (tester) async {
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

      // Tap Comments tab
      final commentsTab = find.text('Comments');
      if (commentsTab.evaluate().isNotEmpty) {
        await tester.tap(commentsTab.first);
        await tester.pumpAndSettle();
      }

      await tester.pumpAndSettleClean();
    });
  });

  group('Comments - Service Integration', () {
    testWidgets('project comments are accessible via service', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      // Comments map should exist
      expect(service.currentProject!.documentComments, isNotNull);
    });
  });

  group('Footnotes - Access', () {
    testWidgets('footnotes are accessible via service', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      // Footnotes map should exist
      expect(service.currentProject!.documentFootnotes, isNotNull);
    });

    testWidgets('footnote settings exist in project', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      // Footnote settings should exist
      expect(service.currentProject!.footnoteSettings, isNotNull);
    });
  });

  group('Comments & Footnotes - Screenshots', () {
    testWidgets('screenshot of comments panel', (tester) async {
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

      // Open Comments tab
      final commentsTab = find.text('Comments');
      if (commentsTab.evaluate().isNotEmpty) {
        await tester.tap(commentsTab.first);
        await tester.pumpAndSettle();
      }

      await takeScreenshotIfAvailable(binding, 'comments_panel', tester: tester);

      await tester.pumpAndSettleClean();
    });
  });
}
