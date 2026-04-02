import 'package:flutter/material.dart' hide SearchBarThemeData;
import 'package:search_plus/search_plus.dart';

/// Demonstrates all the new features added in the search_plus refactoring:
/// - SearchPlusConfig for debug logging
/// - SuggestionChips widget
/// - SearchHistoryList widget
/// - Custom emptyBuilder
/// - SearchPlusBar enhancements (filter, debounce indicator)
/// - Pagination with loadMore
/// - SearchPlusThemeData (renamed from SearchThemeData)
class ModernFeaturesExample extends StatefulWidget {
  const ModernFeaturesExample({super.key});

  @override
  State<ModernFeaturesExample> createState() => _ModernFeaturesExampleState();
}

class _ModernFeaturesExampleState extends State<ModernFeaturesExample> {
  late SearchPlusController<String> _controller;
  final _suggestions = ['Flutter', 'Dart', 'Widget', 'Material', 'Animation'];
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Feature: SearchPlusConfig for debug logging
    SearchPlusConfig.enableDebugLogs = true;

    _controller = SearchPlusController<String>(
      adapter: LocalSearchAdapter<String>(
        items: [
          'Flutter Framework',
          'Dart Language',
          'Material Design',
          'Widget Tree',
          'Animation Controller',
          'State Management',
          'Navigation Router',
          'Custom Painter',
          'Gesture Detector',
          'Inherited Widget',
          'Stream Builder',
          'Future Builder',
          'Layout Builder',
          'Sliver List',
          'Hero Animation',
        ],
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult(
          id: item.toLowerCase().replaceAll(' ', '-'),
          title: item,
          subtitle: 'A Flutter concept',
          data: item,
        ),
      ),
      debounceDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    SearchPlusConfig.enableDebugLogs = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Features'),
        centerTitle: true,
      ),
      body: SearchTheme(
        // Feature: SearchPlusThemeData (the new branded name)
        data: SearchPlusThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(16),
            elevation: 0,
            focusedElevation: 4,
          ),
          resultTheme: const SearchResultThemeData(),
          overlayTheme: const SearchOverlayThemeData(),
        ),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;

            return Column(
              children: [
                // Feature: Enhanced SearchPlusBar with filter & debounce indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SearchPlusBar(
                    onChanged: (query) => _controller.search(query),
                    onSubmitted: (query) {
                      _controller.addToHistory(query);
                      _controller.searchImmediate(query);
                    },
                    hintText: 'Search Flutter concepts...',
                    showDebounceIndicator: true,
                    onFilterPressed: () {
                      setState(() => _showFilters = !_showFilters);
                    },
                  ),
                ),

                // Feature: Filter panel (shown when filter button pressed)
                if (_showFilters)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Filters would go here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                // Feature: SuggestionChips
                if (state.isIdle)
                  SuggestionChips(
                    suggestions: _suggestions,
                    scrollable: true,
                    icon: Icons.trending_up_rounded,
                    onSuggestionTap: (suggestion) {
                      _controller.searchImmediate(suggestion);
                    },
                  ),

                // Feature: SearchHistoryList
                if (state.isIdle && state.history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SearchHistoryList(
                      history: state.history,
                      onHistoryTap: (query) {
                        _controller.searchImmediate(query);
                      },
                      onClearAll: () => _controller.clearHistory(),
                    ),
                  ),

                // Results area with custom emptyBuilder and pagination
                if (!state.isIdle)
                  Expanded(
                    child: SearchPlusResults<String>(
                      state: state,
                      animationConfig: const SearchAnimationConfig(
                        preset: SearchAnimationPreset.fadeSlideUp,
                      ),
                      // Feature: Custom emptyBuilder
                      emptyBuilder: (context, query) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied_rounded,
                                size: 64,
                                color: colorScheme.primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nothing found for "$query"',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try one of the suggestion chips above!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Feature: Pagination
                      onLoadMore: () => _controller.loadMore(),
                      onItemTap: (result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: ${result.title}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  )
                else if (state.history.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Start searching or tap a suggestion!'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
