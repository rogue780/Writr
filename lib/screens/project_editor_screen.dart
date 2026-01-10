import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scrivener_service.dart';
import '../models/scrivener_project.dart';
import '../widgets/binder_tree_view.dart';
import '../widgets/document_editor.dart';

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
            return Text(service.currentProject?.name ?? 'Project');
          },
        ),
        actions: [
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
}
