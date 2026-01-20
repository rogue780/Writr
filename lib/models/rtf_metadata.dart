import 'package:flutter/material.dart';

/// Represents a font entry from an RTF font table.
class RtfFont {
  final int index;
  final String name;
  final String? family; // nil, roman, swiss, modern, script, decor, tech, bidi
  final int? charset;

  const RtfFont({
    required this.index,
    required this.name,
    this.family,
    this.charset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtfFont &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          name == other.name &&
          family == other.family &&
          charset == other.charset;

  @override
  int get hashCode => Object.hash(index, name, family, charset);

  @override
  String toString() => 'RtfFont($index: $name)';
}

/// Metadata extracted from RTF header for round-trip preservation.
///
/// When loading an RTF document, we extract these tables so that when
/// saving back to RTF, we can preserve the original font and color
/// definitions exactly as Scrivener expects them.
class RtfMetadata {
  /// Original font table from the RTF document.
  final List<RtfFont> fontTable;

  /// Original color table from the RTF document.
  /// Index 0 is typically "auto" (null), so colors start at index 1.
  final List<Color?> colorTable;

  /// Default font index (\deffN).
  final int defaultFontIndex;

  /// Any raw RTF header content we want to preserve verbatim.
  /// This includes stylesheets, info blocks, etc.
  final String? rawHeader;

  const RtfMetadata({
    this.fontTable = const [],
    this.colorTable = const [],
    this.defaultFontIndex = 0,
    this.rawHeader,
  });

  /// Creates an empty metadata instance for new documents.
  factory RtfMetadata.empty() => const RtfMetadata();

  /// Gets a font by index, returning null if not found.
  RtfFont? getFontByIndex(int index) {
    for (final font in fontTable) {
      if (font.index == index) return font;
    }
    return null;
  }

  /// Gets a color by index, returning null if not found.
  Color? getColorByIndex(int index) {
    if (index < 0 || index >= colorTable.length) return null;
    return colorTable[index];
  }

  /// Finds the index of a color in the table, or -1 if not found.
  int indexOfColor(Color color) {
    for (var i = 0; i < colorTable.length; i++) {
      if (colorTable[i] == color) return i;
    }
    return -1;
  }

  /// Finds the index of a font by name, or -1 if not found.
  int indexOfFont(String fontName) {
    for (final font in fontTable) {
      if (font.name == fontName) return font.index;
    }
    return -1;
  }

  @override
  String toString() =>
      'RtfMetadata(fonts: ${fontTable.length}, colors: ${colorTable.length})';
}
