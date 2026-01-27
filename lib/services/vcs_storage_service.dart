import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/vcs/commit.dart';

/// Service for low-level VCS storage operations.
/// Handles blob storage, commit persistence, and directory structure.
class VcsStorageService {
  final String projectPath;
  late final String _vcsPath;

  VcsStorageService(this.projectPath) {
    _vcsPath = '$projectPath/.writrc';
  }

  // Directory paths
  String get vcsPath => _vcsPath;
  String get objectsPath => '$_vcsPath/objects';
  String get commitsPath => '$_vcsPath/commits';
  String get refsPath => '$_vcsPath/refs';
  String get headsPath => '$refsPath/heads';
  String get tagsPath => '$refsPath/tags';
  String get mergePath => '$_vcsPath/merge';
  String get logsPath => '$_vcsPath/logs';
  String get headFile => '$_vcsPath/HEAD';
  String get configFile => '$_vcsPath/config.json';

  /// Check if VCS is initialized for this project.
  Future<bool> isInitialized() async {
    if (kIsWeb) return false; // VCS not supported on web yet
    return Directory(_vcsPath).exists();
  }

  /// Initialize VCS directory structure.
  Future<void> initialize() async {
    if (kIsWeb) {
      throw UnsupportedError('VCS not supported on web platform');
    }

    // Create directory structure
    await Directory(objectsPath).create(recursive: true);
    await Directory(commitsPath).create(recursive: true);
    await Directory(headsPath).create(recursive: true);
    await Directory(tagsPath).create(recursive: true);
    await Directory(logsPath).create(recursive: true);

    // Create default config
    final config = {
      'version': '1.0',
      'autoCommit': true,
      'author': 'Writr',
    };
    await File(configFile).writeAsString(jsonEncode(config));
  }

  // ============ Blob Operations ============

  /// Compute SHA-256 hash of content.
  String computeHash(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  /// Get the file path for a blob by its hash.
  String _getBlobPath(String hash) {
    final prefix = hash.substring(0, 2);
    final suffix = hash.substring(2);
    return '$objectsPath/$prefix/$suffix';
  }

  /// Store content as a blob and return its hash.
  Future<String> storeBlob(String content) async {
    final hash = computeHash(content);
    final blobPath = _getBlobPath(hash);
    final blobFile = File(blobPath);

    // Skip if blob already exists (content-addressable)
    if (await blobFile.exists()) {
      return hash;
    }

    // Create parent directory and write blob
    await blobFile.parent.create(recursive: true);

    // Compress content with gzip for storage efficiency
    final compressed = gzip.encode(utf8.encode(content));
    await blobFile.writeAsBytes(compressed);

    return hash;
  }

  /// Retrieve blob content by hash.
  Future<String?> retrieveBlob(String hash) async {
    final blobPath = _getBlobPath(hash);
    final blobFile = File(blobPath);

    if (!await blobFile.exists()) {
      return null;
    }

    // Decompress content
    final compressed = await blobFile.readAsBytes();
    final decompressed = gzip.decode(compressed);
    return utf8.decode(decompressed);
  }

  /// Check if a blob exists.
  Future<bool> blobExists(String hash) async {
    final blobPath = _getBlobPath(hash);
    return File(blobPath).exists();
  }

  // ============ Commit Operations ============

  /// Get the file path for a commit by its hash.
  String _getCommitPath(String hash) {
    final prefix = hash.substring(0, 2);
    final suffix = hash.substring(2);
    return '$commitsPath/$prefix/$suffix.json';
  }

  /// Store a commit object.
  Future<void> storeCommit(VcsCommit commit) async {
    final commitPath = _getCommitPath(commit.hash);
    final commitFile = File(commitPath);

    await commitFile.parent.create(recursive: true);
    await commitFile.writeAsString(jsonEncode(commit.toJson()));
  }

  /// Retrieve a commit by hash.
  Future<VcsCommit?> retrieveCommit(String hash) async {
    final commitPath = _getCommitPath(hash);
    final commitFile = File(commitPath);

    if (!await commitFile.exists()) {
      return null;
    }

    final json = jsonDecode(await commitFile.readAsString());
    return VcsCommit.fromJson(json);
  }

  /// Get all commits (for history traversal).
  Future<List<VcsCommit>> getAllCommits() async {
    final commits = <VcsCommit>[];
    final commitsDir = Directory(commitsPath);

    if (!await commitsDir.exists()) {
      return commits;
    }

    await for (final prefixDir in commitsDir.list()) {
      if (prefixDir is Directory) {
        await for (final commitFile in prefixDir.list()) {
          if (commitFile is File && commitFile.path.endsWith('.json')) {
            try {
              final json = jsonDecode(await commitFile.readAsString());
              commits.add(VcsCommit.fromJson(json));
            } catch (e) {
              debugPrint('Error reading commit: ${commitFile.path}: $e');
            }
          }
        }
      }
    }

    // Sort by timestamp descending (newest first)
    commits.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return commits;
  }

  // ============ Branch Operations ============

  /// Get the file path for a branch reference.
  String _getBranchPath(String branchName) => '$headsPath/$branchName';

  /// Store a branch reference.
  Future<void> storeBranch(VcsBranch branch) async {
    final branchFile = File(_getBranchPath(branch.name));
    await branchFile.parent.create(recursive: true);
    await branchFile.writeAsString(jsonEncode(branch.toJson()));
  }

  /// Retrieve a branch reference.
  Future<VcsBranch?> retrieveBranch(String branchName) async {
    final branchFile = File(_getBranchPath(branchName));

    if (!await branchFile.exists()) {
      return null;
    }

    final json = jsonDecode(await branchFile.readAsString());
    return VcsBranch.fromJson(json);
  }

  /// Delete a branch reference.
  Future<void> deleteBranch(String branchName) async {
    final branchFile = File(_getBranchPath(branchName));
    if (await branchFile.exists()) {
      await branchFile.delete();
    }
  }

  /// Get all branch names.
  Future<List<String>> getBranchNames() async {
    final headsDir = Directory(headsPath);
    if (!await headsDir.exists()) {
      return [];
    }

    final names = <String>[];
    await for (final entity in headsDir.list()) {
      if (entity is File) {
        names.add(entity.uri.pathSegments.last);
      }
    }
    return names;
  }

  /// Get all branches with their data.
  Future<List<VcsBranch>> getAllBranches() async {
    final branches = <VcsBranch>[];
    for (final name in await getBranchNames()) {
      final branch = await retrieveBranch(name);
      if (branch != null) {
        branches.add(branch);
      }
    }
    return branches;
  }

  // ============ HEAD Operations ============

  /// Read the current HEAD.
  Future<VcsHead?> readHead() async {
    final file = File(headFile);

    if (!await file.exists()) {
      return null;
    }

    final json = jsonDecode(await file.readAsString());
    return VcsHead.fromJson(json);
  }

  /// Write the HEAD reference.
  Future<void> writeHead(VcsHead head) async {
    final file = File(headFile);
    await file.writeAsString(jsonEncode(head.toJson()));
  }

  // ============ Config Operations ============

  /// Read VCS configuration.
  Future<Map<String, dynamic>> readConfig() async {
    final file = File(configFile);

    if (!await file.exists()) {
      return {'version': '1.0', 'autoCommit': true, 'author': 'Writr'};
    }

    return jsonDecode(await file.readAsString());
  }

  /// Write VCS configuration.
  Future<void> writeConfig(Map<String, dynamic> config) async {
    final file = File(configFile);
    await file.writeAsString(jsonEncode(config));
  }

  // ============ Merge State Operations ============

  /// Check if a merge is in progress.
  Future<bool> isMergeInProgress() async {
    return Directory(mergePath).exists();
  }

  /// Create merge directory for in-progress merge.
  Future<void> createMergeState() async {
    await Directory(mergePath).create(recursive: true);
  }

  /// Clean up merge directory.
  Future<void> cleanupMergeState() async {
    final mergeDir = Directory(mergePath);
    if (await mergeDir.exists()) {
      await mergeDir.delete(recursive: true);
    }
  }

  // ============ Utility Operations ============

  /// Get total size of VCS storage in bytes.
  Future<int> getStorageSize() async {
    int totalSize = 0;
    final vcsDir = Directory(_vcsPath);

    if (!await vcsDir.exists()) {
      return 0;
    }

    await for (final entity in vcsDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// Get count of commits.
  Future<int> getCommitCount() async {
    int count = 0;
    final commitsDir = Directory(commitsPath);

    if (!await commitsDir.exists()) {
      return 0;
    }

    await for (final prefixDir in commitsDir.list()) {
      if (prefixDir is Directory) {
        await for (final _ in prefixDir.list()) {
          count++;
        }
      }
    }

    return count;
  }

  /// Garbage collection - remove unreferenced blobs.
  /// This should be called periodically to clean up orphaned data.
  Future<int> collectGarbage() async {
    // Get all referenced blob hashes from commits
    final referencedHashes = <String>{};
    final commits = await getAllCommits();

    for (final commit in commits) {
      referencedHashes.addAll(commit.documentHashes.values);
      referencedHashes.addAll(commit.metadataHashes.values);
      referencedHashes.add(commit.binderHash);
    }

    // Find and delete unreferenced blobs
    int deletedCount = 0;
    final objectsDir = Directory(objectsPath);

    if (!await objectsDir.exists()) {
      return 0;
    }

    await for (final prefixDir in objectsDir.list()) {
      if (prefixDir is Directory) {
        final prefix = prefixDir.uri.pathSegments[prefixDir.uri.pathSegments.length - 2];
        await for (final blobFile in prefixDir.list()) {
          if (blobFile is File) {
            final suffix = blobFile.uri.pathSegments.last;
            final hash = '$prefix$suffix';
            if (!referencedHashes.contains(hash)) {
              await blobFile.delete();
              deletedCount++;
            }
          }
        }
      }
    }

    return deletedCount;
  }
}
