/// Represents a merge conflict in a single document.
class VcsMergeConflict {
  final String documentId;
  final String documentTitle;
  final String baseContent;
  final String oursContent;
  final String theirsContent;
  final List<VcsConflictRegion> regions;
  String? resolvedContent;

  VcsMergeConflict({
    required this.documentId,
    required this.documentTitle,
    required this.baseContent,
    required this.oursContent,
    required this.theirsContent,
    required this.regions,
    this.resolvedContent,
  });

  bool get isResolved => resolvedContent != null;

  VcsMergeConflict copyWith({
    String? documentId,
    String? documentTitle,
    String? baseContent,
    String? oursContent,
    String? theirsContent,
    List<VcsConflictRegion>? regions,
    String? resolvedContent,
  }) {
    return VcsMergeConflict(
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      baseContent: baseContent ?? this.baseContent,
      oursContent: oursContent ?? this.oursContent,
      theirsContent: theirsContent ?? this.theirsContent,
      regions: regions ?? this.regions,
      resolvedContent: resolvedContent ?? this.resolvedContent,
    );
  }
}

/// A specific conflicting region within a document.
class VcsConflictRegion {
  final int startLine;
  final int endLine;
  final String baseText;
  final String oursText;
  final String theirsText;
  VcsConflictChoice choice;

  VcsConflictRegion({
    required this.startLine,
    required this.endLine,
    required this.baseText,
    required this.oursText,
    required this.theirsText,
    this.choice = VcsConflictChoice.manual,
  });

  bool get isResolved => choice != VcsConflictChoice.manual;

  String get resolvedText {
    switch (choice) {
      case VcsConflictChoice.ours:
        return oursText;
      case VcsConflictChoice.theirs:
        return theirsText;
      case VcsConflictChoice.both:
        return '$oursText\n\n$theirsText';
      case VcsConflictChoice.manual:
        return '';
    }
  }
}

/// How a conflict was resolved.
enum VcsConflictChoice { ours, theirs, both, manual }

/// Merge state during an in-progress merge.
class VcsMergeState {
  final String sourceBranchName;
  final String targetBranchName;
  final String sourceCommitHash;
  final String targetCommitHash;
  final String? baseCommitHash;
  final List<VcsMergeConflict> conflicts;
  final List<String> autoMergedDocIds;
  final VcsMergeStatus status;

  const VcsMergeState({
    required this.sourceBranchName,
    required this.targetBranchName,
    required this.sourceCommitHash,
    required this.targetCommitHash,
    this.baseCommitHash,
    required this.conflicts,
    required this.autoMergedDocIds,
    required this.status,
  });

  bool get hasConflicts => conflicts.isNotEmpty;

  bool get allConflictsResolved =>
      conflicts.every((conflict) => conflict.isResolved);

  int get unresolvedCount =>
      conflicts.where((conflict) => !conflict.isResolved).length;

  VcsMergeState copyWith({
    String? sourceBranchName,
    String? targetBranchName,
    String? sourceCommitHash,
    String? targetCommitHash,
    String? baseCommitHash,
    List<VcsMergeConflict>? conflicts,
    List<String>? autoMergedDocIds,
    VcsMergeStatus? status,
  }) {
    return VcsMergeState(
      sourceBranchName: sourceBranchName ?? this.sourceBranchName,
      targetBranchName: targetBranchName ?? this.targetBranchName,
      sourceCommitHash: sourceCommitHash ?? this.sourceCommitHash,
      targetCommitHash: targetCommitHash ?? this.targetCommitHash,
      baseCommitHash: baseCommitHash ?? this.baseCommitHash,
      conflicts: conflicts ?? this.conflicts,
      autoMergedDocIds: autoMergedDocIds ?? this.autoMergedDocIds,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceBranch': sourceBranchName,
        'targetBranch': targetBranchName,
        'sourceCommit': sourceCommitHash,
        'targetCommit': targetCommitHash,
        'baseCommit': baseCommitHash,
        'autoMergedDocIds': autoMergedDocIds,
        'status': status.name,
      };

  factory VcsMergeState.fromJson(Map<String, dynamic> json) => VcsMergeState(
        sourceBranchName: json['sourceBranch'] as String,
        targetBranchName: json['targetBranch'] as String,
        sourceCommitHash: json['sourceCommit'] as String,
        targetCommitHash: json['targetCommit'] as String,
        baseCommitHash: json['baseCommit'] as String?,
        autoMergedDocIds: List<String>.from(json['autoMergedDocIds'] as List),
        conflicts: [], // Conflicts loaded separately
        status: VcsMergeStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => VcsMergeStatus.inProgress,
        ),
      );
}

/// Status of a merge operation.
enum VcsMergeStatus {
  inProgress,
  conflicted,
  resolved,
  completed,
  aborted,
}

/// Result of a three-way merge operation.
class VcsMergeResult {
  final String mergedContent;
  final List<VcsConflictRegion> conflicts;
  final bool hasConflicts;

  const VcsMergeResult({
    required this.mergedContent,
    required this.conflicts,
    required this.hasConflicts,
  });

  factory VcsMergeResult.clean(String content) => VcsMergeResult(
        mergedContent: content,
        conflicts: [],
        hasConflicts: false,
      );

  factory VcsMergeResult.conflicted(List<VcsConflictRegion> conflicts) =>
      VcsMergeResult(
        mergedContent: '',
        conflicts: conflicts,
        hasConflicts: true,
      );
}

/// A paragraph in a document for merge purposes.
class MergeParagraph {
  final int index;
  final String content;
  final String hash;

  MergeParagraph({
    required this.index,
    required this.content,
    required this.hash,
  });

  @override
  bool operator ==(Object other) =>
      other is MergeParagraph && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}

/// Alignment of paragraphs between three versions for merging.
class ParagraphAlignment {
  final MergeParagraph? base;
  final MergeParagraph? ours;
  final MergeParagraph? theirs;

  const ParagraphAlignment({
    this.base,
    this.ours,
    this.theirs,
  });

  /// Determine if this alignment represents a conflict.
  bool get isConflict {
    // No conflict if only one side changed
    if (ours == base && theirs != base) return false;
    if (theirs == base && ours != base) return false;
    // No conflict if both changed the same way
    if (ours == theirs) return false;
    // Conflict if both changed differently
    if (ours != base && theirs != base && ours != theirs) return true;
    return false;
  }

  /// Get the resolved content for non-conflict cases.
  String? get autoResolvedContent {
    if (isConflict) return null;
    // Take theirs if only they changed
    if (ours == base && theirs != base) return theirs?.content;
    // Take ours if only we changed
    if (theirs == base && ours != base) return ours?.content;
    // Take either if both changed the same way
    if (ours == theirs) return ours?.content;
    // Keep base if nothing changed
    if (ours == base && theirs == base) return base?.content;
    return null;
  }
}
