import 'dart:ui';
import 'package:super_editor/super_editor.dart';
import '../services/spell_check_service.dart';

/// A style phase that integrates our SpellCheckService with SuperEditor's
/// built-in spelling error underline rendering.
///
/// This uses SuperEditor's SpellingAndGrammarStyler internally but provides
/// a simpler API that works with our SpellCheckService.
class SpellCheckStylePhase extends SingleColumnLayoutStylePhase {
  SpellCheckStylePhase({
    required this.spellCheckService,
    this.enabled = true,
  }) : _styler = SpellingAndGrammarStyler();

  final SpellCheckService spellCheckService;
  bool enabled;

  final SpellingAndGrammarStyler _styler;

  // Cache of document text positions for each node
  final Map<String, int> _nodeStartOffsets = {};

  /// Update the style phase with current document structure
  void updateNodeOffsets(Document document) {
    _nodeStartOffsets.clear();

    int offset = 0;
    for (int i = 0; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node == null) continue;

      _nodeStartOffsets[node.id] = offset;
      if (node is TextNode) {
        offset += node.text.length + 1; // +1 for paragraph separator
      }
    }
  }

  /// Sync spelling errors from our service to the styler
  void syncErrors(Document document) {
    if (!enabled) {
      _styler.clearAllErrors();
      return;
    }

    updateNodeOffsets(document);
    _styler.clearAllErrors();

    final errors = spellCheckService.errors;
    if (errors.isEmpty) return;

    // Group errors by node
    for (int i = 0; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node == null || node is! TextNode) continue;

      final nodeStart = _nodeStartOffsets[node.id] ?? 0;
      final nodeEnd = nodeStart + node.text.length;

      final nodeErrors = <TextError>{};

      for (final error in errors) {
        // Check if error falls within this node's text range
        if (error.range.start >= nodeStart && error.range.end <= nodeEnd) {
          // Convert global offset to node-local offset
          final localStart = error.range.start - nodeStart;
          final localEnd = error.range.end - nodeStart;

          // Validate range is within node text
          if (localStart >= 0 && localEnd <= node.text.length) {
            // DON'T access error.suggestions here - it triggers expensive computation!
            // Suggestions are only needed for context menus, not for rendering underlines
            nodeErrors.add(TextError.spelling(
              nodeId: node.id,
              range: TextRange(start: localStart, end: localEnd),
              value: error.word,
              suggestions: const [], // Empty - load lazily when needed
            ));
          }
        }
      }

      if (nodeErrors.isNotEmpty) {
        _styler.addErrors(node.id, nodeErrors);
      }
    }
  }

  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    if (!enabled) {
      return viewModel;
    }

    // Delegate to the internal styler
    return _styler.style(document, viewModel);
  }

  /// Clear all spelling errors
  void clearErrors() {
    _styler.clearAllErrors();
    markDirty();
  }

  /// Toggle spell checking on/off
  void setEnabled(bool value) {
    if (enabled == value) return;
    enabled = value;
    if (!enabled) {
      _styler.clearAllErrors();
    }
    markDirty();
  }
}
