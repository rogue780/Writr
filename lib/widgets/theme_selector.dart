import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/theme_service.dart';
import 'theme_card.dart';
import 'theme_editor_dialog.dart';

/// A widget for selecting and managing themes
class ThemeSelector extends StatelessWidget {
  final ThemeService themeService;

  const ThemeSelector({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Preset Themes'),
          const SizedBox(height: 12),
          _buildThemeGrid(
            context,
            PresetThemes.all,
            allowDuplicate: true,
          ),
          if (themeService.customThemes.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Custom Themes'),
            const SizedBox(height: 12),
            _buildThemeGrid(
              context,
              themeService.customThemes,
              allowEdit: true,
              allowDelete: true,
              allowDuplicate: true,
            ),
          ],
          const SizedBox(height: 24),
          _buildCreateButton(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildThemeGrid(
    BuildContext context,
    List<AppTheme> themes, {
    bool allowEdit = false,
    bool allowDelete = false,
    bool allowDuplicate = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on available width
        const minCardWidth = 120.0;
        final columns = (constraints.maxWidth / minCardWidth).floor().clamp(2, 4);
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: themes.map((theme) {
            return SizedBox(
              width: cardWidth,
              height: cardWidth * 0.9,
              child: ThemeCard(
                theme: theme,
                isSelected: theme.id == themeService.activeThemeId,
                onTap: () => _selectTheme(context, theme),
                onEdit: allowEdit ? () => _editTheme(context, theme) : null,
                onDelete: allowDelete ? () => _deleteTheme(context, theme) : null,
                onDuplicate: allowDuplicate
                    ? () => _duplicateTheme(context, theme)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _createNewTheme(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Custom Theme'),
      ),
    );
  }

  Future<void> _selectTheme(BuildContext context, AppTheme theme) async {
    await themeService.setActiveTheme(theme.id);
  }

  Future<void> _editTheme(BuildContext context, AppTheme theme) async {
    await ThemeEditorDialog.show(
      context,
      theme: theme,
      themeService: themeService,
      isNew: false,
    );
  }

  Future<void> _deleteTheme(BuildContext context, AppTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Theme'),
        content: Text('Delete "${theme.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await themeService.deleteCustomTheme(theme.id);
    }
  }

  Future<void> _duplicateTheme(BuildContext context, AppTheme theme) async {
    final nameController = TextEditingController(text: '${theme.name} Copy');

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Theme'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Theme Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final newTheme = await themeService.duplicateTheme(theme, name.trim());
      if (context.mounted) {
        // Open editor for the new theme
        await ThemeEditorDialog.show(
          context,
          theme: newTheme,
          themeService: themeService,
          isNew: false,
        );
      }
    }
  }

  Future<void> _createNewTheme(BuildContext context) async {
    final baseThemes = [
      ...PresetThemes.all,
      ...themeService.customThemes,
    ];

    final result = await showDialog<_CreateThemeResult>(
      context: context,
      builder: (context) => _CreateThemeDialog(baseThemes: baseThemes),
    );

    if (result != null && context.mounted) {
      final newTheme = await themeService.createCustomTheme(
        name: result.name,
        basedOn: result.basedOn,
      );

      if (context.mounted) {
        await ThemeEditorDialog.show(
          context,
          theme: newTheme,
          themeService: themeService,
          isNew: false,
        );
      }
    }
  }
}

class _CreateThemeResult {
  final String name;
  final AppTheme? basedOn;

  _CreateThemeResult({required this.name, this.basedOn});
}

class _CreateThemeDialog extends StatefulWidget {
  final List<AppTheme> baseThemes;

  const _CreateThemeDialog({required this.baseThemes});

  @override
  State<_CreateThemeDialog> createState() => _CreateThemeDialogState();
}

class _CreateThemeDialogState extends State<_CreateThemeDialog> {
  final _nameController = TextEditingController(text: 'My Custom Theme');
  AppTheme? _selectedBase;

  @override
  void initState() {
    super.initState();
    _selectedBase = widget.baseThemes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Custom Theme'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Theme Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Base Theme',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppTheme>(
              initialValue: _selectedBase,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.baseThemes.map((theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colors.primary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(theme.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedBase = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a theme name')),
              );
              return;
            }
            Navigator.pop(
              context,
              _CreateThemeResult(
                name: _nameController.text.trim(),
                basedOn: _selectedBase,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
