import 'dart:convert';
import 'package:crypto/crypto.dart';

/// A single commit in the version control history.
class VcsCommit {
  final String hash;
  final String? parentHash;
  final String? mergeParentHash;
  final DateTime timestamp;
  final String message;
  final String author;
  final Map<String, String> documentHashes;
  final Map<String, String> metadataHashes;
  final String binderHash;

  const VcsCommit({
    required this.hash,
    this.parentHash,
    this.mergeParentHash,
    required this.timestamp,
    required this.message,
    required this.author,
    required this.documentHashes,
    required this.metadataHashes,
    required this.binderHash,
  });

  bool get isMergeCommit => mergeParentHash != null;

  /// Compute SHA-256 hash for a commit based on its content.
  static String computeHash({
    required String? parentHash,
    required String? mergeParentHash,
    required DateTime timestamp,
    required String message,
    required String author,
    required Map<String, String> documentHashes,
    required Map<String, String> metadataHashes,
    required String binderHash,
  }) {
    final sortedDocHashes = Map.fromEntries(
      documentHashes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedMetaHashes = Map.fromEntries(
      metadataHashes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final content = jsonEncode({
      'parent': parentHash,
      'mergeParent': mergeParentHash,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'message': message,
      'author': author,
      'documents': sortedDocHashes,
      'metadata': sortedMetaHashes,
      'binder': binderHash,
    });

    return sha256.convert(utf8.encode(content)).toString();
  }

  /// Create a commit with auto-computed hash.
  factory VcsCommit.create({
    String? parentHash,
    String? mergeParentHash,
    required DateTime timestamp,
    required String message,
    required String author,
    required Map<String, String> documentHashes,
    required Map<String, String> metadataHashes,
    required String binderHash,
  }) {
    final hash = computeHash(
      parentHash: parentHash,
      mergeParentHash: mergeParentHash,
      timestamp: timestamp,
      message: message,
      author: author,
      documentHashes: documentHashes,
      metadataHashes: metadataHashes,
      binderHash: binderHash,
    );

    return VcsCommit(
      hash: hash,
      parentHash: parentHash,
      mergeParentHash: mergeParentHash,
      timestamp: timestamp,
      message: message,
      author: author,
      documentHashes: documentHashes,
      metadataHashes: metadataHashes,
      binderHash: binderHash,
    );
  }

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'parent': parentHash,
        'mergeParent': mergeParentHash,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'message': message,
        'author': author,
        'documents': documentHashes,
        'metadata': metadataHashes,
        'binder': binderHash,
      };

  factory VcsCommit.fromJson(Map<String, dynamic> json) => VcsCommit(
        hash: json['hash'] as String,
        parentHash: json['parent'] as String?,
        mergeParentHash: json['mergeParent'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        message: json['message'] as String,
        author: json['author'] as String,
        documentHashes: Map<String, String>.from(json['documents'] as Map),
        metadataHashes: Map<String, String>.from(json['metadata'] as Map),
        binderHash: json['binder'] as String,
      );
}

/// Branch reference pointing to a commit.
class VcsBranch {
  final String name;
  final String headCommitHash;
  final DateTime createdAt;
  final String? createdFromHash;
  final String? description;

  const VcsBranch({
    required this.name,
    required this.headCommitHash,
    required this.createdAt,
    this.createdFromHash,
    this.description,
  });

  VcsBranch copyWith({
    String? name,
    String? headCommitHash,
    DateTime? createdAt,
    String? createdFromHash,
    String? description,
  }) {
    return VcsBranch(
      name: name ?? this.name,
      headCommitHash: headCommitHash ?? this.headCommitHash,
      createdAt: createdAt ?? this.createdAt,
      createdFromHash: createdFromHash ?? this.createdFromHash,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'commit': headCommitHash,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'createdFrom': createdFromHash,
        'description': description,
      };

  factory VcsBranch.fromJson(Map<String, dynamic> json) => VcsBranch(
        name: json['name'] as String,
        headCommitHash: json['commit'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdFromHash: json['createdFrom'] as String?,
        description: json['description'] as String?,
      );
}

/// HEAD reference - tracks current position in the repository.
class VcsHead {
  final String? branchName;
  final String commitHash;

  const VcsHead({
    this.branchName,
    required this.commitHash,
  });

  bool get isDetached => branchName == null;

  Map<String, dynamic> toJson() => {
        'type': isDetached ? 'commit' : 'branch',
        if (branchName != null) 'ref': 'refs/heads/$branchName',
        'hash': commitHash,
      };

  factory VcsHead.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    String? branchName;

    if (type == 'branch') {
      final ref = json['ref'] as String;
      branchName = ref.replaceFirst('refs/heads/', '');
    }

    return VcsHead(
      branchName: branchName,
      commitHash: json['hash'] as String,
    );
  }

  factory VcsHead.onBranch(String branchName, String commitHash) => VcsHead(
        branchName: branchName,
        commitHash: commitHash,
      );

  factory VcsHead.detached(String commitHash) => VcsHead(
        commitHash: commitHash,
      );
}

/// Blob type for content-addressable storage.
enum VcsBlobType { text, metadata, binder }

/// Content blob stored by hash.
class VcsBlob {
  final String hash;
  final String content;
  final VcsBlobType type;

  const VcsBlob({
    required this.hash,
    required this.content,
    required this.type,
  });

  /// Compute SHA-256 hash of content.
  static String computeHash(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  /// Create a blob with auto-computed hash.
  factory VcsBlob.create(String content, VcsBlobType type) {
    return VcsBlob(
      hash: computeHash(content),
      content: content,
      type: type,
    );
  }
}

/// History entry for display in the timeline.
class VcsHistoryEntry {
  final VcsCommit commit;
  final List<String> branchNames;
  final bool isHead;
  final int graphColumn;
  final List<int> parentColumns;

  const VcsHistoryEntry({
    required this.commit,
    required this.branchNames,
    required this.isHead,
    this.graphColumn = 0,
    this.parentColumns = const [],
  });
}

/// Summary of changes between two commits.
class VcsCommitDiff {
  final String fromHash;
  final String toHash;
  final List<VcsDocumentChange> documentChanges;
  final bool binderChanged;
  final int totalAdditions;
  final int totalDeletions;

  const VcsCommitDiff({
    required this.fromHash,
    required this.toHash,
    required this.documentChanges,
    required this.binderChanged,
    required this.totalAdditions,
    required this.totalDeletions,
  });
}

/// Change type for a document between commits.
enum VcsChangeType { added, modified, deleted, renamed }

/// Document change information.
class VcsDocumentChange {
  final String documentId;
  final String documentTitle;
  final VcsChangeType type;
  final int additions;
  final int deletions;
  final String? oldContent;
  final String? newContent;

  const VcsDocumentChange({
    required this.documentId,
    required this.documentTitle,
    required this.type,
    required this.additions,
    required this.deletions,
    this.oldContent,
    this.newContent,
  });
}
