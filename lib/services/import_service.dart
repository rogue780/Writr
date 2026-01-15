import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/research_item.dart';

/// Service for importing research materials into the project
class ImportService {
  /// Allowed file extensions for research import
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'txt',
    'md',
    'markdown',
    'webarchive',
  ];

  /// Maximum file size for import (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Pick files for import using file picker
  Future<List<ImportResult>> pickAndImportFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final importResults = <ImportResult>[];
      for (final file in result.files) {
        final importResult = await _processFile(file);
        importResults.add(importResult);
      }

      return importResults;
    } catch (e) {
      debugPrint('Error picking files: $e');
      return [ImportResult.error('Failed to pick files: $e')];
    }
  }

  /// Process a single picked file
  Future<ImportResult> _processFile(PlatformFile file) async {
    try {
      // Check if file has data
      if (file.bytes == null) {
        return ImportResult.error('No file data for ${file.name}');
      }

      // Check file size
      if (file.size > maxFileSize) {
        return ImportResult.error(
          'File ${file.name} is too large (max ${maxFileSize ~/ (1024 * 1024)}MB)',
        );
      }

      // Determine file type from extension
      final extension = file.extension ?? '';
      final type = ResearchItemType.fromExtension(extension);

      // Determine MIME type
      final mimeType = _getMimeType(extension);

      // Create research item
      final researchItem = ResearchItem.fromImport(
        title: _getFileNameWithoutExtension(file.name),
        type: type,
        data: file.bytes!,
        mimeType: mimeType,
      );

      return ImportResult.success(researchItem);
    } catch (e) {
      return ImportResult.error('Failed to process ${file.name}: $e');
    }
  }

  /// Import from raw bytes (useful for drag-and-drop or programmatic import)
  ResearchItem? importFromBytes({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
    String? description,
  }) {
    try {
      if (bytes.length > maxFileSize) {
        debugPrint('File too large: ${bytes.length} bytes');
        return null;
      }

      // Determine type from extension or mime type
      final extension = fileName.split('.').last;
      final type = mimeType != null
          ? ResearchItemType.fromMimeType(mimeType)
          : ResearchItemType.fromExtension(extension);

      return ResearchItem.fromImport(
        title: _getFileNameWithoutExtension(fileName),
        type: type,
        data: bytes,
        mimeType: mimeType ?? _getMimeType(extension),
        description: description,
      );
    } catch (e) {
      debugPrint('Error importing from bytes: $e');
      return null;
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'txt':
        return 'text/plain';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'webarchive':
        return 'application/x-webarchive';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file name without extension
  String _getFileNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return fileName;
    return fileName.substring(0, lastDot);
  }

  /// Validate file for import
  ValidationResult validateFile(String fileName, int fileSize) {
    // Check extension
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult(
        isValid: false,
        error: 'File type .$extension is not supported',
      );
    }

    // Check size
    if (fileSize > maxFileSize) {
      return ValidationResult(
        isValid: false,
        error: 'File is too large (max ${maxFileSize ~/ (1024 * 1024)}MB)',
      );
    }

    return ValidationResult(isValid: true);
  }
}

/// Result of an import operation
class ImportResult {
  final bool success;
  final ResearchItem? item;
  final String? error;

  ImportResult._({
    required this.success,
    this.item,
    this.error,
  });

  factory ImportResult.success(ResearchItem item) {
    return ImportResult._(success: true, item: item);
  }

  factory ImportResult.error(String error) {
    return ImportResult._(success: false, error: error);
  }
}

/// Result of file validation
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}
