/// Represents a file or folder in cloud storage
class CloudFile {
  final String id;
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedTime;
  final String? mimeType;

  CloudFile({
    required this.id,
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedTime,
    this.mimeType,
  });

  /// Check if this is a Scrivener project folder
  bool get isScrivenerProject => isDirectory && name.endsWith('.scriv');

  @override
  String toString() => 'CloudFile(name: $name, isDir: $isDirectory)';
}
