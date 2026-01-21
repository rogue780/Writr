import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'dictionary_service.dart';

/// Represents a spelling error with its location and suggestions
class SpellCheckError {
  final TextRange range;
  final String word;
  final List<String> suggestions;

  const SpellCheckError({
    required this.range,
    required this.word,
    required this.suggestions,
  });

  @override
  String toString() => 'SpellCheckError($word at ${range.start}-${range.end})';
}

/// Service for performing spell checking on text
class SpellCheckService extends ChangeNotifier {
  final DictionaryService _dictionary;

  Timer? _debounceTimer;
  List<SpellCheckError> _errors = [];
  String _lastCheckedText = '';
  bool _isChecking = false;

  /// Duration to wait after text changes before checking
  final Duration debounceDelay;

  SpellCheckService(
    this._dictionary, {
    this.debounceDelay = const Duration(milliseconds: 500),
  });

  /// Current list of spelling errors
  List<SpellCheckError> get errors => _errors;

  /// Whether a spell check is currently in progress
  bool get isChecking => _isChecking;

  /// Whether the dictionary is loaded and ready
  bool get isReady => _dictionary.isLoaded;

  /// Check text for spelling errors with debouncing
  void checkText(String text) {
    // Skip if text hasn't changed
    if (text == _lastCheckedText) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, () {
      _performCheck(text);
    });
  }

  /// Check text immediately without debouncing
  void checkTextImmediate(String text) {
    _debounceTimer?.cancel();
    _performCheck(text);
  }

  /// Clear all errors
  void clearErrors() {
    if (_errors.isNotEmpty) {
      _errors = [];
      notifyListeners();
    }
  }

  void _performCheck(String text) {
    if (!_dictionary.isLoaded) {
      _errors = [];
      notifyListeners();
      return;
    }

    _isChecking = true;
    _lastCheckedText = text;

    final errors = <SpellCheckError>[];

    // Match words (including contractions with apostrophes)
    final wordPattern = RegExp(r"[a-zA-Z]+(?:'[a-zA-Z]+)?");

    for (final match in wordPattern.allMatches(text)) {
      final word = match.group(0)!;

      // Skip very short words (single letters handled in dictionary)
      if (word.length < 2) continue;

      // Skip words that are all caps (likely acronyms)
      if (word == word.toUpperCase() && word.length <= 5) continue;

      if (!_dictionary.isValidWord(word)) {
        errors.add(SpellCheckError(
          range: TextRange(start: match.start, end: match.end),
          word: word,
          suggestions: _dictionary.getSuggestions(word),
        ));
      }
    }

    _errors = errors;
    _isChecking = false;
    notifyListeners();
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

  /// Get the suggestion for a word at a specific position
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
