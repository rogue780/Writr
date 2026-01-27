/// Helper for taking screenshots that gracefully handles when running under flutter test
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart' show screenshotBoundaryKey;

/// Takes a screenshot if running under flutter drive, otherwise skips gracefully.
/// Returns true if screenshot was taken, false if skipped.
Future<bool> takeScreenshotIfAvailable(
  IntegrationTestWidgetsFlutterBinding binding,
  String name, {
  WidgetTester? tester,
  String outputDir = 'test_output/screenshots',
}) async {
  try {
    await binding.takeScreenshot(name);
    debugPrint('Screenshot saved via binding: $name');
    return true;
  } catch (e) {
    // binding.takeScreenshot failed - try manual method if tester provided
    if (tester != null) {
      debugPrint('Binding screenshot failed, trying manual method for: $name');
      return await takeScreenshotManual(tester, name, outputDir: outputDir);
    }
    debugPrint('Screenshot skipped (not running under flutter drive): $name');
    return false;
  }
}

/// Takes a screenshot using Flutter's rendering system.
/// This works on all platforms including Windows desktop.
/// Call this with the tester from your test.
/// Uses the screenshotBoundaryKey from test_app.dart to find the RepaintBoundary.
Future<bool> takeScreenshotManual(
  WidgetTester tester,
  String name, {
  String outputDir = 'test_output/screenshots',
}) async {
  try {
    // Use the global key to find the RenderRepaintBoundary
    final boundary = screenshotBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary == null) {
      debugPrint('Screenshot skipped (no RenderRepaintBoundary found): $name');
      return false;
    }

    // Capture the image
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      debugPrint('Screenshot skipped (could not encode image): $name');
      return false;
    }

    // Ensure output directory exists
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Save the image
    final file = File('$outputDir/$name.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    debugPrint('Screenshot saved: ${file.path}');
    return true;
  } catch (e) {
    debugPrint('Screenshot failed: $name - $e');
    return false;
  }
}
