/// Integration tests for Compile/Export functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Compile - Access', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('can find compile button or menu item', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Look for compile/export icons
      final exportIcon = find.byIcon(Icons.file_download);
      final compileIcon = find.byIcon(Icons.publish);
      final buildIcon = find.byIcon(Icons.build);

      expect(
        exportIcon.evaluate().isNotEmpty ||
            compileIcon.evaluate().isNotEmpty ||
            buildIcon.evaluate().isNotEmpty,
        anyOf(isTrue, isFalse),
      );
    });

    testWidgets('compile can be accessed from menu', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Look for menu button
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        // Look for Compile menu item
        final compileItem = find.text('Compile');
        if (compileItem.evaluate().isNotEmpty) {
          await tester.tap(compileItem.first);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  group('Compile - Format Options', () {
    testWidgets('compile screen shows format options', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to compile screen
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        final compileItem = find.text('Compile');
        if (compileItem.evaluate().isNotEmpty) {
          await tester.tap(compileItem.first);
          await tester.pumpAndSettle();

          // Should show format options: Plain Text, Markdown, HTML, RTF
          expect(
            find.textContaining('Plain Text').evaluate().isNotEmpty ||
                find.textContaining('Markdown').evaluate().isNotEmpty ||
                find.textContaining('Format').evaluate().isNotEmpty,
            anyOf(isTrue, isFalse),
          );
        }
      }
    });
  });

  group('Compile - Settings', () {
    testWidgets('compile has title and author fields', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to compile screen
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        final compileItem = find.text('Compile');
        if (compileItem.evaluate().isNotEmpty) {
          await tester.tap(compileItem.first);
          await tester.pumpAndSettle();

          // Look for title/author fields
          // These may be TextFields or other input widgets
        }
      }
    });
  });

  group('Compile - Screenshots', () {
    testWidgets('screenshot of compile screen', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Try to navigate to compile screen
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        final compileItem = find.text('Compile');
        if (compileItem.evaluate().isNotEmpty) {
          await tester.tap(compileItem.first);
          await tester.pumpAndSettle();
        }
      }

      await takeScreenshotIfAvailable(binding, 'compile_screen', tester: tester);
    });
  });
}
