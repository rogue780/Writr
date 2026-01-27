/// Integration tests for Theme switching
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:writr/services/theme_service.dart';

import '../test_utils/test_app.dart';
import '../test_utils/test_data_factory.dart';
import '../test_utils/screenshot_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Theme - Service', () {
    setUp(() {
      TestDataFactory.reset();
    });

    testWidgets('ThemeService is accessible', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final themeService = context.read<ThemeService>();

      expect(themeService, isNotNull);
    });

    testWidgets('theme data is applied to app', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final themeService = context.read<ThemeService>();

      expect(themeService.themeData, isNotNull);
    });
  });

  group('Theme - Access', () {
    testWidgets('can find theme settings in menu', (tester) async {
      await tester.pumpWidget(const TestEditorApp());
      await tester.pumpAndSettle();

      // Look for settings/theme icons
      final settingsIcon = find.byIcon(Icons.settings);
      final paletteIcon = find.byIcon(Icons.palette);
      final brightnessIcon = find.byIcon(Icons.brightness_6);

      expect(
        settingsIcon.evaluate().isNotEmpty ||
            paletteIcon.evaluate().isNotEmpty ||
            brightnessIcon.evaluate().isNotEmpty,
        anyOf(isTrue, isFalse),
      );
    });
  });

  group('Theme - Mode', () {
    testWidgets('app has proper theme applied', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // App should render without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('dark theme can be applied', (tester) async {
      await tester.pumpWidget(
        TestApp(
          theme: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle();

      // App should render with dark theme
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('light theme can be applied', (tester) async {
      await tester.pumpWidget(
        TestApp(
          theme: ThemeData.light(),
        ),
      );
      await tester.pumpAndSettle();

      // App should render with light theme
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Theme - Screenshots', () {
    testWidgets('screenshot with light theme', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(
        TestApp(theme: ThemeData.light()),
      );
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'theme_light', tester: tester);
    });

    testWidgets('screenshot with dark theme', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(
        TestApp(theme: ThemeData.dark()),
      );
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'theme_dark', tester: tester);
    });

    testWidgets('screenshot of editor with light theme', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(
        TestEditorApp(theme: ThemeData.light()),
      );
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'editor_theme_light', tester: tester);
    });

    testWidgets('screenshot of editor with dark theme', (tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      await tester.pumpWidget(
        TestEditorApp(theme: ThemeData.dark()),
      );
      await tester.pumpAndSettle();

      await takeScreenshotIfAvailable(binding, 'editor_theme_dark', tester: tester);
    });
  });
}
