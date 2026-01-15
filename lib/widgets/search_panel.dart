import 'package:flutter/material.dart';
import '../models/search_result.dart';
import '../models/scrivener_project.dart';
import '../services/search_service.dart';

/// Panel for searching within the project
class SearchPanel extends StatefulWidget {
  final ScrivenerProject project;
  final SearchService searchService;
  final Function(String documentId)? onNavigateToDocument;
  final Function(String documentId, int matchIndex)? onNavigateToMatch;
  final String? currentFolderId;
  final VoidCallback? onClose;

  const SearchPanel({
    super.key,
    required this.project,
    required this.searchService,
    this.onNavigateToDocument,
    this.onNavigateToMatch,
    this.currentFolderId,
    this.onClose,
  });

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  SearchOptions _options = const SearchOptions();
  bool _showReplace = false;
  bool _showOptions = false;
  SearchResults? _results;
  int _selectedResultIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _results = null;
        _selectedResultIndex = -1;
      });
      return;
    }

    final results = await widget.searchService.search(
      widget.project,
      query,
      options: _options,
      currentFolderId: widget.currentFolderId,
    );

    setState(() {
      _results = results;
      _selectedResultIndex = results.hasResults ? 0 : -1;
    });
  }

  void _navigateToResult(DocumentSearchResult result, int matchIndex) {
    widget.onNavigateToMatch?.call(result.documentId, matchIndex);
  }

  void _nextResult() {
    if (_results == null || !_results!.hasResults) return;

    setState(() {
      _selectedResultIndex = (_selectedResultIndex + 1) % _results!.results.length;
    });
  }

  void _previousResult() {
    if (_results == null || !_results!.hasResults) return;

    setState(() {
      _selectedResultIndex = _selectedResultIndex <= 0
          ? _results!.results.length - 1
          : _selectedResultIndex - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input row
          _buildSearchRow(context),

          // Replace row (if enabled)
          if (_showReplace) _buildReplaceRow(context),

          // Options row (if expanded)
          if (_showOptions) _buildOptionsRow(context),

          // Results summary
          if (_results != null) _buildResultsSummary(context),

          // Results list
          if (_results != null && _results!.hasResults)
            _buildResultsList(context),
        ],
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Search input
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = null;
                            _selectedResultIndex = -1;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onChanged: (_) => _performSearch(),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 8),

          // Navigation buttons
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 20),
            onPressed: _results?.hasResults == true ? _previousResult : null,
            tooltip: 'Previous',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
            onPressed: _results?.hasResults == true ? _nextResult : null,
            tooltip: 'Next',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          // Toggle options
          IconButton(
            icon: Icon(
              _showOptions ? Icons.tune : Icons.tune_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showOptions = !_showOptions;
              });
            },
            tooltip: 'Search Options',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          // Toggle replace
          IconButton(
            icon: Icon(
              _showReplace ? Icons.find_replace : Icons.find_replace_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showReplace = !_showReplace;
              });
            },
            tooltip: 'Find & Replace',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),

          // Close button
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onClose,
              tooltip: 'Close',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildReplaceRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replaceController,
              decoration: InputDecoration(
                hintText: 'Replace with...',
                prefixIcon: const Icon(Icons.find_replace, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _results?.hasResults == true ? _replaceNext : null,
            child: const Text('Replace'),
          ),
          TextButton(
            onPressed: _results?.hasResults == true ? _replaceAll : null,
            child: const Text('Replace All'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          FilterChip(
            label: const Text('Aa'),
            tooltip: 'Case Sensitive',
            selected: _options.caseSensitive,
            onSelected: (value) {
              setState(() {
                _options = _options.copyWith(caseSensitive: value);
              });
              _performSearch();
            },
          ),
          FilterChip(
            label: const Text('W'),
            tooltip: 'Whole Word',
            selected: _options.wholeWord,
            onSelected: (value) {
              setState(() {
                _options = _options.copyWith(wholeWord: value);
              });
              _performSearch();
            },
          ),
          FilterChip(
            label: const Text('.*'),
            tooltip: 'Regular Expression',
            selected: _options.useRegex,
            onSelected: (value) {
              setState(() {
                _options = _options.copyWith(useRegex: value);
              });
              _performSearch();
            },
          ),
          const VerticalDivider(width: 16),
          FilterChip(
            label: const Text('Content'),
            selected: _options.searchInContent,
            onSelected: (value) {
              setState(() {
                _options = _options.copyWith(searchInContent: value);
              });
              _performSearch();
            },
          ),
          FilterChip(
            label: const Text('Titles'),
            selected: _options.searchInTitles,
            onSelected: (value) {
              setState(() {
                _options = _options.copyWith(searchInTitles: value);
              });
              _performSearch();
            },
          ),
          FilterChip(
            label: const Text('Synopsis'),
            selected: _options.searchInSynopsis,
            onSelected: (value) {
              setState(() {
                _options = _options.copyWith(searchInSynopsis: value);
              });
              _performSearch();
            },
          ),
          FilterChip(
            label: const Text('Notes'),
            selected: _options.searchInNotes,
            onSelected: (value) {
              setState(() {
                _options = _options.copyWith(searchInNotes: value);
              });
              _performSearch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(BuildContext context) {
    final results = _results!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Text(
            results.hasResults
                ? '${results.totalMatches} match${results.totalMatches != 1 ? 'es' : ''} in ${results.documentCount} document${results.documentCount != 1 ? 's' : ''}'
                : 'No results found',
            style: TextStyle(
              fontSize: 12,
              color: results.hasResults ? null : Colors.grey[600],
            ),
          ),
          const Spacer(),
          if (results.hasResults)
            Text(
              '${_selectedResultIndex + 1} of ${results.results.length}',
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(width: 8),
          Text(
            '${results.searchDuration.inMilliseconds}ms',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _results!.results.length,
        itemBuilder: (context, index) {
          final result = _results!.results[index];
          final isSelected = index == _selectedResultIndex;

          return _SearchResultItem(
            result: result,
            isSelected: isSelected,
            searchQuery: _searchController.text,
            onTap: () {
              setState(() {
                _selectedResultIndex = index;
              });
              widget.onNavigateToDocument?.call(result.documentId);
            },
            onMatchTap: (matchIndex) {
              _navigateToResult(result, matchIndex);
            },
          );
        },
      ),
    );
  }

  void _replaceNext() {
    // TODO: Implement replace next
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replace next not yet implemented')),
    );
  }

  void _replaceAll() {
    // TODO: Implement replace all
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replace all not yet implemented')),
    );
  }
}

/// Widget for displaying a single search result
class _SearchResultItem extends StatelessWidget {
  final DocumentSearchResult result;
  final bool isSelected;
  final String searchQuery;
  final VoidCallback? onTap;
  final Function(int matchIndex)? onMatchTap;

  const _SearchResultItem({
    required this.result,
    required this.isSelected,
    required this.searchQuery,
    this.onTap,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document title and path
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      result.documentTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${result.matchCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              if (result.documentPath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 2),
                  child: Text(
                    result.documentPath,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Show first match context
              if (result.matches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4),
                  child: _buildMatchContext(context, result.matches.first),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchContext(BuildContext context, SearchMatch match) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
        children: [
          TextSpan(text: match.contextBefore),
          TextSpan(
            text: match.matchedText,
            style: TextStyle(
              backgroundColor: Colors.yellow.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextSpan(text: match.contextAfter),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
