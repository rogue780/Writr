/// Main entry point for all integration tests
///
/// Run with: flutter test integration_test/app_test.dart
/// Or for specific device: flutter test integration_test/app_test.dart -d <device_id>
///
/// For web: flutter test integration_test/app_test.dart -d chrome
/// For Windows: flutter test integration_test/app_test.dart -d windows
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_utils/test_helpers.dart';
import 'tests/home_screen_test.dart' as home_screen;
import 'tests/project_management_test.dart' as project_management;
import 'tests/binder_test.dart' as binder;
import 'tests/editor_test.dart' as editor;
import 'tests/inspector_test.dart' as inspector;
import 'tests/view_modes_test.dart' as view_modes;
import 'tests/search_test.dart' as search;
import 'tests/snapshots_test.dart' as snapshots;
import 'tests/comments_footnotes_test.dart' as comments_footnotes;
import 'tests/keywords_collections_test.dart' as keywords_collections;
import 'tests/statistics_targets_test.dart' as statistics_targets;
import 'tests/compile_test.dart' as compile;
import 'tests/theme_test.dart' as theme;
import 'tests/name_generator_test.dart' as name_generator;
import 'tests/composition_mode_test.dart' as composition_mode;
import 'tests/spell_check_test.dart' as spell_check;
import 'tests/templates_test.dart' as templates;
import 'tests/backup_manager_test.dart' as backup_manager;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Set up error filter to suppress SuperEditor animation disposal warnings
  // This is a known issue with super_editor scheduling callbacks during dispose
  setUpAll(() {
    setupSuperEditorErrorFilter();
  });

  tearDownAll(() {
    teardownSuperEditorErrorFilter();
  });

  // Core functionality
  home_screen.main();
  project_management.main();

  // Editor and navigation
  binder.main();
  editor.main();
  inspector.main();

  // View modes
  view_modes.main();
  composition_mode.main();

  // Features
  search.main();
  snapshots.main();
  comments_footnotes.main();
  keywords_collections.main();
  statistics_targets.main();
  compile.main();

  // Tools
  name_generator.main();
  templates.main();
  backup_manager.main();

  // Writing assistance
  spell_check.main();

  // Appearance
  theme.main();
}
