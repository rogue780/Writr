/// Test app wrapper for integration tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:writr/models/scrivener_project.dart';
import 'package:writr/screens/home_screen.dart';
import 'package:writr/screens/project_editor_screen.dart';
import 'package:writr/services/scrivener_service.dart';
import 'package:writr/services/writr_service.dart';
import 'package:writr/services/storage_access_service.dart';
import 'package:writr/services/cloud_storage_service.dart';
import 'package:writr/services/recent_projects_service.dart';
import 'package:writr/services/cloud_sync_service.dart';
import 'package:writr/services/web_storage_service.dart';
import 'package:writr/services/preferences_service.dart';
import 'package:writr/services/theme_service.dart';

import 'test_data_factory.dart';

/// Global key for accessing the RepaintBoundary for screenshots
final screenshotBoundaryKey = GlobalKey();

/// Creates a test app with all necessary providers
class TestApp extends StatelessWidget {
  final Widget? home;
  final ScrivenerProject? initialProject;
  final ThemeData? theme;

  const TestApp({
    super.key,
    this.home,
    this.initialProject,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final service = ScrivenerService();
            if (initialProject != null) {
              service.setProject(initialProject!);
            }
            return service;
          },
        ),
        ChangeNotifierProvider(create: (_) => WritrService()),
        ChangeNotifierProvider(create: (_) => StorageAccessService()),
        ChangeNotifierProvider(create: (_) => CloudStorageService()),
        ChangeNotifierProvider(create: (_) => RecentProjectsService()),
        ChangeNotifierProvider(create: (_) => WebStorageService()),
        ChangeNotifierProvider(
          create: (_) {
            final prefs = PreferencesService();
            prefs.initialize();
            return prefs;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final themeService = ThemeService();
            themeService.initialize();
            return themeService;
          },
        ),
        ChangeNotifierProxyProvider<CloudStorageService, CloudSyncService>(
          create: (context) =>
              CloudSyncService(context.read<CloudStorageService>()),
          update: (context, cloudStorage, previous) =>
              previous ?? CloudSyncService(cloudStorage),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return RepaintBoundary(
            key: screenshotBoundaryKey,
            child: MaterialApp(
              title: 'Writr Test',
              theme: theme ?? themeService.themeData,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
              ],
              home: home ?? const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}

/// Creates a test app already loaded with a project in the editor
class TestEditorApp extends StatelessWidget {
  final ScrivenerProject? project;
  final ThemeData? theme;

  const TestEditorApp({
    super.key,
    this.project,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final testProject = project ?? TestDataFactory.createFullProject();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final service = ScrivenerService();
            service.setProject(testProject);
            return service;
          },
        ),
        ChangeNotifierProvider(create: (_) => WritrService()),
        ChangeNotifierProvider(create: (_) => StorageAccessService()),
        ChangeNotifierProvider(create: (_) => CloudStorageService()),
        ChangeNotifierProvider(create: (_) => RecentProjectsService()),
        ChangeNotifierProvider(create: (_) => WebStorageService()),
        ChangeNotifierProvider(
          create: (_) {
            final prefs = PreferencesService();
            prefs.initialize();
            return prefs;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final themeService = ThemeService();
            themeService.initialize();
            return themeService;
          },
        ),
        ChangeNotifierProxyProvider<CloudStorageService, CloudSyncService>(
          create: (context) =>
              CloudSyncService(context.read<CloudStorageService>()),
          update: (context, cloudStorage, previous) =>
              previous ?? CloudSyncService(cloudStorage),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return RepaintBoundary(
            key: screenshotBoundaryKey,
            child: MaterialApp(
              title: 'Writr Test',
              theme: theme ?? themeService.themeData,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
              ],
              home: const ProjectEditorScreen(),
            ),
          );
        },
      ),
    );
  }
}

/// Common test keys for finding widgets
class TestKeys {
  static const binderPanel = Key('binder_panel');
  static const inspectorPanel = Key('inspector_panel');
  static const editorPane = Key('editor_pane');
  static const toolbar = Key('main_toolbar');
  static const searchPanel = Key('search_panel');
}
