import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/scrivener_service.dart';
import '../services/web_storage_service.dart';
import '../models/scrivener_project.dart';
import '../widgets/binder_tree_view.dart';
import '../widgets/document_editor.dart';
import 'dart:html' as html;

class ProjectEditorScreen extends StatefulWidget {
  const ProjectEditorScreen({super.key});

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  BinderItem? _selectedItem;
  bool _showBinder = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ScrivenerService>(
          builder: (context, service, child) {
            return Row(
              children: [
                Text(service.currentProject?.name ?? 'Project'),
                const SizedBox(width: 8),
                if (service.hasUnsavedChanges)
                  const Icon(Icons.circle, size: 8, color: Colors.orange),
              ],
            );
          },
        ),
        actions: [
          // Storage indicator for web projects
          if (kIsWeb)
            Consumer<WebStorageService>(
              builder: (context, webStorage, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      webStorage.getStorageUsedFormatted(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
          // Export/Import for web projects
          if (kIsWeb)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'export') {
                  _exportProject();
                } else if (value == 'import') {
                  _importProject();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Export .scriv'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload, size: 20),
                      SizedBox(width: 8),
                      Text('Import .scriv'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(_showBinder ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _showBinder = !_showBinder;
              });
            },
            tooltip: _showBinder ? 'Hide Binder' : 'Show Binder',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProject,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Consumer<ScrivenerService>(
        builder: (context, service, child) {
          if (service.currentProject == null) {
            return const Center(
              child: Text('No project loaded'),
            );
          }

          return Row(
            children: [
              if (_showBinder)
                SizedBox(
                  width: 250,
                  child: BinderTreeView(
                    items: service.currentProject!.binderItems,
                    onItemSelected: (item) {
                      setState(() {
                        _selectedItem = item;
                      });
                    },
                    selectedItem: _selectedItem,
                  ),
                ),
              if (_showBinder) const VerticalDivider(width: 1),
              Expanded(
                child: _selectedItem != null
                    ? DocumentEditor(
                        item: _selectedItem!,
                        content: service.currentProject!
                                .textContents[_selectedItem!.id] ??
                            '',
                        onContentChanged: (content) {
                          service.updateTextContent(
                            _selectedItem!.id,
                            content,
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          'Select a document from the binder',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveProject() async {
    final service = context.read<ScrivenerService>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await service.saveProject();

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    if (service.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: ${service.error}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project saved successfully')),
      );
    }
  }

  Future<void> _exportProject() async {
    final service = context.read<ScrivenerService>();
    final webStorage = context.read<WebStorageService>();

    if (service.currentProject == null) return;

    try {
      // Export project as zip
      final zipBytes = webStorage.exportProject(service.currentProject!);

      // Trigger download in browser
      final blob = html.Blob([zipBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${service.currentProject!.name}.scriv.zip')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importProject() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('No file data');
      }

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Import project
      final webStorage = context.read<WebStorageService>();
      final service = context.read<ScrivenerService>();

      final projectName = file.name.replaceAll('.scriv.zip', '').replaceAll('.zip', '');
      final project = await webStorage.importProject(file.bytes!, projectName);

      if (!mounted) return;

      // Close loading
      Navigator.pop(context);

      if (project == null) {
        throw Exception('Failed to import project');
      }

      // Load the imported project
      service.setProject(project);

      // Setup auto-save callback
      service.setAutoSaveCallback((ScrivenerProject proj) async {
        await webStorage.saveProject(proj);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project imported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        // Close loading dialog if still open
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
