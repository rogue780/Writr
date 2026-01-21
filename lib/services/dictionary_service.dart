import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for spell checking with bundled and user dictionaries
class DictionaryService {
  static DictionaryService? _instance;
  static bool _isInitializing = false;
  static Completer<DictionaryService>? _initCompleter;

  final Set<String> _words = {};
  final Set<String> _userWords = {};
  bool _isLoaded = false;

  static const String _userDictionaryKey = 'user_dictionary';

  DictionaryService._();

  /// Get the singleton instance, initializing if needed
  static Future<DictionaryService> getInstance() async {
    if (_instance != null && _instance!._isLoaded) {
      return _instance!;
    }

    if (_isInitializing) {
      return _initCompleter!.future;
    }

    _isInitializing = true;
    _initCompleter = Completer<DictionaryService>();

    _instance = DictionaryService._();
    await _instance!._loadDictionary();
    await _instance!._loadUserDictionary();

    _isInitializing = false;
    _initCompleter!.complete(_instance);

    return _instance!;
  }

  /// Check if a word is valid (in dictionary or user dictionary)
  bool isValidWord(String word) {
    if (word.isEmpty) return true;

    final normalized = word.toLowerCase().trim();

    // Skip single letters (except 'a' and 'i')
    if (normalized.length == 1 && normalized != 'a' && normalized != 'i') {
      return true;
    }

    // Skip numbers and words with numbers
    if (RegExp(r'\d').hasMatch(normalized)) {
      return true;
    }

    // Check user dictionary first
    if (_userWords.contains(normalized)) {
      return true;
    }

    // Check main dictionary
    return _words.contains(normalized);
  }

  /// Get spelling suggestions for a misspelled word
  List<String> getSuggestions(String word, {int maxResults = 5}) {
    if (word.isEmpty) return [];

    final normalized = word.toLowerCase().trim();
    final suggestions = <_ScoredWord>[];

    // Find words within edit distance 1-2
    for (final dictWord in _words) {
      // Skip words that are too different in length
      if ((dictWord.length - normalized.length).abs() > 2) continue;

      final distance = _levenshteinDistance(normalized, dictWord);
      if (distance <= 2) {
        suggestions.add(_ScoredWord(dictWord, distance));
      }

      // Early exit if we have enough good suggestions
      if (suggestions.length > maxResults * 3) break;
    }

    // Sort by edit distance, then alphabetically
    suggestions.sort((a, b) {
      final distCompare = a.distance.compareTo(b.distance);
      if (distCompare != 0) return distCompare;
      return a.word.compareTo(b.word);
    });

    // Preserve original casing if word was capitalized
    final result = suggestions.take(maxResults).map((s) {
      if (word.isNotEmpty && word[0] == word[0].toUpperCase()) {
        return s.word[0].toUpperCase() + s.word.substring(1);
      }
      return s.word;
    }).toList();

    return result;
  }

  /// Add a word to the user dictionary
  Future<void> addToUserDictionary(String word) async {
    final normalized = word.toLowerCase().trim();
    if (normalized.isEmpty) return;

    _userWords.add(normalized);
    await _saveUserDictionary();
  }

  /// Remove a word from the user dictionary
  Future<void> removeFromUserDictionary(String word) async {
    final normalized = word.toLowerCase().trim();
    _userWords.remove(normalized);
    await _saveUserDictionary();
  }

  /// Get all words in the user dictionary
  List<String> get userDictionaryWords => _userWords.toList()..sort();

  /// Clear the user dictionary
  Future<void> clearUserDictionary() async {
    _userWords.clear();
    await _saveUserDictionary();
  }

  Future<void> _loadDictionary() async {
    try {
      final data = await rootBundle.loadString('assets/dictionaries/en_US.txt');
      final words = data.split('\n');

      for (final word in words) {
        final trimmed = word.trim().toLowerCase();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          _words.add(trimmed);
        }
      }

      _isLoaded = true;
    } catch (e) {
      // Dictionary not found - spell check will be disabled
      _isLoaded = false;
    }
  }

  Future<void> _loadUserDictionary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final words = prefs.getStringList(_userDictionaryKey) ?? [];
      _userWords.addAll(words);
    } catch (e) {
      // Ignore errors loading user dictionary
    }
  }

  Future<void> _saveUserDictionary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userDictionaryKey, _userWords.toList());
    } catch (e) {
      // Ignore errors saving user dictionary
    }
  }

  /// Calculate Levenshtein edit distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    // Use two rows instead of full matrix for memory efficiency
    var prevRow = List<int>.generate(s2.length + 1, (i) => i);
    var currRow = List<int>.filled(s2.length + 1, 0);

    for (var i = 1; i <= s1.length; i++) {
      currRow[0] = i;

      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        currRow[j] = [
          prevRow[j] + 1, // deletion
          currRow[j - 1] + 1, // insertion
          prevRow[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }

      // Swap rows
      final temp = prevRow;
      prevRow = currRow;
      currRow = temp;
    }

    return prevRow[s2.length];
  }

  /// Check if the dictionary is loaded
  bool get isLoaded => _isLoaded;

  /// Get the number of words in the main dictionary
  int get wordCount => _words.length;
}

class _ScoredWord {
  final String word;
  final int distance;

  _ScoredWord(this.word, this.distance);
}
