import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../services/cloud_storage_service.dart';
import '../services/scrivener_service.dart';
import '../models/cloud_storage.dart';
import 'project_editor_screen.dart';

class CloudBrowserScreen extends StatefulWidget {
  final CloudProvider provider;

  const CloudBrowserScreen({super.key, required this.provider});

  @override
  State<CloudBrowserScreen> createState() => _CloudBrowserScreenState();
}

class _CloudBrowserScreenState extends State<CloudBrowserScreen> {
  String? _currentFolderId;
  final List<String> _navigationStack = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final service = context.read<CloudStorageService>();
    await service.listFiles(parentId: _currentFolderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getProviderName(widget.provider)),
        actions: [
          if (_navigationStack.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _currentFolderId = _navigationStack.removeLast();
                });
                _loadFiles();
              },
            ),
        ],
      ),
      body: Consumer<CloudStorageService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${service.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFiles,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (service.files.isEmpty) {
            return const Center(
              child: Text('No files found'),
            );
          }

          return ListView.builder(
            itemCount: service.files.length,
            itemBuilder: (context, index) {
              final file = service.files[index];
              return ListTile(
                leading: Icon(
                  file.isDirectory ? Icons.folder : Icons.file_present,
                  color: file.isScrivenerProject
                      ? Colors.purple
                      : file.isDirectory
                          ? Colors.blue
                          : Colors.grey,
                ),
                title: Text(file.name),
                subtitle: file.modifiedDate != null
                    ? Text(_formatDate(file.modifiedDate!))
                    : null,
                trailing: file.isScrivenerProject
                    ? const Icon(Icons.arrow_forward, color: Colors.purple)
                    : null,
                onTap: () => _handleFileTap(file),
              );
            },
          );
        },
      ),
    );
  }

  String _getProviderName(CloudProvider provider) {
    switch (provider) {
      case CloudProvider.googleDrive:
        return 'Google Drive';
      case CloudProvider.dropbox:
        return 'Dropbox';
      case CloudProvider.oneDrive:
        return 'OneDrive';
      case CloudProvider.local:
        return 'Local Storage';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleFileTap(CloudFile file) async {
    if (file.isDirectory && !file.isScrivenerProject) {
      // Navigate into folder
      setState(() {
        _navigationStack.add(_currentFolderId ?? '');
        _currentFolderId = file.id;
      });
      await _loadFiles();
    } else if (file.isScrivenerProject) {
      // Download and open Scrivener project
      await _openScrivenerProject(file);
    }
  }

  Future<void> _openScrivenerProject(CloudFile file) async {
    final cloudService = context.read<CloudStorageService>();
    final scrivenerService = context.read<ScrivenerService>();

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final projectPath = '${tempDir.path}/${file.name}';

      // Download project
      await cloudService.downloadFile(file.id, projectPath);

      // Load project
      await scrivenerService.loadProject(projectPath);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to editor
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProjectEditorScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening project: $e')),
      );
    }
  }
}
