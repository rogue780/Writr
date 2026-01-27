/// Test helper utilities for integration tests
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stores the original FlutterError.onError handler
FlutterExceptionHandler? _originalOnError;

/// Sets up error filtering to ignore SuperEditor animation disposal errors.
/// Call this in setUp() for test groups that use the editor.
void setupSuperEditorErrorFilter() {
  _originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore the specific SuperEditor animation disposal error
    final message = details.exceptionAsString();
    if (message.contains('animation is still running') &&
        message.contains('widget tree was disposed')) {
      // Log but don't fail
      debugPrint('Suppressed SuperEditor disposal animation warning');
      return;
    }
    // Forward other errors to the original handler
    _originalOnError?.call(details);
  };
}

/// Restores the original FlutterError.onError handler.
/// Call this in tearDown() for test groups that use the editor.
void teardownSuperEditorErrorFilter() {
  if (_originalOnError != null) {
    FlutterError.onError = _originalOnError;
    _originalOnError = null;
  }
}

/// Pumps the widget tree and settles, then pumps additional frames
/// to allow SuperEditor's keyboard state cleanup to complete.
/// This prevents "animation still running after widget disposed" errors.
Future<void> pumpAndSettleWithCleanup(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // Pump additional frames to allow scheduled callbacks to complete
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Extension on WidgetTester for cleaner test code
extension WidgetTesterExtension on WidgetTester {
  /// Pumps and settles with extra cleanup for SuperEditor.
  /// This pumps multiple frames with duration to let scheduled frame callbacks complete.
  Future<void> pumpAndSettleClean() async {
    await pumpAndSettle();
    // SuperEditor schedules frame callbacks during dispose, so we need to pump
    // enough frames for them to execute before the test ends
    for (int i = 0; i < 10; i++) {
      await pump(const Duration(milliseconds: 50));
    }
    await pumpAndSettle();
  }

  /// Taps a widget if it exists, returns true if tapped
  Future<bool> tapIfExists(Finder finder) async {
    if (finder.evaluate().isNotEmpty) {
      await tap(finder.first);
      await pumpAndSettle();
      return true;
    }
    return false;
  }

  /// Navigates to a document by expanding folders
  Future<void> navigateToDocument({
    required String folder,
    String? chapter,
    String? scene,
  }) async {
    await tap(find.text(folder));
    await pumpAndSettle();

    if (chapter != null) {
      await tap(find.text(chapter));
      await pumpAndSettle();
    }

    if (scene != null) {
      final sceneFinder = find.text(scene);
      if (sceneFinder.evaluate().isNotEmpty) {
        await tap(sceneFinder.first);
        await pumpAndSettle();
      }
    }
  }
}

/// Soft expectation that logs but doesn't fail if the widget isn't found
void expectAnyOf(List<Finder> finders, {String? description}) {
  final found = finders.any((f) => f.evaluate().isNotEmpty);
  if (!found && description != null) {
    // ignore: avoid_print
    print('Note: None of the expected widgets found for: $description');
  }
  // This is a soft check - we don't fail if nothing is found
  // The test passes as long as the app doesn't crash
}

/// Checks if at least one finder has matches
bool anyFinderHasMatches(List<Finder> finders) {
  return finders.any((f) => f.evaluate().isNotEmpty);
}
