import 'package:flutter/foundation.dart';
import 'search_result.dart';

/// Represents the current state of a search operation.
@immutable
class SearchState<T> {
  /// Creates a search state.
  const SearchState({
    this.query = '',
    this.results = const [],
    this.sections = const [],
    this.status = SearchStatus.idle,
    this.error,
    this.suggestions = const [],
    this.history = const [],
    this.hasMoreResults = false,
    this.currentPage = 0,
    this.totalResults,
  });

  /// The current search query.
  final String query;

  /// Flat list of search results.
  final List<SearchResult<T>> results;

  /// Grouped/sectioned results.
  final List<SearchResultSection<T>> sections;

  /// Current status of the search.
  final SearchStatus status;

  /// Error message if status is [SearchStatus.error].
  final String? error;

  /// Search suggestions based on current input.
  final List<String> suggestions;

  /// Recent search history.
  final List<String> history;

  /// Whether more results are available for pagination.
  final bool hasMoreResults;

  /// The current page index (0-based).
  final int currentPage;

  /// Total number of results available (if known from the adapter).
  final int? totalResults;

  /// Whether the search is currently loading.
  bool get isLoading => status == SearchStatus.loading;

  /// Whether the search has an error.
  bool get hasError => status == SearchStatus.error;

  /// Whether results are available.
  bool get hasResults => results.isNotEmpty || sections.isNotEmpty;

  /// Whether the search is idle with no query.
  bool get isIdle => status == SearchStatus.idle && query.isEmpty;

  /// Creates a copy with the given fields replaced.
  SearchState<T> copyWith({
    String? query,
    List<SearchResult<T>>? results,
    List<SearchResultSection<T>>? sections,
    SearchStatus? status,
    String? error,
    List<String>? suggestions,
    List<String>? history,
    bool? hasMoreResults,
    int? currentPage,
    int? totalResults,
  }) {
    return SearchState<T>(
      query: query ?? this.query,
      results: results ?? this.results,
      sections: sections ?? this.sections,
      status: status ?? this.status,
      error: error,
      suggestions: suggestions ?? this.suggestions,
      history: history ?? this.history,
      hasMoreResults: hasMoreResults ?? this.hasMoreResults,
      currentPage: currentPage ?? this.currentPage,
      totalResults: totalResults ?? this.totalResults,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchState<T> &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          status == other.status &&
          hasMoreResults == other.hasMoreResults &&
          currentPage == other.currentPage &&
          listEquals(results, other.results);

  @override
  int get hashCode =>
      Object.hash(query, status, results.length, hasMoreResults, currentPage);
}

/// Status of a search operation.
enum SearchStatus {
  /// No search in progress, no query entered.
  idle,

  /// Search is in progress.
  loading,

  /// Search completed successfully.
  success,

  /// Search completed with no results.
  empty,

  /// Search failed with an error.
  error,
}
