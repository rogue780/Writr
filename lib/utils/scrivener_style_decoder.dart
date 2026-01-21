import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// Scrivener style tag types
enum ScrivenerTagType {
  paragraphStyle, // <$Scr_Ps::N>
  characterStyle, // <$Scr_Cs::N>
}

/// Represents a Scrivener style tag found in text
class ScrivenerStyleTag {
  final ScrivenerTagType type;
  final int styleIndex;
  final bool isEnd; // true for <!$Scr_Ps::N> (end tag)
  final String rawTag;
  final int startOffset;
  final int endOffset;

  const ScrivenerStyleTag({
    required this.type,
    required this.styleIndex,
    required this.isEnd,
    required this.rawTag,
    required this.startOffset,
    required this.endOffset,
  });

  @override
  String toString() =>
      'ScrivenerStyleTag(${type.name}[$styleIndex], isEnd: $isEnd, "$rawTag")';
}

/// Defines how a Scrivener style should be rendered
class ScrivenerStyleDefinition {
  final String name;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final double? fontSize; // in points
  final Color? textColor;
  final bool isHeading;
  final int headingLevel; // 1-6 for headings

  const ScrivenerStyleDefinition({
    required this.name,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontSize,
    this.textColor,
    this.isHeading = false,
    this.headingLevel = 0,
  });

  /// Apply this style's formatting to an AttributedSpans builder
  Set<Attribution> toAttributions() {
    final attributions = <Attribution>{};
    if (isBold) attributions.add(boldAttribution);
    if (isItalic) attributions.add(italicsAttribution);
    if (isUnderline) attributions.add(underlineAttribution);
    // Note: fontSize and textColor would need custom attributions
    // For now we focus on basic formatting
    return attributions;
  }
}

/// Default Scrivener style mappings based on common conventions
/// These are the built-in styles Scrivener uses
class ScrivenerStyleMappings {
  // Paragraph styles (Scr_Ps)
  static const Map<int, ScrivenerStyleDefinition> paragraphStyles = {
    0: ScrivenerStyleDefinition(
      name: 'Title',
      isBold: true,
      fontSize: 24,
      isHeading: true,
      headingLevel: 1,
    ),
    1: ScrivenerStyleDefinition(
      name: 'Heading 1',
      isBold: true,
      fontSize: 18,
      isHeading: true,
      headingLevel: 1,
    ),
    2: ScrivenerStyleDefinition(
      name: 'Heading 2',
      isBold: true,
      fontSize: 16,
      isHeading: true,
      headingLevel: 2,
    ),
    3: ScrivenerStyleDefinition(
      name: 'Body',
      fontSize: 12,
    ),
    4: ScrivenerStyleDefinition(
      name: 'Block Quote',
      isItalic: true,
      fontSize: 12,
    ),
  };

  // Character styles (Scr_Cs)
  static const Map<int, ScrivenerStyleDefinition> characterStyles = {
    0: ScrivenerStyleDefinition(name: 'Default'),
    1: ScrivenerStyleDefinition(name: 'Emphasis', isItalic: true),
    2: ScrivenerStyleDefinition(name: 'Strong', isBold: true),
    3: ScrivenerStyleDefinition(name: 'Underline', isUnderline: true),
    4: ScrivenerStyleDefinition(name: 'Note', isItalic: true),
  };

  static ScrivenerStyleDefinition? getParagraphStyle(int index) =>
      paragraphStyles[index];

  static ScrivenerStyleDefinition? getCharacterStyle(int index) =>
      characterStyles[index];
}

/// Parses and processes Scrivener style tags in text
class ScrivenerStyleDecoder {
  // Regex patterns for Scrivener tags
  // Format: <$Scr_Ps::N> or <!$Scr_Ps::N> for paragraph styles
  // Format: <$Scr_Cs::N> or <!$Scr_Cs::N> for character styles
  static final _tagPattern = RegExp(
    r'<(!?)\$Scr_(Ps|Cs)::(\d+)>',
    caseSensitive: true,
  );

  /// Parse all Scrivener style tags from text
  static List<ScrivenerStyleTag> parseTags(String text) {
    final tags = <ScrivenerStyleTag>[];

    for (final match in _tagPattern.allMatches(text)) {
      final isEnd = match.group(1) == '!';
      final typeStr = match.group(2)!;
      final styleIndex = int.parse(match.group(3)!);

      tags.add(ScrivenerStyleTag(
        type: typeStr == 'Ps'
            ? ScrivenerTagType.paragraphStyle
            : ScrivenerTagType.characterStyle,
        styleIndex: styleIndex,
        isEnd: isEnd,
        rawTag: match.group(0)!,
        startOffset: match.start,
        endOffset: match.end,
      ));
    }

    return tags;
  }

  /// Remove all Scrivener style tags from text, returning clean text
  /// and a list of tags with their original positions
  static ScrivenerDecodedText decode(String text) {
    final tags = parseTags(text);
    if (tags.isEmpty) {
      return ScrivenerDecodedText(
        cleanText: text,
        tags: [],
        tagPositions: {},
      );
    }

    // Build clean text by removing tags
    final buffer = StringBuffer();
    final tagPositions = <int, List<ScrivenerStyleTag>>{};
    var lastEnd = 0;
    var cleanOffset = 0;

    for (final tag in tags) {
      // Add text before this tag
      if (tag.startOffset > lastEnd) {
        buffer.write(text.substring(lastEnd, tag.startOffset));
        cleanOffset += tag.startOffset - lastEnd;
      }

      // Record this tag's position in clean text
      tagPositions.putIfAbsent(cleanOffset, () => []).add(tag);

      lastEnd = tag.endOffset;
    }

    // Add remaining text after last tag
    if (lastEnd < text.length) {
      buffer.write(text.substring(lastEnd));
    }

    return ScrivenerDecodedText(
      cleanText: buffer.toString(),
      tags: tags,
      tagPositions: tagPositions,
    );
  }

  /// Encode tags back into text at their original positions
  /// This is used for round-trip preservation
  static String encode(ScrivenerDecodedText decoded) {
    if (decoded.tagPositions.isEmpty) {
      return decoded.cleanText;
    }

    final buffer = StringBuffer();
    var lastPos = 0;

    // Get sorted positions
    final positions = decoded.tagPositions.keys.toList()..sort();

    for (final pos in positions) {
      // Add text up to this position
      if (pos > lastPos) {
        final endPos = pos.clamp(0, decoded.cleanText.length);
        if (lastPos < endPos) {
          buffer.write(decoded.cleanText.substring(lastPos, endPos));
        }
      }

      // Add the tags at this position
      for (final tag in decoded.tagPositions[pos]!) {
        buffer.write(tag.rawTag);
      }

      lastPos = pos;
    }

    // Add remaining text
    if (lastPos < decoded.cleanText.length) {
      buffer.write(decoded.cleanText.substring(lastPos));
    }

    return buffer.toString();
  }

  /// Apply Scrivener styles to AttributedText based on decoded tags
  static AttributedText applyStylesToAttributedText(
    ScrivenerDecodedText decoded,
  ) {
    final text = decoded.cleanText;
    if (text.isEmpty) {
      return AttributedText();
    }

    final spans = AttributedSpans();

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
                _applyStyleToSpans(spans, style, startPos, pos - 1);
              }
            }
          } else {
            // Start of character style
            activeCharStyles[tag.styleIndex] = pos;
          }
        }
        // Paragraph styles are handled differently - they apply to whole paragraphs
        // For now we'll handle them as character styles spanning to next paragraph
      }
    }

    // Close any unclosed character styles at end of text
    for (final entry in activeCharStyles.entries) {
      final style = ScrivenerStyleMappings.getCharacterStyle(entry.key);
      if (style != null && text.length > entry.value) {
        _applyStyleToSpans(spans, style, entry.value, text.length - 1);
      }
    }

    return AttributedText(text, spans);
  }

  static void _applyStyleToSpans(
    AttributedSpans spans,
    ScrivenerStyleDefinition style,
    int start,
    int end,
  ) {
    if (start > end) return;

    final range = SpanRange(start, end);
    for (final attribution in style.toAttributions()) {
      spans.addAttribution(
        newAttribution: attribution,
        start: range.start,
        end: range.end,
      );
    }
  }
}

/// Result of decoding Scrivener style tags from text
class ScrivenerDecodedText {
  /// The text with all Scrivener tags removed
  final String cleanText;

  /// All tags that were found, in order
  final List<ScrivenerStyleTag> tags;

  /// Tags indexed by their position in the clean text
  /// Multiple tags can exist at the same position
  final Map<int, List<ScrivenerStyleTag>> tagPositions;

  const ScrivenerDecodedText({
    required this.cleanText,
    required this.tags,
    required this.tagPositions,
  });

  bool get hasTags => tags.isNotEmpty;
}

/// Extension to integrate with existing RTF processing
extension ScrivenerStyleExtension on String {
  /// Check if this text contains Scrivener style tags
  bool get hasScrivenerTags => ScrivenerStyleDecoder._tagPattern.hasMatch(this);

  /// Decode Scrivener tags from this text
  ScrivenerDecodedText decodeScrivenerTags() =>
      ScrivenerStyleDecoder.decode(this);
}
