import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/scrivener_service.dart';
import '../services/writr_service.dart';
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
import '../widgets/scrivener_editor.dart';
import '../utils/rtf_attributed_text.dart';
import '../widgets/inspector_panel.dart';
import '../widgets/corkboard_view.dart';
import '../widgets/outliner_view.dart';
import '../widgets/scrivenings_view.dart';
import '../widgets/split_editor.dart';
import '../widgets/research_viewer.dart';
import '../widgets/search_panel.dart';
import '../widgets/collection_list.dart';
import '../widgets/app_menu_bar.dart';
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
import '../widgets/settings_modal.dart';
import '../services/project_converter.dart';

class ProjectEditorScreen extends StatefulWidget {
  const ProjectEditorScreen({super.key});

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrivenerEditorKey = GlobalKey<ScrivenerEditorState>();
  final _richTextEditorKey = GlobalKey<RichTextEditorState>();

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
  void initState() {
    super.initState();
    // Register global keyboard handler to intercept shortcuts before SuperEditor
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  /// Global keyboard handler that intercepts shortcuts before they reach widgets
  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isModifierPressed = isControlPressed || isMetaPressed;

    if (!isModifierPressed) return false;

    // Ctrl+Z / Cmd+Z - Undo (without Shift)
    if (event.logicalKey == LogicalKeyboardKey.keyZ && !isShiftPressed) {
      debugPrint('Global handler intercepted Ctrl+Z');
      _performUndo();
      return true; // Consume the event
    }

    // Ctrl+Shift+Z / Cmd+Shift+Z - Redo
    if (event.logicalKey == LogicalKeyboardKey.keyZ && isShiftPressed) {
      debugPrint('Global handler intercepted Ctrl+Shift+Z');
      _performRedo();
      return true;
    }

    // Ctrl+Y / Cmd+Y - Redo
    if (event.logicalKey == LogicalKeyboardKey.keyY) {
      debugPrint('Global handler intercepted Ctrl+Y');
      _performRedo();
      return true;
    }

    // Ctrl+S / Cmd+S - Save (without Shift)
    if (event.logicalKey == LogicalKeyboardKey.keyS && !isShiftPressed) {
      debugPrint('Global handler intercepted Ctrl+S');
      _saveProject();
      return true;
    }

    return false; // Don't consume - let other handlers process
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ScrivenerService, PreferencesService>(
      builder: (context, service, prefs, child) {
        final projectName = service.currentProject?.name ?? 'Project';
        final hasUnsavedChanges = service.hasUnsavedChanges;
        final hasProject = service.currentProject != null;
        final useMobileUi = _useMobileUi(context);
        final colorScheme = Theme.of(context).colorScheme;

        // Keyboard shortcuts are handled by _handleGlobalKeyEvent registered in initState
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
                // Toolbar - always use menu bar (simplified toolbar disabled for now)
                ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: SafeArea(
                    bottom: false,
                    child: AppMenuBar(
                            projectName: projectName,
                            hasUnsavedChanges: hasUnsavedChanges,
                            projectMode: service.projectMode,
                            showBinder:
                                useMobileUi ? _pinBinderOnMobile : _showBinder,
                            showInspector: useMobileUi
                                ? _pinInspectorOnMobile
                                : _showInspector,
                            showSearch: _showSearch,
                            showCollections:
                                useMobileUi ? false : _showCollections,
                            viewMode: _viewMode,
                            splitEditorEnabled:
                                _splitEditorState.isSplitEnabled,
                            onSave: _saveProject,
                            onSaveAs: () => _saveProjectAs(service),
                            onOpenProject: () => _openProject(service),
                            onNewProject: () => _newProject(service),
                            onBackups: () => _openBackupManager(service),
                            onConvertToWritr: service.isScrivenerMode
                                ? () => _convertToWritr(service)
                                : null,
                            onClose: () => Navigator.pop(context),
                            onUndo: _performUndo,
                            onRedo: _performRedo,
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
                                      () =>
                                          _showCollections = !_showCollections,
                                    ),
                            onViewModeChanged: (mode) =>
                                setState(() => _viewMode = mode),
                            onToggleSplitEditor:
                                useMobileUi ? null : _toggleSplitEditor,
                            onCompile: service.currentProject != null
                                ? () =>
                                    _openCompileScreen(service.currentProject!)
                                : null,
                            onTargets: () => _openTargetsDialog(service),
                            onSessionTarget: () => _startSessionTarget(service),
                            onStatistics: () => _openStatistics(service),
                            onTemplateManager: _openTemplateManager,
                            onInsertTemplate: () =>
                                _insertFromTemplate(service),
                            onToggleScrivenerFullEditing:
                                service.projectMode == ProjectMode.scrivener
                                    ? () => _toggleScrivenerFullEditing(service)
                                    : null,
                            scrivenerFullEditingUnlocked:
                                service.isFullEditingUnlocked,
                            onCompositionMode: () =>
                                _openCompositionMode(service),
                            onNameGenerator: _openNameGenerator,
                            onLinguisticAnalysis: () =>
                                _openLinguisticAnalysis(service),
                            onKeywordManager: _openKeywordManager,
                            onCustomFields: _openCustomFieldManager,
                            onSettings: () => SettingsModal.show(context),
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
              projectMode: service.projectMode,
              isFullEditingUnlocked: service.isFullEditingUnlocked,
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
        projectMode: service.projectMode,
        isFullEditingUnlocked: service.isFullEditingUnlocked,
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
    final showInspectorPane =
        useMobileUi ? _pinInspectorOnMobile : _showInspector;

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
                _ResizeHandle(
                  onDrag: (delta) {
                    final nextWidth =
                        (prefs.binderWidth + delta).clamp(
                      _minPanelWidth,
                      _maxPanelWidth,
                    );
                    setState(() {
                      prefs.setBinderWidth(nextWidth, persist: false);
                    });
                  },
                  onDragEnd: () {
                    prefs.setBinderWidth(prefs.binderWidth);
                  },
                ),
              Expanded(
                child: _buildMainContent(service),
              ),
              // Inspector resize handle
              if (showInspectorPane)
                _ResizeHandle(
                  onDrag: (delta) {
                    final nextWidth =
                        (prefs.inspectorWidth - delta).clamp(
                      _minPanelWidth,
                      _maxPanelWidth,
                    );
                    setState(() {
                      prefs.setInspectorWidth(nextWidth, persist: false);
                    });
                  },
                  onDragEnd: () {
                    prefs.setInspectorWidth(prefs.inspectorWidth);
                  },
                ),
              // Inspector Panel
              if (showInspectorPane)
                SizedBox(
                  width: prefs.inspectorWidth,
                  child: _buildInspectorPane(service, useMobileUi: useMobileUi),
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
      projectMode: service.projectMode,
      isFullEditingUnlocked: service.isFullEditingUnlocked,
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
                  _pinBinderOnMobile ? Icons.push_pin : Icons.push_pin_outlined,
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
      projectMode: service.projectMode,
      isFullEditingUnlocked: service.isFullEditingUnlocked,
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
    final useMarkdown =
        service.currentProject?.path.toLowerCase().endsWith('.writ') ?? false;

    // Use split editor if split mode is enabled
    if (_splitEditorState.isSplitEnabled) {
      return SplitEditor(
        state: _splitEditorState,
        textContents: service.currentProject!.textContents,
        researchItems: service.currentProject!.researchItems,
        useMarkdown: useMarkdown,
        hasUnsavedChanges: service.hasUnsavedChanges,
        pageViewMode: context.watch<PreferencesService>().pageViewMode,
        onPageViewModeChanged: (enabled) {
          context.read<PreferencesService>().setPageViewMode(enabled);
        },
        onContentChanged: (documentId, content) {
          service.updateTextContent(documentId, content);
        },
        onStateChanged: (state) {
          setState(() {
            _splitEditorState = state;
            // Update selected item based on focused pane
            if (state.primaryPane.isFocused &&
                state.primaryPane.document != null) {
              _selectedItem = state.primaryPane.document;
            } else if (state.secondaryPane.isFocused &&
                state.secondaryPane.document != null) {
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

    // In Scrivener mode with RTF content, use the ScrivenerEditor for proper
    // RTF formatting round-trip support.
    if (service.isScrivenerMode && service.hasRtfContent(_selectedItem!.id)) {
      final rtfContent = service.getRawRtfContent(_selectedItem!.id) ?? '';
      return ScrivenerEditor(
        key: _scrivenerEditorKey,
        item: _selectedItem!,
        rtfContent: rtfContent,
        hasUnsavedChanges: service.hasUnsavedChanges,
        pageViewMode: context.watch<PreferencesService>().pageViewMode,
        isFullEditingUnlocked: service.isFullEditingUnlocked,
        onPageViewModeChanged: (enabled) {
          context.read<PreferencesService>().setPageViewMode(enabled);
        },
        onContentChanged: (rtfContent) {
          // Extract plain text from the RTF for storage
          final converter = RtfToAttributedText(rtfContent);
          final result = converter.convert();
          final plainText =
              result.paragraphs.map((p) => p.toPlainText()).join('\n');

          service.updateTextContentWithRtf(
            _selectedItem!.id,
            rtfContent,
            plainText,
          );
        },
      );
    }

    // Get comments for this document
    final comments = _commentService.getCommentsForDocument(_selectedItem!.id);

    return RichTextEditor(
      key: _richTextEditorKey,
      item: _selectedItem!,
      content: content,
      useMarkdown: useMarkdown,
      hasUnsavedChanges: service.hasUnsavedChanges,
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

    final useMarkdown =
        service.currentProject?.path.toLowerCase().endsWith('.writ') ?? false;
    return ScriveningsView(
      folder: folder,
      textContents: service.currentProject!.textContents,
      useMarkdown: useMarkdown,
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
        const SnackBar(
            content: Text('Select a document to enter composition mode')),
      );
      return;
    }

    final content =
        service.currentProject!.textContents[_selectedItem!.id] ?? '';
    final metadata = service.getDocumentMetadata(_selectedItem!.id);
    final useMarkdown =
        service.currentProject?.path.toLowerCase().endsWith('.writ') ?? false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompositionModeScreen(
          document: _selectedItem!,
          content: content,
          useMarkdown: useMarkdown,
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

  Future<void> _toggleScrivenerFullEditing(ScrivenerService service) async {
    if (service.isFullEditingUnlocked) {
      // Lock it back
      service.lockFullEditing();
      return;
    }

    // Show warning dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 48),
        title: const Text('Enable Full Editing?'),
        content: const Text(
          'This will allow structural changes (adding, renaming, deleting documents) '
          'to this Scrivener project.\n\n'
          'Warning: These changes may not be fully compatible with Scrivener. '
          'Consider converting to Writr format for full compatibility.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable Full Editing'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      service.unlockFullEditing();
    }
  }

  void _insertFromTemplate(ScrivenerService service) {
    if (service.currentProject == null) return;

    showDialog(
      context: context,
      builder: (context) => DocumentTemplateSelectorDialog(
        templateService: _templateService,
        onSelect: (template) {
          Navigator.pop(context);

          try {
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
              SnackBar(
                  content: Text('Created "${template.name}" from template')),
            );
          } on StateError catch (e) {
            _showScrivenerModeError(e.message);
          }
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

    final content =
        service.currentProject?.textContents[_selectedItem!.id] ?? '';

    showDialog(
      context: context,
      builder: (context) => LinguisticAnalysisDialog(
        text: content,
        documentTitle: _selectedItem!.title,
      ),
    );
  }

  void _showScrivenerModeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Learn More',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Scrivener Mode'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This project is opened in Scrivener-compatible mode to protect your original .scriv project from corruption.',
                    ),
                    SizedBox(height: 12),
                    Text(
                      'In this mode, you can:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Edit document text'),
                    Text('• Create and restore snapshots'),
                    SizedBox(height: 12),
                    Text(
                      'To make structural changes (add/delete/rename), convert to Writr format using File → Convert to Writr Format.',
                    ),
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Perform undo on the current editor (works for both .writ and .scriv modes)
  void _performUndo() {
    debugPrint('_performUndo called');
    debugPrint('  _scrivenerEditorKey.currentState: ${_scrivenerEditorKey.currentState}');
    debugPrint('  _richTextEditorKey.currentState: ${_richTextEditorKey.currentState}');

    // Try ScrivenerEditor first (for .scriv projects)
    if (_scrivenerEditorKey.currentState != null) {
      debugPrint('  Calling ScrivenerEditor.undo()');
      _scrivenerEditorKey.currentState!.undo();
      return;
    }
    // Fall back to RichTextEditor (for .writ projects)
    if (_richTextEditorKey.currentState != null) {
      debugPrint('  Calling RichTextEditor.undo()');
      _richTextEditorKey.currentState!.undo();
      return;
    }
    debugPrint('  No editor found!');
  }

  /// Perform redo on the current editor (works for both .writ and .scriv modes)
  void _performRedo() {
    debugPrint('_performRedo called');
    debugPrint('  _scrivenerEditorKey.currentState: ${_scrivenerEditorKey.currentState}');
    debugPrint('  _richTextEditorKey.currentState: ${_richTextEditorKey.currentState}');

    // Try ScrivenerEditor first (for .scriv projects)
    if (_scrivenerEditorKey.currentState != null) {
      debugPrint('  Calling ScrivenerEditor.redo()');
      _scrivenerEditorKey.currentState!.redo();
      return;
    }
    // Fall back to RichTextEditor (for .writ projects)
    if (_richTextEditorKey.currentState != null) {
      debugPrint('  Calling RichTextEditor.redo()');
      _richTextEditorKey.currentState!.redo();
      return;
    }
    debugPrint('  No editor found!');
  }

  Future<void> _saveProject() async {
    final service = context.read<ScrivenerService>();
    final writrService = context.read<WritrService>();
    final storageService = context.read<StorageAccessService>();

    final projectPath = service.currentProject?.path;
    if (projectPath == null) return;

    final hasPermission = await storageService.ensureStoragePermission(
      writableDirectory: projectPath,
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

    // Detect project format and save with appropriate service
    final format = await detectProjectFormat(projectPath);
    String? errorMessage;

    if (format == ProjectFormat.writr) {
      // Sync project state to WritrService and save as .writ format
      writrService.setProject(service.currentProject!);
      await writrService.saveProject();
      errorMessage = writrService.error;
      // Clear unsaved state in ScrivenerService too
      if (errorMessage == null) {
        service.clearUnsavedChanges();
      }
    } else {
      // Save as .scriv format
      await service.saveProject();
      errorMessage = service.error;
    }

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $errorMessage')),
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

  Future<void> _openProject(ScrivenerService service) async {
    if (kIsWeb) {
      // Web uses import flow
      await _importProject();
      return;
    }

    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Project Folder',
      );

      if (result == null) return;

      // Detect project format
      final format = await detectProjectFormat(result);

      if (format == ProjectFormat.unknown) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unknown project format. Please select a .scriv or .writ folder.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
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

      // Load project based on format
      if (format == ProjectFormat.scrivener) {
        await service.loadProject(result);

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        if (service.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening project: ${service.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Clear selection when loading new project
          setState(() {
            _selectedItem = null;
            _selectedFolder = null;
          });
        }
      } else {
        // Load .writ project using WritrService
        final writrService = context.read<WritrService>();
        await writrService.loadProject(result);

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        if (writrService.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening project: ${writrService.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (writrService.currentProject != null) {
          // Transfer the loaded project to ScrivenerService in native mode
          service.setProject(writrService.currentProject!,
              mode: ProjectMode.native);

          // Clear selection when loading new project
          setState(() {
            _selectedItem = null;
            _selectedFolder = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Opened project: ${writrService.currentProject!.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _newProject(ScrivenerService service) async {
    // Show dialog to get project name
    final projectName = await showDialog<String>(
      context: context,
      builder: (context) => _NewProjectDialog(),
    );

    if (projectName == null || projectName.isEmpty) return;

    if (kIsWeb) {
      // For web, create in-memory project
      final project = ScrivenerProject(
        name: projectName,
        path: '',
        binderItems: [
          BinderItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Manuscript',
            type: BinderItemType.folder,
            children: [
              BinderItem(
                id: '${DateTime.now().millisecondsSinceEpoch}_1',
                title: 'Chapter 1',
                type: BinderItemType.text,
                children: [],
              ),
            ],
          ),
        ],
        textContents: {
          '${DateTime.now().millisecondsSinceEpoch}_1': '',
        },
        researchItems: {},
        settings: ProjectSettings.defaults(),
      );
      service.setProject(project, mode: ProjectMode.native);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created new project: $projectName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // For desktop, let user choose location
      final outputDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose location for new project',
      );

      if (outputDir == null) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Create .writ project using WritrService
        final writrService = context.read<WritrService>();
        await writrService.createProject(projectName, outputDir);

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        if (writrService.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating project: ${writrService.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (writrService.currentProject != null) {
          // Transfer the created project to ScrivenerService in native mode
          service.setProject(writrService.currentProject!,
              mode: ProjectMode.native);

          // Clear selection
          setState(() {
            _selectedItem = null;
            _selectedFolder = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created new project: $projectName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating project: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProjectAs(ScrivenerService service) async {
    if (service.currentProject == null) return;

    if (kIsWeb) {
      // On web, Save As is the same as Export
      await _exportProject();
      return;
    }

    // For desktop, let user choose new location
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Save project to...',
    );

    if (outputDir == null) return;

    // TODO: Implement Save As with project copy
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save As functionality coming soon!'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _convertToWritr(ScrivenerService service) async {
    if (service.currentProject == null || !service.isScrivenerMode) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Writr Format'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create a copy of your project in Writr\'s native format (.writ).',
            ),
            SizedBox(height: 12),
            Text(
              'Benefits of Writr format:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Full editing capabilities (add/delete/rename documents)'),
            Text('• Markdown-based content (Git-friendly)'),
            Text('• No risk of Scrivener project corruption'),
            SizedBox(height: 12),
            Text(
              'Your original Scrivener project will not be modified.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (kIsWeb) {
      // On web, export as .writ zip
      // TODO: Implement web conversion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web conversion coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    // For desktop, let user choose output location
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose location for converted project',
    );

    if (outputDir == null) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final converter = ProjectConverter();
      final writrPath = await converter.scrivenerToWritr(
        scrivenerProject: service.currentProject!,
        outputDirectory: outputDir,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project converted successfully to: $writrPath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Ask if user wants to open the converted project
      final openConverted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conversion Complete'),
          content:
              const Text('Would you like to open the converted Writr project?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay Here'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Converted'),
            ),
          ],
        ),
      );

      if (openConverted == true) {
        // TODO: Load the converted .writ project
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening converted projects coming soon!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversion failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog for creating a new project
class _NewProjectDialog extends StatefulWidget {
  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Project Name',
          hintText: 'My Novel',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      Navigator.pop(context, name);
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
  State<_TargetsManagementDialog> createState() =>
      _TargetsManagementDialogState();
}

class _TargetsManagementDialogState extends State<_TargetsManagementDialog> {
  @override
  Widget build(BuildContext context) {
    final progressList =
        widget.targetService.getAllTargetProgress(widget.project);

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
                          Icon(Icons.track_changes,
                              size: 64, color: Colors.grey[400]),
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

/// A resize handle widget with hover feedback for panel resizing
class _ResizeHandle extends StatefulWidget {
  final void Function(double delta) onDrag;
  final VoidCallback onDragEnd;

  const _ResizeHandle({
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isDragging;
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) => widget.onDrag(details.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd();
        },
        child: Container(
          width: 8,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isActive ? 4 : 1,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.7)
                    : theme.dividerColor,
                borderRadius: isActive ? BorderRadius.circular(2) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

