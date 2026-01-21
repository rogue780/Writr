import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/theme_service.dart';
import 'color_picker_dialog.dart';

/// A dialog for editing theme colors
class ThemeEditorDialog extends StatefulWidget {
  final AppTheme theme;
  final ThemeService themeService;
  final bool isNew;

  const ThemeEditorDialog({
    super.key,
    required this.theme,
    required this.themeService,
    this.isNew = false,
  });

  /// Show the theme editor dialog
  static Future<bool?> show(
    BuildContext context, {
    required AppTheme theme,
    required ThemeService themeService,
    bool isNew = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ThemeEditorDialog(
        theme: theme,
        themeService: themeService,
        isNew: isNew,
      ),
    );
  }

  @override
  State<ThemeEditorDialog> createState() => _ThemeEditorDialogState();
}

class _ThemeEditorDialogState extends State<ThemeEditorDialog> {
  late AppTheme _editingTheme;
  late TextEditingController _nameController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _editingTheme = widget.theme;
    _nameController = TextEditingController(text: widget.theme.name);
    _nameController.addListener(_onNameChanged);

    // Start preview
    widget.themeService.previewTheme(_editingTheme);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_nameController.text != _editingTheme.name) {
      setState(() {
        _editingTheme = _editingTheme.copyWith(name: _nameController.text);
        _hasChanges = true;
      });
    }
  }

  void _updateColor(String property, Color newColor) {
    setState(() {
      _editingTheme = _editingTheme.copyWith(
        colors: _editingTheme.colors.copyWithProperty(property, newColor),
      );
      _hasChanges = true;
    });
    widget.themeService.previewTheme(_editingTheme);
  }

  void _updateBrightness(Brightness brightness) {
    setState(() {
      _editingTheme = _editingTheme.copyWith(brightness: brightness);
      _hasChanges = true;
    });
    widget.themeService.previewTheme(_editingTheme);
  }

  Future<void> _revertToOriginal() async {
    if (_editingTheme.basedOnPresetId == null) return;

    final preset = PresetThemes.getById(_editingTheme.basedOnPresetId!);
    if (preset == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert to Original'),
        content: Text(
          'This will reset all colors to the "${preset.name}" preset. '
          'Your custom changes will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _editingTheme = _editingTheme.copyWith(
          brightness: preset.brightness,
          colors: preset.colors,
        );
        _hasChanges = true;
      });
      widget.themeService.previewTheme(_editingTheme);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme name cannot be empty')),
      );
      return;
    }

    final finalTheme = _editingTheme.copyWith(
      name: _nameController.text.trim(),
    );

    if (widget.isNew) {
      // Create new custom theme
      final newTheme = await widget.themeService.createCustomTheme(
        name: finalTheme.name,
        basedOn: finalTheme,
      );
      await widget.themeService.setActiveTheme(newTheme.id);
    } else {
      // Update existing theme
      await widget.themeService.updateCustomTheme(finalTheme);
      await widget.themeService.setActiveTheme(finalTheme.id);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _cancel() {
    widget.themeService.cancelPreview();
    Navigator.pop(context, false);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      _cancel();
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true) {
      _cancel();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 700,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPreview(),
                      const SizedBox(height: 16),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildBrightnessToggle(),
                      const SizedBox(height: 24),
                      _buildColorSection('Primary Colors', [
                        _ColorItem('Primary', 'primary', _editingTheme.colors.primary),
                        _ColorItem('On Primary', 'onPrimary', _editingTheme.colors.onPrimary),
                        _ColorItem('Primary Container', 'primaryContainer', _editingTheme.colors.primaryContainer),
                        _ColorItem('On Primary Container', 'onPrimaryContainer', _editingTheme.colors.onPrimaryContainer),
                      ]),
                      const SizedBox(height: 16),
                      _buildColorSection('Secondary Colors', [
                        _ColorItem('Secondary', 'secondary', _editingTheme.colors.secondary),
                        _ColorItem('On Secondary', 'onSecondary', _editingTheme.colors.onSecondary),
                        _ColorItem('Secondary Container', 'secondaryContainer', _editingTheme.colors.secondaryContainer),
                        _ColorItem('On Secondary Container', 'onSecondaryContainer', _editingTheme.colors.onSecondaryContainer),
                      ]),
                      const SizedBox(height: 16),
                      _buildColorSection('Tertiary Colors', [
                        _ColorItem('Tertiary', 'tertiary', _editingTheme.colors.tertiary),
                        _ColorItem('On Tertiary', 'onTertiary', _editingTheme.colors.onTertiary),
                      ]),
                      const SizedBox(height: 16),
                      _buildColorSection('Surface Colors', [
                        _ColorItem('Surface', 'surface', _editingTheme.colors.surface),
                        _ColorItem('On Surface', 'onSurface', _editingTheme.colors.onSurface),
                        _ColorItem('Surface Container', 'surfaceContainer', _editingTheme.colors.surfaceContainer),
                        _ColorItem('Surface Container Highest', 'surfaceContainerHighest', _editingTheme.colors.surfaceContainerHighest),
                        _ColorItem('Surface Container High', 'surfaceContainerHigh', _editingTheme.colors.surfaceContainerHigh),
                        _ColorItem('Surface Container Low', 'surfaceContainerLow', _editingTheme.colors.surfaceContainerLow),
                        _ColorItem('Surface Container Lowest', 'surfaceContainerLowest', _editingTheme.colors.surfaceContainerLowest),
                        _ColorItem('Inverse Surface', 'inverseSurface', _editingTheme.colors.inverseSurface),
                        _ColorItem('On Inverse Surface', 'onInverseSurface', _editingTheme.colors.onInverseSurface),
                      ]),
                      const SizedBox(height: 16),
                      _buildColorSection('Error Colors', [
                        _ColorItem('Error', 'error', _editingTheme.colors.error),
                        _ColorItem('On Error', 'onError', _editingTheme.colors.onError),
                        _ColorItem('Error Container', 'errorContainer', _editingTheme.colors.errorContainer),
                        _ColorItem('On Error Container', 'onErrorContainer', _editingTheme.colors.onErrorContainer),
                      ]),
                      const SizedBox(height: 16),
                      _buildColorSection('Other Colors', [
                        _ColorItem('Outline', 'outline', _editingTheme.colors.outline),
                        _ColorItem('Outline Variant', 'outlineVariant', _editingTheme.colors.outlineVariant),
                        _ColorItem('Shadow', 'shadow', _editingTheme.colors.shadow),
                        _ColorItem('Scrim', 'scrim', _editingTheme.colors.scrim),
                        _ColorItem('Inverse Primary', 'inversePrimary', _editingTheme.colors.inversePrimary),
                      ]),
                    ],
                  ),
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isNew ? Icons.add : Icons.edit,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isNew ? 'Create Custom Theme' : 'Edit Theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _onWillPop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: _editingTheme.colors.primary,
                child: Center(
                  child: Text(
                    'Primary',
                    style: TextStyle(
                      color: _editingTheme.colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: _editingTheme.colors.secondary,
                child: Center(
                  child: Text(
                    'Secondary',
                    style: TextStyle(
                      color: _editingTheme.colors.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: _editingTheme.colors.surface,
                child: Center(
                  child: Text(
                    'Surface',
                    style: TextStyle(
                      color: _editingTheme.colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Theme Name',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildBrightnessToggle() {
    return Row(
      children: [
        const Text('Brightness:'),
        const SizedBox(width: 16),
        SegmentedButton<Brightness>(
          segments: const [
            ButtonSegment(
              value: Brightness.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: Brightness.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {_editingTheme.brightness},
          onSelectionChanged: (value) => _updateBrightness(value.first),
        ),
      ],
    );
  }

  Widget _buildColorSection(String title, List<_ColorItem> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...colors.map((item) => _buildColorRow(item)),
      ],
    );
  }

  Widget _buildColorRow(_ColorItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final newColor = await ColorPickerDialog.show(
                context,
                initialColor: item.color,
                title: item.label,
              );
              if (newColor != null) {
                _updateColor(item.property, newColor);
              }
            },
            child: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              '#${item.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (!widget.isNew && _editingTheme.basedOnPresetId != null)
            TextButton.icon(
              onPressed: _revertToOriginal,
              icon: const Icon(Icons.restore),
              label: const Text('Revert'),
            ),
          const Spacer(),
          TextButton(
            onPressed: _cancel,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _save,
            child: Text(widget.isNew ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _ColorItem {
  final String label;
  final String property;
  final Color color;

  _ColorItem(this.label, this.property, this.color);
}
