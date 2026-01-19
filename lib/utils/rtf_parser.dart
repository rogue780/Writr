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
    0x80: 0x20AC, // €
    0x82: 0x201A,
    0x83: 0x0192,
    0x84: 0x201E,
    0x85: 0x2026,
    0x86: 0x2020,
    0x87: 0x2021,
    0x88: 0x02C6,
    0x89: 0x2030,
    0x8A: 0x0160,
    0x8B: 0x2039,
    0x8C: 0x0152,
    0x8E: 0x017D,
    0x91: 0x2018,
    0x92: 0x2019,
    0x93: 0x201C,
    0x94: 0x201D,
    0x95: 0x2022,
    0x96: 0x2013,
    0x97: 0x2014,
    0x98: 0x02DC,
    0x99: 0x2122,
    0x9A: 0x0161,
    0x9B: 0x203A,
    0x9C: 0x0153,
    0x9E: 0x017E,
    0x9F: 0x0178,
  };

  final codePoint = map[byteValue] ?? byteValue;
  return String.fromCharCode(codePoint);
}

const _ignoredDestinations = <String>{
  'fonttbl',
  'colortbl',
  'stylesheet',
  'info',
  'pict',
  'object',
  'datastore',
};

/// Basic RTF to plain text converter.
///
/// This is intentionally lightweight (no external deps), but handles the common
/// Scrivener/Windows cases like:
/// - `\'hh` hex escapes (e.g. `\'93` -> “)
/// - `\uN?` Unicode escapes (with `\ucN` skip count support)
/// - `\par`, `\line`, `\tab`
///
/// Note: This function is intentionally conservative about normalization so it
/// can be used for round-tripping Scrivener documents without changing content.
String rtfToPlainText(String rtfContent) {
  if (!rtfContent.trimLeft().startsWith(r'{\rtf')) {
    return rtfContent;
  }

  final buffer = StringBuffer();

  final ignoreStack = <bool>[];
  var ignoreGroup = false;
  var groupStart = false;

  var ucSkipCount = 1;
  var pendingAnsiSkip = 0;

  void emitChar(String char, {bool countsAsAnsiChar = true}) {
    if (countsAsAnsiChar && pendingAnsiSkip > 0) {
      pendingAnsiSkip--;
      return;
    }
    if (!ignoreGroup) {
      buffer.write(char);
    }
  }

  var i = 0;
  while (i < rtfContent.length) {
    final ch = rtfContent[i];

    if (ch == '{') {
      ignoreStack.add(ignoreGroup);
      groupStart = true;
      i++;
      continue;
    }

    if (ch == '}') {
      ignoreGroup = ignoreStack.isNotEmpty ? ignoreStack.removeLast() : false;
      groupStart = false;
      i++;
      continue;
    }

    if (ch != '\\') {
      // RTF files often contain raw newlines and indentation for readability.
      // Those characters are not part of the document content.
      if (ch == '\r' || ch == '\n' || ch == '\t') {
        i++;
        continue;
      }

      // Some RTF groups begin with whitespace/newlines before their destination
      // control word (e.g. `{ \fonttbl ... }`). Keep `groupStart` true until we
      // see the first meaningful token so we can still detect destinations that
      // should be ignored.
      if (groupStart && ch == ' ') {
        i++;
        continue;
      }

      emitChar(ch);
      groupStart = false;
      i++;
      continue;
    }

    // Control word or control symbol.
    i++; // consume backslash
    if (i >= rtfContent.length) break;

    final next = rtfContent[i];

    // Control symbol: \'hh hex escape.
    if (next == "'") {
      if (i + 2 < rtfContent.length &&
          _isHexDigit(rtfContent[i + 1]) &&
          _isHexDigit(rtfContent[i + 2])) {
        final hex = rtfContent.substring(i + 1, i + 3);
        final value = int.parse(hex, radix: 16);
        emitChar(_decodeCp1252Byte(value));
        i += 3;
      } else {
        i++;
      }
      groupStart = false;
      continue;
    }

    // Escaped literal characters.
    if (next == '\\' || next == '{' || next == '}') {
      emitChar(next);
      i++;
      groupStart = false;
      continue;
    }

    // Non-breaking space, optional hyphen, non-breaking hyphen.
    if (next == '~') {
      emitChar(' ');
      i++;
      groupStart = false;
      continue;
    }
    if (next == '-') {
      // Optional hyphen; ignore.
      i++;
      groupStart = false;
      continue;
    }
    if (next == '_') {
      emitChar('-');
      i++;
      groupStart = false;
      continue;
    }

    // Ignorable destination.
    if (next == '*') {
      ignoreGroup = true;
      i++;
      groupStart = false;
      continue;
    }

    // Control word: \wordN?
    if (!_isAsciiLetter(next)) {
      // Unknown control symbol; skip it.
      i++;
      groupStart = false;
      continue;
    }

    final wordStart = i;
    while (i < rtfContent.length && _isAsciiLetter(rtfContent[i])) {
      i++;
    }
    final word = rtfContent.substring(wordStart, i);

    var hasParam = false;
    var paramSign = 1;
    var paramValue = 0;

    if (i < rtfContent.length && (rtfContent[i] == '-' || rtfContent[i] == '+')) {
      hasParam = true;
      paramSign = rtfContent[i] == '-' ? -1 : 1;
      i++;
    }

    final digitStart = i;
    while (i < rtfContent.length && _isDigit(rtfContent[i])) {
      i++;
    }
    if (i > digitStart) {
      hasParam = true;
      paramValue = int.parse(rtfContent.substring(digitStart, i)) * paramSign;
    }

    // A space after a control word is a delimiter and should be consumed.
    if (i < rtfContent.length && rtfContent[i] == ' ') {
      i++;
    }

    // Destination groups we never want as text.
    if (groupStart && _ignoredDestinations.contains(word)) {
      ignoreGroup = true;
    }

    if (word == 'par' || word == 'line') {
      emitChar('\n', countsAsAnsiChar: false);
    } else if (word == 'tab') {
      emitChar('\t', countsAsAnsiChar: false);
    } else if (word == 'uc' && hasParam) {
      ucSkipCount = paramValue.clamp(0, 16);
    } else if (word == 'u' && hasParam) {
      var codeUnit = paramValue;
      if (codeUnit < 0) {
        codeUnit = 65536 + codeUnit;
      }
      emitChar(String.fromCharCode(codeUnit), countsAsAnsiChar: false);
      pendingAnsiSkip = ucSkipCount;
    }

    groupStart = false;
  }

  return buffer.toString().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

String _encodePlainTextToRtfFragment(String text) {
  final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final buffer = StringBuffer();

  for (var i = 0; i < normalized.length; i++) {
    final ch = normalized[i];
    switch (ch) {
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
        buffer.write(r'\par' '\n');
        break;
      case '\t':
        buffer.write(r'\tab ');
        break;
      default:
        final codeUnit = normalized.codeUnitAt(i);
        if (codeUnit >= 0x20 && codeUnit <= 0x7E) {
          buffer.write(ch);
        } else {
          final signed = codeUnit > 0x7FFF ? codeUnit - 0x10000 : codeUnit;
          buffer.write(r'\u');
          buffer.write(signed);
          buffer.write('?');
        }
        break;
    }
  }

  return buffer.toString();
}

/// Minimal plain text -> RTF converter.
///
/// This preserves newlines and escapes special RTF characters so that the
/// resulting file is readable by RTF consumers (e.g. Scrivener).
String plainTextToRtf(String text) {
  final fragment = _encodePlainTextToRtfFragment(text);
  return '{\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 Calibri;}}\\viewkind4\\uc1\\pard\\f0\\fs24 $fragment}';
}

enum _RtfTokenType { groupStart, groupEnd, control, text }

class _RtfToken {
  _RtfToken(this.type, this.raw);

  final _RtfTokenType type;
  String raw;
}

class _RtfSlice {
  _RtfSlice(this.tokenIndex, this.startOffset, this.endOffset);

  final int tokenIndex;
  final int startOffset;
  final int endOffset;
}

class _PlainCharRef {
  _PlainCharRef(this.slices);

  final List<_RtfSlice> slices;
}

class _RtfCursor {
  const _RtfCursor(this.tokenIndex, this.offset);

  final int tokenIndex;
  final int offset;
}

List<_RtfToken> _tokenizeRtf(String rtf) {
  final tokens = <_RtfToken>[];
  final textBuffer = StringBuffer();

  void flushText() {
    if (textBuffer.isEmpty) return;
    tokens.add(_RtfToken(_RtfTokenType.text, textBuffer.toString()));
    textBuffer.clear();
  }

  var i = 0;
  while (i < rtf.length) {
    final ch = rtf[i];

    if (ch == '{') {
      flushText();
      tokens.add(_RtfToken(_RtfTokenType.groupStart, '{'));
      i++;
      continue;
    }

    if (ch == '}') {
      flushText();
      tokens.add(_RtfToken(_RtfTokenType.groupEnd, '}'));
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
      tokens.add(_RtfToken(_RtfTokenType.control, rtf.substring(start)));
      break;
    }

    final next = rtf[i];

    // Control symbol: \'hh hex escape.
    if (next == "'" &&
        i + 2 < rtf.length &&
        _isHexDigit(rtf[i + 1]) &&
        _isHexDigit(rtf[i + 2])) {
      i += 3;
      tokens.add(_RtfToken(_RtfTokenType.control, rtf.substring(start, i)));
      continue;
    }

    // Single-character control symbols.
    if (!_isAsciiLetter(next)) {
      i++;
      tokens.add(_RtfToken(_RtfTokenType.control, rtf.substring(start, i)));
      continue;
    }

    // Control word: \wordN?
    while (i < rtf.length && _isAsciiLetter(rtf[i])) {
      i++;
    }

    if (i < rtf.length && (rtf[i] == '-' || rtf[i] == '+')) {
      i++;
    }

    while (i < rtf.length && _isDigit(rtf[i])) {
      i++;
    }

    // A space after a control word is a delimiter and should be consumed.
    if (i < rtf.length && rtf[i] == ' ') {
      i++;
    }

    tokens.add(_RtfToken(_RtfTokenType.control, rtf.substring(start, i)));
  }

  flushText();
  return tokens;
}

({String word, bool hasParam, int paramValue}) _parseControlWord(String raw) {
  // raw starts with '\', followed by letters, optional signed int, optional space.
  var i = 1;
  final start = i;
  while (i < raw.length && _isAsciiLetter(raw[i])) {
    i++;
  }
  final word = raw.substring(start, i);

  var hasParam = false;
  var sign = 1;
  if (i < raw.length && (raw[i] == '-' || raw[i] == '+')) {
    hasParam = true;
    sign = raw[i] == '-' ? -1 : 1;
    i++;
  }

  final digitsStart = i;
  while (i < raw.length && _isDigit(raw[i])) {
    i++;
  }

  var value = 0;
  if (i > digitsStart) {
    hasParam = true;
    value = int.parse(raw.substring(digitsStart, i)) * sign;
  }

  return (word: word, hasParam: hasParam, paramValue: value);
}

({List<_RtfToken> tokens, String plainText, List<_PlainCharRef> charRefs})
    _parseRtfWithMapping(String rtf) {
  final tokens = _tokenizeRtf(rtf);
  final plainText = StringBuffer();
  final charRefs = <_PlainCharRef>[];

  final ignoreStack = <bool>[];
  var ignoreGroup = false;
  var groupStart = false;

  var ucSkipCount = 1;
  var pendingAnsiSkip = 0;

  _PlainCharRef? captureFallbackFor;
  var remainingFallbackChars = 0;

  void skipAnsi(List<_RtfSlice> slices) {
    if (pendingAnsiSkip > 0) {
      pendingAnsiSkip--;
      if (captureFallbackFor != null && remainingFallbackChars > 0) {
        captureFallbackFor!.slices.addAll(slices);
        remainingFallbackChars--;
        if (remainingFallbackChars == 0) {
          captureFallbackFor = null;
        }
      }
    }
  }

  void emitChar(
    String char,
    List<_RtfSlice> slices, {
    bool countsAsAnsiChar = true,
  }) {
    if (countsAsAnsiChar && pendingAnsiSkip > 0) {
      skipAnsi(slices);
      return;
    }
    if (!ignoreGroup) {
      plainText.write(char);
      charRefs.add(_PlainCharRef(List<_RtfSlice>.from(slices)));
    }
  }

  for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
    final token = tokens[tokenIndex];

    if (token.type == _RtfTokenType.groupStart) {
      ignoreStack.add(ignoreGroup);
      groupStart = true;
      continue;
    }

    if (token.type == _RtfTokenType.groupEnd) {
      ignoreGroup = ignoreStack.isNotEmpty ? ignoreStack.removeLast() : false;
      groupStart = false;
      continue;
    }

    if (token.type == _RtfTokenType.text) {
      for (var offset = 0; offset < token.raw.length; offset++) {
        final ch = token.raw[offset];

        // RTF files often contain raw newlines and indentation for readability.
        if (ch == '\r' || ch == '\n' || ch == '\t') {
          continue;
        }

        if (groupStart && ch == ' ') {
          continue;
        }

        emitChar(ch, [_RtfSlice(tokenIndex, offset, offset + 1)]);
        groupStart = false;
      }
      continue;
    }

    // Control token
    final raw = token.raw;
    if (raw.length < 2) {
      groupStart = false;
      continue;
    }

    final second = raw[1];

    // Hex escape: \'hh
    if (second == "'" &&
        raw.length >= 4 &&
        _isHexDigit(raw[2]) &&
        _isHexDigit(raw[3])) {
      final value = int.parse(raw.substring(2, 4), radix: 16);
      emitChar(
        _decodeCp1252Byte(value),
        [_RtfSlice(tokenIndex, 0, raw.length)],
      );
      groupStart = false;
      continue;
    }

    // Control symbols
    if (!_isAsciiLetter(second)) {
      if (second == '\\' || second == '{' || second == '}') {
        emitChar(
          second,
          [_RtfSlice(tokenIndex, 0, raw.length)],
        );
      } else if (second == '~') {
        emitChar(
          ' ',
          [_RtfSlice(tokenIndex, 0, raw.length)],
        );
      } else if (second == '-') {
        // Optional hyphen; ignore.
      } else if (second == '_') {
        emitChar(
          '-',
          [_RtfSlice(tokenIndex, 0, raw.length)],
        );
      } else if (second == '*') {
        ignoreGroup = true;
      } else {
        // Unknown control symbol; ignore.
      }

      groupStart = false;
      continue;
    }

    // Control word
    final parsed = _parseControlWord(raw);
    final word = parsed.word;
    final hasParam = parsed.hasParam;
    final paramValue = parsed.paramValue;

    if (groupStart && _ignoredDestinations.contains(word)) {
      ignoreGroup = true;
    }

    if (word == 'par' || word == 'line') {
      emitChar('\n', [_RtfSlice(tokenIndex, 0, raw.length)], countsAsAnsiChar: false);
    } else if (word == 'tab') {
      emitChar('\t', [_RtfSlice(tokenIndex, 0, raw.length)], countsAsAnsiChar: false);
    } else if (word == 'uc' && hasParam) {
      ucSkipCount = paramValue.clamp(0, 16);
    } else if (word == 'u' && hasParam) {
      var codeUnit = paramValue;
      if (codeUnit < 0) {
        codeUnit = 65536 + codeUnit;
      }

      if (!ignoreGroup) {
        final ref = _PlainCharRef([_RtfSlice(tokenIndex, 0, raw.length)]);
        plainText.write(String.fromCharCode(codeUnit));
        charRefs.add(ref);
        captureFallbackFor = ref;
        remainingFallbackChars = ucSkipCount;
      }

      pendingAnsiSkip = ucSkipCount;
    }

    groupStart = false;
  }

  return (tokens: tokens, plainText: plainText.toString(), charRefs: charRefs);
}

_RtfCursor _cursorForPlainOffset(
  int offset,
  List<_PlainCharRef> refs,
  List<_RtfToken> tokens,
) {
  if (refs.isEmpty) {
    // Insert before the final closing brace, if present.
    for (var i = tokens.length - 1; i >= 0; i--) {
      if (tokens[i].type == _RtfTokenType.groupEnd) {
        return _RtfCursor(i, 0);
      }
    }
    return _RtfCursor(tokens.length, 0);
  }

  if (offset <= 0) {
    final first = refs.first.slices.first;
    return _RtfCursor(first.tokenIndex, first.startOffset);
  }

  if (offset >= refs.length) {
    final last = refs.last.slices.last;
    final token = tokens[last.tokenIndex];
    final isWholeNonTextToken = token.type != _RtfTokenType.text &&
        last.startOffset == 0 &&
        last.endOffset == token.raw.length;
    if (isWholeNonTextToken) {
      return _RtfCursor(last.tokenIndex + 1, 0);
    }
    return _RtfCursor(last.tokenIndex, last.endOffset);
  }

  final slice = refs[offset].slices.first;
  return _RtfCursor(slice.tokenIndex, slice.startOffset);
}

void _deleteSlices(List<_RtfToken> tokens, List<_RtfSlice> slices) {
  final slicesByToken = <int, List<_RtfSlice>>{};
  for (final slice in slices) {
    slicesByToken.putIfAbsent(slice.tokenIndex, () => []).add(slice);
  }

  final tokenIndices = slicesByToken.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final tokenIndex in tokenIndices) {
    if (tokenIndex < 0 || tokenIndex >= tokens.length) continue;
    final token = tokens[tokenIndex];
    final deletions = slicesByToken[tokenIndex]!
      ..sort((a, b) => b.startOffset.compareTo(a.startOffset));

    var newRaw = token.raw;
    for (final deletion in deletions) {
      final start = deletion.startOffset.clamp(0, newRaw.length);
      final end = deletion.endOffset.clamp(0, newRaw.length);
      if (end <= start) continue;
      newRaw = newRaw.substring(0, start) + newRaw.substring(end);
    }

    token.raw = newRaw;
  }

  for (var i = tokens.length - 1; i >= 0; i--) {
    if (tokens[i].raw.isEmpty) {
      tokens.removeAt(i);
    }
  }
}

void _insertRtfFragment(
  List<_RtfToken> tokens,
  _RtfCursor cursor,
  String fragment,
) {
  final insertTokens = _tokenizeRtf(fragment);
  if (insertTokens.isEmpty) return;

  var tokenIndex = cursor.tokenIndex.clamp(0, tokens.length);

  if (tokenIndex < tokens.length && tokens[tokenIndex].type == _RtfTokenType.text) {
    final raw = tokens[tokenIndex].raw;
    final splitOffset = cursor.offset.clamp(0, raw.length);
    final before = raw.substring(0, splitOffset);
    final after = raw.substring(splitOffset);

    final replacement = <_RtfToken>[];
    if (before.isNotEmpty) {
      replacement.add(_RtfToken(_RtfTokenType.text, before));
    }
    replacement.addAll(insertTokens);
    if (after.isNotEmpty) {
      replacement.add(_RtfToken(_RtfTokenType.text, after));
    }

    tokens.removeAt(tokenIndex);
    tokens.insertAll(tokenIndex, replacement);
    return;
  }

  tokens.insertAll(tokenIndex, insertTokens);
}

({int start, int end, String insert}) _computeSingleReplacement(
  String oldText,
  String newText,
) {
  var prefix = 0;
  final minLen = oldText.length < newText.length ? oldText.length : newText.length;
  while (prefix < minLen &&
      oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
    prefix++;
  }

  var oldSuffix = oldText.length;
  var newSuffix = newText.length;
  while (oldSuffix > prefix &&
      newSuffix > prefix &&
      oldText.codeUnitAt(oldSuffix - 1) == newText.codeUnitAt(newSuffix - 1)) {
    oldSuffix--;
    newSuffix--;
  }

  return (
    start: prefix,
    end: oldSuffix,
    insert: newText.substring(prefix, newSuffix),
  );
}

/// Applies a plain-text edit to an existing RTF document while preserving
/// Scrivener formatting and metadata wherever possible.
///
/// This performs a conservative "single replacement" update based on the
/// longest common prefix/suffix between the current RTF plain-text and the
/// desired plain-text.
///
/// Throws a [FormatException] if the edit can't be applied safely.
String updateRtfPlainTextPreservingFormatting({
  required String rtfContent,
  required String plainText,
}) {
  if (!rtfContent.trimLeft().startsWith(r'{\rtf')) {
    return plainTextToRtf(plainText);
  }

  final parsed = _parseRtfWithMapping(rtfContent);
  final currentPlainText =
      parsed.plainText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final desiredPlainText = plainText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  if (currentPlainText == desiredPlainText) {
    return rtfContent;
  }

  final diff = _computeSingleReplacement(currentPlainText, desiredPlainText);
  final start = diff.start;
  final end = diff.end;

  if (start < 0 || end < start || end > parsed.charRefs.length) {
    throw const FormatException('Plain-text edit range is out of bounds for RTF');
  }

  final cursor = _cursorForPlainOffset(start, parsed.charRefs, parsed.tokens);
  final deletionSlices = <_RtfSlice>[];
  for (var i = start; i < end; i++) {
    deletionSlices.addAll(parsed.charRefs[i].slices);
  }

  _deleteSlices(parsed.tokens, deletionSlices);

  final fragment = _encodePlainTextToRtfFragment(diff.insert);
  _insertRtfFragment(parsed.tokens, cursor, fragment);

  final updatedRtf = parsed.tokens.map((t) => t.raw).join();
  final updatedPlainText =
      rtfToPlainText(updatedRtf).replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  if (updatedPlainText != desiredPlainText) {
    throw const FormatException(
      'Failed to apply plain-text edit without altering RTF structure',
    );
  }

  return updatedRtf;
}

