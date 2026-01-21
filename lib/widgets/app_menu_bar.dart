import 'package:flutter/material.dart';
import '../models/view_mode.dart';
import '../services/scrivener_service.dart';

/// Traditional menu bar with File/Edit/View/Project/Tools menus
class AppMenuBar extends StatelessWidget {
  // Project info
  final String? projectName;
  final bool hasUnsavedChanges;

  // Project mode
  final ProjectMode projectMode;

  // File menu callbacks
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;
  final VoidCallback? onOpenProject;
  final VoidCallback? onNewProject;
  final VoidCallback? onBackups;
  final VoidCallback? onConvertToWritr;
  final VoidCallback? onClose;

  // Edit menu callbacks
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

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
  final VoidCallback? onToggleScrivenerFullEditing;
  final bool scrivenerFullEditingUnlocked;

  // Tools menu callbacks
  final VoidCallback? onCompositionMode;
  final VoidCallback? onNameGenerator;
  final VoidCallback? onLinguisticAnalysis;
  final VoidCallback? onKeywordManager;
  final VoidCallback? onCustomFields;
  final VoidCallback? onSettings;


  const AppMenuBar({
    super.key,
    // Project info
    this.projectName,
    this.hasUnsavedChanges = false,
    // Mode
    this.projectMode = ProjectMode.native,
    // File
    this.onSave,
    this.onSaveAs,
    this.onOpenProject,
    this.onNewProject,
    this.onBackups,
    this.onConvertToWritr,
    this.onClose,
    // Edit
    this.onUndo,
    this.onRedo,
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
    this.onToggleScrivenerFullEditing,
    this.scrivenerFullEditingUnlocked = false,
    // Tools
    this.onCompositionMode,
    this.onNameGenerator,
    this.onLinguisticAnalysis,
    this.onKeywordManager,
    this.onCustomFields,
    this.onSettings,
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
          // Divider after menus
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(width: 8),
          // Project name with unsaved indicator
          if (projectName != null) ...[
            Text(
              projectName!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasUnsavedChanges) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Unsaved',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
          ],
          const Spacer(),
          // Mode indicator
          _buildModeIndicator(context),
          // View mode toggle (moved to right side after mode indicator)
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
          const SizedBox(width: 8),
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

  Widget _buildModeIndicator(BuildContext context) {
    final isScrivenerProject = projectMode == ProjectMode.scrivener;
    final isUnlocked = isScrivenerProject && scrivenerFullEditingUnlocked;
    final isLocked = isScrivenerProject && !scrivenerFullEditingUnlocked;

    // Determine colors based on state
    final Color backgroundColor;
    final Color borderColor;
    final Color iconAndTextColor;
    final IconData icon;
    final String label;
    final String tooltip;

    if (isUnlocked) {
      // Scrivener project with full editing unlocked - green
      backgroundColor = Colors.green.withValues(alpha: 0.2);
      borderColor = Colors.green.shade700;
      iconAndTextColor = Colors.green.shade800;
      icon = Icons.lock_open;
      label = 'Scrivener';
      tooltip = 'Scrivener Mode: Full editing enabled (changes may not be Scrivener-compatible)';
    } else if (isLocked) {
      // Scrivener project locked - amber
      backgroundColor = Colors.amber.withValues(alpha: 0.2);
      borderColor = Colors.amber.shade700;
      iconAndTextColor = Colors.amber.shade800;
      icon = Icons.lock_outline;
      label = 'Scrivener';
      tooltip = 'Scrivener Mode: Only text editing allowed to preserve project integrity';
    } else {
      // Native Writr project
      backgroundColor = Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5);
      borderColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
      iconAndTextColor = Theme.of(context).colorScheme.primary;
      icon = Icons.edit_note;
      label = 'Writr';
      tooltip = 'Writr Mode: Full editing capabilities';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: iconAndTextColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: iconAndTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMenu(BuildContext context) {
    return _MenuBarButton(
      label: 'File',
      items: [
        _MenuItem(
          icon: Icons.create_new_folder,
          label: 'New Project...',
          shortcut: 'Ctrl+N',
          onTap: onNewProject,
        ),
        _MenuItem(
          icon: Icons.folder_open,
          label: 'Open Project...',
          shortcut: 'Ctrl+O',
          onTap: onOpenProject,
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.save,
          label: 'Save',
          shortcut: 'Ctrl+S',
          onTap: onSave,
        ),
        _MenuItem(
          icon: Icons.save_as,
          label: 'Save As...',
          shortcut: 'Ctrl+Shift+S',
          onTap: onSaveAs,
        ),
        const _MenuDivider(),
        if (projectMode == ProjectMode.scrivener)
          _MenuItem(
            icon: Icons.transform,
            label: 'Convert to Writr Format...',
            onTap: onConvertToWritr,
          ),
        if (projectMode == ProjectMode.scrivener)
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
          onTap: onUndo,
        ),
        _MenuItem(
          icon: Icons.redo,
          label: 'Redo',
          shortcut: 'Ctrl+Y',
          onTap: onRedo,
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
        if (projectMode == ProjectMode.scrivener) ...[
          const _MenuDivider(),
          _MenuCheckItem(
            label: 'Allow Full Editing',
            checked: scrivenerFullEditingUnlocked,
            onTap: onToggleScrivenerFullEditing,
          ),
        ],
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
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.settings,
          label: 'Settings...',
          onTap: onSettings,
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
      popUpAnimationStyle: AnimationStyle.noAnimation,
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
      popUpAnimationStyle: AnimationStyle.noAnimation,
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
