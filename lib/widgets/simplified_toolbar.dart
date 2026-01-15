import 'package:flutter/material.dart';
import '../models/view_mode.dart';

/// Simplified modern toolbar with grouped dropdown menus
class SimplifiedToolbar extends StatelessWidget {
  // Project info
  final String projectName;
  final bool hasUnsavedChanges;

  // View state
  final ViewMode viewMode;
  final bool showBinder;
  final bool showInspector;
  final bool showSearch;
  final bool showCollections;
  final bool splitEditorEnabled;

  // Target progress (optional)
  final double? targetProgress;

  // View callbacks
  final Function(ViewMode)? onViewModeChanged;
  final VoidCallback? onToggleBinder;
  final VoidCallback? onToggleInspector;
  final VoidCallback? onToggleSearch;
  final VoidCallback? onToggleCollections;
  final VoidCallback? onToggleSplitEditor;

  // File callbacks
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final VoidCallback? onBackups;

  // Project callbacks
  final VoidCallback? onCompile;
  final VoidCallback? onTargets;
  final VoidCallback? onSessionTarget;
  final VoidCallback? onStatistics;
  final VoidCallback? onTemplateManager;
  final VoidCallback? onInsertTemplate;

  // Tools callbacks
  final VoidCallback? onCompositionMode;
  final VoidCallback? onNameGenerator;
  final VoidCallback? onLinguisticAnalysis;
  final VoidCallback? onKeywordManager;
  final VoidCallback? onCustomFields;

  // Settings
  final VoidCallback? onSwitchToMenuBar;

  const SimplifiedToolbar({
    super.key,
    required this.projectName,
    this.hasUnsavedChanges = false,
    this.viewMode = ViewMode.editor,
    this.showBinder = true,
    this.showInspector = true,
    this.showSearch = false,
    this.showCollections = false,
    this.splitEditorEnabled = false,
    this.targetProgress,
    this.onViewModeChanged,
    this.onToggleBinder,
    this.onToggleInspector,
    this.onToggleSearch,
    this.onToggleCollections,
    this.onToggleSplitEditor,
    this.onSave,
    this.onExport,
    this.onImport,
    this.onBackups,
    this.onCompile,
    this.onTargets,
    this.onSessionTarget,
    this.onStatistics,
    this.onTemplateManager,
    this.onInsertTemplate,
    this.onCompositionMode,
    this.onNameGenerator,
    this.onLinguisticAnalysis,
    this.onKeywordManager,
    this.onCustomFields,
    this.onSwitchToMenuBar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Project name with unsaved indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                projectName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasUnsavedChanges) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
          const SizedBox(width: 8),

          // View mode toggle
          _buildViewModeToggle(context),

          const SizedBox(width: 8),

          // View dropdown (panels, split)
          _buildViewDropdown(context),

          // Project dropdown
          _buildProjectDropdown(context),

          // Tools dropdown
          _buildToolsDropdown(context),

          const Spacer(),

          // Target progress (if available)
          if (targetProgress != null) ...[
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: targetProgress!.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  targetProgress! >= 1.0 ? Colors.green : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: onSave,
            tooltip: 'Save (Ctrl+S)',
          ),

          // Compile button
          FilledButton.icon(
            onPressed: onCompile,
            icon: const Icon(Icons.publish, size: 18),
            label: const Text('Compile'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),

          const SizedBox(width: 8),

          // Switch to menu bar
          if (onSwitchToMenuBar != null)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onSwitchToMenuBar,
              tooltip: 'Switch to Menu Bar',
            ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ViewMode.values.map((mode) {
          final isSelected = viewMode == mode;
          return Tooltip(
            message: mode.tooltip,
            child: InkWell(
              onTap: () => onViewModeChanged?.call(mode),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  mode.icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'View Options',
      offset: const Offset(0, 40),
      onSelected: (value) {
        switch (value) {
          case 'binder':
            onToggleBinder?.call();
            break;
          case 'inspector':
            onToggleInspector?.call();
            break;
          case 'search':
            onToggleSearch?.call();
            break;
          case 'collections':
            onToggleCollections?.call();
            break;
          case 'split':
            onToggleSplitEditor?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildCheckMenuItem('binder', 'Binder', showBinder, Icons.folder_open),
        _buildCheckMenuItem('inspector', 'Inspector', showInspector, Icons.info_outline),
        _buildCheckMenuItem('search', 'Search', showSearch, Icons.search),
        _buildCheckMenuItem('collections', 'Collections', showCollections, Icons.collections_bookmark_outlined),
        const PopupMenuDivider(),
        _buildCheckMenuItem('split', 'Split Editor', splitEditorEnabled, Icons.vertical_split),
      ],
      child: _buildDropdownButton(context, 'View', Icons.visibility),
    );
  }

  Widget _buildProjectDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Project Options',
      offset: const Offset(0, 40),
      onSelected: (value) {
        switch (value) {
          case 'targets':
            onTargets?.call();
            break;
          case 'session':
            onSessionTarget?.call();
            break;
          case 'statistics':
            onStatistics?.call();
            break;
          case 'templates':
            onTemplateManager?.call();
            break;
          case 'insert_template':
            onInsertTemplate?.call();
            break;
          case 'backups':
            onBackups?.call();
            break;
          case 'export':
            onExport?.call();
            break;
          case 'import':
            onImport?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem('targets', 'Writing Targets...', Icons.track_changes),
        _buildMenuItem('session', 'Start Session Target...', Icons.timer),
        _buildMenuItem('statistics', 'Project Statistics...', Icons.analytics),
        const PopupMenuDivider(),
        _buildMenuItem('templates', 'Template Manager...', Icons.dashboard_customize),
        _buildMenuItem('insert_template', 'Insert from Template...', Icons.post_add),
        const PopupMenuDivider(),
        _buildMenuItem('backups', 'Backup Manager...', Icons.backup),
        _buildMenuItem('export', 'Export Project...', Icons.download),
        _buildMenuItem('import', 'Import Project...', Icons.upload),
      ],
      child: _buildDropdownButton(context, 'Project', Icons.folder_special),
    );
  }

  Widget _buildToolsDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Writing Tools',
      offset: const Offset(0, 40),
      onSelected: (value) {
        switch (value) {
          case 'composition':
            onCompositionMode?.call();
            break;
          case 'names':
            onNameGenerator?.call();
            break;
          case 'linguistic':
            onLinguisticAnalysis?.call();
            break;
          case 'keywords':
            onKeywordManager?.call();
            break;
          case 'custom_fields':
            onCustomFields?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem('composition', 'Composition Mode', Icons.fullscreen),
        const PopupMenuDivider(),
        _buildMenuItem('names', 'Name Generator...', Icons.person_search),
        _buildMenuItem('linguistic', 'Linguistic Analysis...', Icons.spellcheck),
        const PopupMenuDivider(),
        _buildMenuItem('keywords', 'Keyword Manager...', Icons.label),
        _buildMenuItem('custom_fields', 'Custom Fields...', Icons.tune),
      ],
      child: _buildDropdownButton(context, 'Tools', Icons.build),
    );
  }

  Widget _buildDropdownButton(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildCheckMenuItem(
    String value,
    String label,
    bool checked,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: checked
                ? const Icon(Icons.check, size: 18)
                : const SizedBox.shrink(),
          ),
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
