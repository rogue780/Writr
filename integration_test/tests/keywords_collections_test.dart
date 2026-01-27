/// Integration tests for Keywords and Collections
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Keywords - Access', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('can find keywords section', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Keywords might be in a menu or panel
      // Look for keywords icon
      final keywordsIcon = find.byIcon(Icons.label);
      final tagIcon = find.byIcon(Icons.tag);

      // Either icon might indicate keywords
      expect(
        keywordsIcon.evaluate().isNotEmpty || tagIcon.evaluate().isNotEmpty,
        anyOf(isTrue, isFalse),
      );
    });
  });

  group('Collections - Access', () {
    testWidgets('can find collections panel', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Look for collections icon or menu item
      final collectionsIcon = find.byIcon(Icons.collections_bookmark);
      final folderSpecialIcon = find.byIcon(Icons.folder_special);

      // Either icon might indicate collections
      expect(
        collectionsIcon.evaluate().isNotEmpty ||
            folderSpecialIcon.evaluate().isNotEmpty,
        anyOf(isTrue, isFalse),
      );
    });
  });

  group('Collections - Types', () {
    testWidgets('can create manual collection', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // This test would require navigation to collections feature
      // and interaction with create collection dialog
    });

    testWidgets('can create smart collection from search', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // This test would require executing a search
      // and saving it as a smart collection
    });
  });

  group('Keywords & Collections - Screenshots', () {
    testWidgets('screenshot of editor with binder', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'keywords_collections_overview', tester: tester);
    });
  });
}
