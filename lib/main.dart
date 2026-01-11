import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/scrivener_service.dart';
import 'services/storage_access_service.dart';
import 'services/cloud_storage_service.dart';
import 'services/recent_projects_service.dart';

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
      ],
      child: MaterialApp(
        title: 'Writr - Scrivener Editor',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
