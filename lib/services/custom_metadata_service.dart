import 'package:flutter/material.dart';
import '../models/custom_field.dart';

/// Service for managing custom metadata fields
class CustomMetadataService extends ChangeNotifier {
  /// Field definitions
  final List<CustomFieldDefinition> _definitions = [];

  /// Document metadata values
  final Map<String, DocumentCustomMetadata> _documentMetadata = {};

  /// Get all field definitions sorted by order
  List<CustomFieldDefinition> get definitions {
    final sorted = List<CustomFieldDefinition>.from(_definitions);
    sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }

  /// Get field definition by ID
  CustomFieldDefinition? getDefinition(String id) {
    try {
      return _definitions.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get metadata for a document
  DocumentCustomMetadata? getDocumentMetadata(String documentId) {
    return _documentMetadata[documentId];
  }

  /// Get value for a specific field on a document
  CustomFieldValue? getFieldValue(String documentId, String fieldId) {
    return _documentMetadata[documentId]?.values[fieldId];
  }

  /// Create a new field definition
  CustomFieldDefinition createField({
    required String name,
    required CustomFieldType type,
    String? description,
    bool isRequired = false,
    dynamic defaultValue,
    List<String>? options,
  }) {
    final definition = CustomFieldDefinition(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      description: description,
      isRequired: isRequired,
      defaultValue: defaultValue,
      options: options,
      sortOrder: _definitions.length,
      createdAt: DateTime.now(),
    );

    _definitions.add(definition);
    notifyListeners();
    return definition;
  }

  /// Update a field definition
  void updateField(CustomFieldDefinition definition) {
    final index = _definitions.indexWhere((d) => d.id == definition.id);
    if (index != -1) {
      _definitions[index] = definition;
      notifyListeners();
    }
  }

  /// Delete a field definition
  void deleteField(String fieldId) {
    // Remove from all documents
    for (final entry in _documentMetadata.entries) {
      final newValues = Map<String, CustomFieldValue>.from(entry.value.values);
      newValues.remove(fieldId);
      _documentMetadata[entry.key] = entry.value.copyWith(values: newValues);
    }

    // Remove definition
    _definitions.removeWhere((d) => d.id == fieldId);
    notifyListeners();
  }

  /// Reorder fields
  void reorderFields(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final sorted = definitions;
    final item = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, item);

    // Update sort orders
    for (var i = 0; i < sorted.length; i++) {
      final index = _definitions.indexWhere((d) => d.id == sorted[i].id);
      if (index != -1) {
        _definitions[index] = _definitions[index].copyWith(sortOrder: i);
      }
    }
    notifyListeners();
  }

  /// Set field value for a document
  void setFieldValue(String documentId, String fieldId, dynamic value) {
    final existing = _documentMetadata[documentId];
    final fieldValue = CustomFieldValue(
      fieldId: fieldId,
      documentId: documentId,
      value: value,
      updatedAt: DateTime.now(),
    );

    if (existing != null) {
      final newValues = Map<String, CustomFieldValue>.from(existing.values);
      newValues[fieldId] = fieldValue;
      _documentMetadata[documentId] = existing.copyWith(values: newValues);
    } else {
      _documentMetadata[documentId] = DocumentCustomMetadata(
        documentId: documentId,
        values: {fieldId: fieldValue},
      );
    }
    notifyListeners();
  }

  /// Clear field value for a document
  void clearFieldValue(String documentId, String fieldId) {
    final existing = _documentMetadata[documentId];
    if (existing != null) {
      final newValues = Map<String, CustomFieldValue>.from(existing.values);
      newValues.remove(fieldId);
      _documentMetadata[documentId] = existing.copyWith(values: newValues);
      notifyListeners();
    }
  }

  /// Set all metadata for a document
  void setDocumentMetadata(String documentId, DocumentCustomMetadata metadata) {
    _documentMetadata[documentId] = metadata;
    notifyListeners();
  }

  /// Delete all metadata for a document
  void deleteDocumentMetadata(String documentId) {
    _documentMetadata.remove(documentId);
    notifyListeners();
  }

  /// Get documents with a specific field value
  List<String> getDocumentsWithFieldValue(
    String fieldId,
    dynamic value, {
    bool exactMatch = true,
  }) {
    return _documentMetadata.entries
        .where((entry) {
          final fieldValue = entry.value.values[fieldId];
          if (fieldValue == null) return false;

          if (exactMatch) {
            return fieldValue.value == value;
          } else {
            // Partial match for strings
            if (fieldValue.value is String && value is String) {
              return (fieldValue.value as String)
                  .toLowerCase()
                  .contains(value.toLowerCase());
            }
            return fieldValue.value == value;
          }
        })
        .map((entry) => entry.key)
        .toList();
  }

  /// Search across all custom fields
  List<String> searchDocuments(String query) {
    final lowerQuery = query.toLowerCase();
    final results = <String>{};

    for (final entry in _documentMetadata.entries) {
      for (final value in entry.value.values.values) {
        if (value.value != null) {
          final stringValue = value.value.toString().toLowerCase();
          if (stringValue.contains(lowerQuery)) {
            results.add(entry.key);
            break;
          }
        }
      }
    }

    return results.toList();
  }

  /// Validate document metadata against required fields
  List<String> validateDocument(String documentId) {
    final errors = <String>[];
    final metadata = _documentMetadata[documentId];

    for (final definition in _definitions) {
      if (definition.isRequired) {
        final value = metadata?.values[definition.id];
        if (value == null || value.value == null || value.value == '') {
          errors.add('${definition.name} is required');
        }
      }
    }

    return errors;
  }

  /// Load definitions from JSON
  void loadDefinitions(List<Map<String, dynamic>> data) {
    _definitions.clear();
    for (final item in data) {
      _definitions.add(CustomFieldDefinition.fromJson(item));
    }
    notifyListeners();
  }

  /// Load document metadata from JSON
  void loadDocumentMetadata(List<Map<String, dynamic>> data) {
    _documentMetadata.clear();
    for (final item in data) {
      final metadata = DocumentCustomMetadata.fromJson(item);
      _documentMetadata[metadata.documentId] = metadata;
    }
    notifyListeners();
  }

  /// Export definitions to JSON
  List<Map<String, dynamic>> definitionsToJson() {
    return _definitions.map((d) => d.toJson()).toList();
  }

  /// Export document metadata to JSON
  List<Map<String, dynamic>> documentMetadataToJson() {
    return _documentMetadata.values.map((m) => m.toJson()).toList();
  }

  /// Clear all data
  void clear() {
    _definitions.clear();
    _documentMetadata.clear();
    notifyListeners();
  }

  /// Create default fields for a new project
  void createDefaultFields() {
    createField(
      name: 'POV Character',
      type: CustomFieldType.text,
      description: 'Point of view character for this scene',
    );
    createField(
      name: 'Timeline',
      type: CustomFieldType.text,
      description: 'When this scene takes place',
    );
    createField(
      name: 'Location',
      type: CustomFieldType.text,
      description: 'Where this scene takes place',
    );
    createField(
      name: 'Revision Needed',
      type: CustomFieldType.checkbox,
      description: 'Mark if this document needs revision',
      defaultValue: false,
    );
    createField(
      name: 'Draft Number',
      type: CustomFieldType.number,
      description: 'Current draft number',
      defaultValue: 1,
    );
  }
}
