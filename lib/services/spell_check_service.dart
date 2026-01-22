import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'dictionary_service.dart';

/// Represents a spelling error with its location
/// Suggestions are loaded lazily to avoid performance issues
class SpellCheckError {
  final TextRange range;
  final String word;
  final DictionaryService _dictionary;
  List<String>? _suggestions;

  SpellCheckError({
    required this.range,
    required this.word,
    required DictionaryService dictionary,
  }) : _dictionary = dictionary;

  /// Get suggestions - computed lazily on first access
  List<String> get suggestions {
    _suggestions ??= _dictionary.getSuggestions(word);
    return _suggestions!;
  }

  /// Create a copy with adjusted range
  SpellCheckError copyWithOffset(int offset) {
    return SpellCheckError(
      range: TextRange(start: range.start + offset, end: range.end + offset),
      word: word,
      dictionary: _dictionary,
    );
  }

  @override
  String toString() => 'SpellCheckError($word at ${range.start}-${range.end})';
}

/// Represents a region that needs spell checking
class _CheckRegion {
  final int start;
  final int end;

  _CheckRegion(this.start, this.end);

  @override
  String toString() => '_CheckRegion($start-$end)';
}

/// Service for performing spell checking on text
/// Uses chunked processing for performance - checks in small batches with UI yielding
class SpellCheckService extends ChangeNotifier {
  final DictionaryService _dictionary;

  Timer? _debounceTimer;
  List<SpellCheckError> _errors = [];
  String _currentText = '';
  bool _isChecking = false;
  bool _fullCheckNeeded = true;
  int _checkVersion = 0; // Tracks check version to discard stale results

  // Queue of regions that need checking
  final Queue<_CheckRegion> _pendingRegions = Queue();

  // Word buffer - check this many words before/after the modified area
  static const int _wordBuffer = 5;

  // Chunk size for batch processing - check this many words then yield
  static const int _chunkSize = 50;

  /// Duration to wait after text changes before checking
  final Duration debounceDelay;

  SpellCheckService(
    this._dictionary, {
    this.debounceDelay = const Duration(milliseconds: 300),
  });

  /// Current list of spelling errors
  List<SpellCheckError> get errors => _errors;

  /// Whether a spell check is currently in progress
  bool get isChecking => _isChecking;

  /// Whether the dictionary is loaded and ready
  bool get isReady => _dictionary.isLoaded;

  /// Check text for spelling errors with debouncing
  /// For initial load or when text changes significantly
  void checkText(String text, {int? visibleStartOffset, int? visibleEndOffset}) {
    if (text == _currentText && !_fullCheckNeeded) return;

    _debounceTimer?.cancel();

    // Determine if this is a small edit or a full document change
    if (_currentText.isEmpty || _needsFullCheck(text)) {
      _fullCheckNeeded = true;
      _currentText = text;
      _debounceTimer = Timer(debounceDelay, () {
        _performChunkedFullCheck(
          visibleStart: visibleStartOffset,
          visibleEnd: visibleEndOffset,
        );
      });
    } else {
      // Find the changed region and queue it
      final region = _findChangedRegion(_currentText, text);
      _currentText = text;
      if (region != null) {
        _queueRegion(region);
        _debounceTimer = Timer(debounceDelay, _processQueue);
      }
    }
  }

  /// Check text immediately without debouncing (for initial load)
  void checkTextImmediate(String text, {int? visibleStartOffset, int? visibleEndOffset}) {
    _debounceTimer?.cancel();
    _currentText = text;
    _fullCheckNeeded = true;
    _performChunkedFullCheck(
      visibleStart: visibleStartOffset,
      visibleEnd: visibleEndOffset,
    );
  }

  /// Clear all errors
  void clearErrors() {
    _checkVersion++; // Cancel any in-progress checks
    if (_errors.isNotEmpty) {
      _errors = [];
      _pendingRegions.clear();
      notifyListeners();
    }
  }

  /// Determine if we need a full re-check vs incremental
  bool _needsFullCheck(String newText) {
    // If lengths differ by more than 50 chars, do full check
    // This handles paste operations, document switches, etc.
    if ((newText.length - _currentText.length).abs() > 50) {
      return true;
    }
    return false;
  }

  /// Find the region that changed between old and new text
  _CheckRegion? _findChangedRegion(String oldText, String newText) {
    if (oldText == newText) return null;

    // Find where the texts start to differ
    int start = 0;
    final minLen = math.min(oldText.length, newText.length);
    while (start < minLen && oldText[start] == newText[start]) {
      start++;
    }

    // Find where they stop differing from the end
    int oldEnd = oldText.length;
    int newEnd = newText.length;
    while (oldEnd > start && newEnd > start &&
           oldText[oldEnd - 1] == newText[newEnd - 1]) {
      oldEnd--;
      newEnd--;
    }

    // Expand to word boundaries with buffer
    final expandedStart = _expandToWordBoundary(newText, start, -1);
    final expandedEnd = _expandToWordBoundary(newText, newEnd, 1);

    return _CheckRegion(expandedStart, expandedEnd);
  }

  /// Expand a position to include word buffer
  int _expandToWordBoundary(String text, int pos, int direction) {
    if (text.isEmpty) return 0;

    pos = pos.clamp(0, text.length);
    int wordCount = 0;

    if (direction < 0) {
      // Expand backwards
      while (pos > 0 && wordCount < _wordBuffer) {
        pos--;
        // Count word boundaries (space to non-space transition going backwards)
        if (pos > 0 && !_isWordChar(text[pos]) && _isWordChar(text[pos - 1])) {
          wordCount++;
        }
      }
      // Go to start of current word
      while (pos > 0 && _isWordChar(text[pos - 1])) {
        pos--;
      }
    } else {
      // Expand forwards
      while (pos < text.length && wordCount < _wordBuffer) {
        if (pos < text.length - 1 && !_isWordChar(text[pos]) && _isWordChar(text[pos + 1])) {
          wordCount++;
        }
        pos++;
      }
      // Go to end of current word
      while (pos < text.length && _isWordChar(text[pos])) {
        pos++;
      }
    }

    return pos;
  }

  bool _isWordChar(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||   // A-Z
           (code >= 97 && code <= 122) ||  // a-z
           char == "'";                     // apostrophe for contractions
  }

  /// Queue a region for checking, merging with existing regions if overlapping
  void _queueRegion(_CheckRegion region) {
    // For simplicity, just add to queue - regions will be processed in order
    _pendingRegions.add(region);
  }

  /// Process the pending check queue
  Future<void> _processQueue() async {
    if (!_dictionary.isLoaded || _isChecking) return;

    _isChecking = true;

    try {
      if (_fullCheckNeeded) {
        await _performChunkedFullCheck();
        _fullCheckNeeded = false;
        _pendingRegions.clear();
      } else {
        // Process all pending regions (these are quick, no chunking needed)
        while (_pendingRegions.isNotEmpty) {
          final region = _pendingRegions.removeFirst();
          _checkRegionSync(region);
        }
      }
    } finally {
      _isChecking = false;
    }

    notifyListeners();
  }

  /// Perform a full spell check in chunks to avoid blocking UI
  /// Optionally prioritizes visible region first
  Future<void> _performChunkedFullCheck({int? visibleStart, int? visibleEnd}) async {
    if (!_dictionary.isLoaded) return;
    if (_isChecking) return;

    _isChecking = true;
    final text = _currentText;
    final version = ++_checkVersion;

    try {
      final wordPattern = RegExp(r"[a-zA-Z]+(?:'[a-zA-Z]+)?");
      final allMatches = wordPattern.allMatches(text).toList();

      if (allMatches.isEmpty) {
        _errors = [];
        _fullCheckNeeded = false;
        notifyListeners();
        return;
      }

      // If we have visible region info, reorder matches to prioritize visible area
      List<RegExpMatch> orderedMatches;
      int visibleEndIndex = 0;

      if (visibleStart != null && visibleEnd != null) {
        // Split matches into visible and non-visible
        final visibleMatches = <RegExpMatch>[];
        final beforeMatches = <RegExpMatch>[];
        final afterMatches = <RegExpMatch>[];

        for (final match in allMatches) {
          if (match.end <= visibleStart) {
            beforeMatches.add(match);
          } else if (match.start >= visibleEnd) {
            afterMatches.add(match);
          } else {
            visibleMatches.add(match);
          }
        }

        // Process visible first, then before (user might scroll up), then after
        orderedMatches = [...visibleMatches, ...beforeMatches, ...afterMatches];
        visibleEndIndex = visibleMatches.length;
      } else {
        orderedMatches = allMatches;
        // Process first chunk immediately (likely visible)
        visibleEndIndex = math.min(_chunkSize, allMatches.length);
      }

      final errors = <SpellCheckError>[];
      int processedCount = 0;

      for (final match in orderedMatches) {
        // Check if this check has been superseded
        if (_checkVersion != version) return;

        final word = match.group(0)!;

        if (!_shouldSkipWord(word)) {
          final isValid = _dictionary.isValidWord(word);

          if (!isValid) {
            errors.add(SpellCheckError(
              range: TextRange(start: match.start, end: match.end),
              word: word,
              dictionary: _dictionary,
            ));
          }
        }

        processedCount++;

        // After processing visible chunk, update UI immediately
        if (processedCount == visibleEndIndex && visibleEndIndex > 0) {
          if (_checkVersion != version) return;
          _errors = List.from(errors);
          _errors.sort((a, b) => a.range.start.compareTo(b.range.start));
          notifyListeners();
        }

        // Yield to UI every chunk with delay to avoid blocking
        if (processedCount % _chunkSize == 0 && processedCount > visibleEndIndex) {
          await Future.delayed(const Duration(milliseconds: 250));
          if (_checkVersion != version) return;

          // Periodic update so errors appear progressively
          _errors = List.from(errors);
          _errors.sort((a, b) => a.range.start.compareTo(b.range.start));
          notifyListeners();
        }
      }

      // Final update with all errors
      if (_checkVersion == version) {
        _errors = errors;
        _errors.sort((a, b) => a.range.start.compareTo(b.range.start));
        _fullCheckNeeded = false;
      }
    } finally {
      _isChecking = false;
    }

    if (_checkVersion == version) {
      notifyListeners();
    }
  }

  /// Check a region synchronously (for small incremental changes)
  void _checkRegionSync(_CheckRegion region) {
    final text = _currentText;
    if (text.isEmpty) return;

    final start = region.start.clamp(0, text.length);
    final end = region.end.clamp(0, text.length);
    if (start >= end) return;

    final regionText = text.substring(start, end);
    final wordPattern = RegExp(r"[a-zA-Z]+(?:'[a-zA-Z]+)?");

    // Remove old errors in this region
    _errors = _errors.where((e) =>
      e.range.end <= start || e.range.start >= end
    ).toList();

    // Check words in the region
    final newErrors = <SpellCheckError>[];
    for (final match in wordPattern.allMatches(regionText)) {
      final word = match.group(0)!;

      if (_shouldSkipWord(word)) continue;

      if (!_dictionary.isValidWord(word)) {
        newErrors.add(SpellCheckError(
          range: TextRange(
            start: start + match.start,
            end: start + match.end,
          ),
          word: word,
          dictionary: _dictionary,
        ));
      }
    }

    // Add new errors and sort by position
    _errors.addAll(newErrors);
    _errors.sort((a, b) => a.range.start.compareTo(b.range.start));
  }

  /// Check if a word should be skipped
  bool _shouldSkipWord(String word) {
    // Skip very short words
    if (word.length < 2) return true;
    // Skip words that are all caps (likely acronyms)
    if (word == word.toUpperCase() && word.length <= 5) return true;
    return false;
  }

  /// Get errors within a specific text range (for a single paragraph)
  List<SpellCheckError> getErrorsInRange(int start, int end) {
    return _errors.where((error) {
      return error.range.start >= start && error.range.end <= end;
    }).toList();
  }

  /// Get errors adjusted for a node starting at a specific offset
  List<TextRange> getErrorRangesForNode(int nodeStartOffset, int nodeLength) {
    final nodeEnd = nodeStartOffset + nodeLength;

    return _errors
        .where((error) =>
            error.range.start >= nodeStartOffset && error.range.end <= nodeEnd)
        .map((error) => TextRange(
              start: error.range.start - nodeStartOffset,
              end: error.range.end - nodeStartOffset,
            ))
        .toList();
  }

  /// Add a word to the user dictionary and re-check
  Future<void> addToUserDictionary(String word) async {
    await _dictionary.addToUserDictionary(word);

    // Remove errors for this word and notify
    _errors = _errors.where((e) => e.word.toLowerCase() != word.toLowerCase()).toList();
    notifyListeners();
  }

  /// Get the error at a specific position
  SpellCheckError? getErrorAtPosition(int position) {
    for (final error in _errors) {
      if (position >= error.range.start && position < error.range.end) {
        return error;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
