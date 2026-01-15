import 'package:flutter/foundation.dart';
import '../models/scrivener_project.dart';

/// Service for tracking and calculating writing statistics
class StatisticsService extends ChangeNotifier {
  /// Writing sessions indexed by date (YYYY-MM-DD)
  final Map<String, WritingSession> _sessions = {};

  /// Current active session
  WritingSession? _currentSession;

  /// Get current session
  WritingSession? get currentSession => _currentSession;

  /// Get all sessions
  List<WritingSession> get allSessions => _sessions.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  /// Start a new writing session
  void startSession() {
    final today = _getDateKey(DateTime.now());
    _currentSession = _sessions[today] ?? WritingSession(date: DateTime.now());
    _currentSession = _currentSession!.copyWith(
      sessionStart: DateTime.now(),
    );
    notifyListeners();
  }

  /// Record words written in current session
  void recordWords(int wordCount, int previousWordCount) {
    if (_currentSession == null) {
      startSession();
    }

    final wordsWritten = wordCount - previousWordCount;
    if (wordsWritten != 0) {
      _currentSession = _currentSession!.copyWith(
        wordsWritten: _currentSession!.wordsWritten + wordsWritten,
        endWordCount: wordCount,
      );

      // Save to daily sessions
      final today = _getDateKey(DateTime.now());
      _sessions[today] = _currentSession!;
      notifyListeners();
    }
  }

  /// End current session
  void endSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        sessionEnd: DateTime.now(),
      );
      final today = _getDateKey(DateTime.now());
      _sessions[today] = _currentSession!;
      _currentSession = null;
      notifyListeners();
    }
  }

  /// Calculate project statistics
  ProjectStatistics calculateProjectStatistics(ScrivenerProject project) {
    int totalWords = 0;
    int totalCharacters = 0;
    int documentCount = 0;
    final wordsByDocument = <String, int>{};

    void processItems(List<BinderItem> items) {
      for (final item in items) {
        if (!item.isFolder) {
          final content = project.textContents[item.id] ?? '';
          final words = _countWords(content);
          final chars = content.length;

          totalWords += words;
          totalCharacters += chars;
          documentCount++;
          wordsByDocument[item.id] = words;
        }
        if (item.children.isNotEmpty) {
          processItems(item.children);
        }
      }
    }

    processItems(project.binderItems);

    return ProjectStatistics(
      totalWords: totalWords,
      totalCharacters: totalCharacters,
      documentCount: documentCount,
      wordsByDocument: wordsByDocument,
      averageWordsPerDocument: documentCount > 0 ? totalWords ~/ documentCount : 0,
    );
  }

  /// Calculate document statistics
  DocumentStatistics calculateDocumentStatistics(String content) {
    final words = _countWords(content);
    final characters = content.length;
    final charactersNoSpaces = content.replaceAll(RegExp(r'\s'), '').length;
    final sentences = _countSentences(content);
    final paragraphs = _countParagraphs(content);
    final averageWordLength = words > 0
        ? (charactersNoSpaces / words).toStringAsFixed(1)
        : '0';
    final averageSentenceLength = sentences > 0
        ? (words / sentences).toStringAsFixed(1)
        : '0';

    // Estimate reading time (average 200 words per minute)
    final readingTimeMinutes = (words / 200).ceil();

    // Estimate speaking time (average 150 words per minute)
    final speakingTimeMinutes = (words / 150).ceil();

    return DocumentStatistics(
      wordCount: words,
      characterCount: characters,
      characterCountNoSpaces: charactersNoSpaces,
      sentenceCount: sentences,
      paragraphCount: paragraphs,
      averageWordLength: double.tryParse(averageWordLength) ?? 0,
      averageSentenceLength: double.tryParse(averageSentenceLength) ?? 0,
      estimatedReadingTimeMinutes: readingTimeMinutes,
      estimatedSpeakingTimeMinutes: speakingTimeMinutes,
    );
  }

  /// Get writing streak (consecutive days with writing)
  int getWritingStreak() {
    if (_sessions.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();

    // Check if wrote today
    final today = _getDateKey(checkDate);
    if (!_sessions.containsKey(today)) {
      // Check if wrote yesterday (streak might still be valid)
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateKey = _getDateKey(checkDate);
      if (_sessions.containsKey(dateKey) && _sessions[dateKey]!.wordsWritten > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get words written in the last N days
  Map<String, int> getWordsPerDay(int days) {
    final result = <String, int>{};
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      result[dateKey] = _sessions[dateKey]?.wordsWritten ?? 0;
    }

    return result;
  }

  /// Get total words written in date range
  int getTotalWordsInRange(DateTime start, DateTime end) {
    int total = 0;
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final dateKey = _getDateKey(current);
      total += _sessions[dateKey]?.wordsWritten ?? 0;
      current = current.add(const Duration(days: 1));
    }

    return total;
  }

  /// Get average words per day
  double getAverageWordsPerDay(int days) {
    final wordsPerDay = getWordsPerDay(days);
    if (wordsPerDay.isEmpty) return 0;

    final total = wordsPerDay.values.fold(0, (sum, words) => sum + words);
    return total / days;
  }

  /// Load sessions from JSON
  void loadSessions(Map<String, dynamic> data) {
    _sessions.clear();
    for (final entry in data.entries) {
      _sessions[entry.key] = WritingSession.fromJson(entry.value as Map<String, dynamic>);
    }
    notifyListeners();
  }

  /// Export sessions to JSON
  Map<String, dynamic> toJson() {
    return _sessions.map((key, value) => MapEntry(key, value.toJson()));
  }

  /// Clear all sessions
  void clear() {
    _sessions.clear();
    _currentSession = null;
    notifyListeners();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  int _countSentences(String text) {
    if (text.isEmpty) return 0;
    // Count sentence-ending punctuation
    return RegExp(r'[.!?]+').allMatches(text).length;
  }

  int _countParagraphs(String text) {
    if (text.isEmpty) return 0;
    // Count non-empty paragraphs
    return text
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .length;
  }
}

/// Represents a writing session
class WritingSession {
  final DateTime date;
  final DateTime? sessionStart;
  final DateTime? sessionEnd;
  final int wordsWritten;
  final int startWordCount;
  final int endWordCount;

  const WritingSession({
    required this.date,
    this.sessionStart,
    this.sessionEnd,
    this.wordsWritten = 0,
    this.startWordCount = 0,
    this.endWordCount = 0,
  });

  Duration get duration {
    if (sessionStart == null) return Duration.zero;
    final end = sessionEnd ?? DateTime.now();
    return end.difference(sessionStart!);
  }

  double get wordsPerMinute {
    final minutes = duration.inMinutes;
    if (minutes == 0) return 0;
    return wordsWritten / minutes;
  }

  WritingSession copyWith({
    DateTime? sessionStart,
    DateTime? sessionEnd,
    int? wordsWritten,
    int? startWordCount,
    int? endWordCount,
  }) {
    return WritingSession(
      date: date,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
      wordsWritten: wordsWritten ?? this.wordsWritten,
      startWordCount: startWordCount ?? this.startWordCount,
      endWordCount: endWordCount ?? this.endWordCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'sessionStart': sessionStart?.toIso8601String(),
      'sessionEnd': sessionEnd?.toIso8601String(),
      'wordsWritten': wordsWritten,
      'startWordCount': startWordCount,
      'endWordCount': endWordCount,
    };
  }

  factory WritingSession.fromJson(Map<String, dynamic> json) {
    return WritingSession(
      date: DateTime.parse(json['date'] as String),
      sessionStart: json['sessionStart'] != null
          ? DateTime.parse(json['sessionStart'] as String)
          : null,
      sessionEnd: json['sessionEnd'] != null
          ? DateTime.parse(json['sessionEnd'] as String)
          : null,
      wordsWritten: json['wordsWritten'] as int? ?? 0,
      startWordCount: json['startWordCount'] as int? ?? 0,
      endWordCount: json['endWordCount'] as int? ?? 0,
    );
  }
}

/// Statistics for the entire project
class ProjectStatistics {
  final int totalWords;
  final int totalCharacters;
  final int documentCount;
  final Map<String, int> wordsByDocument;
  final int averageWordsPerDocument;

  const ProjectStatistics({
    required this.totalWords,
    required this.totalCharacters,
    required this.documentCount,
    required this.wordsByDocument,
    required this.averageWordsPerDocument,
  });
}

/// Statistics for a single document
class DocumentStatistics {
  final int wordCount;
  final int characterCount;
  final int characterCountNoSpaces;
  final int sentenceCount;
  final int paragraphCount;
  final double averageWordLength;
  final double averageSentenceLength;
  final int estimatedReadingTimeMinutes;
  final int estimatedSpeakingTimeMinutes;

  const DocumentStatistics({
    required this.wordCount,
    required this.characterCount,
    required this.characterCountNoSpaces,
    required this.sentenceCount,
    required this.paragraphCount,
    required this.averageWordLength,
    required this.averageSentenceLength,
    required this.estimatedReadingTimeMinutes,
    required this.estimatedSpeakingTimeMinutes,
  });
}
