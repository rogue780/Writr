import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cloud_file.dart';
import '../services/cloud_storage_service.dart';

class CloudBrowserScreen extends StatefulWidget {
  const CloudBrowserScreen({super.key});

  @override
  State<CloudBrowserScreen> createState() => _CloudBrowserScreenState();
}

class _CloudBrowserScreenState extends State<CloudBrowserScreen> {
  final List<CloudFile?> _breadcrumbs = [null]; // null = root
  List<CloudFile> _currentFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);

    try {
      final cloudService = context.read<CloudStorageService>();
      final folderId = _breadcrumbs.last?.id;
      final files = await cloudService.listFiles(folderId: folderId);

      setState(() {
        _currentFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load files: $e')),
        );
      }
    }
  }

  void _navigateToFolder(CloudFile folder) {
    setState(() {
      _breadcrumbs.add(folder);
    });
    _loadFiles();
  }

  void _navigateBack() {
    if (_breadcrumbs.length > 1) {
      setState(() {
        _breadcrumbs.removeLast();
      });
      _loadFiles();
    }
  }

  void _selectProject(CloudFile project) {
    // Return the selected project to the previous screen
    Navigator.of(context).pop(project);
  }

  @override
  Widget build(BuildContext context) {
    final cloudService = context.watch<CloudStorageService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Browse ${cloudService.currentProvider?.providerName ?? "Cloud"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await cloudService.signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb navigation
          if (_breadcrumbs.length > 1)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _navigateBack,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _breadcrumbs.map((folder) {
                          final isLast = folder == _breadcrumbs.last;
                          return Row(
                            children: [
                              Text(
                                folder?.name ?? 'Root',
                                style: TextStyle(
                                  fontWeight: isLast
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (!isLast)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.chevron_right, size: 16),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // File list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentFiles.isEmpty
                    ? const Center(
                        child: Text('No files found'),
                      )
                    : ListView.builder(
                        itemCount: _currentFiles.length,
                        itemBuilder: (context, index) {
                          final file = _currentFiles[index];
                          return ListTile(
                            leading: Icon(
                              file.isDirectory
                                  ? Icons.folder
                                  : Icons.insert_drive_file,
                              color: file.isDirectory
                                  ? Colors.blue
                                  : file.isScrivenerProject
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                            title: Text(file.name),
                            subtitle: file.isDirectory
                                ? null
                                : Text(_formatSize(file.size)),
                            trailing: file.isScrivenerProject
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                            onTap: () {
                              if (file.isScrivenerProject) {
                                _selectProject(file);
                              } else if (file.isDirectory) {
                                _navigateToFolder(file);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _breadcrumbs.length > 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Show dialog to create new project
                _showCreateProjectDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            ),
    );
  }

  Future<void> _showCreateProjectDialog() async {
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Scrivener Project'),
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      await _createProject(nameController.text);
    }
  }

  Future<void> _createProject(String name) async {
    setState(() => _isLoading = true);

    try {
      final cloudService = context.read<CloudStorageService>();
      final projectName = name.endsWith('.scriv') ? name : '$name.scriv';

      // Create project folder
      final projectFolder = await cloudService.createFolder(
        name: projectName,
        parentFolderId: _breadcrumbs.last?.id,
      );

      // Return the new project
      if (mounted) {
        Navigator.of(context).pop(projectFolder);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project: $e')),
        );
      }
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
