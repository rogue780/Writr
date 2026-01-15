import 'package:flutter/material.dart';

/// Represents a writing target/goal
class WritingTarget {
  final String id;
  final String name;
  final TargetType type;
  final int targetCount;
  final TargetUnit unit;
  final DateTime? deadline;
  final DateTime createdAt;
  final bool isActive;
  final String? documentId; // For document-specific targets
  final TargetPeriod? period; // For recurring targets

  const WritingTarget({
    required this.id,
    required this.name,
    required this.type,
    required this.targetCount,
    required this.unit,
    this.deadline,
    required this.createdAt,
    this.isActive = true,
    this.documentId,
    this.period,
  });

  WritingTarget copyWith({
    String? name,
    TargetType? type,
    int? targetCount,
    TargetUnit? unit,
    DateTime? deadline,
    bool? isActive,
    String? documentId,
    TargetPeriod? period,
  }) {
    return WritingTarget(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      documentId: documentId ?? this.documentId,
      period: period ?? this.period,
    );
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double getProgress(int currentCount) {
    if (targetCount <= 0) return 0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Check if target is complete
  bool isComplete(int currentCount) {
    return currentCount >= targetCount;
  }

  /// Get remaining count to reach target
  int getRemaining(int currentCount) {
    return (targetCount - currentCount).clamp(0, targetCount);
  }

  /// Check if deadline has passed
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Get days until deadline
  int? get daysUntilDeadline {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  /// Get color based on progress and deadline
  Color getStatusColor(int currentCount) {
    final progress = getProgress(currentCount);

    if (isComplete(currentCount)) {
      return Colors.green;
    }

    if (isOverdue) {
      return Colors.red;
    }

    if (deadline != null) {
      final expectedProgress = _getExpectedProgress();

      if (progress < expectedProgress - 0.1) {
        return Colors.orange; // Behind schedule
      }
    }

    if (progress >= 0.75) {
      return Colors.green;
    } else if (progress >= 0.5) {
      return Colors.blue;
    } else if (progress >= 0.25) {
      return Colors.orange;
    }

    return Colors.grey;
  }

  double _getExpectedProgress() {
    if (deadline == null) return 0;

    final totalDuration = deadline!.difference(createdAt);
    final elapsed = DateTime.now().difference(createdAt);

    if (totalDuration.inDays <= 0) return 1.0;

    return (elapsed.inDays / totalDuration.inDays).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'targetCount': targetCount,
      'unit': unit.name,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'documentId': documentId,
      'period': period?.name,
    };
  }

  factory WritingTarget.fromJson(Map<String, dynamic> json) {
    return WritingTarget(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TargetType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TargetType.project,
      ),
      targetCount: json['targetCount'] as int,
      unit: TargetUnit.values.firstWhere(
        (u) => u.name == json['unit'],
        orElse: () => TargetUnit.words,
      ),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      documentId: json['documentId'] as String?,
      period: json['period'] != null
          ? TargetPeriod.values.firstWhere(
              (p) => p.name == json['period'],
              orElse: () => TargetPeriod.daily,
            )
          : null,
    );
  }
}

/// Type of target
enum TargetType {
  project,    // Total project word count
  document,   // Specific document word count
  session,    // Single writing session
  daily,      // Daily writing goal
  weekly,     // Weekly writing goal
  monthly,    // Monthly writing goal
}

/// Unit for measuring target
enum TargetUnit {
  words,
  characters,
  pages,      // Estimated at 250 words per page
  chapters,
}

/// Period for recurring targets
enum TargetPeriod {
  daily,
  weekly,
  monthly,
}

/// Extension for display names
extension TargetTypeExtension on TargetType {
  String get displayName {
    switch (this) {
      case TargetType.project:
        return 'Project';
      case TargetType.document:
        return 'Document';
      case TargetType.session:
        return 'Session';
      case TargetType.daily:
        return 'Daily';
      case TargetType.weekly:
        return 'Weekly';
      case TargetType.monthly:
        return 'Monthly';
    }
  }

  IconData get icon {
    switch (this) {
      case TargetType.project:
        return Icons.folder;
      case TargetType.document:
        return Icons.description;
      case TargetType.session:
        return Icons.timer;
      case TargetType.daily:
        return Icons.today;
      case TargetType.weekly:
        return Icons.date_range;
      case TargetType.monthly:
        return Icons.calendar_month;
    }
  }
}

extension TargetUnitExtension on TargetUnit {
  String get displayName {
    switch (this) {
      case TargetUnit.words:
        return 'Words';
      case TargetUnit.characters:
        return 'Characters';
      case TargetUnit.pages:
        return 'Pages';
      case TargetUnit.chapters:
        return 'Chapters';
    }
  }

  String get abbreviation {
    switch (this) {
      case TargetUnit.words:
        return 'w';
      case TargetUnit.characters:
        return 'c';
      case TargetUnit.pages:
        return 'p';
      case TargetUnit.chapters:
        return 'ch';
    }
  }
}

/// Progress tracking for a target
class TargetProgress {
  final WritingTarget target;
  final int currentCount;
  final DateTime lastUpdated;

  const TargetProgress({
    required this.target,
    required this.currentCount,
    required this.lastUpdated,
  });

  double get progress => target.getProgress(currentCount);
  bool get isComplete => target.isComplete(currentCount);
  int get remaining => target.getRemaining(currentCount);
  Color get statusColor => target.getStatusColor(currentCount);
}

/// Session target tracking
class SessionTarget {
  final int targetWords;
  final int startingWordCount;
  final DateTime sessionStart;
  int currentWordCount;

  SessionTarget({
    required this.targetWords,
    required this.startingWordCount,
    required this.sessionStart,
    int? currentWordCount,
  }) : currentWordCount = currentWordCount ?? startingWordCount;

  int get wordsWritten => currentWordCount - startingWordCount;
  int get wordsRemaining => (targetWords - wordsWritten).clamp(0, targetWords);
  double get progress => targetWords > 0
      ? (wordsWritten / targetWords).clamp(0.0, 1.0)
      : 0.0;
  bool get isComplete => wordsWritten >= targetWords;

  Duration get elapsed => DateTime.now().difference(sessionStart);

  double get wordsPerMinute {
    final minutes = elapsed.inMinutes;
    if (minutes <= 0) return 0;
    return wordsWritten / minutes;
  }

  Duration? get estimatedTimeRemaining {
    if (wordsPerMinute <= 0 || isComplete) return null;
    final minutesRemaining = wordsRemaining / wordsPerMinute;
    return Duration(minutes: minutesRemaining.ceil());
  }
}
