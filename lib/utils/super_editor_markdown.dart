import 'package:super_editor/super_editor.dart';

/// Converts a subset of Markdown into SuperEditor document structures.
///
/// Supported inline styles:
/// - Bold: `**bold**`
/// - Italic: `*italic*`
/// - Strikethrough: `~~strike~~`
/// - Underline: `<u>underline</u>`
///
/// Supported escaping for literal marker characters:
/// - `\\*`, `\\~`, `\\\\`
MutableDocument createDocumentFromMarkdown(String content) {
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  var lines = normalized.split('\n');

  // SuperEditor serializes each TextNode with a trailing '\n'. If the input
  // already ends with '\n', avoid creating an extra empty paragraph node.
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
          text: parseMarkdownInline(line),
        ),
    ],
  );
}

/// Serializes a SuperEditor [Document] to Markdown with inline style markers.
///
/// Only standard text nodes are serialized. Non-text nodes are serialized
/// as blank lines.
String markdownFromDocument(Document document) {
  final lines = <String>[];

  for (final node in document) {
    if (node is TextNode) {
      lines.add(serializeAttributedTextToMarkdown(node.text));
      continue;
    }
    lines.add('');
  }

  return lines.join('\n');
}

AttributedText parseMarkdownInline(String markdown) {
  final plainText = StringBuffer();
  final spans = AttributedSpans();

  var isBold = false;
  var isItalic = false;
  var isStrikethrough = false;
  var isUnderline = false;

  int? boldStart;
  int? italicStart;
  int? strikeStart;
  int? underlineStart;

  void closeSpan(Attribution attribution, int? start) {
    if (start == null) return;
    final end = plainText.length - 1;
    if (end < start) return;
    spans.addAttribution(newAttribution: attribution, start: start, end: end);
  }

  void toggleBold() {
    if (isBold) {
      closeSpan(boldAttribution, boldStart);
      boldStart = null;
    } else {
      boldStart = plainText.length;
    }
    isBold = !isBold;
  }

  void toggleItalic() {
    if (isItalic) {
      closeSpan(italicsAttribution, italicStart);
      italicStart = null;
    } else {
      italicStart = plainText.length;
    }
    isItalic = !isItalic;
  }

  void toggleStrikethrough() {
    if (isStrikethrough) {
      closeSpan(strikethroughAttribution, strikeStart);
      strikeStart = null;
    } else {
      strikeStart = plainText.length;
    }
    isStrikethrough = !isStrikethrough;
  }

  void openUnderline() {
    if (isUnderline) {
      // Ignore nested underline tags to avoid accidental toggling.
      return;
    }
    isUnderline = true;
    underlineStart = plainText.length;
  }

  void closeUnderline() {
    if (!isUnderline) {
      return;
    }
    closeSpan(underlineAttribution, underlineStart);
    underlineStart = null;
    isUnderline = false;
  }

  var i = 0;
  while (i < markdown.length) {
    final ch = markdown[i];

    // Escapes for literal marker chars (e.g., \*, \~, \\).
    if (ch == '\\' && i + 1 < markdown.length) {
      final next = markdown[i + 1];
      if (next == '\\' || next == '*' || next == '~') {
        plainText.write(next);
        i += 2;
        continue;
      }
    }

    if (markdown.startsWith('<u>', i)) {
      openUnderline();
      i += 3;
      continue;
    }

    if (markdown.startsWith('</u>', i)) {
      closeUnderline();
      i += 4;
      continue;
    }

    if (markdown.startsWith('~~', i)) {
      toggleStrikethrough();
      i += 2;
      continue;
    }

    if (markdown.startsWith('**', i)) {
      toggleBold();
      i += 2;
      continue;
    }

    if (ch == '*') {
      toggleItalic();
      i += 1;
      continue;
    }

    plainText.write(ch);
    i += 1;
  }

  // Close any open spans.
  closeSpan(boldAttribution, boldStart);
  closeSpan(italicsAttribution, italicStart);
  closeSpan(strikethroughAttribution, strikeStart);
  closeSpan(underlineAttribution, underlineStart);

  return AttributedText(plainText.toString(), spans);
}

String serializeAttributedTextToMarkdown(AttributedText text) {
  final str = text.toPlainText();
  if (str.isEmpty) return '';

  var prev = const _InlineStyleState();
  final buffer = StringBuffer();

  for (var i = 0; i < str.length; i++) {
    final current = _inlineStyleAt(text, i);

    if (current != prev) {
      _writeClosingMarkers(buffer, prev, current);
      _writeOpeningMarkers(buffer, prev, current);
      prev = current;
    }

    buffer.write(_escapeMarkdownChar(str[i]));
  }

  _writeClosingMarkers(buffer, prev, const _InlineStyleState());
  return buffer.toString();
}

String _escapeMarkdownChar(String ch) {
  if (ch == '\\' || ch == '*' || ch == '~') {
    return '\\$ch';
  }
  return ch;
}

_InlineStyleState _inlineStyleAt(AttributedText text, int offset) {
  final attributions = text.getAllAttributionsAt(offset);

  return _InlineStyleState(
    bold: attributions.contains(boldAttribution),
    italic: attributions.contains(italicsAttribution),
    underline: attributions.contains(underlineAttribution),
    strikethrough: attributions.contains(strikethroughAttribution),
  );
}

void _writeOpeningMarkers(
  StringBuffer buffer,
  _InlineStyleState prev,
  _InlineStyleState current,
) {
  if (!prev.underline && current.underline) {
    buffer.write('<u>');
  }
  if (!prev.strikethrough && current.strikethrough) {
    buffer.write('~~');
  }
  if (!prev.bold && current.bold) {
    buffer.write('**');
  }
  if (!prev.italic && current.italic) {
    buffer.write('*');
  }
}

void _writeClosingMarkers(
  StringBuffer buffer,
  _InlineStyleState prev,
  _InlineStyleState current,
) {
  if (prev.italic && !current.italic) {
    buffer.write('*');
  }
  if (prev.bold && !current.bold) {
    buffer.write('**');
  }
  if (prev.strikethrough && !current.strikethrough) {
    buffer.write('~~');
  }
  if (prev.underline && !current.underline) {
    buffer.write('</u>');
  }
}

class _InlineStyleState {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;

  const _InlineStyleState({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
  });

  @override
  bool operator ==(Object other) {
    return other is _InlineStyleState &&
        other.bold == bold &&
        other.italic == italic &&
        other.underline == underline &&
        other.strikethrough == strikethrough;
  }

  @override
  int get hashCode => Object.hash(bold, italic, underline, strikethrough);
}
