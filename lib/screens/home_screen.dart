import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scrivener_service.dart';
import '../services/storage_access_service.dart';
import '../services/cloud_storage_service.dart';
import 'project_editor_screen.dart';
import 'cloud_browser_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writr'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              'A Scrivener-compatible editor',
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
                      'Writr provides two ways to access your projects:\n\n'
                      '1. Native File Picker (recommended):\n'
                      '   • Local storage, network drives, external drives\n'
                      '   • Works with installed cloud apps\n'
                      '   • No setup required\n\n'
                      '2. Direct Cloud API Access:\n'
                      '   • Google Drive, Dropbox, OneDrive\n'
                      '   • Requires API configuration\n'
                      '   • Browse and manage cloud files',
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
              onPressed: () => _showOpenProjectOptions(context),
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
            const SizedBox(height: 32),
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
      ),
    );
  }

  Future<void> _showOpenProjectOptions(BuildContext context) async {
    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('File Picker'),
              subtitle: const Text('Use native file picker (recommended)'),
              onTap: () => Navigator.pop(context, 'file_picker'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.green),
              title: const Text('Google Drive'),
              subtitle: const Text('Browse with Google Drive API'),
              onTap: () => Navigator.pop(context, 'google_drive'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.blue),
              title: const Text('Dropbox'),
              subtitle: const Text('Browse with Dropbox API'),
              onTap: () => Navigator.pop(context, 'dropbox'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.purple),
              title: const Text('OneDrive'),
              subtitle: const Text('Browse with OneDrive API'),
              onTap: () => Navigator.pop(context, 'onedrive'),
            ),
          ],
        ),
      ),
    );

    if (option == null || !context.mounted) return;

    switch (option) {
      case 'file_picker':
        await _openExistingProject(context);
        break;
      case 'google_drive':
        await _openCloudProject(context, CloudProvider.googleDrive);
        break;
      case 'dropbox':
        await _openCloudProject(context, CloudProvider.dropbox);
        break;
      case 'onedrive':
        await _openCloudProject(context, CloudProvider.oneDrive);
        break;
    }
  }

  Future<void> _openCloudProject(
      BuildContext context, CloudProvider provider) async {
    final cloudService = context.read<CloudStorageService>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Sign in to provider
    final success = await cloudService.selectProvider(provider);

    if (!context.mounted) return;

    // Close loading
    Navigator.pop(context);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to sign in to ${cloudService.currentProvider?.providerName ?? "cloud provider"}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to cloud browser
    final selectedProject = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CloudBrowserScreen(),
      ),
    );

    // TODO: Handle selected cloud project - download and open it
    // This would require implementing cloud project download logic
    if (selectedProject != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cloud project loading not yet fully implemented. Working on download logic...'),
          ),
        );
      }
    }
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
