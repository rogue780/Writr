/// Basic RTF to plain text converter.
///
/// This is intentionally lightweight (no external deps), but handles the common
/// Scrivener/Windows cases like:
/// - `\'hh` hex escapes (e.g. `\'93` -> “, `\'92` -> ’)
/// - `\uN?` Unicode escapes (with `\ucN` skip count support)
/// - `\par`, `\line`, `\tab`
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

  bool isHexDigit(String c) =>
      (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) ||
      (c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x46) ||
      (c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x66);

  String decodeCp1252Byte(int byteValue) {
    const map = <int, int>{
      0x80: 0x20AC, // €
      0x82: 0x201A, // ‚
      0x83: 0x0192, // ƒ
      0x84: 0x201E, // „
      0x85: 0x2026, // …
      0x86: 0x2020, // †
      0x87: 0x2021, // ‡
      0x88: 0x02C6, // ˆ
      0x89: 0x2030, // ‰
      0x8A: 0x0160, // Š
      0x8B: 0x2039, // ‹
      0x8C: 0x0152, // Œ
      0x8E: 0x017D, // Ž
      0x91: 0x2018, // ‘
      0x92: 0x2019, // ’
      0x93: 0x201C, // “
      0x94: 0x201D, // ”
      0x95: 0x2022, // •
      0x96: 0x2013, // –
      0x97: 0x2014, // —
      0x98: 0x02DC, // ˜
      0x99: 0x2122, // ™
      0x9A: 0x0161, // š
      0x9B: 0x203A, // ›
      0x9C: 0x0153, // œ
      0x9E: 0x017E, // ž
      0x9F: 0x0178, // Ÿ
    };

    final codePoint = map[byteValue] ?? byteValue;
    return String.fromCharCode(codePoint);
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
          isHexDigit(rtfContent[i + 1]) &&
          isHexDigit(rtfContent[i + 2])) {
        final hex = rtfContent.substring(i + 1, i + 3);
        final value = int.parse(hex, radix: 16);
        emitChar(decodeCp1252Byte(value));
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
    if (!RegExp(r'[A-Za-z]').hasMatch(next)) {
      // Unknown control symbol; skip it.
      i++;
      groupStart = false;
      continue;
    }

    final wordStart = i;
    while (i < rtfContent.length &&
        RegExp(r'[A-Za-z]').hasMatch(rtfContent[i])) {
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
    while (i < rtfContent.length && RegExp(r'\d').hasMatch(rtfContent[i])) {
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
    const ignoredDestinations = <String>{
      'fonttbl',
      'colortbl',
      'stylesheet',
      'info',
      'pict',
      'object',
      'datastore',
    };
    if (groupStart && ignoredDestinations.contains(word)) {
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

  var text = buffer.toString();

  // Normalize newlines.
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  // Trim outer whitespace from RTF containers.
  text = text.trim();

  // Remove multiple consecutive blank lines.
  text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

  return text;
}

/// Minimal plain text -> RTF converter.
///
/// This preserves newlines and escapes special RTF characters so that the
/// resulting file is readable by RTF consumers (e.g. Scrivener).
String plainTextToRtf(String text) {
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

  return '{\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 Calibri;}}\\viewkind4\\uc1\\pard\\f0\\fs24 ${buffer.toString()}}';
}
