import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scrivener_service.dart';
import '../services/storage_access_service.dart';
import 'project_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writr'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome to Writr',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'A Scrivener-compatible editor for Android',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Info card about storage access
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Access Files Anywhere',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Writr uses your device\'s file picker to access projects from:\n\n'
                      '• Google Drive (if app installed)\n'
                      '• Dropbox (if app installed)\n'
                      '• OneDrive (if app installed)\n'
                      '• Local device storage\n'
                      '• Any other cloud storage app\n\n'
                      'No API keys or login required!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Open existing project button
            ElevatedButton.icon(
              onPressed: () => _openExistingProject(context),
              icon: const Icon(Icons.folder_open, size: 28),
              label: const Text(
                'Open Project',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Create new project button
            OutlinedButton.icon(
              onPressed: () => _createNewProject(context),
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text(
                'Create New Project',
                style: TextStyle(fontSize: 18),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const Spacer(),
            // Currently open project info
            Consumer<ScrivenerService>(
              builder: (context, service, child) {
                if (service.currentProject != null) {
                  return Card(
                    elevation: 4,
                    child: ListTile(
                      leading: const Icon(Icons.book, color: Colors.deepPurple),
                      title: Text(
                        service.currentProject!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Currently open'),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProjectEditorScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExistingProject(BuildContext context) async {
    final storageService = context.read<StorageAccessService>();
    final scrivenerService = context.read<ScrivenerService>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Let user pick a .scriv folder from anywhere
      final projectPath = await storageService.pickScrivenerProject();

      if (!context.mounted) return;

      if (projectPath == null) {
        // User cancelled
        Navigator.pop(context);
        return;
      }

      // Optional: Copy to cache for better performance
      // You can skip this if you want to edit directly in cloud storage
      final cachedPath = await storageService.copyProjectToCache(projectPath);
      final pathToLoad = cachedPath ?? projectPath;

      // Load the project
      await scrivenerService.loadProject(pathToLoad);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (scrivenerService.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${scrivenerService.error}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProjectEditorScreen(),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createNewProject(BuildContext context) async {
    final nameController = TextEditingController();

    final projectName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'My Novel',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, nameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (projectName == null || projectName.isEmpty) return;
    if (!context.mounted) return;

    final storageService = context.read<StorageAccessService>();
    final scrivenerService = context.read<ScrivenerService>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Let user pick where to create the project
      final directory = await storageService.pickDirectoryForNewProject();

      if (!context.mounted) return;

      if (directory == null) {
        // User cancelled
        Navigator.pop(context);
        return;
      }

      // Create the project
      await scrivenerService.createProject(projectName, directory);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (scrivenerService.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${scrivenerService.error}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProjectEditorScreen(),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
