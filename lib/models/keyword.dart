import 'package:flutter/material.dart';

/// Represents a project keyword for categorization
class Keyword {
  final String id;
  final String name;
  final int colorValue;
  final String? parentId; // For hierarchical keywords
  final DateTime createdAt;

  const Keyword({
    required this.id,
    required this.name,
    required this.colorValue,
    this.parentId,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  Keyword copyWith({
    String? name,
    int? colorValue,
    String? parentId,
  }) {
    return Keyword(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Keyword.fromJson(Map<String, dynamic> json) {
    return Keyword(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Keyword && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Association between a document and keywords
class DocumentKeywords {
  final String documentId;
  final List<String> keywordIds;

  const DocumentKeywords({
    required this.documentId,
    required this.keywordIds,
  });

  DocumentKeywords copyWith({
    List<String>? keywordIds,
  }) {
    return DocumentKeywords(
      documentId: documentId,
      keywordIds: keywordIds ?? this.keywordIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'keywordIds': keywordIds,
    };
  }

  factory DocumentKeywords.fromJson(Map<String, dynamic> json) {
    return DocumentKeywords(
      documentId: json['documentId'] as String,
      keywordIds: (json['keywordIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Predefined keyword colors
class KeywordColors {
  static const List<Color> palette = [
    Color(0xFFE57373), // Red
    Color(0xFFFFB74D), // Orange
    Color(0xFFFFF176), // Yellow
    Color(0xFFAED581), // Light Green
    Color(0xFF4DB6AC), // Teal
    Color(0xFF4FC3F7), // Light Blue
    Color(0xFF7986CB), // Indigo
    Color(0xFFBA68C8), // Purple
    Color(0xFFF06292), // Pink
    Color(0xFF90A4AE), // Blue Grey
    Color(0xFFA1887F), // Brown
    Color(0xFF81C784), // Green
  ];

  static Color getColor(int index) {
    return palette[index % palette.length];
  }

  static int getColorValue(int index) {
    return palette[index % palette.length].toARGB32();
  }
}
