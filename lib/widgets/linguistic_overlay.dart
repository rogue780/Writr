import 'package:flutter/material.dart';
import '../services/linguistic_analyzer.dart';

/// Widget for displaying linguistic analysis controls and highlights
class LinguisticAnalysisPanel extends StatefulWidget {
  final String text;
  final Function(List<LinguisticHighlight>)? onHighlightsChanged;

  const LinguisticAnalysisPanel({
    super.key,
    required this.text,
    this.onHighlightsChanged,
  });

  @override
  State<LinguisticAnalysisPanel> createState() => _LinguisticAnalysisPanelState();
}

class _LinguisticAnalysisPanelState extends State<LinguisticAnalysisPanel> {
  final LinguisticAnalyzer _analyzer = LinguisticAnalyzer();
  final Set<LinguisticHighlightType> _enabledTypes = {};
  List<LinguisticHighlight> _highlights = [];
  ReadabilityStats? _stats;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  @override
  void didUpdateWidget(LinguisticAnalysisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _calculateStats();
      _updateHighlights();
    }
  }

  void _calculateStats() {
    _stats = _analyzer.calculateReadability(widget.text);
  }

  void _updateHighlights() {
    _highlights = _analyzer.analyze(widget.text, _enabledTypes);
    widget.onHighlightsChanged?.call(_highlights);
    setState(() {});
  }

  void _toggleHighlightType(LinguisticHighlightType type) {
    setState(() {
      if (_enabledTypes.contains(type)) {
        _enabledTypes.remove(type);
      } else {
        _enabledTypes.add(type);
      }
      _updateHighlights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Readability Stats
        if (_stats != null) _buildReadabilityStats(),

        const Divider(),

        // Highlight Toggles
        const Text(
          'Highlight Analysis',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...LinguisticHighlightType.values.map((type) => _buildToggle(type)),

        const Divider(),

        // Highlight Summary
        if (_highlights.isNotEmpty) _buildHighlightSummary(),
      ],
    );
  }

  Widget _buildReadabilityStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Readability',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Reading ease gauge
        _buildStatRow(
          'Reading Ease',
          _stats!.readabilityLevel,
          _stats!.fleschReadingEase / 100,
          _getReadabilityColor(_stats!.fleschReadingEase),
        ),
        const SizedBox(height: 4),
        _buildStatRow(
          'Grade Level',
          _stats!.gradeLevel,
          _stats!.fleschKincaidGrade / 20,
          _getGradeColor(_stats!.fleschKincaidGrade),
        ),

        const SizedBox(height: 12),

        // Statistics grid
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatChip('Words', _stats!.wordCount.toString()),
            _buildStatChip('Sentences', _stats!.sentenceCount.toString()),
            _buildStatChip('Paragraphs', _stats!.paragraphCount.toString()),
            _buildStatChip(
              'Avg Words/Sentence',
              _stats!.avgWordsPerSentence.toStringAsFixed(1),
            ),
            _buildStatChip('Adverbs', _stats!.adverbCount.toString()),
            _buildStatChip('Passive Voice', _stats!.passiveVoiceCount.toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getReadabilityColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(double grade) {
    if (grade <= 8) return Colors.green;
    if (grade <= 12) return Colors.orange;
    return Colors.red;
  }

  Widget _buildToggle(LinguisticHighlightType type) {
    final isEnabled = _enabledTypes.contains(type);
    final count = _highlights.where((h) => h.type == type).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _toggleHighlightType(type),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isEnabled,
                  onChanged: (_) => _toggleHighlightType(type),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: type.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      type.description,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isEnabled && count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: type.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightSummary() {
    final groupedHighlights = <LinguisticHighlightType, List<LinguisticHighlight>>{};
    for (final highlight in _highlights) {
      groupedHighlights.putIfAbsent(highlight.type, () => []).add(highlight);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Found Issues',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '${_highlights.length} total',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...groupedHighlights.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key.displayName} (${entry.value.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: entry.value.take(10).map((h) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: entry.key.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      h.matchedText.length > 20
                          ? '${h.matchedText.substring(0, 20)}...'
                          : h.matchedText,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
              if (entry.value.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${entry.value.length - 10} more',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}

/// Dialog for displaying full linguistic analysis
class LinguisticAnalysisDialog extends StatelessWidget {
  final String text;
  final String documentTitle;

  const LinguisticAnalysisDialog({
    super.key,
    required this.text,
    required this.documentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analysis: $documentTitle',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: LinguisticAnalysisPanel(text: text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to apply highlights to text
extension LinguisticHighlightExtension on List<LinguisticHighlight> {
  /// Build text spans with highlights applied
  List<TextSpan> buildHighlightedSpans(String text, TextStyle baseStyle) {
    if (isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final spans = <TextSpan>[];
    var lastEnd = 0;

    // Sort highlights by position
    final sorted = List<LinguisticHighlight>.from(this)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    for (final highlight in sorted) {
      // Skip overlapping highlights
      if (highlight.startOffset < lastEnd) continue;

      // Add text before highlight
      if (highlight.startOffset > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, highlight.startOffset),
          style: baseStyle,
        ));
      }

      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(highlight.startOffset, highlight.endOffset),
        style: baseStyle.copyWith(
          backgroundColor: highlight.type.color.withValues(alpha: 0.3),
          decoration: TextDecoration.underline,
          decorationColor: highlight.type.color,
        ),
      ));

      lastEnd = highlight.endOffset;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
