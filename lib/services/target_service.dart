import 'package:flutter/foundation.dart';
import '../models/target.dart';
import '../models/scrivener_project.dart';

/// Service for managing writing targets and goals
class TargetService extends ChangeNotifier {
  /// All targets indexed by ID
  final Map<String, WritingTarget> _targets = {};

  /// Daily word counts indexed by date (YYYY-MM-DD)
  final Map<String, int> _dailyWordCounts = {};

  /// Weekly word counts indexed by week start date (YYYY-MM-DD)
  final Map<String, int> _weeklyWordCounts = {};

  /// Monthly word counts indexed by month (YYYY-MM)
  final Map<String, int> _monthlyWordCounts = {};

  /// Current session target
  SessionTarget? _sessionTarget;

  /// Get all targets
  List<WritingTarget> get allTargets => _targets.values.toList();

  /// Get active targets
  List<WritingTarget> get activeTargets =>
      _targets.values.where((t) => t.isActive).toList();

  /// Get current session target
  SessionTarget? get sessionTarget => _sessionTarget;

  /// Get targets by type
  List<WritingTarget> getTargetsByType(TargetType type) {
    return _targets.values.where((t) => t.type == type).toList();
  }

  /// Get target for a specific document
  WritingTarget? getDocumentTarget(String documentId) {
    return _targets.values.firstWhere(
      (t) => t.type == TargetType.document && t.documentId == documentId,
      orElse: () => throw StateError('No target found'),
    );
  }

  /// Try to get document target, returns null if not found
  WritingTarget? tryGetDocumentTarget(String documentId) {
    try {
      return getDocumentTarget(documentId);
    } catch (_) {
      return null;
    }
  }

  /// Get project target
  WritingTarget? get projectTarget {
    try {
      return _targets.values.firstWhere((t) => t.type == TargetType.project);
    } catch (_) {
      return null;
    }
  }

  /// Get daily target
  WritingTarget? get dailyTarget {
    try {
      return _targets.values
          .firstWhere((t) => t.type == TargetType.daily && t.isActive);
    } catch (_) {
      return null;
    }
  }

  /// Create a new target
  WritingTarget createTarget({
    required String name,
    required TargetType type,
    required int targetCount,
    TargetUnit unit = TargetUnit.words,
    DateTime? deadline,
    String? documentId,
    TargetPeriod? period,
  }) {
    final target = WritingTarget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      targetCount: targetCount,
      unit: unit,
      deadline: deadline,
      createdAt: DateTime.now(),
      documentId: documentId,
      period: period,
    );

    _targets[target.id] = target;
    notifyListeners();
    return target;
  }

  /// Update an existing target
  void updateTarget(WritingTarget target) {
    _targets[target.id] = target;
    notifyListeners();
  }

  /// Delete a target
  void deleteTarget(String targetId) {
    _targets.remove(targetId);
    notifyListeners();
  }

  /// Toggle target active state
  void toggleTargetActive(String targetId) {
    final target = _targets[targetId];
    if (target != null) {
      _targets[targetId] = target.copyWith(isActive: !target.isActive);
      notifyListeners();
    }
  }

  /// Start a session target
  void startSessionTarget({
    required int targetWords,
    required int currentWordCount,
  }) {
    _sessionTarget = SessionTarget(
      targetWords: targetWords,
      startingWordCount: currentWordCount,
      sessionStart: DateTime.now(),
      currentWordCount: currentWordCount,
    );
    notifyListeners();
  }

  /// Update session word count
  void updateSessionWordCount(int wordCount) {
    if (_sessionTarget != null) {
      _sessionTarget!.currentWordCount = wordCount;
      notifyListeners();
    }
  }

  /// End session target
  SessionTarget? endSessionTarget() {
    final session = _sessionTarget;
    _sessionTarget = null;
    notifyListeners();
    return session;
  }

  /// Record daily word count
  void recordDailyWords(int wordCount) {
    final today = _getDateKey(DateTime.now());
    _dailyWordCounts[today] = wordCount;

    // Also update weekly and monthly
    _updateWeeklyCount();
    _updateMonthlyCount();

    notifyListeners();
  }

  /// Get today's word count
  int get todayWordCount {
    final today = _getDateKey(DateTime.now());
    return _dailyWordCounts[today] ?? 0;
  }

  /// Get this week's word count
  int get weekWordCount {
    final weekStart = _getWeekStartKey(DateTime.now());
    return _weeklyWordCounts[weekStart] ?? 0;
  }

  /// Get this month's word count
  int get monthWordCount {
    final month = _getMonthKey(DateTime.now());
    return _monthlyWordCounts[month] ?? 0;
  }

  /// Calculate progress for a target
  TargetProgress getTargetProgress(WritingTarget target, ScrivenerProject project) {
    int currentCount = 0;

    switch (target.type) {
      case TargetType.project:
        currentCount = _calculateProjectWordCount(project, target.unit);
        break;
      case TargetType.document:
        if (target.documentId != null) {
          currentCount = _calculateDocumentWordCount(
            project,
            target.documentId!,
            target.unit,
          );
        }
        break;
      case TargetType.session:
        currentCount = _sessionTarget?.wordsWritten ?? 0;
        break;
      case TargetType.daily:
        currentCount = todayWordCount;
        break;
      case TargetType.weekly:
        currentCount = weekWordCount;
        break;
      case TargetType.monthly:
        currentCount = monthWordCount;
        break;
    }

    return TargetProgress(
      target: target,
      currentCount: currentCount,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get all target progress
  List<TargetProgress> getAllTargetProgress(ScrivenerProject project) {
    return activeTargets
        .map((target) => getTargetProgress(target, project))
        .toList();
  }

  /// Calculate project word count
  int _calculateProjectWordCount(ScrivenerProject project, TargetUnit unit) {
    int totalWords = 0;

    for (final content in project.textContents.values) {
      totalWords += _countWords(content);
    }

    return _convertToUnit(totalWords, unit);
  }

  /// Calculate document word count
  int _calculateDocumentWordCount(
    ScrivenerProject project,
    String documentId,
    TargetUnit unit,
  ) {
    final content = project.textContents[documentId] ?? '';
    final words = _countWords(content);
    return _convertToUnit(words, unit);
  }

  /// Convert word count to target unit
  int _convertToUnit(int words, TargetUnit unit) {
    switch (unit) {
      case TargetUnit.words:
        return words;
      case TargetUnit.characters:
        // Approximate: average 5 characters per word
        return words * 5;
      case TargetUnit.pages:
        // Standard: 250 words per page
        return (words / 250).ceil();
      case TargetUnit.chapters:
        // This should be counted differently, but as fallback use words
        return words;
    }
  }

  /// Count words in text
  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  void _updateWeeklyCount() {
    final weekStart = _getWeekStartKey(DateTime.now());
    int weekTotal = 0;

    // Sum up all days in current week
    for (int i = 0; i < 7; i++) {
      final date = _getWeekStart(DateTime.now()).add(Duration(days: i));
      final dateKey = _getDateKey(date);
      weekTotal += _dailyWordCounts[dateKey] ?? 0;
    }

    _weeklyWordCounts[weekStart] = weekTotal;
  }

  void _updateMonthlyCount() {
    final monthKey = _getMonthKey(DateTime.now());
    int monthTotal = 0;

    // Sum up all days in current month
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      final dateKey = _getDateKey(date);
      monthTotal += _dailyWordCounts[dateKey] ?? 0;
    }

    _monthlyWordCounts[monthKey] = monthTotal;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekStartKey(DateTime date) {
    return _getDateKey(_getWeekStart(date));
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Load targets from JSON
  void loadTargets(Map<String, dynamic> data) {
    _targets.clear();
    _dailyWordCounts.clear();
    _weeklyWordCounts.clear();
    _monthlyWordCounts.clear();

    if (data['targets'] != null) {
      for (final targetJson in data['targets'] as List) {
        final target = WritingTarget.fromJson(targetJson as Map<String, dynamic>);
        _targets[target.id] = target;
      }
    }

    if (data['dailyWordCounts'] != null) {
      final daily = data['dailyWordCounts'] as Map<String, dynamic>;
      for (final entry in daily.entries) {
        _dailyWordCounts[entry.key] = entry.value as int;
      }
    }

    if (data['weeklyWordCounts'] != null) {
      final weekly = data['weeklyWordCounts'] as Map<String, dynamic>;
      for (final entry in weekly.entries) {
        _weeklyWordCounts[entry.key] = entry.value as int;
      }
    }

    if (data['monthlyWordCounts'] != null) {
      final monthly = data['monthlyWordCounts'] as Map<String, dynamic>;
      for (final entry in monthly.entries) {
        _monthlyWordCounts[entry.key] = entry.value as int;
      }
    }

    notifyListeners();
  }

  /// Export targets to JSON
  Map<String, dynamic> toJson() {
    return {
      'targets': _targets.values.map((t) => t.toJson()).toList(),
      'dailyWordCounts': _dailyWordCounts,
      'weeklyWordCounts': _weeklyWordCounts,
      'monthlyWordCounts': _monthlyWordCounts,
    };
  }

  /// Clear all data
  void clear() {
    _targets.clear();
    _dailyWordCounts.clear();
    _weeklyWordCounts.clear();
    _monthlyWordCounts.clear();
    _sessionTarget = null;
    notifyListeners();
  }

  /// Create default targets for a new project
  void createDefaultTargets({
    int projectTargetWords = 50000,
    int dailyTargetWords = 1000,
  }) {
    // Project target (e.g., novel at 50,000 words)
    createTarget(
      name: 'Project Goal',
      type: TargetType.project,
      targetCount: projectTargetWords,
      unit: TargetUnit.words,
    );

    // Daily writing target
    createTarget(
      name: 'Daily Writing Goal',
      type: TargetType.daily,
      targetCount: dailyTargetWords,
      unit: TargetUnit.words,
      period: TargetPeriod.daily,
    );
  }
}
