import 'package:flutter/material.dart';
import '../models/view_mode.dart';

/// Traditional menu bar with File/Edit/View/Project/Tools menus
class AppMenuBar extends StatelessWidget {
  // File menu callbacks
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final VoidCallback? onBackups;
  final VoidCallback? onClose;

  // View menu callbacks
  final bool showBinder;
  final bool showInspector;
  final bool showSearch;
  final bool showCollections;
  final ViewMode viewMode;
  final bool splitEditorEnabled;
  final VoidCallback? onToggleBinder;
  final VoidCallback? onToggleInspector;
  final VoidCallback? onToggleSearch;
  final VoidCallback? onToggleCollections;
  final Function(ViewMode)? onViewModeChanged;
  final VoidCallback? onToggleSplitEditor;

  // Project menu callbacks
  final VoidCallback? onCompile;
  final VoidCallback? onTargets;
  final VoidCallback? onSessionTarget;
  final VoidCallback? onStatistics;
  final VoidCallback? onTemplateManager;
  final VoidCallback? onInsertTemplate;

  // Tools menu callbacks
  final VoidCallback? onCompositionMode;
  final VoidCallback? onNameGenerator;
  final VoidCallback? onLinguisticAnalysis;
  final VoidCallback? onKeywordManager;
  final VoidCallback? onCustomFields;

  // Settings
  final VoidCallback? onSwitchToSimplifiedToolbar;

  const AppMenuBar({
    super.key,
    // File
    this.onSave,
    this.onExport,
    this.onImport,
    this.onBackups,
    this.onClose,
    // View
    this.showBinder = true,
    this.showInspector = true,
    this.showSearch = false,
    this.showCollections = false,
    this.viewMode = ViewMode.editor,
    this.splitEditorEnabled = false,
    this.onToggleBinder,
    this.onToggleInspector,
    this.onToggleSearch,
    this.onToggleCollections,
    this.onViewModeChanged,
    this.onToggleSplitEditor,
    // Project
    this.onCompile,
    this.onTargets,
    this.onSessionTarget,
    this.onStatistics,
    this.onTemplateManager,
    this.onInsertTemplate,
    // Tools
    this.onCompositionMode,
    this.onNameGenerator,
    this.onLinguisticAnalysis,
    this.onKeywordManager,
    this.onCustomFields,
    // Settings
    this.onSwitchToSimplifiedToolbar,
  });

  @override
  Widget build(BuildContext context) {
    final showViewModeToggle = MediaQuery.sizeOf(context).width >= 700;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          _buildFileMenu(context),
          _buildEditMenu(context),
          _buildViewMenu(context),
          _buildProjectMenu(context),
          _buildToolsMenu(context),
          if (showViewModeToggle && onViewModeChanged != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 20,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(width: 8),
            _buildViewModeToggle(context),
          ],
          const Spacer(),
          // Switch to simplified toolbar option
          if (onSwitchToSimplifiedToolbar != null)
            TextButton.icon(
              onPressed: onSwitchToSimplifiedToolbar,
              icon: const Icon(Icons.view_compact, size: 16),
              label: const Text('Simplified', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in ViewMode.values)
            Tooltip(
              message: mode.tooltip,
              child: InkWell(
                onTap: () => onViewModeChanged?.call(mode),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: viewMode == mode
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    mode.icon,
                    size: 16,
                    color: viewMode == mode
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileMenu(BuildContext context) {
    return _MenuBarButton(
      label: 'File',
      items: [
        _MenuItem(
          icon: Icons.save,
          label: 'Save',
          shortcut: 'Ctrl+S',
          onTap: onSave,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.download,
          label: 'Export Project...',
          onTap: onExport,
        ),
        _MenuItem(
          icon: Icons.upload,
          label: 'Import Project...',
          onTap: onImport,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.backup,
          label: 'Backup Manager...',
          onTap: onBackups,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.close,
          label: 'Close Project',
          onTap: onClose,
        ),
      ],
    );
  }

  Widget _buildEditMenu(BuildContext context) {
    return _MenuBarButton(
      label: 'Edit',
      items: [
        _MenuItem(
          icon: Icons.undo,
          label: 'Undo',
          shortcut: 'Ctrl+Z',
          onTap: () {
            // Handled by editor
          },
        ),
        _MenuItem(
          icon: Icons.redo,
          label: 'Redo',
          shortcut: 'Ctrl+Y',
          onTap: () {
            // Handled by editor
          },
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.content_cut,
          label: 'Cut',
          shortcut: 'Ctrl+X',
          onTap: () {
            // Handled by system
          },
        ),
        _MenuItem(
          icon: Icons.content_copy,
          label: 'Copy',
          shortcut: 'Ctrl+C',
          onTap: () {
            // Handled by system
          },
        ),
        _MenuItem(
          icon: Icons.content_paste,
          label: 'Paste',
          shortcut: 'Ctrl+V',
          onTap: () {
            // Handled by system
          },
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.select_all,
          label: 'Select All',
          shortcut: 'Ctrl+A',
          onTap: () {
            // Handled by system
          },
        ),
      ],
    );
  }

  Widget _buildViewMenu(BuildContext context) {
    return _MenuBarButton(
      label: 'View',
      items: [
        _MenuCheckItem(
          label: 'Binder',
          checked: showBinder,
          shortcut: 'Ctrl+B',
          onTap: onToggleBinder,
        ),
        _MenuCheckItem(
          label: 'Inspector',
          checked: showInspector,
          shortcut: 'Ctrl+I',
          onTap: onToggleInspector,
        ),
        _MenuCheckItem(
          label: 'Search',
          checked: showSearch,
          shortcut: 'Ctrl+F',
          onTap: onToggleSearch,
        ),
        _MenuCheckItem(
          label: 'Collections',
          checked: showCollections,
          onTap: onToggleCollections,
        ),
        const _MenuDivider(),
        _MenuSubMenu(
          label: 'View Mode',
          icon: Icons.view_module,
          items: [
            _MenuRadioItem(
              label: 'Editor',
              icon: Icons.edit,
              selected: viewMode == ViewMode.editor,
              onTap: () => onViewModeChanged?.call(ViewMode.editor),
            ),
            _MenuRadioItem(
              label: 'Corkboard',
              icon: Icons.dashboard,
              selected: viewMode == ViewMode.corkboard,
              onTap: () => onViewModeChanged?.call(ViewMode.corkboard),
            ),
            _MenuRadioItem(
              label: 'Outliner',
              icon: Icons.list,
              selected: viewMode == ViewMode.outliner,
              onTap: () => onViewModeChanged?.call(ViewMode.outliner),
            ),
            _MenuRadioItem(
              label: 'Scrivenings',
              icon: Icons.article,
              selected: viewMode == ViewMode.scrivenings,
              onTap: () => onViewModeChanged?.call(ViewMode.scrivenings),
            ),
          ],
        ),
        const _MenuDivider(),
        _MenuCheckItem(
          label: 'Split Editor',
          checked: splitEditorEnabled,
          onTap: onToggleSplitEditor,
        ),
      ],
    );
  }

  Widget _buildProjectMenu(BuildContext context) {
    return _MenuBarButton(
      label: 'Project',
      items: [
        _MenuItem(
          icon: Icons.publish,
          label: 'Compile...',
          shortcut: 'Ctrl+Shift+E',
          onTap: onCompile,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.track_changes,
          label: 'Writing Targets...',
          onTap: onTargets,
        ),
        _MenuItem(
          icon: Icons.timer,
          label: 'Start Session Target...',
          onTap: onSessionTarget,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.analytics,
          label: 'Project Statistics...',
          onTap: onStatistics,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.dashboard_customize,
          label: 'Template Manager...',
          onTap: onTemplateManager,
        ),
        _MenuItem(
          icon: Icons.post_add,
          label: 'Insert from Template...',
          onTap: onInsertTemplate,
        ),
      ],
    );
  }

  Widget _buildToolsMenu(BuildContext context) {
    return _MenuBarButton(
      label: 'Tools',
      items: [
        _MenuItem(
          icon: Icons.fullscreen,
          label: 'Composition Mode',
          shortcut: 'F11',
          onTap: onCompositionMode,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.person_search,
          label: 'Name Generator...',
          onTap: onNameGenerator,
        ),
        _MenuItem(
          icon: Icons.spellcheck,
          label: 'Linguistic Analysis...',
          onTap: onLinguisticAnalysis,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.label,
          label: 'Keyword Manager...',
          onTap: onKeywordManager,
        ),
        _MenuItem(
          icon: Icons.tune,
          label: 'Custom Fields...',
          onTap: onCustomFields,
        ),
      ],
    );
  }
}

/// Menu bar button that shows a dropdown when clicked
class _MenuBarButton extends StatelessWidget {
  final String label;
  final List<Widget> items;

  const _MenuBarButton({
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: '',
      offset: const Offset(0, 32),
      onSelected: (callback) => callback(),
      itemBuilder: (context) {
        final List<PopupMenuEntry<VoidCallback>> entries = [];
        for (final item in items) {
          if (item is _MenuDivider) {
            entries.add(const PopupMenuDivider());
          } else if (item is _MenuItem) {
            entries.add(PopupMenuItem<VoidCallback>(
              value: item.onTap,
              enabled: item.onTap != null,
              child: _buildMenuItemContent(item),
            ));
          } else if (item is _MenuCheckItem) {
            entries.add(PopupMenuItem<VoidCallback>(
              value: item.onTap,
              enabled: item.onTap != null,
              child: _buildCheckItemContent(item),
            ));
          } else if (item is _MenuRadioItem) {
            entries.add(PopupMenuItem<VoidCallback>(
              value: item.onTap,
              enabled: item.onTap != null,
              child: _buildRadioItemContent(item),
            ));
          } else if (item is _MenuSubMenu) {
            entries.add(PopupMenuItem<VoidCallback>(
              enabled: false,
              child: _buildSubMenuContent(context, item),
            ));
          }
        }
        return entries;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemContent(_MenuItem item) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: item.icon != null
              ? Icon(item.icon, size: 18)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(item.label)),
        if (item.shortcut != null)
          Text(
            item.shortcut!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildCheckItemContent(_MenuCheckItem item) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: item.checked
              ? const Icon(Icons.check, size: 18)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(item.label)),
        if (item.shortcut != null)
          Text(
            item.shortcut!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildRadioItemContent(_MenuRadioItem item) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: item.icon != null
              ? Icon(item.icon, size: 18)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(item.label)),
        if (item.selected)
          Icon(Icons.radio_button_checked, size: 16, color: Colors.blue[700]),
      ],
    );
  }

  Widget _buildSubMenuContent(BuildContext context, _MenuSubMenu item) {
    return PopupMenuButton<VoidCallback>(
      tooltip: '',
      offset: const Offset(200, 0),
      onSelected: (callback) {
        callback();
        Navigator.pop(context); // Close parent menu
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<VoidCallback>> entries = [];
        for (final subItem in item.items) {
          if (subItem is _MenuRadioItem) {
            entries.add(PopupMenuItem<VoidCallback>(
              value: subItem.onTap,
              child: _buildRadioItemContent(subItem),
            ));
          }
        }
        return entries;
      },
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: item.icon != null
                ? Icon(item.icon, size: 18)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(item.label)),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

/// Simple menu item
class _MenuItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? shortcut;
  final VoidCallback? onTap;

  const _MenuItem({
    this.icon,
    required this.label,
    this.shortcut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Menu divider
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Checkable menu item
class _MenuCheckItem extends StatelessWidget {
  final String label;
  final bool checked;
  final String? shortcut;
  final VoidCallback? onTap;

  const _MenuCheckItem({
    required this.label,
    this.checked = false,
    this.shortcut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Radio menu item
class _MenuRadioItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _MenuRadioItem({
    this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Submenu container
class _MenuSubMenu extends StatelessWidget {
  final IconData? icon;
  final String label;
  final List<Widget> items;

  const _MenuSubMenu({
    this.icon,
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
