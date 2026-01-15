import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import '../models/scrivener_project.dart';

/// Service for managing project backups
class BackupService extends ChangeNotifier {
  /// Backup settings
  BackupSettings _settings = const BackupSettings();

  /// List of available backups
  final List<BackupInfo> _backups = [];

  /// Get current settings
  BackupSettings get settings => _settings;

  /// Get all backups sorted by date (newest first)
  List<BackupInfo> get backups => List.unmodifiable(
        _backups..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  /// Get backups for a specific project
  List<BackupInfo> getBackupsForProject(String projectName) {
    return backups.where((b) => b.projectName == projectName).toList();
  }

  /// Update backup settings
  void updateSettings(BackupSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Create a backup of the project
  Future<BackupInfo> createBackup({
    required ScrivenerProject project,
    String? description,
    bool isAutomatic = false,
  }) async {
    final timestamp = DateTime.now();
    final backupName = _generateBackupName(project.name, timestamp, isAutomatic);

    // Create backup archive
    final archive = Archive();

    // Add project metadata
    final metadata = {
      'projectName': project.name,
      'projectPath': project.path,
      'createdAt': timestamp.toIso8601String(),
      'description': description,
      'isAutomatic': isAutomatic,
      'version': '1.0',
    };
    archive.addFile(ArchiveFile(
      'backup_metadata.json',
      utf8.encode(jsonEncode(metadata)).length,
      utf8.encode(jsonEncode(metadata)),
    ));

    // Add binder structure
    final binderJson = _serializeBinderItems(project.binderItems);
    archive.addFile(ArchiveFile(
      'binder.json',
      utf8.encode(jsonEncode(binderJson)).length,
      utf8.encode(jsonEncode(binderJson)),
    ));

    // Add text contents
    for (final entry in project.textContents.entries) {
      final content = utf8.encode(entry.value);
      archive.addFile(ArchiveFile(
        'documents/${entry.key}.txt',
        content.length,
        content,
      ));
    }

    // Add document metadata
    final docMetadata = project.documentMetadata.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    archive.addFile(ArchiveFile(
      'document_metadata.json',
      utf8.encode(jsonEncode(docMetadata)).length,
      utf8.encode(jsonEncode(docMetadata)),
    ));

    // Add settings
    final settingsJson = {
      'autoSave': project.settings.autoSave,
      'autoSaveInterval': project.settings.autoSaveInterval,
      'defaultTextFormat': project.settings.defaultTextFormat,
    };
    archive.addFile(ArchiveFile(
      'settings.json',
      utf8.encode(jsonEncode(settingsJson)).length,
      utf8.encode(jsonEncode(settingsJson)),
    ));

    // Compress archive
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Failed to create backup archive');
    }

    // Calculate size
    final sizeBytes = zipData.length;

    // Create backup info
    final backupInfo = BackupInfo(
      id: timestamp.millisecondsSinceEpoch.toString(),
      projectName: project.name,
      fileName: backupName,
      createdAt: timestamp,
      sizeBytes: sizeBytes,
      description: description,
      isAutomatic: isAutomatic,
      data: Uint8List.fromList(zipData),
    );

    // Add to list
    _backups.add(backupInfo);

    // Enforce retention policy
    _enforceRetentionPolicy(project.name);

    notifyListeners();
    return backupInfo;
  }

  /// Restore a project from backup
  Future<ScrivenerProject?> restoreFromBackup(BackupInfo backup) async {
    if (backup.data == null) {
      throw Exception('Backup data not available');
    }

    try {
      final archive = ZipDecoder().decodeBytes(backup.data!);

      // Read metadata
      final metadataFile = archive.findFile('backup_metadata.json');
      if (metadataFile == null) {
        throw Exception('Invalid backup: missing metadata');
      }
      final metadata = jsonDecode(utf8.decode(metadataFile.content as List<int>))
          as Map<String, dynamic>;

      // Read binder structure
      final binderFile = archive.findFile('binder.json');
      if (binderFile == null) {
        throw Exception('Invalid backup: missing binder');
      }
      final binderJson = jsonDecode(utf8.decode(binderFile.content as List<int>))
          as List<dynamic>;
      final binderItems = _deserializeBinderItems(binderJson);

      // Read text contents
      final textContents = <String, String>{};
      for (final file in archive.files) {
        if (file.name.startsWith('documents/') && file.name.endsWith('.txt')) {
          final docId = file.name
              .replaceFirst('documents/', '')
              .replaceFirst('.txt', '');
          textContents[docId] = utf8.decode(file.content as List<int>);
        }
      }

      // Read settings
      final settingsFile = archive.findFile('settings.json');
      ProjectSettings settings;
      if (settingsFile != null) {
        final settingsJson =
            jsonDecode(utf8.decode(settingsFile.content as List<int>))
                as Map<String, dynamic>;
        settings = ProjectSettings(
          autoSave: settingsJson['autoSave'] as bool? ?? true,
          autoSaveInterval: settingsJson['autoSaveInterval'] as int? ?? 300,
          defaultTextFormat:
              settingsJson['defaultTextFormat'] as String? ?? 'rtf',
        );
      } else {
        settings = ProjectSettings.defaults();
      }

      return ScrivenerProject(
        name: metadata['projectName'] as String,
        path: metadata['projectPath'] as String,
        binderItems: binderItems,
        textContents: textContents,
        settings: settings,
      );
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return null;
    }
  }

  /// Delete a backup
  void deleteBackup(String backupId) {
    _backups.removeWhere((b) => b.id == backupId);
    notifyListeners();
  }

  /// Delete all backups for a project
  void deleteAllBackupsForProject(String projectName) {
    _backups.removeWhere((b) => b.projectName == projectName);
    notifyListeners();
  }

  /// Get backup data for download
  Uint8List? getBackupData(String backupId) {
    final backup = _backups.firstWhere(
      (b) => b.id == backupId,
      orElse: () => throw Exception('Backup not found'),
    );
    return backup.data;
  }

  /// Import backup from file data
  Future<BackupInfo?> importBackup(Uint8List data, String fileName) async {
    try {
      final archive = ZipDecoder().decodeBytes(data);

      // Read metadata
      final metadataFile = archive.findFile('backup_metadata.json');
      if (metadataFile == null) {
        throw Exception('Invalid backup file: missing metadata');
      }

      final metadata = jsonDecode(utf8.decode(metadataFile.content as List<int>))
          as Map<String, dynamic>;

      final backupInfo = BackupInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectName: metadata['projectName'] as String,
        fileName: fileName,
        createdAt: DateTime.parse(metadata['createdAt'] as String),
        sizeBytes: data.length,
        description: metadata['description'] as String?,
        isAutomatic: metadata['isAutomatic'] as bool? ?? false,
        data: data,
      );

      _backups.add(backupInfo);
      notifyListeners();
      return backupInfo;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return null;
    }
  }

  /// Enforce backup retention policy
  void _enforceRetentionPolicy(String projectName) {
    final projectBackups = _backups
        .where((b) => b.projectName == projectName)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Keep only the configured number of backups
    if (projectBackups.length > _settings.maxBackupsPerProject) {
      final toRemove =
          projectBackups.sublist(_settings.maxBackupsPerProject);
      for (final backup in toRemove) {
        _backups.removeWhere((b) => b.id == backup.id);
      }
    }

    // Remove backups older than retention period
    final cutoffDate =
        DateTime.now().subtract(Duration(days: _settings.retentionDays));
    _backups.removeWhere(
      (b) =>
          b.projectName == projectName &&
          b.createdAt.isBefore(cutoffDate) &&
          b.isAutomatic, // Only auto-remove automatic backups
    );
  }

  String _generateBackupName(String projectName, DateTime timestamp, bool isAutomatic) {
    final dateStr =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}';
    final prefix = isAutomatic ? 'auto' : 'manual';
    return '${projectName}_${prefix}_${dateStr}_$timeStr.zip';
  }

  List<Map<String, dynamic>> _serializeBinderItems(List<BinderItem> items) {
    return items.map((item) {
      return {
        'id': item.id,
        'title': item.title,
        'type': item.type.name,
        'label': item.label,
        'status': item.status,
        'children': _serializeBinderItems(item.children),
      };
    }).toList();
  }

  List<BinderItem> _deserializeBinderItems(List<dynamic> items) {
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      return BinderItem(
        id: map['id'] as String,
        title: map['title'] as String,
        type: BinderItemType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => BinderItemType.text,
        ),
        label: map['label'] as String?,
        status: map['status'] as String?,
        children: _deserializeBinderItems(
          (map['children'] as List<dynamic>?) ?? [],
        ),
      );
    }).toList();
  }

  /// Load backups from storage
  void loadBackups(List<Map<String, dynamic>> data) {
    _backups.clear();
    for (final item in data) {
      _backups.add(BackupInfo.fromJson(item));
    }
    notifyListeners();
  }

  /// Export backups list to JSON (without data)
  List<Map<String, dynamic>> toJson() {
    return _backups.map((b) => b.toJson()).toList();
  }

  /// Load settings from JSON
  void loadSettings(Map<String, dynamic> data) {
    _settings = BackupSettings.fromJson(data);
    notifyListeners();
  }

  /// Export settings to JSON
  Map<String, dynamic> settingsToJson() {
    return _settings.toJson();
  }
}

/// Backup configuration settings
class BackupSettings {
  final bool autoBackupOnClose;
  final bool autoBackupOnSave;
  final int autoBackupIntervalMinutes;
  final int maxBackupsPerProject;
  final int retentionDays;
  final bool compressBackups;

  const BackupSettings({
    this.autoBackupOnClose = true,
    this.autoBackupOnSave = false,
    this.autoBackupIntervalMinutes = 30,
    this.maxBackupsPerProject = 25,
    this.retentionDays = 30,
    this.compressBackups = true,
  });

  BackupSettings copyWith({
    bool? autoBackupOnClose,
    bool? autoBackupOnSave,
    int? autoBackupIntervalMinutes,
    int? maxBackupsPerProject,
    int? retentionDays,
    bool? compressBackups,
  }) {
    return BackupSettings(
      autoBackupOnClose: autoBackupOnClose ?? this.autoBackupOnClose,
      autoBackupOnSave: autoBackupOnSave ?? this.autoBackupOnSave,
      autoBackupIntervalMinutes:
          autoBackupIntervalMinutes ?? this.autoBackupIntervalMinutes,
      maxBackupsPerProject: maxBackupsPerProject ?? this.maxBackupsPerProject,
      retentionDays: retentionDays ?? this.retentionDays,
      compressBackups: compressBackups ?? this.compressBackups,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoBackupOnClose': autoBackupOnClose,
      'autoBackupOnSave': autoBackupOnSave,
      'autoBackupIntervalMinutes': autoBackupIntervalMinutes,
      'maxBackupsPerProject': maxBackupsPerProject,
      'retentionDays': retentionDays,
      'compressBackups': compressBackups,
    };
  }

  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      autoBackupOnClose: json['autoBackupOnClose'] as bool? ?? true,
      autoBackupOnSave: json['autoBackupOnSave'] as bool? ?? false,
      autoBackupIntervalMinutes:
          json['autoBackupIntervalMinutes'] as int? ?? 30,
      maxBackupsPerProject: json['maxBackupsPerProject'] as int? ?? 25,
      retentionDays: json['retentionDays'] as int? ?? 30,
      compressBackups: json['compressBackups'] as bool? ?? true,
    );
  }
}

/// Information about a backup
class BackupInfo {
  final String id;
  final String projectName;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
  final String? description;
  final bool isAutomatic;
  final Uint8List? data;

  const BackupInfo({
    required this.id,
    required this.projectName,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
    this.description,
    this.isAutomatic = false,
    this.data,
  });

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDate {
    return '${createdAt.month}/${createdAt.day}/${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get ageDescription {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectName': projectName,
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
      'sizeBytes': sizeBytes,
      'description': description,
      'isAutomatic': isAutomatic,
      // Note: data is not serialized to JSON
    };
  }

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      id: json['id'] as String,
      projectName: json['projectName'] as String,
      fileName: json['fileName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sizeBytes: json['sizeBytes'] as int,
      description: json['description'] as String?,
      isAutomatic: json['isAutomatic'] as bool? ?? false,
    );
  }
}
