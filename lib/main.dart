import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/scrivener_service.dart';
import 'services/storage_access_service.dart';
import 'services/cloud_storage_service.dart';
import 'services/recent_projects_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/web_storage_service.dart';
import 'services/preferences_service.dart';
import 'widgets/orientation_policy.dart';

void main() {
  runApp(const WritrApp());
}

class WritrApp extends StatelessWidget {
  const WritrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScrivenerService()),
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
        ChangeNotifierProxyProvider<CloudStorageService, CloudSyncService>(
          create: (context) =>
              CloudSyncService(context.read<CloudStorageService>()),
          update: (context, cloudStorage, previous) =>
              previous ?? CloudSyncService(cloudStorage),
        ),
      ],
      child: MaterialApp(
        title: 'Writr - Scrivener Editor',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return OrientationPolicy(
            child: child ?? const SizedBox.shrink(),
          );
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        home: const HomeScreen(),
      ),
    );
  }
}
