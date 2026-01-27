/// Integration tests for Project Management functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:writr/services/scrivener_service.dart';

import '../test_utils/screenshot_helper.dart';
import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Project Management', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('loaded project appears in ScrivenerService', (tester) async {
      final project = TestDataFactory.createFullProject(name: 'My Novel');

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      // Access the service and verify project is loaded
      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      expect(service.currentProject, isNotNull);
      expect(service.currentProject!.name, 'My Novel');
    });

    testWidgets('project with documents has correct structure', (tester) async {
      final project = TestDataFactory.createFullProject(
        name: 'Structured Novel',
        documentCount: 3,
        folderCount: 2,
      );

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      // Verify structure
      expect(service.currentProject!.binderItems.length, 3); // Manuscript, Research, Characters

      // Find Manuscript folder
      final manuscript = service.currentProject!.binderItems
          .firstWhere((item) => item.title == 'Manuscript');
      expect(manuscript.children.length, 2); // 2 chapters

      // Each chapter should have 3 scenes
      for (final chapter in manuscript.children) {
        expect(chapter.children.length, 3);
      }
    });

    testWidgets('project text contents are accessible', (tester) async {
      final project = TestDataFactory.createFullProject();

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      // Verify text contents exist
      expect(service.currentProject!.textContents.isNotEmpty, true);
    });

    testWidgets('project metadata is accessible', (tester) async {
      final project = TestDataFactory.createFullProject();

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      // Verify metadata exists
      expect(service.currentProject!.documentMetadata.isNotEmpty, true);
    });

    testWidgets('empty project has default folders', (tester) async {
      final project = TestDataFactory.createMinimalProject(name: 'Empty Project');

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      // Verify default folders exist
      final folderNames = service.currentProject!.binderItems
          .map((item) => item.title)
          .toList();

      expect(folderNames, contains('Manuscript'));
      expect(folderNames, contains('Research'));
      expect(folderNames, contains('Characters'));
      expect(folderNames, contains('Places'));
    });
  });

  group('Project Management - Web Projects', () {
    testWidgets('web project path starts with web_ prefix', (tester) async {
      // Create a simulated web project
      final project = TestDataFactory.createMinimalProject(
        name: 'Web Novel',
        path: 'web_Web_Novel',
      );

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final service = context.read<ScrivenerService>();

      expect(service.currentProject!.path.startsWith('web_'), true);
    });
  });

  group('Project Management - Screenshots', () {
    testWidgets('screenshot with loaded project', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      final project = TestDataFactory.createFullProject(name: 'Screenshot Test');

      await tester.pumpWidget(TestApp(initialProject: project));
      await tester.pumpAndSettle();

      // Wait for Consumer to rebuild with the project data
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify the project card is visible
      expect(find.text('Screenshot Test'), findsOneWidget);
      expect(find.text('Currently open'), findsOneWidget);

      // Scroll down to ensure the project card is visible in the screenshot
      // Drag from center of screen upward to scroll down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'home_with_project', tester: tester);
    });
  });
}
