import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import '../models/rtf_metadata.dart';
import 'scrivener_style_decoder.dart';

// ============================================================================
// RTF Tokenization
// ============================================================================

bool _isHexDigit(String c) =>
    (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) ||
    (c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x46) ||
    (c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x66);

bool _isAsciiLetter(String c) =>
    (c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x5A) ||
    (c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x7A);

bool _isDigit(String c) =>
    c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

String _decodeCp1252Byte(int byteValue) {
  const map = <int, int>{
    0x80: 0x20AC, 0x82: 0x201A, 0x83: 0x0192, 0x84: 0x201E,
    0x85: 0x2026, 0x86: 0x2020, 0x87: 0x2021, 0x88: 0x02C6,
    0x89: 0x2030, 0x8A: 0x0160, 0x8B: 0x2039, 0x8C: 0x0152,
    0x8E: 0x017D, 0x91: 0x2018, 0x92: 0x2019, 0x93: 0x201C,
    0x94: 0x201D, 0x95: 0x2022, 0x96: 0x2013, 0x97: 0x2014,
    0x98: 0x02DC, 0x99: 0x2122, 0x9A: 0x0161, 0x9B: 0x203A,
    0x9C: 0x0153, 0x9E: 0x017E, 0x9F: 0x0178,
  };
  return String.fromCharCode(map[byteValue] ?? byteValue);
}

/// Token types for RTF parsing.
enum RtfTokenType { groupStart, groupEnd, control, text }

/// A single RTF token.
class RtfToken {
  final RtfTokenType type;
  final String raw;

  /// For control words: the word without backslash (e.g., "b", "i", "fs")
  final String? word;

  /// For control words with parameters: the numeric value
  final int? param;

  const RtfToken(this.type, this.raw, {this.word, this.param});

  bool get isControlWord => type == RtfTokenType.control && word != null;
  bool get isText => type == RtfTokenType.text;
  bool get isGroupStart => type == RtfTokenType.groupStart;
  bool get isGroupEnd => type == RtfTokenType.groupEnd;

  @override
  String toString() {
    if (word != null) {
      return 'RtfToken(control: $word${param != null ? "=$param" : ""})';
    }
    return 'RtfToken($type: ${raw.length > 20 ? "${raw.substring(0, 20)}..." : raw})';
  }
}

/// Tokenizes RTF content into a list of tokens.
List<RtfToken> tokenizeRtf(String rtf) {
  final tokens = <RtfToken>[];
  final textBuffer = StringBuffer();

  void flushText() {
    if (textBuffer.isEmpty) return;
    tokens.add(RtfToken(RtfTokenType.text, textBuffer.toString()));
    textBuffer.clear();
  }

  var i = 0;
  while (i < rtf.length) {
    final ch = rtf[i];

    if (ch == '{') {
      flushText();
      tokens.add(const RtfToken(RtfTokenType.groupStart, '{'));
      i++;
      continue;
    }

    if (ch == '}') {
      flushText();
      tokens.add(const RtfToken(RtfTokenType.groupEnd, '}'));
      i++;
      continue;
    }

    if (ch != '\\') {
      textBuffer.write(ch);
      i++;
      continue;
    }

    flushText();
    final start = i;
    i++; // consume backslash
    if (i >= rtf.length) {
      tokens.add(RtfToken(RtfTokenType.control, rtf.substring(start)));
      break;
    }

    final next = rtf[i];

    // Hex escape: \'hh
    if (next == "'" &&
        i + 2 < rtf.length &&
        _isHexDigit(rtf[i + 1]) &&
        _isHexDigit(rtf[i + 2])) {
      i += 3;
      tokens.add(RtfToken(RtfTokenType.control, rtf.substring(start, i)));
      continue;
    }

    // Single-character control symbols
    if (!_isAsciiLetter(next)) {
      i++;
      tokens.add(RtfToken(RtfTokenType.control, rtf.substring(start, i)));
      continue;
    }

    // Control word: \wordN?
    final wordStart = i;
    while (i < rtf.length && _isAsciiLetter(rtf[i])) {
      i++;
    }
    final word = rtf.substring(wordStart, i);

    int? paramValue;
    var paramSign = 1;

    if (i < rtf.length && (rtf[i] == '-' || rtf[i] == '+')) {
      paramSign = rtf[i] == '-' ? -1 : 1;
      i++;
    }

    final digitStart = i;
    while (i < rtf.length && _isDigit(rtf[i])) {
      i++;
    }
    if (i > digitStart) {
      paramValue = int.parse(rtf.substring(digitStart, i)) * paramSign;
    }

    // Space after control word is delimiter, consume it
    if (i < rtf.length && rtf[i] == ' ') {
      i++;
    }

    tokens.add(RtfToken(
      RtfTokenType.control,
      rtf.substring(start, i),
      word: word,
      param: paramValue,
    ));
  }

  flushText();
  return tokens;
}

// ============================================================================
// Format State Tracking
// ============================================================================

/// Tracks the current formatting state while parsing RTF.
class RtfFormatState {
  bool bold;
  bool italic;
  bool underline;
  bool strikethrough;
  bool superscript;
  bool subscript;
  double? fontSize; // In points (RTF uses half-points)
  int? fontIndex;
  int? colorIndex;
  int? highlightIndex;

  RtfFormatState({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.superscript = false,
    this.subscript = false,
    this.fontSize,
    this.fontIndex,
    this.colorIndex,
    this.highlightIndex,
  });

  RtfFormatState copy() => RtfFormatState(
        bold: bold,
        italic: italic,
        underline: underline,
        strikethrough: strikethrough,
        superscript: superscript,
        subscript: subscript,
        fontSize: fontSize,
        fontIndex: fontIndex,
        colorIndex: colorIndex,
        highlightIndex: highlightIndex,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtfFormatState &&
          runtimeType == other.runtimeType &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          strikethrough == other.strikethrough &&
          superscript == other.superscript &&
          subscript == other.subscript &&
          fontSize == other.fontSize &&
          fontIndex == other.fontIndex &&
          colorIndex == other.colorIndex &&
          highlightIndex == other.highlightIndex;

  @override
  int get hashCode => Object.hash(
        bold, italic, underline, strikethrough,
        superscript, subscript, fontSize,
        fontIndex, colorIndex, highlightIndex,
      );
}

// ============================================================================
// Custom Attributions for RTF-specific formatting
// ============================================================================

/// Attribution for font size in points (RTF-specific).
class RtfFontSizeAttribution implements Attribution {
  final double fontSize;

  const RtfFontSizeAttribution(this.fontSize);

  @override
  String get id => 'rtfFontSize_$fontSize';

  @override
  bool canMergeWith(Attribution other) =>
      other is RtfFontSizeAttribution && other.fontSize == fontSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtfFontSizeAttribution && other.fontSize == fontSize;

  @override
  int get hashCode => fontSize.hashCode;
}

/// Attribution for text color (RTF-specific).
class RtfTextColorAttribution implements Attribution {
  final Color color;

  const RtfTextColorAttribution(this.color);

  @override
  String get id => 'rtfTextColor_${color.toHex()}';

  @override
  bool canMergeWith(Attribution other) =>
      other is RtfTextColorAttribution && other.color == color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtfTextColorAttribution && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// Attribution for background/highlight color (RTF-specific).
class RtfBackgroundColorAttribution implements Attribution {
  final Color color;

  const RtfBackgroundColorAttribution(this.color);

  @override
  String get id => 'rtfBackgroundColor_${color.toHex()}';

  @override
  bool canMergeWith(Attribution other) =>
      other is RtfBackgroundColorAttribution && other.color == color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtfBackgroundColorAttribution && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// Attribution for font family (RTF-specific).
class RtfFontFamilyAttribution implements Attribution {
  final String fontFamily;

  const RtfFontFamilyAttribution(this.fontFamily);

  @override
  String get id => 'rtfFontFamily_$fontFamily';

  @override
  bool canMergeWith(Attribution other) =>
      other is RtfFontFamilyAttribution && other.fontFamily == fontFamily;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtfFontFamilyAttribution && other.fontFamily == fontFamily;

  @override
  int get hashCode => fontFamily.hashCode;
}

/// Attribution for superscript text (RTF-specific).
const rtfSuperscriptAttribution = NamedAttribution('rtfSuperscript');

/// Attribution for subscript text (RTF-specific).
const rtfSubscriptAttribution = NamedAttribution('rtfSubscript');

extension on Color {
  String toHex() {
    final r = (this.r * 255).round().clamp(0, 255);
    final g = (this.g * 255).round().clamp(0, 255);
    final b = (this.b * 255).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }
}

// ============================================================================
// RTF → AttributedText Converter
// ============================================================================

/// Result of converting RTF to AttributedText.
class RtfConversionResult {
  /// The converted document as a list of paragraphs with attributed text.
  final List<AttributedText> paragraphs;

  /// Extracted metadata (font table, color table) for round-trip.
  final RtfMetadata metadata;

  /// Scrivener style tag data for each paragraph (for round-trip preservation).
  /// Only populated if decodeScrivenerTags() was called.
  final List<ScrivenerDecodedText>? scrivenerTagData;

  const RtfConversionResult({
    required this.paragraphs,
    required this.metadata,
    this.scrivenerTagData,
  });

  /// Decode Scrivener style tags from the text, removing them from display
  /// but preserving them for round-trip. Returns a new result with clean text
  /// and applied formatting.
  RtfConversionResult decodeScrivenerTags() {
    final decodedParagraphs = <AttributedText>[];
    final tagData = <ScrivenerDecodedText>[];

    for (final paragraph in paragraphs) {
      final text = paragraph.toPlainText();
      final decoded = ScrivenerStyleDecoder.decode(text);
      tagData.add(decoded);

      if (!decoded.hasTags) {
        // No tags, keep original paragraph
        decodedParagraphs.add(paragraph);
        continue;
      }

      // Build new attributed text with tags removed and styles applied
      final newSpans = AttributedSpans();

      // First, copy existing attributions, adjusting positions for removed tags
      _copyAttributionsWithTagRemoval(paragraph, decoded, newSpans);

      // Then apply Scrivener style formatting
      _applyScrivenerStyles(decoded, newSpans);

      decodedParagraphs.add(AttributedText(decoded.cleanText, newSpans));
    }

    return RtfConversionResult(
      paragraphs: decodedParagraphs,
      metadata: metadata,
      scrivenerTagData: tagData,
    );
  }

  /// Copy attributions from original paragraph, adjusting positions for removed tags
  static void _copyAttributionsWithTagRemoval(
    AttributedText original,
    ScrivenerDecodedText decoded,
    AttributedSpans newSpans,
  ) {
    final originalText = original.toPlainText();
    if (originalText.isEmpty || decoded.cleanText.isEmpty) return;

    // Build a mapping from original positions to clean positions
    final positionMap = <int, int>{};
    var cleanPos = 0;
    var origPos = 0;

    // Sort tags by start position
    final sortedTags = decoded.tags.toList()
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    var tagIndex = 0;

    while (origPos < originalText.length) {
      // Check if we're at a tag
      if (tagIndex < sortedTags.length &&
          origPos == sortedTags[tagIndex].startOffset) {
        // Skip the tag
        origPos = sortedTags[tagIndex].endOffset;
        tagIndex++;
        continue;
      }

      positionMap[origPos] = cleanPos;
      origPos++;
      cleanPos++;
    }

    // Get all attribution spans and copy them with adjusted positions
    final allSpans = original.getAttributionSpansByFilter((_) => true);

    for (final span in allSpans) {
      final newStart = positionMap[span.start];
      final newEnd = positionMap[span.end];

      if (newStart != null && newEnd != null && newStart <= newEnd) {
        newSpans.addAttribution(
          newAttribution: span.attribution,
          start: newStart,
          end: newEnd,
        );
      }
    }
  }

  /// Apply Scrivener styles based on decoded tags
  static void _applyScrivenerStyles(
    ScrivenerDecodedText decoded,
    AttributedSpans spans,
  ) {
    // Track active character styles with their start positions
    final activeCharStyles = <int, int>{}; // styleIndex -> startPosition

    // Sort all tag positions
    final sortedPositions = decoded.tagPositions.keys.toList()..sort();

    for (final pos in sortedPositions) {
      final tagsAtPos = decoded.tagPositions[pos]!;

      for (final tag in tagsAtPos) {
        if (tag.type == ScrivenerTagType.characterStyle) {
          if (tag.isEnd) {
            // End of character style - apply formatting from start to here
            final startPos = activeCharStyles.remove(tag.styleIndex);
            if (startPos != null && pos > startPos) {
              final style =
                  ScrivenerStyleMappings.getCharacterStyle(tag.styleIndex);
              if (style != null) {
                for (final attr in style.toAttributions()) {
                  spans.addAttribution(
                    newAttribution: attr,
                    start: startPos,
                    end: pos - 1, // SuperEditor uses inclusive end
                  );
                }
              }
            }
          } else {
            // Start of character style
            activeCharStyles[tag.styleIndex] = pos;
          }
        }
        // Paragraph styles apply to the whole paragraph
        // They're handled separately when rendering
      }
    }

    // Close any unclosed character styles at end of text
    final textLength = decoded.cleanText.length;
    for (final entry in activeCharStyles.entries) {
      final style = ScrivenerStyleMappings.getCharacterStyle(entry.key);
      if (style != null && textLength > entry.value) {
        for (final attr in style.toAttributions()) {
          spans.addAttribution(
            newAttribution: attr,
            start: entry.value,
            end: textLength - 1,
          );
        }
      }
    }
  }
}

/// Converts RTF content to SuperEditor's AttributedText with full formatting.
class RtfToAttributedText {
  final String rtf;

  // Parsed tables
  final List<RtfFont> _fontTable = [];
  final List<Color?> _colorTable = [];
  int _defaultFontIndex = 0;

  RtfToAttributedText(this.rtf);

  /// Parse only the header to extract metadata without converting content.
  RtfMetadata parseHeader() {
    if (!rtf.trimLeft().startsWith(r'{\rtf')) {
      return RtfMetadata.empty();
    }

    final tokens = tokenizeRtf(rtf);
    _parseHeaderTables(tokens);

    return RtfMetadata(
      fontTable: List.unmodifiable(_fontTable),
      colorTable: List.unmodifiable(_colorTable),
      defaultFontIndex: _defaultFontIndex,
    );
  }

  /// Convert RTF to attributed text paragraphs.
  RtfConversionResult convert() {
    if (!rtf.trimLeft().startsWith(r'{\rtf')) {
      // Not RTF, treat as plain text
      return RtfConversionResult(
        paragraphs: [AttributedText(rtf)],
        metadata: RtfMetadata.empty(),
      );
    }

    final tokens = tokenizeRtf(rtf);
    _parseHeaderTables(tokens);

    final paragraphs = <AttributedText>[];
    final currentText = StringBuffer();
    final currentSpans = <_AttributionSpan>[];
    var state = RtfFormatState();
    final stateStack = <RtfFormatState>[];
    var position = 0;

    final ignoreStack = <bool>[];
    var ignoreGroup = false;
    var groupStart = false;

    var ucSkipCount = 1;
    var pendingAnsiSkip = 0;

    void finalizeParagraph({bool allowEmpty = false}) {
      if (currentText.isEmpty && currentSpans.isEmpty) {
        // Only add empty paragraph if explicitly allowed (for \par handling)
        if (allowEmpty) {
          paragraphs.add(AttributedText(''));
        }
        return;
      }

      final text = currentText.toString();
      final attributedSpans = AttributedSpans();

      for (final span in currentSpans) {
        if (span.start < span.end && span.end <= text.length) {
          attributedSpans.addAttribution(
            newAttribution: span.attribution,
            start: span.start,
            end: span.end - 1, // SuperEditor uses inclusive end
          );
        }
      }

      paragraphs.add(AttributedText(text, attributedSpans));
      currentText.clear();
      currentSpans.clear();
      position = 0;
    }

    void emitChar(String char, {bool countsAsAnsi = true}) {
      if (countsAsAnsi && pendingAnsiSkip > 0) {
        pendingAnsiSkip--;
        return;
      }
      if (ignoreGroup) return;

      // Handle paragraph breaks
      if (char == '\n') {
        // Close any open spans at current position
        _closeSpansAtPosition(currentSpans, position, state);
        finalizeParagraph(allowEmpty: true);
        // Reopen spans for new paragraph
        _openSpansForState(currentSpans, 0, state);
        return;
      }

      currentText.write(char);
      position++;
    }

    for (final token in tokens) {
      if (token.isGroupStart) {
        stateStack.add(state.copy());
        ignoreStack.add(ignoreGroup);
        groupStart = true;
        continue;
      }

      if (token.isGroupEnd) {
        // Close spans before state change
        _closeSpansAtPosition(currentSpans, position, state);

        if (stateStack.isNotEmpty) {
          state = stateStack.removeLast();
        }
        ignoreGroup = ignoreStack.isNotEmpty ? ignoreStack.removeLast() : false;
        groupStart = false;

        // Reopen spans with restored state
        _openSpansForState(currentSpans, position, state);
        continue;
      }

      if (token.isText) {
        for (var i = 0; i < token.raw.length; i++) {
          final ch = token.raw[i];
          // Skip raw whitespace in RTF
          if (ch == '\r' || ch == '\n' || ch == '\t') continue;
          if (groupStart && ch == ' ') continue;

          emitChar(ch);
          groupStart = false;
        }
        continue;
      }

      // Control token
      if (token.type == RtfTokenType.control) {
        final raw = token.raw;
        if (raw.length < 2) {
          groupStart = false;
          continue;
        }

        final second = raw[1];

        // Hex escape
        if (second == "'" && raw.length >= 4) {
          final value = int.parse(raw.substring(2, 4), radix: 16);
          emitChar(_decodeCp1252Byte(value));
          groupStart = false;
          continue;
        }

        // Control symbols
        if (!_isAsciiLetter(second)) {
          if (second == '\\' || second == '{' || second == '}') {
            emitChar(second);
          } else if (second == '~') {
            emitChar(' ');
          } else if (second == '_') {
            emitChar('-');
          } else if (second == '*') {
            ignoreGroup = true;
          }
          groupStart = false;
          continue;
        }

        // Control word
        final word = token.word;
        final param = token.param;

        // Check for destinations to ignore
        if (groupStart && _isIgnoredDestination(word)) {
          ignoreGroup = true;
          groupStart = false;
          continue;
        }

        // Apply formatting
        final oldState = state.copy();
        _applyControlWord(state, word, param);

        // If state changed, close old spans and open new ones
        if (state != oldState) {
          _closeSpansAtPosition(currentSpans, position, oldState);
          _openSpansForState(currentSpans, position, state);
        }

        // Handle special content-emitting control words
        if (word == 'par' || word == 'line') {
          emitChar('\n', countsAsAnsi: false);
        } else if (word == 'tab') {
          emitChar('\t', countsAsAnsi: false);
        } else if (word == 'uc' && param != null) {
          ucSkipCount = param.clamp(0, 16);
        } else if (word == 'u' && param != null) {
          var codeUnit = param;
          if (codeUnit < 0) codeUnit = 65536 + codeUnit;
          emitChar(String.fromCharCode(codeUnit), countsAsAnsi: false);
          pendingAnsiSkip = ucSkipCount;
        }

        groupStart = false;
      }
    }

    // Finalize last paragraph
    _closeSpansAtPosition(currentSpans, position, state);
    finalizeParagraph();

    return RtfConversionResult(
      paragraphs: paragraphs,
      metadata: RtfMetadata(
        fontTable: List.unmodifiable(_fontTable),
        colorTable: List.unmodifiable(_colorTable),
        defaultFontIndex: _defaultFontIndex,
      ),
    );
  }

  void _parseHeaderTables(List<RtfToken> tokens) {
    var i = 0;

    // Find \deff parameter
    while (i < tokens.length) {
      final token = tokens[i];
      if (token.word == 'deff' && token.param != null) {
        _defaultFontIndex = token.param!;
        break;
      }
      if (token.isText && token.raw.trim().isNotEmpty) break;
      i++;
    }

    // Parse font table
    _parseFontTable(tokens);

    // Parse color table
    _parseColorTable(tokens);
  }

  void _parseFontTable(List<RtfToken> tokens) {
    // Find {\fonttbl ...}
    var depth = 0;
    var inFontTable = false;

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.isGroupStart) {
        depth++;
        if (i + 1 < tokens.length && tokens[i + 1].word == 'fonttbl') {
          inFontTable = true;
        }
        continue;
      }

      if (token.isGroupEnd) {
        depth--;
        if (inFontTable && depth == 1) {
          // End of font table
          break;
        }
        continue;
      }

      if (!inFontTable) continue;

      // Parse font entries: {\f0\fswiss Arial;}
      if (token.word == 'f' && token.param != null) {
        final fontIndex = token.param!;
        String? fontFamily;
        String fontName = '';

        // Look ahead for family and name
        for (var j = i + 1; j < tokens.length; j++) {
          final t = tokens[j];
          if (t.isGroupEnd) break;
          if (t.word == 'fnil') fontFamily = 'nil';
          if (t.word == 'froman') fontFamily = 'roman';
          if (t.word == 'fswiss') fontFamily = 'swiss';
          if (t.word == 'fmodern') fontFamily = 'modern';
          if (t.word == 'fscript') fontFamily = 'script';
          if (t.word == 'fdecor') fontFamily = 'decor';
          if (t.word == 'ftech') fontFamily = 'tech';
          if (t.word == 'fbidi') fontFamily = 'bidi';
          if (t.isText) {
            fontName += t.raw.replaceAll(';', '').trim();
          }
        }

        if (fontName.isNotEmpty) {
          _fontTable.add(RtfFont(
            index: fontIndex,
            name: fontName,
            family: fontFamily,
          ));
        }
      }
    }
  }

  void _parseColorTable(List<RtfToken> tokens) {
    // Find {\colortbl ...}
    var depth = 0;
    var inColorTable = false;

    int? red, green, blue;

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token.isGroupStart) {
        depth++;
        if (i + 1 < tokens.length && tokens[i + 1].word == 'colortbl') {
          inColorTable = true;
          // Don't add null here - let the semicolon handling add entries
        }
        continue;
      }

      if (token.isGroupEnd) {
        depth--;
        if (inColorTable && depth == 1) {
          // Finalize last color if pending
          if (red != null || green != null || blue != null) {
            _colorTable.add(Color.fromARGB(
              255,
              red ?? 0,
              green ?? 0,
              blue ?? 0,
            ));
          }
          break;
        }
        continue;
      }

      if (!inColorTable) continue;

      if (token.word == 'red') red = token.param ?? 0;
      if (token.word == 'green') green = token.param ?? 0;
      if (token.word == 'blue') blue = token.param ?? 0;

      // Semicolon ends a color entry
      if (token.isText && token.raw.contains(';')) {
        if (red != null || green != null || blue != null) {
          _colorTable.add(Color.fromARGB(
            255,
            red ?? 0,
            green ?? 0,
            blue ?? 0,
          ));
        } else {
          // Auto color (semicolon with no color values)
          _colorTable.add(null);
        }
        red = green = blue = null;
      }
    }
  }

  bool _isIgnoredDestination(String? word) {
    const ignored = {
      'fonttbl', 'colortbl', 'stylesheet', 'info', 'pict',
      'object', 'datastore', 'themedata', 'colorschememapping',
      'latentstyles', 'datafield', 'formfield',
    };
    return word != null && ignored.contains(word);
  }

  void _applyControlWord(RtfFormatState state, String? word, int? param) {
    if (word == null) return;

    switch (word) {
      // Bold
      case 'b':
        state.bold = param != 0;
        break;
      // Italic
      case 'i':
        state.italic = param != 0;
        break;
      // Underline
      case 'ul':
        state.underline = true;
        break;
      case 'ulnone':
        state.underline = false;
        break;
      // Strikethrough
      case 'strike':
        state.strikethrough = param != 0;
        break;
      // Superscript/subscript
      case 'super':
        state.superscript = true;
        state.subscript = false;
        break;
      case 'sub':
        state.subscript = true;
        state.superscript = false;
        break;
      case 'nosupersub':
        state.superscript = false;
        state.subscript = false;
        break;
      // Font size (half-points -> points)
      case 'fs':
        state.fontSize = param != null ? param / 2.0 : null;
        break;
      // Font index
      case 'f':
        state.fontIndex = param;
        break;
      // Color index
      case 'cf':
        state.colorIndex = param;
        break;
      // Highlight color
      case 'highlight':
        state.highlightIndex = param;
        break;
      // Plain (reset all formatting)
      case 'plain':
        state.bold = false;
        state.italic = false;
        state.underline = false;
        state.strikethrough = false;
        state.superscript = false;
        state.subscript = false;
        state.fontSize = null;
        state.fontIndex = null;
        state.colorIndex = null;
        state.highlightIndex = null;
        break;
    }
  }

  void _closeSpansAtPosition(
    List<_AttributionSpan> spans,
    int position,
    RtfFormatState state,
  ) {
    // Find open spans and close them
    for (final span in spans) {
      if (span.end == -1) {
        span.end = position;
      }
    }
  }

  void _openSpansForState(
    List<_AttributionSpan> spans,
    int position,
    RtfFormatState state,
  ) {
    if (state.bold) {
      spans.add(_AttributionSpan(boldAttribution, position));
    }
    if (state.italic) {
      spans.add(_AttributionSpan(italicsAttribution, position));
    }
    if (state.underline) {
      spans.add(_AttributionSpan(underlineAttribution, position));
    }
    if (state.strikethrough) {
      spans.add(_AttributionSpan(strikethroughAttribution, position));
    }
    if (state.superscript) {
      spans.add(_AttributionSpan(rtfSuperscriptAttribution, position));
    }
    if (state.subscript) {
      spans.add(_AttributionSpan(rtfSubscriptAttribution, position));
    }
    if (state.fontSize != null) {
      spans.add(_AttributionSpan(RtfFontSizeAttribution(state.fontSize!), position));
    }
    if (state.colorIndex != null && state.colorIndex! > 0) {
      final color = _colorTable.length > state.colorIndex!
          ? _colorTable[state.colorIndex!]
          : null;
      if (color != null) {
        spans.add(_AttributionSpan(RtfTextColorAttribution(color), position));
      }
    }
    if (state.highlightIndex != null && state.highlightIndex! > 0) {
      final color = _colorTable.length > state.highlightIndex!
          ? _colorTable[state.highlightIndex!]
          : null;
      if (color != null) {
        spans.add(_AttributionSpan(RtfBackgroundColorAttribution(color), position));
      }
    }
    if (state.fontIndex != null) {
      final font = _fontTable.where((f) => f.index == state.fontIndex).firstOrNull;
      if (font != null) {
        spans.add(_AttributionSpan(RtfFontFamilyAttribution(font.name), position));
      }
    }
  }
}

/// Helper class for tracking attribution spans during parsing.
class _AttributionSpan {
  final Attribution attribution;
  final int start;
  int end;

  _AttributionSpan(this.attribution, this.start) : end = -1;
}

// ============================================================================
// AttributedText → RTF Converter
// ============================================================================

/// Converts SuperEditor's AttributedText back to RTF with formatting preserved.
class AttributedTextToRtf {
  final List<AttributedText> paragraphs;
  final RtfMetadata metadata;

  AttributedTextToRtf(this.paragraphs, {RtfMetadata? metadata})
      : metadata = metadata ?? RtfMetadata.empty();

  /// Convert to RTF string.
  String convert() {
    final buffer = StringBuffer();

    // RTF header
    buffer.write(r'{\rtf1\ansi\deff');
    buffer.write(metadata.defaultFontIndex);

    // Font table
    _writeFontTable(buffer);

    // Color table
    _writeColorTable(buffer);

    // Content
    buffer.write(r'\viewkind4\uc1\pard ');

    for (var i = 0; i < paragraphs.length; i++) {
      if (i > 0) {
        buffer.write(r'\par ');
      }
      _writeParagraph(buffer, paragraphs[i]);
    }

    buffer.write('}');
    return buffer.toString();
  }

  void _writeFontTable(StringBuffer buffer) {
    if (metadata.fontTable.isEmpty) {
      // Default font table
      buffer.write(r'{\fonttbl{\f0 Calibri;}}');
      return;
    }

    buffer.write(r'{\fonttbl');
    for (final font in metadata.fontTable) {
      buffer.write(r'{\f');
      buffer.write(font.index);
      if (font.family != null) {
        buffer.write(r'\f');
        buffer.write(font.family);
      }
      buffer.write(' ');
      buffer.write(font.name);
      buffer.write(';}');
    }
    buffer.write('}');
  }

  void _writeColorTable(StringBuffer buffer) {
    if (metadata.colorTable.isEmpty) return;

    buffer.write(r'{\colortbl');
    for (final color in metadata.colorTable) {
      if (color == null) {
        buffer.write(';');
      } else {
        buffer.write(r'\red');
        buffer.write((color.r * 255).round().clamp(0, 255));
        buffer.write(r'\green');
        buffer.write((color.g * 255).round().clamp(0, 255));
        buffer.write(r'\blue');
        buffer.write((color.b * 255).round().clamp(0, 255));
        buffer.write(';');
      }
    }
    buffer.write('}');
  }

  void _writeParagraph(StringBuffer buffer, AttributedText text) {
    final str = text.toPlainText();
    if (str.isEmpty) return;

    var prevState = _StateAtPosition();

    for (var i = 0; i < str.length; i++) {
      final currentState = _getStateAtPosition(text, i);

      // Emit state changes
      if (currentState != prevState) {
        _emitStateChange(buffer, prevState, currentState);
        prevState = currentState;
      }

      // Emit character
      _emitChar(buffer, str[i]);
    }

    // Reset formatting at end
    if (prevState.hasFormatting) {
      buffer.write(r'\plain ');
    }
  }

  _StateAtPosition _getStateAtPosition(AttributedText text, int offset) {
    final attributions = text.getAllAttributionsAt(offset);

    return _StateAtPosition(
      bold: attributions.contains(boldAttribution),
      italic: attributions.contains(italicsAttribution),
      underline: attributions.contains(underlineAttribution),
      strikethrough: attributions.contains(strikethroughAttribution),
      superscript: attributions.contains(rtfSuperscriptAttribution),
      subscript: attributions.contains(rtfSubscriptAttribution),
      fontSize: attributions
          .whereType<RtfFontSizeAttribution>()
          .firstOrNull
          ?.fontSize,
      textColor: attributions
          .whereType<RtfTextColorAttribution>()
          .firstOrNull
          ?.color,
      backgroundColor: attributions
          .whereType<RtfBackgroundColorAttribution>()
          .firstOrNull
          ?.color,
      fontFamily: attributions
          .whereType<RtfFontFamilyAttribution>()
          .firstOrNull
          ?.fontFamily,
    );
  }

  void _emitStateChange(
    StringBuffer buffer,
    _StateAtPosition prev,
    _StateAtPosition current,
  ) {
    // Bold
    if (current.bold != prev.bold) {
      buffer.write(current.bold ? r'\b ' : r'\b0 ');
    }

    // Italic
    if (current.italic != prev.italic) {
      buffer.write(current.italic ? r'\i ' : r'\i0 ');
    }

    // Underline
    if (current.underline != prev.underline) {
      buffer.write(current.underline ? r'\ul ' : r'\ulnone ');
    }

    // Strikethrough
    if (current.strikethrough != prev.strikethrough) {
      buffer.write(current.strikethrough ? r'\strike ' : r'\strike0 ');
    }

    // Superscript/subscript
    if (current.superscript != prev.superscript ||
        current.subscript != prev.subscript) {
      if (current.superscript) {
        buffer.write(r'\super ');
      } else if (current.subscript) {
        buffer.write(r'\sub ');
      } else {
        buffer.write(r'\nosupersub ');
      }
    }

    // Font size
    if (current.fontSize != prev.fontSize) {
      if (current.fontSize != null) {
        buffer.write(r'\fs');
        buffer.write((current.fontSize! * 2).round());
        buffer.write(' ');
      }
    }

    // Text color
    if (current.textColor != prev.textColor) {
      if (current.textColor != null) {
        final colorIndex = _findOrAddColor(current.textColor!);
        buffer.write(r'\cf');
        buffer.write(colorIndex);
        buffer.write(' ');
      } else {
        buffer.write(r'\cf0 ');
      }
    }

    // Background color
    if (current.backgroundColor != prev.backgroundColor) {
      if (current.backgroundColor != null) {
        final colorIndex = _findOrAddColor(current.backgroundColor!);
        buffer.write(r'\highlight');
        buffer.write(colorIndex);
        buffer.write(' ');
      } else {
        buffer.write(r'\highlight0 ');
      }
    }

    // Font family
    if (current.fontFamily != prev.fontFamily) {
      if (current.fontFamily != null) {
        final fontIndex = metadata.indexOfFont(current.fontFamily!);
        if (fontIndex >= 0) {
          buffer.write(r'\f');
          buffer.write(fontIndex);
          buffer.write(' ');
        }
      }
    }
  }

  int _findOrAddColor(Color color) {
    final existing = metadata.indexOfColor(color);
    if (existing >= 0) return existing;
    // If not found, return 0 (auto)
    return 0;
  }

  void _emitChar(StringBuffer buffer, String char) {
    switch (char) {
      case '\\':
        buffer.write(r'\\');
        break;
      case '{':
        buffer.write(r'\{');
        break;
      case '}':
        buffer.write(r'\}');
        break;
      case '\n':
        // Already handled at paragraph level
        break;
      case '\t':
        buffer.write(r'\tab ');
        break;
      default:
        final codeUnit = char.codeUnitAt(0);
        if (codeUnit >= 0x20 && codeUnit <= 0x7E) {
          buffer.write(char);
        } else {
          // Unicode escape
          final signed = codeUnit > 0x7FFF ? codeUnit - 0x10000 : codeUnit;
          buffer.write(r'\u');
          buffer.write(signed);
          buffer.write('?');
        }
    }
  }
}

/// Helper class for tracking formatting state at a position.
class _StateAtPosition {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final bool superscript;
  final bool subscript;
  final double? fontSize;
  final Color? textColor;
  final Color? backgroundColor;
  final String? fontFamily;

  _StateAtPosition({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.superscript = false,
    this.subscript = false,
    this.fontSize,
    this.textColor,
    this.backgroundColor,
    this.fontFamily,
  });

  bool get hasFormatting =>
      bold ||
      italic ||
      underline ||
      strikethrough ||
      superscript ||
      subscript ||
      fontSize != null ||
      textColor != null ||
      backgroundColor != null ||
      fontFamily != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StateAtPosition &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          strikethrough == other.strikethrough &&
          superscript == other.superscript &&
          subscript == other.subscript &&
          fontSize == other.fontSize &&
          textColor == other.textColor &&
          backgroundColor == other.backgroundColor &&
          fontFamily == other.fontFamily;

  @override
  int get hashCode => Object.hash(
        bold, italic, underline, strikethrough,
        superscript, subscript, fontSize,
        textColor, backgroundColor, fontFamily,
      );
}
