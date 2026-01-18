import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/scrivener_service.dart';
import '../services/storage_access_service.dart';
import '../services/web_storage_service.dart';
import '../services/search_service.dart';
import '../services/collection_service.dart';
import '../services/comment_service.dart';
import '../services/preferences_service.dart';
import '../models/scrivener_project.dart';
import '../models/view_mode.dart';
import '../models/editor_state.dart';
import '../widgets/binder_tree_view.dart';
import '../widgets/rich_text_editor.dart';
import '../widgets/inspector_panel.dart';
import '../widgets/corkboard_view.dart';
import '../widgets/outliner_view.dart';
import '../widgets/scrivenings_view.dart';
import '../widgets/split_editor.dart';
import '../widgets/research_viewer.dart';
import '../widgets/search_panel.dart';
import '../widgets/collection_list.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/simplified_toolbar.dart';
import '../widgets/edge_panel_handle.dart';
import '../utils/web_download.dart';
import '../services/statistics_service.dart';
import '../services/target_service.dart';
import '../models/target.dart';
import '../widgets/target_progress.dart';
import 'compile_screen.dart';
import 'composition_mode_screen.dart';
import 'statistics_screen.dart';
import 'name_generator_screen.dart';
import 'backup_manager_screen.dart';
import '../services/backup_service.dart';
import '../services/template_service.dart';
import '../services/keyword_service.dart';
import '../services/custom_metadata_service.dart';
import 'template_selector_screen.dart';
import '../widgets/keyword_selector.dart';
import '../widgets/custom_metadata_editor.dart';
import '../widgets/linguistic_overlay.dart';

class ProjectEditorScreen extends StatefulWidget {
  const ProjectEditorScreen({super.key});

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  BinderItem? _selectedItem;
  BinderItem? _selectedFolder; // For folder-based views
  bool _showBinder = true;
  bool _showInspector = true;
  bool _showSearch = false;
  bool _showCollections = false;
  ViewMode _viewMode = ViewMode.editor;
  SplitEditorState _splitEditorState = const SplitEditorState();

  // Mobile pin state (phone UI uses drawers by default).
  bool _pinBinderOnMobile = false;
  bool _pinInspectorOnMobile = false;

  // Resizable panel widths (persisted via PreferencesService)
  static const double _minPanelWidth = 150;
  static const double _maxPanelWidth = 500;

  // Services for search and collections
  final SearchService _searchService = SearchService();
  final CollectionService _collectionService = CollectionService();
  final CommentService _commentService = CommentService();
  final StatisticsService _statisticsService = StatisticsService();
  final TargetService _targetService = TargetService();
  final BackupService _backupService = BackupService();
  final TemplateService _templateService = TemplateService();
  final KeywordService _keywordService = KeywordService();
  final CustomMetadataService _customMetadataService = CustomMetadataService();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ScrivenerService, PreferencesService>(
      builder: (context, service, prefs, child) {
        final projectName = service.currentProject?.name ?? 'Project';
        final hasUnsavedChanges = service.hasUnsavedChanges;
        final hasProject = service.currentProject != null;
        final useMobileUi = _useMobileUi(context);
        final toolbarStyle = prefs.toolbarStyle;

        // Calculate target progress
        double? targetProgress;
        final dailyTarget = _targetService.dailyTarget;
        if (dailyTarget != null && hasProject) {
          final progress = _targetService.getTargetProgress(
            dailyTarget,
            service.currentProject!,
          );
          targetProgress = progress.progress;
        }

        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          key: _scaffoldKey,
          drawer: useMobileUi && hasProject && !_pinBinderOnMobile
              ? Drawer(child: _buildMobileBinderDrawer(service))
              : null,
          endDrawer: useMobileUi && hasProject && !_pinInspectorOnMobile
              ? Drawer(child: _buildMobileInspectorDrawer(service))
              : null,
          body: Column(
            children: [
              // Toolbar - either menu bar or simplified
              ColoredBox(
                color: toolbarStyle == ToolbarStyle.menuBar
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface,
                child: SafeArea(
                  bottom: false,
                  child: toolbarStyle == ToolbarStyle.menuBar
                      ? AppMenuBar(
                          showBinder: useMobileUi ? _pinBinderOnMobile : _showBinder,
                          showInspector:
                              useMobileUi ? _pinInspectorOnMobile : _showInspector,
                          showSearch: _showSearch,
                          showCollections: useMobileUi ? false : _showCollections,
                          viewMode: _viewMode,
                          splitEditorEnabled: _splitEditorState.isSplitEnabled,
                          onSave: _saveProject,
                          onExport: kIsWeb ? _exportProject : null,
                          onImport: kIsWeb ? _importProject : null,
                          onBackups: () => _openBackupManager(service),
                          onClose: () => Navigator.pop(context),
                          onToggleBinder: () {
                            if (useMobileUi) {
                              if (!hasProject) {
                                return;
                              }
                              if (_pinBinderOnMobile) {
                                setState(() => _pinBinderOnMobile = false);
                                return;
                              }
                              _toggleBinderDrawer(context);
                              return;
                            }
                            setState(() => _showBinder = !_showBinder);
                          },
                          onToggleInspector: () {
                            if (useMobileUi) {
                              if (!hasProject) {
                                return;
                              }
                              if (_pinInspectorOnMobile) {
                                setState(() => _pinInspectorOnMobile = false);
                                return;
                              }
                              _toggleInspectorDrawer(context);
                              return;
                            }
                            setState(() => _showInspector = !_showInspector);
                          },
                          onToggleSearch: () =>
                              setState(() => _showSearch = !_showSearch),
                          onToggleCollections: useMobileUi
                              ? null
                              : () => setState(
                                    () => _showCollections = !_showCollections,
                                  ),
                          onViewModeChanged: (mode) =>
                              setState(() => _viewMode = mode),
                          onToggleSplitEditor:
                              useMobileUi ? null : _toggleSplitEditor,
                          onCompile: service.currentProject != null
                              ? () => _openCompileScreen(service.currentProject!)
                              : null,
                          onTargets: () => _openTargetsDialog(service),
                          onSessionTarget: () => _startSessionTarget(service),
                          onStatistics: () => _openStatistics(service),
                          onTemplateManager: _openTemplateManager,
                          onInsertTemplate: () => _insertFromTemplate(service),
                          onCompositionMode: () => _openCompositionMode(service),
                          onNameGenerator: _openNameGenerator,
                          onLinguisticAnalysis: () =>
                              _openLinguisticAnalysis(service),
                          onKeywordManager: _openKeywordManager,
                          onCustomFields: _openCustomFieldManager,
                          onSwitchToSimplifiedToolbar: () {
                            prefs.setToolbarStyle(ToolbarStyle.simplified);
                          },
                        )
                      : SimplifiedToolbar(
                          projectName: projectName,
                          hasUnsavedChanges: hasUnsavedChanges,
                          viewMode: _viewMode,
                          showBinder: useMobileUi ? _pinBinderOnMobile : _showBinder,
                          showInspector:
                              useMobileUi ? _pinInspectorOnMobile : _showInspector,
                          showSearch: _showSearch,
                          showCollections: useMobileUi ? false : _showCollections,
                          splitEditorEnabled: _splitEditorState.isSplitEnabled,
                          targetProgress: targetProgress,
                          onViewModeChanged: (mode) =>
                              setState(() => _viewMode = mode),
                          onToggleBinder: () {
                            if (useMobileUi) {
                              if (!hasProject) {
                                return;
                              }
                              if (_pinBinderOnMobile) {
                                setState(() => _pinBinderOnMobile = false);
                                return;
                              }
                              _toggleBinderDrawer(context);
                              return;
                            }
                            setState(() => _showBinder = !_showBinder);
                          },
                          onToggleInspector: () {
                            if (useMobileUi) {
                              if (!hasProject) {
                                return;
                              }
                              if (_pinInspectorOnMobile) {
                                setState(() => _pinInspectorOnMobile = false);
                                return;
                              }
                              _toggleInspectorDrawer(context);
                              return;
                            }
                            setState(() => _showInspector = !_showInspector);
                          },
                          onToggleSearch: () =>
                              setState(() => _showSearch = !_showSearch),
                          onToggleCollections: useMobileUi
                              ? null
                              : () => setState(
                                    () => _showCollections = !_showCollections,
                                  ),
                          onToggleSplitEditor:
                              useMobileUi ? null : _toggleSplitEditor,
                          onSave: _saveProject,
                          onExport: kIsWeb ? _exportProject : null,
                          onImport: kIsWeb ? _importProject : null,
                          onBackups: () => _openBackupManager(service),
                          onCompile: service.currentProject != null
                              ? () => _openCompileScreen(service.currentProject!)
                              : null,
                          onTargets: () => _openTargetsDialog(service),
                          onSessionTarget: () => _startSessionTarget(service),
                          onStatistics: () => _openStatistics(service),
                          onTemplateManager: _openTemplateManager,
                          onInsertTemplate: () => _insertFromTemplate(service),
                          onCompositionMode: () => _openCompositionMode(service),
                          onNameGenerator: _openNameGenerator,
                          onLinguisticAnalysis: () =>
                              _openLinguisticAnalysis(service),
                          onKeywordManager: _openKeywordManager,
                          onCustomFields: _openCustomFieldManager,
                          onSwitchToMenuBar: () {
                            prefs.setToolbarStyle(ToolbarStyle.menuBar);
                          },
                        ),
                ),
              ),

              // Main content
              Expanded(
                child: _buildBody(service, prefs),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _useMobileUi(BuildContext context) {
    if (kIsWeb) {
      return false;
    }

    final platform = Theme.of(context).platform;
    final isMobilePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    if (!isMobilePlatform) {
      return false;
    }

    // Treat phones as "compact"; keep side-by-side panes for tablets.
    return MediaQuery.sizeOf(context).shortestSide < 600;
  }

  void _toggleBinderDrawer(BuildContext context) {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null) {
      return;
    }

    if (scaffoldState.isEndDrawerOpen) {
      Navigator.of(context).pop();
    }

    if (scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
      return;
    }

    scaffoldState.openDrawer();
  }

  void _toggleInspectorDrawer(BuildContext context) {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null) {
      return;
    }

    if (scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    }

    if (scaffoldState.isEndDrawerOpen) {
      Navigator.of(context).pop();
      return;
    }

    scaffoldState.openEndDrawer();
  }

  void _closeOpenDrawerIfAny() {
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState == null) {
      return;
    }

    if (scaffoldState.isDrawerOpen || scaffoldState.isEndDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildMobileBinderDrawer(ScrivenerService service) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Binder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _pinBinderOnMobile
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    size: 20,
                  ),
                  tooltip: _pinBinderOnMobile ? 'Unpin' : 'Pin',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _pinBinderOnMobile = !_pinBinderOnMobile;
                      if (_pinBinderOnMobile) {
                        _pinInspectorOnMobile = false;
                      }
                    });
                    _closeOpenDrawerIfAny();
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  tooltip: 'Hide Binder',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _closeOpenDrawerIfAny,
                ),
              ],
            ),
          ),
          Expanded(
            child: BinderTreeView(
              items: service.currentProject!.binderItems,
              onItemSelected: (item) {
                _onBinderItemSelected(item);
                _closeOpenDrawerIfAny();
              },
              selectedItem: _selectedItem,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInspectorDrawer(ScrivenerService service) {
    return SafeArea(
      child: InspectorPanel(
        selectedItem: _selectedItem,
        metadata: _selectedItem != null
            ? service.getDocumentMetadata(_selectedItem!.id)
            : null,
        content: _selectedItem != null
            ? service.currentProject!.textContents[_selectedItem!.id]
            : null,
        snapshots: _selectedItem != null
            ? service.getDocumentSnapshots(_selectedItem!.id)
            : [],
        onMetadataChanged: (metadata) {
          if (_selectedItem != null) {
            service.updateDocumentMetadata(
              _selectedItem!.id,
              metadata,
            );
          }
        },
        onCreateSnapshot: _selectedItem != null
            ? () {
                service.createSnapshot(
                  _selectedItem!.id,
                  _selectedItem!.title,
                );
              }
            : null,
        onRestoreSnapshot: _selectedItem != null
            ? (snapshot) {
                service.restoreFromSnapshot(
                  _selectedItem!.id,
                  snapshot,
                );
              }
            : null,
        onDeleteSnapshot: _selectedItem != null
            ? (snapshot) {
                service.deleteSnapshot(
                  _selectedItem!.id,
                  snapshot.id,
                );
              }
            : null,
        isPinned: _pinInspectorOnMobile,
        onTogglePinned: () {
          setState(() {
            _pinInspectorOnMobile = !_pinInspectorOnMobile;
            if (_pinInspectorOnMobile) {
              _pinBinderOnMobile = false;
            }
          });
          _closeOpenDrawerIfAny();
        },
        onClose: _closeOpenDrawerIfAny,
      ),
    );
  }

  void _onBinderItemSelected(BinderItem item) {
    setState(() {
      _selectedItem = item;

      if (item.isFolder) {
        _selectedFolder = item;
      }

      if (_splitEditorState.isSplitEnabled && !item.isFolder) {
        if (_splitEditorState.primaryPane.isFocused) {
          _splitEditorState = _splitEditorState.copyWith(
            primaryPane: _splitEditorState.primaryPane.copyWith(
              document: item,
            ),
          );
        } else {
          _splitEditorState = _splitEditorState.copyWith(
            secondaryPane: _splitEditorState.secondaryPane.copyWith(
              document: item,
            ),
          );
        }
      }
    });
  }

  void _toggleSplitEditor() {
    setState(() {
      if (_splitEditorState.isSplitEnabled) {
        _splitEditorState = const SplitEditorState();
      } else {
        _splitEditorState = SplitEditorState(
          isSplitEnabled: true,
          primaryPane: EditorPaneState(
            document: _selectedItem,
            isFocused: true,
          ),
          secondaryPane: const EditorPaneState(
            isFocused: false,
          ),
        );
      }
    });
  }

  Widget _buildBody(ScrivenerService service, PreferencesService prefs) {
    if (service.currentProject == null) {
      return const Center(
        child: Text('No project loaded'),
      );
    }

    final useMobileUi = _useMobileUi(context);
    final showBinderPane = useMobileUi ? _pinBinderOnMobile : _showBinder;
    final showInspectorPane = useMobileUi ? _pinInspectorOnMobile : _showInspector;

    return Column(
      children: [
        // Search Panel (at top when visible)
        if (_showSearch)
          SearchPanel(
            project: service.currentProject!,
            searchService: _searchService,
            currentFolderId: _selectedFolder?.id,
            onNavigateToDocument: (documentId) {
              final item = _findBinderItemById(
                service.currentProject!.binderItems,
                documentId,
              );
              if (item != null) {
                setState(() {
                  _selectedItem = item;
                });
              }
            },
            onClose: () {
              setState(() {
                _showSearch = false;
              });
            },
          ),
        // Main content area
        Expanded(
          child: Row(
            children: [
              if (!showBinderPane)
                EdgePanelHandle(
                  label: 'Binder',
                  side: EdgePanelSide.left,
                  onTap: () {
                    if (useMobileUi) {
                      _toggleBinderDrawer(context);
                      return;
                    }
                    setState(() => _showBinder = true);
                  },
                ),
              // Collections panel (left side when visible)
              if (!useMobileUi && _showCollections)
                SizedBox(
                  width: 220,
                  child: CollectionList(
                    collectionService: _collectionService,
                    onCollectionSelected: (collection) {
                      // Could filter binder view to show only collection documents
                    },
                  ),
                ),
              if (!useMobileUi && _showCollections)
                const VerticalDivider(width: 1),
              // Binder
              if (showBinderPane)
                SizedBox(
                  width: prefs.binderWidth,
                  child: _buildBinderPane(service, useMobileUi: useMobileUi),
                ),
              // Binder resize handle
              if (showBinderPane)
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final nextWidth =
                          (prefs.binderWidth + details.delta.dx).clamp(
                        _minPanelWidth,
                        _maxPanelWidth,
                      );
                      setState(() {
                        prefs.setBinderWidth(nextWidth, persist: false);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      prefs.setBinderWidth(prefs.binderWidth);
                    },
                    child: Container(
                      width: 8,
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _buildMainContent(service),
              ),
              // Inspector resize handle
              if (showInspectorPane)
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final nextWidth =
                          (prefs.inspectorWidth - details.delta.dx).clamp(
                        _minPanelWidth,
                        _maxPanelWidth,
                      );
                      setState(() {
                        // Drag left increases width, drag right decreases
                        prefs.setInspectorWidth(nextWidth, persist: false);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      prefs.setInspectorWidth(prefs.inspectorWidth);
                    },
                    child: Container(
                      width: 8,
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              // Inspector Panel
              if (showInspectorPane)
                SizedBox(
                  width: prefs.inspectorWidth,
                  child:
                      _buildInspectorPane(service, useMobileUi: useMobileUi),
                ),
              if (!showInspectorPane)
                EdgePanelHandle(
                  label: 'Inspector',
                  side: EdgePanelSide.right,
                  onTap: () {
                    if (useMobileUi) {
                      _toggleInspectorDrawer(context);
                      return;
                    }
                    setState(() => _showInspector = true);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBinderPane(
    ScrivenerService service, {
    required bool useMobileUi,
  }) {
    final showHeader = useMobileUi;

    final binderTree = BinderTreeView(
      items: service.currentProject!.binderItems,
      onItemSelected: (item) {
        _onBinderItemSelected(item);
      },
      selectedItem: _selectedItem,
      onClose: useMobileUi ? null : () => setState(() => _showBinder = false),
    );

    if (!showHeader) {
      return binderTree;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Binder',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  _pinBinderOnMobile
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  size: 20,
                ),
                tooltip: _pinBinderOnMobile ? 'Unpin' : 'Pin',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _pinBinderOnMobile = !_pinBinderOnMobile;
                    if (_pinBinderOnMobile) {
                      _pinInspectorOnMobile = false;
                    }
                  });
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: 'Hide Binder',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _pinBinderOnMobile = false;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(child: binderTree),
      ],
    );
  }

  Widget _buildInspectorPane(
    ScrivenerService service, {
    required bool useMobileUi,
  }) {
    return InspectorPanel(
      selectedItem: _selectedItem,
      metadata: _selectedItem != null
          ? service.getDocumentMetadata(_selectedItem!.id)
          : null,
      content: _selectedItem != null
          ? service.currentProject!.textContents[_selectedItem!.id]
          : null,
      snapshots: _selectedItem != null
          ? service.getDocumentSnapshots(_selectedItem!.id)
          : [],
      onMetadataChanged: (metadata) {
        if (_selectedItem != null) {
          service.updateDocumentMetadata(
            _selectedItem!.id,
            metadata,
          );
        }
      },
      onCreateSnapshot: _selectedItem != null
          ? () {
              service.createSnapshot(
                _selectedItem!.id,
                _selectedItem!.title,
              );
            }
          : null,
      onRestoreSnapshot: _selectedItem != null
          ? (snapshot) {
              service.restoreFromSnapshot(
                _selectedItem!.id,
                snapshot,
              );
            }
          : null,
      onDeleteSnapshot: _selectedItem != null
          ? (snapshot) {
              service.deleteSnapshot(
                _selectedItem!.id,
                snapshot.id,
              );
            }
          : null,
      isPinned: useMobileUi ? _pinInspectorOnMobile : false,
      onTogglePinned: useMobileUi
          ? () {
              setState(() {
                _pinInspectorOnMobile = !_pinInspectorOnMobile;
                if (_pinInspectorOnMobile) {
                  _pinBinderOnMobile = false;
                }
              });
            }
          : null,
      onClose: () {
        setState(() {
          if (useMobileUi) {
            _pinInspectorOnMobile = false;
          } else {
            _showInspector = false;
          }
        });
      },
    );
  }

  /// Find a binder item by ID recursively
  BinderItem? _findBinderItemById(List<BinderItem> items, String itemId) {
    for (final item in items) {
      if (item.id == itemId) return item;
      if (item.children.isNotEmpty) {
        final found = _findBinderItemById(item.children, itemId);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Find a binder item by title recursively (returns last match)
  BinderItem? _findBinderItemByTitle(List<BinderItem> items, String title) {
    BinderItem? result;
    for (final item in items) {
      if (item.title == title) result = item;
      if (item.children.isNotEmpty) {
        final found = _findBinderItemByTitle(item.children, title);
        if (found != null) result = found;
      }
    }
    return result;
  }

  Widget _buildMainContent(ScrivenerService service) {
    switch (_viewMode) {
      case ViewMode.editor:
        return _buildEditorView(service);
      case ViewMode.corkboard:
        return _buildCorkboardView(service);
      case ViewMode.outliner:
        return _buildOutlinerView(service);
      case ViewMode.scrivenings:
        return _buildScriveningsView(service);
    }
  }

  Widget _buildEditorView(ScrivenerService service) {
    // Use split editor if split mode is enabled
    if (_splitEditorState.isSplitEnabled) {
      return SplitEditor(
        state: _splitEditorState,
        textContents: service.currentProject!.textContents,
        onContentChanged: (documentId, content) {
          service.updateTextContent(documentId, content);
        },
        onStateChanged: (state) {
          setState(() {
            _splitEditorState = state;
            // Update selected item based on focused pane
            if (state.primaryPane.isFocused && state.primaryPane.document != null) {
              _selectedItem = state.primaryPane.document;
            } else if (state.secondaryPane.isFocused && state.secondaryPane.document != null) {
              _selectedItem = state.secondaryPane.document;
            }
          });
        },
      );
    }

    // Single editor mode
    if (_selectedItem == null) {
      return const Center(
        child: Text(
          'Select a document from the binder',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Check if this is a research item (image, PDF, web archive)
    if (_selectedItem!.isResearchItem) {
      return _buildResearchView(service);
    }

    final content =
        service.currentProject!.textContents[_selectedItem!.id] ?? '';
    debugPrint(
        'Loading content for item: ${_selectedItem!.title} (ID: ${_selectedItem!.id})');
    debugPrint('Content length: ${content.length}');

    // Get comments for this document
    final comments = _commentService.getCommentsForDocument(_selectedItem!.id);

    return RichTextEditor(
      item: _selectedItem!,
      content: content,
      comments: comments,
      pageViewMode: context.watch<PreferencesService>().pageViewMode,
      onPageViewModeChanged: (enabled) {
        context.read<PreferencesService>().setPageViewMode(enabled);
      },
      onContentChanged: (content) {
        service.updateTextContent(
          _selectedItem!.id,
          content,
        );
        // Adjust comment offsets when text changes
        // Note: This is a simplified approach - a full implementation would
        // track the exact position and delta of changes
      },
      onAddComment: (startOffset, endOffset, text, color) {
        _commentService.createComment(
          documentId: _selectedItem!.id,
          startOffset: startOffset,
          endOffset: endOffset,
          commentText: text,
          colorValue: color,
        );
        setState(() {}); // Refresh to show new comment
      },
      onDeleteComment: (commentId) {
        _commentService.deleteComment(_selectedItem!.id, commentId);
        setState(() {}); // Refresh to remove comment
      },
      onResolveComment: (commentId, resolved) {
        _commentService.setCommentResolved(
          _selectedItem!.id,
          commentId,
          resolved,
        );
        setState(() {}); // Refresh to update comment state
      },
      onEditComment: (commentId, text) {
        _commentService.updateCommentText(_selectedItem!.id, commentId, text);
        setState(() {}); // Refresh to show updated comment
      },
      onReplyToComment: (commentId, replyText) {
        _commentService.createReply(
          documentId: _selectedItem!.id,
          commentId: commentId,
          text: replyText,
        );
        setState(() {}); // Refresh to show new reply
      },
    );
  }

  Widget _buildResearchView(ScrivenerService service) {
    final researchItem = service.getResearchItem(_selectedItem!.id);

    if (researchItem == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForResearchType(_selectedItem!.type),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedItem!.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Research item data not available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ResearchViewer(
      item: researchItem,
      onDelete: () {
        _confirmDeleteResearchItem(service, researchItem);
      },
      onUpdate: (updatedItem) {
        service.updateResearchItem(updatedItem);
      },
    );
  }

  void _confirmDeleteResearchItem(ScrivenerService service, researchItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Research Item'),
        content: Text(
          'Are you sure you want to delete "${researchItem.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.deleteResearchItem(researchItem.id);
              setState(() {
                _selectedItem = null;
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForResearchType(BinderItemType type) {
    switch (type) {
      case BinderItemType.image:
        return Icons.image;
      case BinderItemType.pdf:
        return Icons.picture_as_pdf;
      case BinderItemType.webArchive:
        return Icons.web;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildCorkboardView(ScrivenerService service) {
    // Use selected folder, or find first folder if none selected
    final folder = _selectedFolder ?? _findFirstFolder(service);

    if (folder == null) {
      return const Center(
        child: Text(
          'Select a folder to view its contents',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return CorkboardView(
      folder: folder,
      metadata: service.currentProject!.documentMetadata,
      selectedItem: _selectedItem,
      onItemSelected: (item) {
        setState(() {
          _selectedItem = item;
        });
      },
      onItemDoubleClicked: (item) {
        setState(() {
          _selectedItem = item;
          if (item.isFolder) {
            _selectedFolder = item;
          } else {
            // Switch to editor mode to edit the document
            _viewMode = ViewMode.editor;
          }
        });
      },
      onMetadataChanged: (documentId, metadata) {
        service.updateDocumentMetadata(documentId, metadata);
      },
    );
  }

  Widget _buildOutlinerView(ScrivenerService service) {
    final folder = _selectedFolder ?? _findFirstFolder(service);

    if (folder == null) {
      return const Center(
        child: Text(
          'Select a folder to view its contents',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return OutlinerView(
      folder: folder,
      textContents: service.currentProject!.textContents,
      metadata: service.currentProject!.documentMetadata,
      selectedItem: _selectedItem,
      onItemSelected: (item) {
        setState(() {
          _selectedItem = item;
        });
      },
      onItemDoubleClicked: (item) {
        setState(() {
          _selectedItem = item;
          if (item.isFolder) {
            _selectedFolder = item;
          } else {
            _viewMode = ViewMode.editor;
          }
        });
      },
      onMetadataChanged: (documentId, metadata) {
        service.updateDocumentMetadata(documentId, metadata);
      },
    );
  }

  Widget _buildScriveningsView(ScrivenerService service) {
    final folder = _selectedFolder ?? _findFirstFolder(service);

    if (folder == null) {
      return const Center(
        child: Text(
          'Select a folder to edit its documents',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ScriveningsView(
      folder: folder,
      textContents: service.currentProject!.textContents,
      onContentChanged: (documentId, content) {
        service.updateTextContent(documentId, content);
      },
      onDocumentTapped: (document) {
        setState(() {
          _selectedItem = document;
        });
      },
    );
  }

  BinderItem? _findFirstFolder(ScrivenerService service) {
    if (service.currentProject == null) return null;

    for (final item in service.currentProject!.binderItems) {
      if (item.isFolder) return item;
    }
    return null;
  }

  void _openCompositionMode(ScrivenerService service) {
    if (_selectedItem == null || _selectedItem!.isFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a document to enter composition mode')),
      );
      return;
    }

    final content = service.currentProject!.textContents[_selectedItem!.id] ?? '';
    final metadata = service.getDocumentMetadata(_selectedItem!.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompositionModeScreen(
          document: _selectedItem!,
          content: content,
          targetWordCount: metadata.wordCountTarget,
          onContentChanged: (newContent) {
            service.updateTextContent(_selectedItem!.id, newContent);
          },
        ),
      ),
    );
  }

  void _openStatistics(ScrivenerService service) {
    if (service.currentProject == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          project: service.currentProject!,
          statisticsService: _statisticsService,
        ),
      ),
    );
  }

  void _openNameGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NameGeneratorScreen(),
      ),
    );
  }

  void _openTargetsDialog(ScrivenerService service) {
    if (service.currentProject == null) return;

    showDialog(
      context: context,
      builder: (context) => _TargetsManagementDialog(
        targetService: _targetService,
        project: service.currentProject!,
        documents: _getAllDocuments(service.currentProject!.binderItems),
      ),
    );
  }

  void _startSessionTarget(ScrivenerService service) async {
    if (service.currentProject == null) return;

    // Get current word count
    int currentWordCount = 0;
    for (final content in service.currentProject!.textContents.values) {
      currentWordCount += _countWords(content);
    }

    final targetWords = await showDialog<int>(
      context: context,
      builder: (context) => const SessionTargetDialog(),
    );

    if (targetWords != null && targetWords > 0) {
      _targetService.startSessionTarget(
        targetWords: targetWords,
        currentWordCount: currentWordCount,
      );
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session target started: $targetWords words'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _openTargetsDialog(service),
            ),
          ),
        );
      }
    }
  }

  List<BinderItem> _getAllDocuments(List<BinderItem> items) {
    final documents = <BinderItem>[];
    for (final item in items) {
      if (!item.isFolder) {
        documents.add(item);
      }
      if (item.children.isNotEmpty) {
        documents.addAll(_getAllDocuments(item.children));
      }
    }
    return documents;
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  void _openBackupManager(ScrivenerService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupManagerScreen(
          backupService: _backupService,
          currentProject: service.currentProject,
          onRestoreProject: (project) {
            // Handle restored project
            service.setProject(project);
          },
        ),
      ),
    );
  }

  void _openTemplateManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateManagerScreen(
          templateService: _templateService,
        ),
      ),
    );
  }

  void _insertFromTemplate(ScrivenerService service) {
    if (service.currentProject == null) return;

    showDialog(
      context: context,
      builder: (context) => DocumentTemplateSelectorDialog(
        templateService: _templateService,
        onSelect: (template) {
          Navigator.pop(context);

          // Add the document to the project
          service.addBinderItem(
            title: template.name,
            type: BinderItemType.text,
            parentId: _selectedFolder?.id,
          );

          // Find the newly added item (last item with this title)
          final newItem = _findBinderItemByTitle(
            service.currentProject!.binderItems,
            template.name,
          );

          // Set the content from template
          if (newItem != null) {
            service.updateTextContent(newItem.id, template.content);

            // Select the new document
            setState(() {
              _selectedItem = newItem;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created "${template.name}" from template')),
          );
        },
      ),
    );
  }

  void _openKeywordManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeywordManagerScreen(
          keywordService: _keywordService,
        ),
      ),
    );
  }

  void _openCustomFieldManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomFieldManagerScreen(
          metadataService: _customMetadataService,
        ),
      ),
    );
  }

  void _openLinguisticAnalysis(ScrivenerService service) {
    if (_selectedItem == null || _selectedItem!.isFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a document to analyze')),
      );
      return;
    }

    final content = service.currentProject?.textContents[_selectedItem!.id] ?? '';

    showDialog(
      context: context,
      builder: (context) => LinguisticAnalysisDialog(
        text: content,
        documentTitle: _selectedItem!.title,
      ),
    );
  }

  Future<void> _saveProject() async {
    final service = context.read<ScrivenerService>();
    final storageService = context.read<StorageAccessService>();

    final hasPermission = await storageService.ensureStoragePermission(
      writableDirectory: service.currentProject?.path,
    );
    if (!mounted) return;
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storageService.error ?? 'Storage permission is required to save.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => storageService.openPermissionSettings(),
          ),
        ),
      );
      return;
    }

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

  void _openCompileScreen(ScrivenerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompileScreen(project: project),
      ),
    );
  }

  Future<void> _exportProject() async {
    final service = context.read<ScrivenerService>();
    final webStorage = context.read<WebStorageService>();

    if (service.currentProject == null) return;

    try {
      // Export project as zip
      final zipBytes = webStorage.exportProject(service.currentProject!);

      // Trigger download in browser
      downloadBytes(zipBytes, '${service.currentProject!.name}.scriv.zip');

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

      final projectName =
          file.name.replaceAll('.scriv.zip', '').replaceAll('.zip', '');
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

/// Dialog for managing writing targets
class _TargetsManagementDialog extends StatefulWidget {
  final TargetService targetService;
  final ScrivenerProject project;
  final List<BinderItem> documents;

  const _TargetsManagementDialog({
    required this.targetService,
    required this.project,
    required this.documents,
  });

  @override
  State<_TargetsManagementDialog> createState() => _TargetsManagementDialogState();
}

class _TargetsManagementDialogState extends State<_TargetsManagementDialog> {
  @override
  Widget build(BuildContext context) {
    final progressList = widget.targetService.getAllTargetProgress(widget.project);

    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.track_changes, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Writing Targets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Session target if active
            if (widget.targetService.sessionTarget != null) ...[
              SessionTargetWidget(
                session: widget.targetService.sessionTarget!,
                onEnd: () {
                  widget.targetService.endSessionTarget();
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
            ],

            // Targets list
            Expanded(
              child: progressList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.track_changes, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No targets set',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a target to track your writing progress',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: progressList.length,
                      itemBuilder: (context, index) {
                        final progress = progressList[index];
                        return TargetProgressCard(
                          progress: progress,
                          onEdit: () => _editTarget(progress.target),
                          onDelete: () => _deleteTarget(progress.target.id),
                        );
                      },
                    ),
            ),

            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Target'),
                  onPressed: _addTarget,
                ),
                const SizedBox(width: 8),
                if (widget.targetService.activeTargets.isEmpty)
                  FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Create Default Targets'),
                    onPressed: () {
                      widget.targetService.createDefaultTargets();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTarget() async {
    final target = await showDialog<WritingTarget>(
      context: context,
      builder: (context) => TargetEditDialog(
        documents: widget.documents,
      ),
    );

    if (target != null) {
      widget.targetService.updateTarget(target);
      setState(() {});
    }
  }

  Future<void> _editTarget(WritingTarget target) async {
    final updatedTarget = await showDialog<WritingTarget>(
      context: context,
      builder: (context) => TargetEditDialog(
        target: target,
        documents: widget.documents,
      ),
    );

    if (updatedTarget != null) {
      widget.targetService.updateTarget(updatedTarget);
      setState(() {});
    }
  }

  void _deleteTarget(String targetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Target'),
        content: const Text('Are you sure you want to delete this target?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.targetService.deleteTarget(targetId);
              setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
