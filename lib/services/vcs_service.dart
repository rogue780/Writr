import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/scrivener_project.dart';
import '../models/vcs/commit.dart';
import '../models/vcs/merge.dart';
import 'vcs_storage_service.dart';

/// Main service for version control operations.
/// Provides high-level commit, branch, merge, and history operations.
class VcsService extends ChangeNotifier {
  VcsStorageService? _storage;
  VcsHead? _head;
  List<VcsBranch> _branches = [];
  VcsMergeState? _activeMerge;
  String _author = 'Writr';

  // Getters
  bool get isInitialized => _storage != null && _head != null;
  VcsHead? get head => _head;
  List<VcsBranch> get branches => List.unmodifiable(_branches);
  VcsMergeState? get activeMerge => _activeMerge;
  bool get isMergeInProgress => _activeMerge != null;
  String get author => _author;

  VcsBranch? get currentBranch {
    if (_head?.branchName == null) return null;
    try {
      return _branches.firstWhere((b) => b.name == _head!.branchName);
    } catch (_) {
      return null;
    }
  }

  /// Initialize VCS for a project.
  Future<void> initialize(String projectPath) async {
    if (kIsWeb) {
      debugPrint('VCS not supported on web platform');
      return;
    }

    _storage = VcsStorageService(projectPath);

    // Check if VCS already exists
    if (await _storage!.isInitialized()) {
      // Load existing state
      await _loadState();
    }
    // VCS will be initialized on first commit if needed

    notifyListeners();
  }

  /// Load VCS state from storage.
  Future<void> _loadState() async {
    if (_storage == null) return;

    _head = await _storage!.readHead();
    _branches = await _storage!.getAllBranches();

    // Load author from config
    final config = await _storage!.readConfig();
    _author = config['author'] ?? 'Writr';

    // Check for in-progress merge
    if (await _storage!.isMergeInProgress()) {
      // TODO: Load merge state
    }

    notifyListeners();
  }

  /// Set the author name for commits.
  Future<void> setAuthor(String name) async {
    _author = name;
    if (_storage != null) {
      final config = await _storage!.readConfig();
      config['author'] = name;
      await _storage!.writeConfig(config);
    }
    notifyListeners();
  }

  // ============ Commit Operations ============

  /// Create a commit from the current project state.
  /// Returns the new commit, or null if nothing changed.
  Future<VcsCommit?> commit({
    required ScrivenerProject project,
    String? message,
  }) async {
    if (_storage == null) return null;

    // Initialize VCS if this is the first commit
    if (!await _storage!.isInitialized()) {
      await _storage!.initialize();
    }

    // Store document blobs
    final documentHashes = <String, String>{};
    for (final entry in project.textContents.entries) {
      final hash = await _storage!.storeBlob(entry.value);
      documentHashes[entry.key] = hash;
    }

    // Store metadata blobs
    final metadataHashes = <String, String>{};
    for (final entry in project.documentMetadata.entries) {
      final metadataJson = jsonEncode(entry.value.toJson());
      final hash = await _storage!.storeBlob(metadataJson);
      metadataHashes[entry.key] = hash;
    }

    // Store binder structure
    final binderJson = jsonEncode(_serializeBinder(project.binderItems));
    final binderHash = await _storage!.storeBlob(binderJson);

    // Check if anything changed from last commit
    if (_head != null) {
      final lastCommit = await _storage!.retrieveCommit(_head!.commitHash);
      if (lastCommit != null &&
          _mapsEqual(lastCommit.documentHashes, documentHashes) &&
          _mapsEqual(lastCommit.metadataHashes, metadataHashes) &&
          lastCommit.binderHash == binderHash) {
        // Nothing changed
        return null;
      }
    }

    // Generate auto message if not provided
    final commitMessage = message ?? _generateAutoMessage(project, documentHashes);

    // Create commit
    final commit = VcsCommit.create(
      parentHash: _head?.commitHash,
      timestamp: DateTime.now(),
      message: commitMessage,
      author: _author,
      documentHashes: documentHashes,
      metadataHashes: metadataHashes,
      binderHash: binderHash,
    );

    // Store commit
    await _storage!.storeCommit(commit);

    // Update or create main branch
    if (_head == null) {
      // First commit - create main branch
      final mainBranch = VcsBranch(
        name: 'main',
        headCommitHash: commit.hash,
        createdAt: DateTime.now(),
      );
      await _storage!.storeBranch(mainBranch);
      _branches = [mainBranch];
      _head = VcsHead.onBranch('main', commit.hash);
    } else if (_head!.branchName != null) {
      // Update current branch
      final branch = currentBranch!.copyWith(headCommitHash: commit.hash);
      await _storage!.storeBranch(branch);
      _branches = _branches.map((b) => b.name == branch.name ? branch : b).toList();
      _head = VcsHead.onBranch(_head!.branchName!, commit.hash);
    } else {
      // Detached HEAD - just update HEAD
      _head = VcsHead.detached(commit.hash);
    }

    await _storage!.writeHead(_head!);
    notifyListeners();

    return commit;
  }

  /// Generate an auto-commit message based on changes.
  String _generateAutoMessage(
      ScrivenerProject project, Map<String, String> newDocHashes) {
    final changedDocs = <String>[];

    // Find document titles for changed documents
    for (final docId in newDocHashes.keys) {
      final item = _findBinderItem(project.binderItems, docId);
      if (item != null) {
        changedDocs.add(item.title);
      }
    }

    if (changedDocs.isEmpty) {
      return 'Auto-save';
    } else if (changedDocs.length == 1) {
      return 'Auto-save: ${changedDocs.first}';
    } else if (changedDocs.length <= 3) {
      return 'Auto-save: ${changedDocs.join(", ")}';
    } else {
      return 'Auto-save: ${changedDocs.take(2).join(", ")} and ${changedDocs.length - 2} more';
    }
  }

  /// Find a binder item by ID.
  BinderItem? _findBinderItem(List<BinderItem> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
      final found = _findBinderItem(item.children, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Serialize binder structure for storage.
  List<Map<String, dynamic>> _serializeBinder(List<BinderItem> items) {
    return items.map((item) => {
          'id': item.id,
          'title': item.title,
          'type': item.type.name,
          'children': _serializeBinder(item.children),
        }).toList();
  }

  /// Compare two maps for equality.
  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  // ============ Branch Operations ============

  /// Create a new branch from the current HEAD.
  Future<VcsBranch?> createBranch(String name, {String? description}) async {
    if (_storage == null || _head == null) return null;

    // Validate branch name
    if (name.isEmpty || name.contains(' ') || name.contains('/')) {
      throw ArgumentError('Invalid branch name: $name');
    }

    // Check if branch already exists
    if (_branches.any((b) => b.name == name)) {
      throw StateError('Branch already exists: $name');
    }

    final branch = VcsBranch(
      name: name,
      headCommitHash: _head!.commitHash,
      createdAt: DateTime.now(),
      createdFromHash: _head!.commitHash,
      description: description,
    );

    await _storage!.storeBranch(branch);
    _branches = [..._branches, branch];
    notifyListeners();

    return branch;
  }

  /// Checkout a branch, updating the working tree.
  /// Returns the commit that was checked out.
  Future<VcsCommit?> checkoutBranch(String branchName) async {
    if (_storage == null) return null;

    final branch = _branches.firstWhere(
      (b) => b.name == branchName,
      orElse: () => throw StateError('Branch not found: $branchName'),
    );

    final commit = await _storage!.retrieveCommit(branch.headCommitHash);
    if (commit == null) {
      throw StateError('Commit not found: ${branch.headCommitHash}');
    }

    _head = VcsHead.onBranch(branchName, commit.hash);
    await _storage!.writeHead(_head!);
    notifyListeners();

    return commit;
  }

  /// Delete a branch.
  Future<void> deleteBranch(String branchName) async {
    if (_storage == null) return;

    // Can't delete current branch
    if (_head?.branchName == branchName) {
      throw StateError('Cannot delete the current branch');
    }

    // Can't delete main branch
    if (branchName == 'main') {
      throw StateError('Cannot delete the main branch');
    }

    await _storage!.deleteBranch(branchName);
    _branches = _branches.where((b) => b.name != branchName).toList();
    notifyListeners();
  }

  // ============ History Operations ============

  /// Get commit history for the current branch.
  Future<List<VcsHistoryEntry>> getHistory({int? limit}) async {
    if (_storage == null || _head == null) return [];

    final allCommits = await _storage!.getAllCommits();
    final branchHeads = {for (final b in _branches) b.headCommitHash: b.name};

    // Build history entries
    final entries = <VcsHistoryEntry>[];
    for (final commit in allCommits) {
      if (limit != null && entries.length >= limit) break;

      final branchNames = <String>[];
      if (branchHeads.containsKey(commit.hash)) {
        branchNames.add(branchHeads[commit.hash]!);
      }

      entries.add(VcsHistoryEntry(
        commit: commit,
        branchNames: branchNames,
        isHead: commit.hash == _head!.commitHash,
      ));
    }

    return entries;
  }

  /// Get a specific commit.
  Future<VcsCommit?> getCommit(String hash) async {
    return _storage?.retrieveCommit(hash);
  }

  /// Get diff between two commits.
  Future<VcsCommitDiff?> getDiff(String fromHash, String toHash) async {
    if (_storage == null) return null;

    final fromCommit = await _storage!.retrieveCommit(fromHash);
    final toCommit = await _storage!.retrieveCommit(toHash);

    if (fromCommit == null || toCommit == null) return null;

    final changes = <VcsDocumentChange>[];
    int totalAdditions = 0;
    int totalDeletions = 0;

    // Find added and modified documents
    for (final entry in toCommit.documentHashes.entries) {
      final docId = entry.key;
      final toHash = entry.value;
      final fromHash = fromCommit.documentHashes[docId];

      if (fromHash == null) {
        // Added
        final content = await _storage!.retrieveBlob(toHash);
        final lines = content?.split('\n').length ?? 0;
        changes.add(VcsDocumentChange(
          documentId: docId,
          documentTitle: docId, // TODO: Get actual title
          type: VcsChangeType.added,
          additions: lines,
          deletions: 0,
          newContent: content,
        ));
        totalAdditions += lines;
      } else if (fromHash != toHash) {
        // Modified
        final oldContent = await _storage!.retrieveBlob(fromHash);
        final newContent = await _storage!.retrieveBlob(toHash);
        final (additions, deletions) = _countDiff(oldContent, newContent);
        changes.add(VcsDocumentChange(
          documentId: docId,
          documentTitle: docId,
          type: VcsChangeType.modified,
          additions: additions,
          deletions: deletions,
          oldContent: oldContent,
          newContent: newContent,
        ));
        totalAdditions += additions;
        totalDeletions += deletions;
      }
    }

    // Find deleted documents
    for (final entry in fromCommit.documentHashes.entries) {
      final docId = entry.key;
      if (!toCommit.documentHashes.containsKey(docId)) {
        final content = await _storage!.retrieveBlob(entry.value);
        final lines = content?.split('\n').length ?? 0;
        changes.add(VcsDocumentChange(
          documentId: docId,
          documentTitle: docId,
          type: VcsChangeType.deleted,
          additions: 0,
          deletions: lines,
          oldContent: content,
        ));
        totalDeletions += lines;
      }
    }

    return VcsCommitDiff(
      fromHash: fromHash,
      toHash: toHash,
      documentChanges: changes,
      binderChanged: fromCommit.binderHash != toCommit.binderHash,
      totalAdditions: totalAdditions,
      totalDeletions: totalDeletions,
    );
  }

  /// Count additions and deletions between two content strings.
  (int additions, int deletions) _countDiff(String? oldContent, String? newContent) {
    final oldLines = oldContent?.split('\n') ?? [];
    final newLines = newContent?.split('\n') ?? [];

    // Simple diff: count non-matching lines
    int additions = 0;
    int deletions = 0;

    final oldSet = oldLines.toSet();
    final newSet = newLines.toSet();

    for (final line in newLines) {
      if (!oldSet.contains(line)) additions++;
    }
    for (final line in oldLines) {
      if (!newSet.contains(line)) deletions++;
    }

    return (additions, deletions);
  }

  // ============ Restore Operations ============

  /// Restore project state from a commit.
  /// Returns the document contents and binder structure.
  Future<({Map<String, String> contents, List<Map<String, dynamic>> binder})?>
      restoreFromCommit(String commitHash) async {
    if (_storage == null) return null;

    final commit = await _storage!.retrieveCommit(commitHash);
    if (commit == null) return null;

    // Restore document contents
    final contents = <String, String>{};
    for (final entry in commit.documentHashes.entries) {
      final content = await _storage!.retrieveBlob(entry.value);
      if (content != null) {
        contents[entry.key] = content;
      }
    }

    // Restore binder structure
    final binderJson = await _storage!.retrieveBlob(commit.binderHash);
    final binder = binderJson != null
        ? List<Map<String, dynamic>>.from(jsonDecode(binderJson))
        : <Map<String, dynamic>>[];

    return (contents: contents, binder: binder);
  }

  // ============ Stats ============

  /// Get VCS statistics.
  Future<Map<String, dynamic>> getStats() async {
    if (_storage == null) {
      return {'initialized': false};
    }

    return {
      'initialized': await _storage!.isInitialized(),
      'commitCount': await _storage!.getCommitCount(),
      'branchCount': _branches.length,
      'storageSize': await _storage!.getStorageSize(),
      'currentBranch': _head?.branchName ?? 'detached',
    };
  }
}
