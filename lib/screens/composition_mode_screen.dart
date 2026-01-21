import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:super_editor/super_editor.dart';
import '../models/scrivener_project.dart';
import '../services/dictionary_service.dart';
import '../services/preferences_service.dart';
import '../services/spell_check_service.dart' as spell;
import '../utils/super_editor_markdown.dart';
import '../widgets/spell_check_style_phase.dart';
import '../widgets/super_editor_style_phases.dart';

/// Full-screen distraction-free composition mode
class CompositionModeScreen extends StatefulWidget {
  final BinderItem document;
  final String content;
  final bool useMarkdown;
  final Function(String) onContentChanged;
  final int? targetWordCount;

  const CompositionModeScreen({
    super.key,
    required this.document,
    required this.content,
    this.useMarkdown = false,
    required this.onContentChanged,
    this.targetWordCount,
  });

  @override
  State<CompositionModeScreen> createState() => _CompositionModeScreenState();
}

class _CompositionModeScreenState extends State<CompositionModeScreen> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  final _documentLayoutKey = GlobalKey();
  late final List<SingleColumnLayoutStylePhase> _customStylePhases;
  bool _showUI = true;
  Timer? _hideUITimer;
  bool _typewriterMode = true;
  double _textWidth = 700;
  Color _backgroundColor = const Color(0xFF1A1A2E);
  Color _textColor = const Color(0xFFE8E8E8);
  double _fontSize = 18;
  String _fontFamily = 'Georgia';

  // Session statistics
  int _sessionWordCount = 0;
  int _initialWordCount = 0;
  final DateTime _sessionStart = DateTime.now();

  // Spell check
  spell.SpellCheckService? _spellCheckService;
  SpellCheckStylePhase? _spellCheckStylePhase;
  bool _spellCheckInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _customStylePhases = [ClampInvalidTextSelectionStylePhase()];
    _initializeEditor();
    _initialWordCount = _countWords(_document.toPlainText());
    _startHideUITimer();
    _initSpellCheck();

    // Enter full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initSpellCheck() async {
    try {
      final dictionary = await DictionaryService.getInstance();
      if (!mounted) return;

      _spellCheckService = spell.SpellCheckService(dictionary);
      _spellCheckStylePhase = SpellCheckStylePhase(
        spellCheckService: _spellCheckService!,
        enabled: true,
      );

      _spellCheckService!.addListener(_onSpellCheckUpdate);

      setState(() {
        _spellCheckInitialized = true;
        _customStylePhases.add(_spellCheckStylePhase!);
      });

      _triggerSpellCheck();
    } catch (e) {
      debugPrint('Spell check initialization failed: $e');
    }
  }

  void _onSpellCheckUpdate() {
    if (!mounted || _spellCheckStylePhase == null) return;
    _spellCheckStylePhase!.syncErrors(_document);
    setState(() {});
  }

  void _triggerSpellCheck() {
    if (_spellCheckService == null || !_spellCheckInitialized) return;
    final text = _document.toPlainText();
    _spellCheckService!.checkText(text);
  }

  void _initializeEditor() {
    _document = _createDocumentFromContent(widget.content);
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );

    _document.addListener(_onDocumentChangeLog);
  }

  MutableDocument _createDocumentFromContent(String content) {
    if (widget.useMarkdown) {
      return createDocumentFromMarkdown(content);
    }

    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    var lines = normalized.split('\n');

    if (normalized.endsWith('\n') && lines.isNotEmpty && lines.last.isEmpty) {
      lines = lines.sublist(0, lines.length - 1);
    }

    if (lines.isEmpty) {
      return MutableDocument.empty();
    }

    return MutableDocument(
      nodes: [
        for (final line in lines)
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText(line),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _hideUITimer?.cancel();
    _document.removeListener(_onDocumentChangeLog);
    _spellCheckService?.removeListener(_onSpellCheckUpdate);
    _spellCheckService?.dispose();
    _document.dispose();
    _composer.dispose();
    _focusNode.dispose();
    _scrollController.dispose();

    // Exit full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _onDocumentChangeLog(DocumentChangeLog changeLog) {
    final newContent = widget.useMarkdown
        ? markdownFromDocument(_document)
        : _document.toPlainText();
    widget.onContentChanged(newContent);

    final plainText = _document.toPlainText();
    final currentWordCount = _countWords(plainText);
    setState(() {
      _sessionWordCount = currentWordCount - _initialWordCount;
    });

    // Trigger spell check on document changes
    _triggerSpellCheck();
  }

  void _startHideUITimer() {
    _hideUITimer?.cancel();
    _hideUITimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showUI = false;
        });
      }
    });
  }

  void _onMouseMove(PointerEvent event) {
    if (!_showUI) {
      setState(() {
        _showUI = true;
      });
    }
    _startHideUITimer();
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: _onMouseMove,
        onEnter: _onMouseMove,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showUI = true;
            });
            _startHideUITimer();
          },
          child: Container(
            color: _backgroundColor,
            child: Stack(
              children: [
                // Main editor
                _buildEditor(),

                // Top bar (fades in/out)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _showUI ? 0 : -60,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(),
                ),

                // Bottom progress bar (fades in/out)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  bottom: _showUI ? 0 : -50,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    // Update spell check based on preferences
    final prefs = context.watch<PreferencesService>();
    _spellCheckStylePhase?.setEnabled(prefs.spellCheckEnabled);

    return Center(
      child: Container(
        width: _textWidth,
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              SuperEditor(
                editor: _editor,
                focusNode: _focusNode,
                autofocus: true,
                scrollController: _scrollController,
                documentLayoutKey: _documentLayoutKey,
                stylesheet: _buildEditorStylesheet(),
                customStylePhases: _customStylePhases,
              ),
              if (_document.toPlainText().trim().isEmpty)
                Positioned(
                  left: 0,
                  top: 0,
                  child: IgnorePointer(
                    child: Text(
                      'Start writing...',
                      style: TextStyle(
                        color: _textColor.withValues(alpha: 0.3),
                        fontSize: _fontSize,
                        fontFamily: _fontFamily,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Stylesheet _buildEditorStylesheet() {
    final textStyle = TextStyle(
      color: _textColor,
      fontSize: _fontSize,
      fontFamily: _fontFamily,
      height: 1.8,
    );

    return defaultStylesheet.copyWith(
      documentPadding: EdgeInsets.zero,
      rules: [
        StyleRule(
          BlockSelector.all,
          (doc, docNode) => {
            Styles.maxWidth: double.infinity,
            Styles.padding: const CascadingPadding.all(0),
            Styles.textStyle: textStyle,
          },
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _backgroundColor,
            _backgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Exit button
            IconButton(
              icon: Icon(Icons.close, color: _textColor.withValues(alpha: 0.7)),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Exit Composition Mode',
            ),
            const SizedBox(width: 16),

            // Document title
            Expanded(
              child: Text(
                widget.document.title,
                style: TextStyle(
                  color: _textColor.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Settings button
            IconButton(
              icon: Icon(Icons.settings,
                  color: _textColor.withValues(alpha: 0.7)),
              onPressed: _showSettingsDialog,
              tooltip: 'Settings',
            ),

            // Typewriter mode toggle
            IconButton(
              icon: Icon(
                _typewriterMode
                    ? Icons.vertical_align_center
                    : Icons.vertical_align_top,
                color: _textColor.withValues(alpha: _typewriterMode ? 1 : 0.5),
              ),
              onPressed: () {
                setState(() {
                  _typewriterMode = !_typewriterMode;
                });
              },
              tooltip: 'Typewriter Mode',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final currentWordCount = _countWords(_document.toPlainText());
    final sessionDuration = DateTime.now().difference(_sessionStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _backgroundColor,
            _backgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar (if target is set)
            if (widget.targetWordCount != null && widget.targetWordCount! > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProgressBar(currentWordCount),
              ),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  Icons.text_fields,
                  '$currentWordCount words',
                ),
                const SizedBox(width: 16),
                _buildStatChip(
                  _sessionWordCount >= 0 ? Icons.add : Icons.remove,
                  '${_sessionWordCount.abs()} this session',
                  color: _sessionWordCount >= 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatChip(
                  Icons.timer,
                  _formatDuration(sessionDuration),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int currentWordCount) {
    final progress =
        (currentWordCount / widget.targetWordCount!).clamp(0.0, 1.0);
    final progressColor = progress >= 1.0 ? Colors.green : Colors.blue;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentWordCount / ${widget.targetWordCount} words',
              style: TextStyle(
                color: _textColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: progressColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _textColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, {Color? color}) {
    final chipColor = color ?? _textColor.withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: chipColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: chipColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Composition Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text width slider
                  const Text('Text Width',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _textWidth,
                    min: 400,
                    max: 1000,
                    divisions: 12,
                    label: '${_textWidth.toInt()}px',
                    onChanged: (value) {
                      setDialogState(() {
                        _textWidth = value;
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // Font size slider
                  const Text('Font Size',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _fontSize,
                    min: 14,
                    max: 28,
                    divisions: 14,
                    label: '${_fontSize.toInt()}pt',
                    onChanged: (value) {
                      setDialogState(() {
                        _fontSize = value;
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // Font family
                  const Text('Font Family',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        ['Georgia', 'Times New Roman', 'Arial', 'Courier New']
                            .map((font) => ChoiceChip(
                                  label: Text(font,
                                      style: TextStyle(fontFamily: font)),
                                  selected: _fontFamily == font,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() {
                                        _fontFamily = font;
                                      });
                                      setState(() {});
                                    }
                                  },
                                ))
                            .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Background color presets
                  const Text('Theme',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildThemeOption(
                        'Dark Blue',
                        const Color(0xFF1A1A2E),
                        const Color(0xFFE8E8E8),
                        setDialogState,
                      ),
                      _buildThemeOption(
                        'Dark',
                        const Color(0xFF121212),
                        const Color(0xFFE0E0E0),
                        setDialogState,
                      ),
                      _buildThemeOption(
                        'Sepia',
                        const Color(0xFFF4ECD8),
                        const Color(0xFF5C4033),
                        setDialogState,
                      ),
                      _buildThemeOption(
                        'Light',
                        const Color(0xFFFAFAFA),
                        const Color(0xFF212121),
                        setDialogState,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    String name,
    Color bgColor,
    Color txtColor,
    StateSetter setDialogState,
  ) {
    final isSelected = _backgroundColor == bgColor;

    return InkWell(
      onTap: () {
        setDialogState(() {
          _backgroundColor = bgColor;
          _textColor = txtColor;
        });
        setState(() {});
      },
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Aa',
            style: TextStyle(
              color: txtColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
