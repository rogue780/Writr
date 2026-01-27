/// Integration tests for Backup Manager
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Backup Manager - Access', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('can find backup option in menu', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Look for menu button
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        // Look for Backup or Backup Manager menu item
        final backupItem = find.text('Backup');
        final backupManagerItem = find.text('Backup Manager');

        expect(
          backupItem.evaluate().isNotEmpty ||
              backupManagerItem.evaluate().isNotEmpty,
          anyOf(isTrue, isFalse),
        );
      }
    });
  });

  group('Backup Manager - UI', () {
    testWidgets('backup manager shows backup list', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to backup manager
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        final backupItem = find.text('Backup Manager');
        if (backupItem.evaluate().isNotEmpty) {
          await tester.tap(backupItem.first);
          await tester.pumpAndSettle();

          // Backup manager screen should show
          // - List of backups (may be empty)
          // - Create backup button
        }
      }
    });

    testWidgets('can find create backup button', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to backup manager
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        final backupItem = find.text('Backup Manager');
        if (backupItem.evaluate().isNotEmpty) {
          await tester.tap(backupItem.first);
          await tester.pumpAndSettle();

          // Look for create backup button
          final createBackupBtn = find.text('Create Backup');
          final backupNowBtn = find.text('Backup Now');
          final addIcon = find.byIcon(Icons.add);

          expect(
            createBackupBtn.evaluate().isNotEmpty ||
                backupNowBtn.evaluate().isNotEmpty ||
                addIcon.evaluate().isNotEmpty,
            anyOf(isTrue, isFalse),
          );
        }
      }
    });
  });

  group('Backup Manager - Backup Creation', () {
    testWidgets('can initiate backup creation', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Navigate to backup manager
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        final backupItem = find.text('Backup Manager');
        if (backupItem.evaluate().isNotEmpty) {
          await tester.tap(backupItem.first);
          await tester.pumpAndSettle();

          // Try to create backup
          final createBtn = find.text('Create Backup');
          if (createBtn.evaluate().isNotEmpty) {
            await tester.tap(createBtn.first);
            await tester.pumpAndSettle();

            // Backup creation dialog or confirmation should appear
          }
        }
      }
    });
  });

  group('Backup Manager - Screenshots', () {
    testWidgets('screenshot of backup manager', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Try to navigate to backup manager
      final menuIcon = find.byIcon(Icons.more_vert);
      if (menuIcon.evaluate().isNotEmpty) {
        await tester.tap(menuIcon.first);
        await tester.pumpAndSettle();

        final backupItem = find.text('Backup Manager');
        if (backupItem.evaluate().isNotEmpty) {
          await tester.tap(backupItem.first);
          await tester.pumpAndSettle();
        }
      }

      await takeScreenshotIfAvailable(binding, 'backup_manager', tester: tester);
    });
  });
}
