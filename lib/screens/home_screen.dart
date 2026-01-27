import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scrivener_service.dart';
import '../services/writr_service.dart';
import '../services/storage_access_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/recent_projects_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/web_storage_service.dart';
import '../services/project_converter.dart';
import '../models/cloud_file.dart';
import '../models/scrivener_project.dart';
import 'project_editor_screen.dart';
import 'cloud_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load recent projects when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecentProjectsService>().loadRecentProjects();
    });
  }

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
            const SizedBox(height: 32),
            // Recent projects section (in a card box)
            _buildRecentProjectsSection(context),
            const SizedBox(height: 24),
            // Open and Create buttons side by side
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showOpenProjectOptions(context),
                    icon: const Icon(Icons.folder_open, size: 24),
                    label: const Text(
                      'Open Project',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _createNewProject(context),
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text(
                      'Create New',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentProjectsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currently open project
            Consumer<ScrivenerService>(
              builder: (context, service, child) {
                if (service.currentProject != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_document,
                               size: 18,
                               color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Currently Open',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.book,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          service.currentProject!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProjectEditorScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Continue'),
                        ),
                      ),
                      const Divider(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Recent projects list
            Consumer<RecentProjectsService>(
              builder: (context, recentService, child) {
                if (!recentService.isLoaded) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (recentService.recentProjects.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No recent projects',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Projects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showClearRecentDialog(context),
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...recentService.recentProjects.map((project) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.book,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          project.getRelativeTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () =>
                              _removeRecentProject(context, project.path),
                          tooltip: 'Remove from recent',
                        ),
                        onTap: () => _openRecentProject(context, project),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
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
      final providerName = switch (provider) {
        CloudProvider.googleDrive => 'Google Drive',
        CloudProvider.dropbox => 'Dropbox',
        CloudProvider.oneDrive => 'OneDrive',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cloudService.error?.isNotEmpty == true
                ? cloudService.error!
                : 'Failed to sign in to $providerName',
          ),
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

    // Download and open selected cloud project
    if (selectedProject != null && selectedProject is CloudFile) {
      if (!context.mounted) return;

      final syncService = context.read<CloudSyncService>();
      final scrivenerService = context.read<ScrivenerService>();
      final recentService = context.read<RecentProjectsService>();

      // Show download progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Consumer<CloudSyncService>(
                builder: (context, sync, child) {
                  return Text(
                    sync.syncStatus ?? 'Downloading project...',
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      );

      try {
        // Download project from cloud
        final localPath = await syncService.downloadProject(selectedProject);

        if (!context.mounted) return;

        // Close progress dialog
        Navigator.pop(context);

        if (localPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to download project: ${syncService.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Load the downloaded project
        await scrivenerService.loadProject(localPath);

        if (!context.mounted) return;

        if (scrivenerService.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading project: ${scrivenerService.error}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Add to recent projects
        await recentService.addRecentProject(
          name: scrivenerService.currentProject!.name,
          path: localPath,
        );

        if (!context.mounted) return;

        // Navigate to editor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProjectEditorScreen(),
          ),
        );

        if (!context.mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Project downloaded from ${cloudService.currentProvider?.providerName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        // Close progress dialog if still open
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openExistingProject(BuildContext context) async {
    final storageService = context.read<StorageAccessService>();
    final scrivenerService = context.read<ScrivenerService>();
    final writrService = context.read<WritrService>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Let user pick a .scriv or .writ folder from anywhere
      final projectPath = await storageService.pickProject();

      if (!context.mounted) return;

      if (projectPath == null) {
        Navigator.pop(context);
        final error = storageService.error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => storageService.openPermissionSettings(),
              ),
            ),
          );
          storageService.clearError();
        }
        return;
      }

      // Optional: Copy to cache for better performance
      // You can skip this if you want to edit directly in cloud storage
      final cachedPath = await storageService.copyProjectToCache(projectPath);
      final pathToLoad = cachedPath ?? projectPath;

      // Detect project format and load with appropriate service
      final format = await detectProjectFormat(pathToLoad);

      if (format == ProjectFormat.writr) {
        // Load .writ project using WritrService
        await writrService.loadProject(pathToLoad);

        if (!context.mounted) return;

        if (writrService.error != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${writrService.error}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Transfer to ScrivenerService in native mode for unified access
        scrivenerService.setProject(
          writrService.currentProject!,
          mode: ProjectMode.native,
        );
      } else {
        // Load .scriv project using ScrivenerService
        await scrivenerService.loadProject(pathToLoad);

        if (!context.mounted) return;

        if (scrivenerService.error != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${scrivenerService.error}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Add to recent projects
      final recentService = context.read<RecentProjectsService>();
      await recentService.addRecentProject(
        name: scrivenerService.currentProject!.name,
        path: pathToLoad,
      );

      if (!context.mounted) return;

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

    // Handle web platform differently
    if (kIsWeb) {
      await _createWebProject(context, projectName);
    } else {
      await _createFileSystemProject(context, projectName);
    }
  }

  Future<void> _createWebProject(
      BuildContext context, String projectName) async {
    final scrivenerService = context.read<ScrivenerService>();
    final webStorageService = context.read<WebStorageService>();
    final recentService = context.read<RecentProjectsService>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create project in memory (web_$projectName as path identifier)
      final projectPath = 'web_${projectName.replaceAll(' ', '_')}';
      final project = ScrivenerProject.empty(projectName, projectPath);

      // Save to web storage
      await webStorageService.saveProject(project);

      // Set as current project in ScrivenerService
      scrivenerService.setProject(project);

      // Setup auto-save callback for web projects
      scrivenerService.setAutoSaveCallback((ScrivenerProject proj) async {
        await webStorageService.saveProject(proj);
      });

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Add to recent projects
      await recentService.addRecentProject(
        name: project.name,
        path: project.path,
      );

      if (!context.mounted) return;

      // Navigate to editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProjectEditorScreen(),
        ),
      );

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project created in browser storage'),
          backgroundColor: Colors.green,
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

  Future<void> _createFileSystemProject(
      BuildContext context, String projectName) async {
    final storageService = context.read<StorageAccessService>();
    final scrivenerService = context.read<ScrivenerService>();
    final writrService = context.read<WritrService>();
    final recentService = context.read<RecentProjectsService>();

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
        Navigator.pop(context);
        final error = storageService.error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => storageService.openPermissionSettings(),
              ),
            ),
          );
          storageService.clearError();
        }
        return;
      }

      // Create native .writ project using WritrService
      await writrService.createProject(projectName, directory);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (writrService.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${writrService.error}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Transfer to ScrivenerService in native mode for unified editor access
      scrivenerService.setProject(
        writrService.currentProject!,
        mode: ProjectMode.native,
      );

      // Add to recent projects
      await recentService.addRecentProject(
        name: writrService.currentProject!.name,
        path: writrService.currentProject!.path,
      );

      if (!context.mounted) return;

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

  Future<void> _openRecentProject(
      BuildContext context, dynamic recentProject) async {
    final scrivenerService = context.read<ScrivenerService>();
    final writrService = context.read<WritrService>();
    final recentService = context.read<RecentProjectsService>();
    final webStorageService = context.read<WebStorageService>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Check if this is a web project
      if (recentProject.path.startsWith('web_')) {
        // Load from web storage
        final project = await webStorageService.loadProject(recentProject.path);

        if (project == null) {
          throw Exception('Project not found in browser storage');
        }

        scrivenerService.setProject(project);

        // Setup auto-save callback for web projects
        scrivenerService.setAutoSaveCallback((ScrivenerProject proj) async {
          await webStorageService.saveProject(proj);
        });
      } else {
        // Load from file system - detect format first
        final format = await detectProjectFormat(recentProject.path);

        if (format == ProjectFormat.writr) {
          // Load .writ project using WritrService
          await writrService.loadProject(recentProject.path);

          if (writrService.error != null) {
            throw Exception(writrService.error);
          }

          // Transfer to ScrivenerService in native mode for unified access
          scrivenerService.setProject(
            writrService.currentProject!,
            mode: ProjectMode.native,
          );
        } else {
          // Load .scriv project using ScrivenerService
          await scrivenerService.loadProject(recentProject.path);
        }
      }

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

      // Update last opened time
      await recentService.addRecentProject(
        name: scrivenerService.currentProject!.name,
        path: recentProject.path,
      );

      if (!context.mounted) return;

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

  Future<void> _removeRecentProject(BuildContext context, String path) async {
    final recentService = context.read<RecentProjectsService>();
    await recentService.removeRecentProject(path);
  }

  Future<void> _showClearRecentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent Projects'),
        content: const Text(
          'Are you sure you want to clear all recent projects?\n\n'
          'This will not delete the actual project files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final recentService = context.read<RecentProjectsService>();
      await recentService.clearRecentProjects();
    }
  }
}
