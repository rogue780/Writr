import 'package:flutter/material.dart';

/// Types of custom metadata fields
enum CustomFieldType {
  text,
  number,
  date,
  checkbox,
  dropdown,
  multiSelect,
}

extension CustomFieldTypeExtension on CustomFieldType {
  String get displayName {
    switch (this) {
      case CustomFieldType.text:
        return 'Text';
      case CustomFieldType.number:
        return 'Number';
      case CustomFieldType.date:
        return 'Date';
      case CustomFieldType.checkbox:
        return 'Checkbox';
      case CustomFieldType.dropdown:
        return 'Dropdown';
      case CustomFieldType.multiSelect:
        return 'Multi-Select';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomFieldType.text:
        return Icons.text_fields;
      case CustomFieldType.number:
        return Icons.numbers;
      case CustomFieldType.date:
        return Icons.calendar_today;
      case CustomFieldType.checkbox:
        return Icons.check_box;
      case CustomFieldType.dropdown:
        return Icons.arrow_drop_down_circle;
      case CustomFieldType.multiSelect:
        return Icons.checklist;
    }
  }
}

/// Definition of a custom metadata field
class CustomFieldDefinition {
  final String id;
  final String name;
  final CustomFieldType type;
  final String? description;
  final bool isRequired;
  final dynamic defaultValue;
  final List<String>? options; // For dropdown/multiSelect types
  final int sortOrder;
  final DateTime createdAt;

  const CustomFieldDefinition({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.isRequired = false,
    this.defaultValue,
    this.options,
    required this.sortOrder,
    required this.createdAt,
  });

  CustomFieldDefinition copyWith({
    String? name,
    CustomFieldType? type,
    String? description,
    bool? isRequired,
    dynamic defaultValue,
    List<String>? options,
    int? sortOrder,
  }) {
    return CustomFieldDefinition(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description,
      'isRequired': isRequired,
      'defaultValue': defaultValue,
      'options': options,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomFieldDefinition.fromJson(Map<String, dynamic> json) {
    return CustomFieldDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      type: CustomFieldType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CustomFieldType.text,
      ),
      description: json['description'] as String?,
      isRequired: json['isRequired'] as bool? ?? false,
      defaultValue: json['defaultValue'],
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Value of a custom field for a specific document
class CustomFieldValue {
  final String fieldId;
  final String documentId;
  final dynamic value;
  final DateTime updatedAt;

  const CustomFieldValue({
    required this.fieldId,
    required this.documentId,
    required this.value,
    required this.updatedAt,
  });

  CustomFieldValue copyWith({
    dynamic value,
  }) {
    return CustomFieldValue(
      fieldId: fieldId,
      documentId: documentId,
      value: value ?? this.value,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'documentId': documentId,
      'value': value,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomFieldValue.fromJson(Map<String, dynamic> json) {
    return CustomFieldValue(
      fieldId: json['fieldId'] as String,
      documentId: json['documentId'] as String,
      value: json['value'],
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Get typed value as String
  String? get asString => value as String?;

  /// Get typed value as num
  num? get asNumber => value as num?;

  /// Get typed value as DateTime
  DateTime? get asDate {
    if (value == null) return null;
    if (value is DateTime) return value as DateTime;
    if (value is String) return DateTime.tryParse(value as String);
    return null;
  }

  /// Get typed value as bool
  bool get asBool => value as bool? ?? false;

  /// Get typed value as List<String>
  List<String> get asStringList {
    if (value == null) return [];
    if (value is List) {
      return (value as List).map((e) => e.toString()).toList();
    }
    return [];
  }
}

/// Document's custom metadata (all field values)
class DocumentCustomMetadata {
  final String documentId;
  final Map<String, CustomFieldValue> values;

  const DocumentCustomMetadata({
    required this.documentId,
    required this.values,
  });

  /// Get value for a specific field
  CustomFieldValue? getValue(String fieldId) => values[fieldId];

  /// Get display value for a field
  String getDisplayValue(String fieldId, CustomFieldDefinition definition) {
    final value = values[fieldId];
    if (value == null) return '';

    switch (definition.type) {
      case CustomFieldType.text:
        return value.asString ?? '';
      case CustomFieldType.number:
        return value.asNumber?.toString() ?? '';
      case CustomFieldType.date:
        final date = value.asDate;
        if (date == null) return '';
        return '${date.month}/${date.day}/${date.year}';
      case CustomFieldType.checkbox:
        return value.asBool ? 'Yes' : 'No';
      case CustomFieldType.dropdown:
        return value.asString ?? '';
      case CustomFieldType.multiSelect:
        return value.asStringList.join(', ');
    }
  }

  DocumentCustomMetadata copyWith({
    Map<String, CustomFieldValue>? values,
  }) {
    return DocumentCustomMetadata(
      documentId: documentId,
      values: values ?? this.values,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'values': values.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  factory DocumentCustomMetadata.fromJson(Map<String, dynamic> json) {
    final valuesJson = json['values'] as Map<String, dynamic>? ?? {};
    return DocumentCustomMetadata(
      documentId: json['documentId'] as String,
      values: valuesJson.map(
        (k, v) => MapEntry(k, CustomFieldValue.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}
