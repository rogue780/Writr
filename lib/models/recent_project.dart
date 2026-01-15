class RecentProject {
  final String name;
  final String path;
  final DateTime lastOpened;

  RecentProject({
    required this.name,
    required this.path,
    required this.lastOpened,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'lastOpened': lastOpened.toIso8601String(),
    };
  }

  // Create from JSON
  factory RecentProject.fromJson(Map<String, dynamic> json) {
    return RecentProject(
      name: json['name'] as String,
      path: json['path'] as String,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
    );
  }

  // Get relative time string (e.g., "2 hours ago")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(lastOpened);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentProject && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
