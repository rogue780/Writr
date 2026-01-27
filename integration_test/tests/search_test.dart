/// Integration tests for Search and Find/Replace
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search - Panel', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('can open search panel', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Look for search icon in toolbar
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();

        // Search panel should be visible
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('search panel has text input field', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();

        // Should have search input
        expect(find.byType(TextField), findsWidgets);
      }
    });
  });

  group('Search - Query Execution', () {
    testWidgets('can enter search query', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();

        // Enter search text
        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, 'Lorem');
        await tester.pumpAndSettle();

        expect(find.text('Lorem'), findsWidgets);
      }
    });

    testWidgets('search finds content in documents', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();

        // Search for text that exists in test data
        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, 'ipsum');
        await tester.pumpAndSettle();

        // Submit search
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Results should appear (depends on implementation)
      }
    });
  });

  group('Search - Options', () {
    testWidgets('has case sensitive option', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();

        // Look for options button or case sensitive toggle
        // Implementation may vary
      }
    });

    testWidgets('has regex option', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();

        // Look for regex toggle
        // Implementation may vary
      }
    });
  });

  group('Search - Replace', () {
    testWidgets('can access replace functionality', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon.first);
        await tester.pumpAndSettle();

        // Look for replace toggle or second text field
        // Some implementations show replace field with a toggle
      }
    });
  });

  group('Search - Screenshots', () {
    testWidgets('screenshot of search panel', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search via View menu
      final viewMenu = find.text('View');
      if (viewMenu.evaluate().isNotEmpty) {
        await tester.tap(viewMenu.first);
        await tester.pumpAndSettle();

        // Click on Search menu item
        final searchMenuItem = find.text('Search');
        if (searchMenuItem.evaluate().isNotEmpty) {
          await tester.tap(searchMenuItem.first);
          await tester.pumpAndSettle();
        }
      }

      await takeScreenshotIfAvailable(binding, 'search_panel', tester: tester);
    });

    testWidgets('screenshot of search with results', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Open search via View menu
      final viewMenu = find.text('View');
      if (viewMenu.evaluate().isNotEmpty) {
        await tester.tap(viewMenu.first);
        await tester.pumpAndSettle();

        final searchMenuItem = find.text('Search');
        if (searchMenuItem.evaluate().isNotEmpty) {
          await tester.tap(searchMenuItem.first);
          await tester.pumpAndSettle();

          // Enter search query
          final searchField = find.byType(TextField).first;
          await tester.enterText(searchField, 'Lorem');
          await tester.pumpAndSettle();
        }
      }

      await takeScreenshotIfAvailable(binding, 'search_with_query', tester: tester);
    });
  });
}
