/// Represents a footnote or inline note in a document
class DocumentFootnote {
  final String id;
  final String documentId;
  final int anchorOffset; // Position in text where footnote marker appears
  final String content;
  final FootnoteType type;
  final int? number; // Auto-assigned number for traditional footnotes
  final DateTime createdAt;
  final DateTime modifiedAt;

  const DocumentFootnote({
    required this.id,
    required this.documentId,
    required this.anchorOffset,
    required this.content,
    required this.type,
    this.number,
    required this.createdAt,
    required this.modifiedAt,
  });

  /// Create a new footnote
  factory DocumentFootnote.create({
    required String documentId,
    required int anchorOffset,
    required String content,
    FootnoteType type = FootnoteType.footnote,
    int? number,
  }) {
    final now = DateTime.now();
    return DocumentFootnote(
      id: '${now.millisecondsSinceEpoch}_footnote',
      documentId: documentId,
      anchorOffset: anchorOffset,
      content: content,
      type: type,
      number: number,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Update the content
  DocumentFootnote withContent(String newContent) {
    return copyWith(
      content: newContent,
      modifiedAt: DateTime.now(),
    );
  }

  /// Update the number
  DocumentFootnote withNumber(int newNumber) {
    return copyWith(number: newNumber);
  }

  /// Adjust anchor offset when text is inserted/deleted
  DocumentFootnote adjustOffset(int changePosition, int delta) {
    if (changePosition > anchorOffset) {
      // Change is after this footnote, no adjustment needed
      return this;
    }

    // Change is before or at this footnote, shift offset
    return copyWith(
      anchorOffset: (anchorOffset + delta).clamp(0, double.maxFinite.toInt()),
    );
  }

  /// Copy with updated fields
  DocumentFootnote copyWith({
    int? anchorOffset,
    String? content,
    FootnoteType? type,
    int? number,
    DateTime? modifiedAt,
  }) {
    return DocumentFootnote(
      id: id,
      documentId: documentId,
      anchorOffset: anchorOffset ?? this.anchorOffset,
      content: content ?? this.content,
      type: type ?? this.type,
      number: number ?? this.number,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Get marker text for display
  String get markerText {
    switch (type) {
      case FootnoteType.footnote:
        return number != null ? '[$number]' : '[*]';
      case FootnoteType.endnote:
        return number != null ? '($number)' : '(*)';
      case FootnoteType.inlineNote:
        return '†';
      case FootnoteType.annotation:
        return '‡';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'anchorOffset': anchorOffset,
      'content': content,
      'type': type.name,
      'number': number,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory DocumentFootnote.fromJson(Map<String, dynamic> json) {
    return DocumentFootnote(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      anchorOffset: json['anchorOffset'] as int,
      content: json['content'] as String,
      type: FootnoteType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FootnoteType.footnote,
      ),
      number: json['number'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }
}

/// Types of footnotes/notes
enum FootnoteType {
  footnote('Footnote', 'Numbered reference at bottom of page'),
  endnote('Endnote', 'Numbered reference at end of document/chapter'),
  inlineNote('Inline Note', 'Parenthetical aside within text'),
  annotation('Annotation', 'Author annotation for reference');

  final String displayName;
  final String description;

  const FootnoteType(this.displayName, this.description);
}

/// Settings for footnote numbering and display
class FootnoteSettings {
  final FootnoteNumberingStyle numberingStyle;
  final FootnoteRestartMode restartMode;
  final bool showInlineNotes; // Whether to show inline notes in compiled output
  final bool showAnnotations; // Whether to show annotations in compiled output

  const FootnoteSettings({
    this.numberingStyle = FootnoteNumberingStyle.arabic,
    this.restartMode = FootnoteRestartMode.continuous,
    this.showInlineNotes = true,
    this.showAnnotations = false,
  });

  FootnoteSettings copyWith({
    FootnoteNumberingStyle? numberingStyle,
    FootnoteRestartMode? restartMode,
    bool? showInlineNotes,
    bool? showAnnotations,
  }) {
    return FootnoteSettings(
      numberingStyle: numberingStyle ?? this.numberingStyle,
      restartMode: restartMode ?? this.restartMode,
      showInlineNotes: showInlineNotes ?? this.showInlineNotes,
      showAnnotations: showAnnotations ?? this.showAnnotations,
    );
  }

  /// Convert number to string based on style
  String formatNumber(int number) {
    switch (numberingStyle) {
      case FootnoteNumberingStyle.arabic:
        return number.toString();
      case FootnoteNumberingStyle.roman:
        return _toRoman(number);
      case FootnoteNumberingStyle.alphabetic:
        return _toAlphabetic(number);
      case FootnoteNumberingStyle.symbols:
        return _toSymbol(number);
    }
  }

  String _toRoman(int number) {
    if (number <= 0 || number > 3999) return number.toString();

    const romanNumerals = [
      [1000, 'M'],
      [900, 'CM'],
      [500, 'D'],
      [400, 'CD'],
      [100, 'C'],
      [90, 'XC'],
      [50, 'L'],
      [40, 'XL'],
      [10, 'X'],
      [9, 'IX'],
      [5, 'V'],
      [4, 'IV'],
      [1, 'I'],
    ];

    var result = '';
    var remaining = number;

    for (final pair in romanNumerals) {
      final value = pair[0] as int;
      final numeral = pair[1] as String;
      while (remaining >= value) {
        result += numeral;
        remaining -= value;
      }
    }

    return result.toLowerCase();
  }

  String _toAlphabetic(int number) {
    if (number <= 0) return number.toString();

    var result = '';
    var n = number;

    while (n > 0) {
      n--; // Adjust for 0-based indexing
      result = String.fromCharCode('a'.codeUnitAt(0) + (n % 26)) + result;
      n ~/= 26;
    }

    return result;
  }

  String _toSymbol(int number) {
    const symbols = ['*', '†', '‡', '§', '‖', '¶'];
    if (number <= 0) return '*';

    final index = (number - 1) % symbols.length;
    final repetition = (number - 1) ~/ symbols.length + 1;

    return symbols[index] * repetition;
  }

  Map<String, dynamic> toJson() {
    return {
      'numberingStyle': numberingStyle.name,
      'restartMode': restartMode.name,
      'showInlineNotes': showInlineNotes,
      'showAnnotations': showAnnotations,
    };
  }

  factory FootnoteSettings.fromJson(Map<String, dynamic> json) {
    return FootnoteSettings(
      numberingStyle: FootnoteNumberingStyle.values.firstWhere(
        (s) => s.name == json['numberingStyle'],
        orElse: () => FootnoteNumberingStyle.arabic,
      ),
      restartMode: FootnoteRestartMode.values.firstWhere(
        (m) => m.name == json['restartMode'],
        orElse: () => FootnoteRestartMode.continuous,
      ),
      showInlineNotes: json['showInlineNotes'] as bool? ?? true,
      showAnnotations: json['showAnnotations'] as bool? ?? false,
    );
  }
}

/// Numbering style for footnotes
enum FootnoteNumberingStyle {
  arabic('1, 2, 3...'),
  roman('i, ii, iii...'),
  alphabetic('a, b, c...'),
  symbols('*, †, ‡...');

  final String example;
  const FootnoteNumberingStyle(this.example);
}

/// When to restart footnote numbering
enum FootnoteRestartMode {
  continuous('Continuous throughout document'),
  perChapter('Restart each chapter'),
  perPage('Restart each page');

  final String description;
  const FootnoteRestartMode(this.description);
}
