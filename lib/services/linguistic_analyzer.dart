import 'package:flutter/material.dart';

/// Types of linguistic analysis
enum LinguisticHighlightType {
  adverbs,
  passiveVoice,
  weakWords,
  repeatedWords,
  longSentences,
  dialogueTags,
  filterWords,
}

extension LinguisticHighlightTypeExtension on LinguisticHighlightType {
  String get displayName {
    switch (this) {
      case LinguisticHighlightType.adverbs:
        return 'Adverbs';
      case LinguisticHighlightType.passiveVoice:
        return 'Passive Voice';
      case LinguisticHighlightType.weakWords:
        return 'Weak Words';
      case LinguisticHighlightType.repeatedWords:
        return 'Repeated Words';
      case LinguisticHighlightType.longSentences:
        return 'Long Sentences';
      case LinguisticHighlightType.dialogueTags:
        return 'Dialogue Tags';
      case LinguisticHighlightType.filterWords:
        return 'Filter Words';
    }
  }

  String get description {
    switch (this) {
      case LinguisticHighlightType.adverbs:
        return 'Words ending in -ly that modify verbs';
      case LinguisticHighlightType.passiveVoice:
        return 'Sentences using passive construction';
      case LinguisticHighlightType.weakWords:
        return 'Vague or weak word choices';
      case LinguisticHighlightType.repeatedWords:
        return 'Words used multiple times nearby';
      case LinguisticHighlightType.longSentences:
        return 'Sentences over 30 words';
      case LinguisticHighlightType.dialogueTags:
        return 'Said/asked and alternatives';
      case LinguisticHighlightType.filterWords:
        return 'Words that distance the reader';
    }
  }

  Color get color {
    switch (this) {
      case LinguisticHighlightType.adverbs:
        return const Color(0xFFFFB74D); // Orange
      case LinguisticHighlightType.passiveVoice:
        return const Color(0xFFE57373); // Red
      case LinguisticHighlightType.weakWords:
        return const Color(0xFFBA68C8); // Purple
      case LinguisticHighlightType.repeatedWords:
        return const Color(0xFF4FC3F7); // Light Blue
      case LinguisticHighlightType.longSentences:
        return const Color(0xFFF06292); // Pink
      case LinguisticHighlightType.dialogueTags:
        return const Color(0xFF81C784); // Green
      case LinguisticHighlightType.filterWords:
        return const Color(0xFF90A4AE); // Blue Grey
    }
  }
}

/// A linguistic highlight in text
class LinguisticHighlight {
  final int startOffset;
  final int endOffset;
  final LinguisticHighlightType type;
  final String matchedText;
  final String? suggestion;

  const LinguisticHighlight({
    required this.startOffset,
    required this.endOffset,
    required this.type,
    required this.matchedText,
    this.suggestion,
  });
}

/// Readability statistics
class ReadabilityStats {
  final int wordCount;
  final int sentenceCount;
  final int paragraphCount;
  final double avgWordsPerSentence;
  final double avgSentencesPerParagraph;
  final int syllableCount;
  final double fleschReadingEase;
  final double fleschKincaidGrade;
  final int adverbCount;
  final int passiveVoiceCount;
  final int dialogueWordCount;

  const ReadabilityStats({
    required this.wordCount,
    required this.sentenceCount,
    required this.paragraphCount,
    required this.avgWordsPerSentence,
    required this.avgSentencesPerParagraph,
    required this.syllableCount,
    required this.fleschReadingEase,
    required this.fleschKincaidGrade,
    required this.adverbCount,
    required this.passiveVoiceCount,
    required this.dialogueWordCount,
  });

  String get readabilityLevel {
    if (fleschReadingEase >= 90) return 'Very Easy';
    if (fleschReadingEase >= 80) return 'Easy';
    if (fleschReadingEase >= 70) return 'Fairly Easy';
    if (fleschReadingEase >= 60) return 'Standard';
    if (fleschReadingEase >= 50) return 'Fairly Difficult';
    if (fleschReadingEase >= 30) return 'Difficult';
    return 'Very Difficult';
  }

  String get gradeLevel {
    if (fleschKincaidGrade < 6) return 'Elementary';
    if (fleschKincaidGrade < 9) return 'Middle School';
    if (fleschKincaidGrade < 13) return 'High School';
    return 'College';
  }
}

/// Service for linguistic analysis
class LinguisticAnalyzer {
  // Common adverbs to highlight
  static const Set<String> _commonAdverbs = {
    'very', 'really', 'quite', 'extremely', 'absolutely', 'completely',
    'totally', 'utterly', 'highly', 'greatly', 'deeply', 'strongly',
    'suddenly', 'quickly', 'slowly', 'softly', 'loudly', 'quietly',
    'gently', 'roughly', 'carefully', 'carelessly', 'easily', 'hardly',
    'nearly', 'almost', 'just', 'only', 'simply', 'merely', 'actually',
    'basically', 'certainly', 'clearly', 'definitely', 'probably',
    'obviously', 'apparently', 'seemingly', 'literally', 'truly',
  };

  // Weak words to highlight
  static const Set<String> _weakWords = {
    'very', 'really', 'quite', 'rather', 'somewhat', 'fairly',
    'thing', 'things', 'stuff', 'something', 'anything', 'everything',
    'good', 'bad', 'nice', 'great', 'big', 'small', 'little',
    'got', 'get', 'gets', 'getting', 'went', 'go', 'goes', 'going',
    'said', 'says', 'say', 'saying',
    'was', 'were', 'is', 'are', 'been', 'being',
    'seem', 'seems', 'seemed', 'seeming',
    'feel', 'feels', 'felt', 'feeling',
    'think', 'thinks', 'thought', 'thinking',
  };

  // Filter words (distancing words)
  static const Set<String> _filterWords = {
    'saw', 'heard', 'felt', 'noticed', 'realized', 'wondered',
    'thought', 'knew', 'believed', 'understood', 'recognized',
    'watched', 'looked', 'seemed', 'appeared', 'sounded',
    'could see', 'could hear', 'could feel', 'could tell',
  };

  // Dialogue tags
  static const Set<String> _dialogueTags = {
    'said', 'asked', 'replied', 'answered', 'whispered', 'shouted',
    'yelled', 'screamed', 'muttered', 'mumbled', 'murmured',
    'exclaimed', 'declared', 'announced', 'stated', 'remarked',
    'commented', 'noted', 'added', 'continued', 'explained',
    'insisted', 'demanded', 'suggested', 'offered', 'proposed',
    'admitted', 'confessed', 'denied', 'agreed', 'disagreed',
    'interrupted', 'interjected', 'snapped', 'growled', 'hissed',
  };


  /// Analyze text and return highlights
  List<LinguisticHighlight> analyze(
    String text,
    Set<LinguisticHighlightType> enabledTypes,
  ) {
    final highlights = <LinguisticHighlight>[];

    if (enabledTypes.contains(LinguisticHighlightType.adverbs)) {
      highlights.addAll(_findAdverbs(text));
    }

    if (enabledTypes.contains(LinguisticHighlightType.passiveVoice)) {
      highlights.addAll(_findPassiveVoice(text));
    }

    if (enabledTypes.contains(LinguisticHighlightType.weakWords)) {
      highlights.addAll(_findWeakWords(text));
    }

    if (enabledTypes.contains(LinguisticHighlightType.repeatedWords)) {
      highlights.addAll(_findRepeatedWords(text));
    }

    if (enabledTypes.contains(LinguisticHighlightType.longSentences)) {
      highlights.addAll(_findLongSentences(text));
    }

    if (enabledTypes.contains(LinguisticHighlightType.dialogueTags)) {
      highlights.addAll(_findDialogueTags(text));
    }

    if (enabledTypes.contains(LinguisticHighlightType.filterWords)) {
      highlights.addAll(_findFilterWords(text));
    }

    // Sort by start offset
    highlights.sort((a, b) => a.startOffset.compareTo(b.startOffset));

    return highlights;
  }

  /// Find adverbs in text
  List<LinguisticHighlight> _findAdverbs(String text) {
    final highlights = <LinguisticHighlight>[];
    final wordPattern = RegExp(r'\b(\w+ly)\b', caseSensitive: false);

    for (final match in wordPattern.allMatches(text)) {
      final word = match.group(1)!.toLowerCase();
      // Check if it's a common adverb or ends in -ly
      if (_commonAdverbs.contains(word) || word.endsWith('ly')) {
        // Exclude some false positives
        if (!_isNotAdverb(word)) {
          highlights.add(LinguisticHighlight(
            startOffset: match.start,
            endOffset: match.end,
            type: LinguisticHighlightType.adverbs,
            matchedText: match.group(0)!,
            suggestion: 'Consider using a stronger verb instead',
          ));
        }
      }
    }

    // Also check for common adverbs that don't end in -ly
    for (final adverb in _commonAdverbs.where((a) => !a.endsWith('ly'))) {
      final pattern = RegExp('\\b$adverb\\b', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        highlights.add(LinguisticHighlight(
          startOffset: match.start,
          endOffset: match.end,
          type: LinguisticHighlightType.adverbs,
          matchedText: match.group(0)!,
        ));
      }
    }

    return highlights;
  }

  bool _isNotAdverb(String word) {
    // Words ending in -ly that are not adverbs
    const notAdverbs = {
      'family', 'only', 'early', 'daily', 'weekly', 'monthly', 'yearly',
      'holy', 'ugly', 'lonely', 'friendly', 'lovely', 'lively', 'likely',
      'unlikely', 'deadly', 'elderly', 'costly', 'orderly', 'timely',
      'silly', 'jolly', 'belly', 'bully', 'hilly', 'jelly', 'rally',
      'ally', 'tally', 'folly', 'holly', 'molly', 'polly', 'dolly',
    };
    return notAdverbs.contains(word);
  }

  /// Find passive voice constructions
  List<LinguisticHighlight> _findPassiveVoice(String text) {
    final highlights = <LinguisticHighlight>[];

    // Pattern: be verb + past participle
    final pattern = RegExp(
      r'\b(was|were|is|are|been|being|be|am|has been|have been|had been|will be)\s+(\w+ed|\w+en)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      highlights.add(LinguisticHighlight(
        startOffset: match.start,
        endOffset: match.end,
        type: LinguisticHighlightType.passiveVoice,
        matchedText: match.group(0)!,
        suggestion: 'Consider using active voice',
      ));
    }

    return highlights;
  }

  /// Find weak words
  List<LinguisticHighlight> _findWeakWords(String text) {
    final highlights = <LinguisticHighlight>[];

    for (final word in _weakWords) {
      final pattern = RegExp('\\b$word\\b', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        highlights.add(LinguisticHighlight(
          startOffset: match.start,
          endOffset: match.end,
          type: LinguisticHighlightType.weakWords,
          matchedText: match.group(0)!,
          suggestion: 'Consider a more specific word',
        ));
      }
    }

    return highlights;
  }

  /// Find repeated words within proximity
  List<LinguisticHighlight> _findRepeatedWords(String text, {int proximity = 100}) {
    final highlights = <LinguisticHighlight>[];
    final wordPattern = RegExp(r'\b(\w{4,})\b'); // Words with 4+ characters
    final matches = wordPattern.allMatches(text).toList();

    final wordPositions = <String, List<Match>>{};

    for (final match in matches) {
      final word = match.group(1)!.toLowerCase();
      // Skip common words
      if (_isCommonWord(word)) continue;

      wordPositions.putIfAbsent(word, () => []).add(match);
    }

    for (final entry in wordPositions.entries) {
      final positions = entry.value;
      if (positions.length < 2) continue;

      for (var i = 1; i < positions.length; i++) {
        final prev = positions[i - 1];
        final curr = positions[i];

        if (curr.start - prev.end < proximity) {
          // Mark both occurrences
          if (i == 1) {
            highlights.add(LinguisticHighlight(
              startOffset: prev.start,
              endOffset: prev.end,
              type: LinguisticHighlightType.repeatedWords,
              matchedText: prev.group(0)!,
              suggestion: 'Word repeated nearby',
            ));
          }
          highlights.add(LinguisticHighlight(
            startOffset: curr.start,
            endOffset: curr.end,
            type: LinguisticHighlightType.repeatedWords,
            matchedText: curr.group(0)!,
            suggestion: 'Word repeated nearby',
          ));
        }
      }
    }

    return highlights;
  }

  bool _isCommonWord(String word) {
    const commonWords = {
      'that', 'this', 'with', 'from', 'they', 'been', 'have', 'were',
      'said', 'each', 'which', 'their', 'will', 'would', 'there',
      'could', 'other', 'into', 'than', 'them', 'these', 'some',
      'what', 'when', 'your', 'more', 'about', 'time', 'very',
    };
    return commonWords.contains(word);
  }

  /// Find long sentences
  List<LinguisticHighlight> _findLongSentences(String text, {int threshold = 30}) {
    final highlights = <LinguisticHighlight>[];
    final sentencePattern = RegExp(r'[^.!?]+[.!?]+');

    for (final match in sentencePattern.allMatches(text)) {
      final sentence = match.group(0)!;
      final wordCount = sentence.trim().split(RegExp(r'\s+')).length;

      if (wordCount > threshold) {
        highlights.add(LinguisticHighlight(
          startOffset: match.start,
          endOffset: match.end,
          type: LinguisticHighlightType.longSentences,
          matchedText: sentence,
          suggestion: 'Consider breaking into shorter sentences ($wordCount words)',
        ));
      }
    }

    return highlights;
  }

  /// Find dialogue tags
  List<LinguisticHighlight> _findDialogueTags(String text) {
    final highlights = <LinguisticHighlight>[];

    for (final tag in _dialogueTags) {
      final pattern = RegExp('\\b$tag\\b', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        highlights.add(LinguisticHighlight(
          startOffset: match.start,
          endOffset: match.end,
          type: LinguisticHighlightType.dialogueTags,
          matchedText: match.group(0)!,
        ));
      }
    }

    return highlights;
  }

  /// Find filter words
  List<LinguisticHighlight> _findFilterWords(String text) {
    final highlights = <LinguisticHighlight>[];

    for (final word in _filterWords) {
      final pattern = RegExp('\\b$word\\b', caseSensitive: false);
      for (final match in pattern.allMatches(text)) {
        highlights.add(LinguisticHighlight(
          startOffset: match.start,
          endOffset: match.end,
          type: LinguisticHighlightType.filterWords,
          matchedText: match.group(0)!,
          suggestion: 'Consider showing directly instead',
        ));
      }
    }

    return highlights;
  }

  /// Calculate readability statistics
  ReadabilityStats calculateReadability(String text) {
    final words = _getWords(text);
    final sentences = _getSentences(text);
    final paragraphs = _getParagraphs(text);

    final wordCount = words.length;
    final sentenceCount = sentences.length.clamp(1, double.maxFinite.toInt());
    final paragraphCount = paragraphs.length.clamp(1, double.maxFinite.toInt());

    final avgWordsPerSentence = wordCount / sentenceCount;
    final avgSentencesPerParagraph = sentenceCount / paragraphCount;

    // Count syllables (approximate)
    var syllableCount = 0;
    for (final word in words) {
      syllableCount += _countSyllables(word);
    }

    // Flesch Reading Ease
    final fleschReadingEase = 206.835 -
        (1.015 * avgWordsPerSentence) -
        (84.6 * (syllableCount / wordCount.clamp(1, double.maxFinite.toInt())));

    // Flesch-Kincaid Grade Level
    final fleschKincaidGrade = (0.39 * avgWordsPerSentence) +
        (11.8 * (syllableCount / wordCount.clamp(1, double.maxFinite.toInt()))) -
        15.59;

    // Count adverbs
    final adverbCount = _findAdverbs(text).length;

    // Count passive voice
    final passiveVoiceCount = _findPassiveVoice(text).length;

    // Estimate dialogue word count
    final dialoguePattern = RegExp(r'"[^"]*"');
    var dialogueWordCount = 0;
    for (final match in dialoguePattern.allMatches(text)) {
      dialogueWordCount += match.group(0)!.split(RegExp(r'\s+')).length;
    }

    return ReadabilityStats(
      wordCount: wordCount,
      sentenceCount: sentenceCount,
      paragraphCount: paragraphCount,
      avgWordsPerSentence: avgWordsPerSentence,
      avgSentencesPerParagraph: avgSentencesPerParagraph,
      syllableCount: syllableCount,
      fleschReadingEase: fleschReadingEase.clamp(0, 100),
      fleschKincaidGrade: fleschKincaidGrade.clamp(0, 20),
      adverbCount: adverbCount,
      passiveVoiceCount: passiveVoiceCount,
      dialogueWordCount: dialogueWordCount,
    );
  }

  List<String> _getWords(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'\w').hasMatch(w))
        .toList();
  }

  List<String> _getSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  List<String> _getParagraphs(String text) {
    return text
        .split(RegExp(r'\n\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }

  int _countSyllables(String word) {
    word = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (word.isEmpty) return 0;

    // Simple syllable counting heuristic
    var count = 0;
    var prevVowel = false;
    const vowels = 'aeiouy';

    for (var i = 0; i < word.length; i++) {
      final isVowel = vowels.contains(word[i]);
      if (isVowel && !prevVowel) {
        count++;
      }
      prevVowel = isVowel;
    }

    // Handle silent e
    if (word.endsWith('e') && count > 1) {
      count--;
    }

    // Handle -le endings
    if (word.length > 2 && word.endsWith('le') && !vowels.contains(word[word.length - 3])) {
      count++;
    }

    return count.clamp(1, 10);
  }
}
