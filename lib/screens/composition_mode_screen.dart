import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/scrivener_project.dart';

/// Full-screen distraction-free composition mode
class CompositionModeScreen extends StatefulWidget {
  final BinderItem document;
  final String content;
  final Function(String) onContentChanged;
  final int? targetWordCount;

  const CompositionModeScreen({
    super.key,
    required this.document,
    required this.content,
    required this.onContentChanged,
    this.targetWordCount,
  });

  @override
  State<CompositionModeScreen> createState() => _CompositionModeScreenState();
}

class _CompositionModeScreenState extends State<CompositionModeScreen> {
  late QuillController _controller;
  late FocusNode _focusNode;
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

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initializeController();
    _initialWordCount = _countWords(widget.content);
    _startHideUITimer();

    // Enter full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializeController() {
    final document = Document();
    if (widget.content.isNotEmpty) {
      document.insert(0, widget.content);
    }
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_onDocumentChanged);

    // Clear history after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.document.history.clear();
    });
  }

  @override
  void dispose() {
    _hideUITimer?.cancel();
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _focusNode.dispose();

    // Exit full screen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _onDocumentChanged() {
    final plainText = _controller.document.toPlainText();
    widget.onContentChanged(plainText);

    final currentWordCount = _countWords(plainText);
    setState(() {
      _sessionWordCount = currentWordCount - _initialWordCount;
    });
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
    return Center(
      child: Container(
        width: _textWidth,
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: QuillEditor(
          controller: _controller,
          focusNode: _focusNode,
          scrollController: ScrollController(),
          config: QuillEditorConfig(
            placeholder: 'Start writing...',
            autoFocus: true,
            expands: true,
            scrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            customStyles: DefaultStyles(
              paragraph: DefaultTextBlockStyle(
                TextStyle(
                  color: _textColor,
                  fontSize: _fontSize,
                  fontFamily: _fontFamily,
                  height: 1.8,
                ),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(12, 12),
                const VerticalSpacing(0, 0),
                null,
              ),
              placeHolder: DefaultTextBlockStyle(
                TextStyle(
                  color: _textColor.withValues(alpha: 0.3),
                  fontSize: _fontSize,
                  fontFamily: _fontFamily,
                  fontStyle: FontStyle.italic,
                ),
                const HorizontalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                const VerticalSpacing(0, 0),
                null,
              ),
            ),
          ),
        ),
      ),
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
              icon: Icon(Icons.settings, color: _textColor.withValues(alpha: 0.7)),
              onPressed: _showSettingsDialog,
              tooltip: 'Settings',
            ),

            // Typewriter mode toggle
            IconButton(
              icon: Icon(
                _typewriterMode ? Icons.vertical_align_center : Icons.vertical_align_top,
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
    final currentWordCount = _countWords(_controller.document.toPlainText());
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
    final progress = (currentWordCount / widget.targetWordCount!).clamp(0.0, 1.0);
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
                  const Text('Text Width', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('Font Size', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('Font Family', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Georgia', 'Times New Roman', 'Arial', 'Courier New']
                        .map((font) => ChoiceChip(
                              label: Text(font, style: TextStyle(fontFamily: font)),
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
                  const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
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
