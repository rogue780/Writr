enum CloudProvider {
  googleDrive,
  dropbox,
  oneDrive,
  local,
}

class CloudFile {
  final String id;
  final String name;
  final String path;
  final CloudProvider provider;
  final bool isDirectory;
  final DateTime? modifiedDate;
  final int? size;

  CloudFile({
    required this.id,
    required this.name,
    required this.path,
    required this.provider,
    required this.isDirectory,
    this.modifiedDate,
    this.size,
  });

  bool get isScrivenerProject => name.endsWith('.scriv');
}

class CloudStorageCredentials {
  final CloudProvider provider;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiryDate;

  CloudStorageCredentials({
    required this.provider,
    this.accessToken,
    this.refreshToken,
    this.expiryDate,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}
