import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cloud_storage_service.dart';
import '../services/scrivener_service.dart';
import '../models/cloud_storage.dart';
import 'cloud_browser_screen.dart';
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
            const SizedBox(height: 32),
            const Text(
              'Open Project From:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _CloudProviderButton(
              provider: CloudProvider.googleDrive,
              icon: Icons.cloud,
              label: 'Google Drive',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _CloudProviderButton(
              provider: CloudProvider.dropbox,
              icon: Icons.folder,
              label: 'Dropbox',
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),
            _CloudProviderButton(
              provider: CloudProvider.oneDrive,
              icon: Icons.cloud_upload,
              label: 'OneDrive',
              color: Colors.cyan,
            ),
            const SizedBox(height: 12),
            _LocalProjectButton(),
            const Spacer(),
            Consumer<ScrivenerService>(
              builder: (context, service, child) {
                if (service.currentProject != null) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(service.currentProject!.name),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context),
        tooltip: 'Create New Project',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'My Novel',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                // TODO: Implement create project with directory picker
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project creation requires directory picker'),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _CloudProviderButton extends StatelessWidget {
  final CloudProvider provider;
  final IconData icon;
  final String label;
  final Color color;

  const _CloudProviderButton({
    required this.provider,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CloudStorageService>(
      builder: (context, service, child) {
        return ElevatedButton.icon(
          onPressed: () async {
            service.setProvider(provider);

            if (!service.isAuthenticated) {
              try {
                await service.authenticate();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Authentication error: $e')),
                  );
                }
                return;
              }
            }

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CloudBrowserScreen(provider: provider),
                ),
              );
            }
          },
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
          ),
        );
      },
    );
  }
}

class _LocalProjectButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implement local file picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local file picker not yet implemented'),
          ),
        );
      },
      icon: const Icon(Icons.phone_android),
      label: const Text('Local Storage'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
