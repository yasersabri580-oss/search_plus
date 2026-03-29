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
  }) {
    return SearchState<T>(
      query: query ?? this.query,
      results: results ?? this.results,
      sections: sections ?? this.sections,
      status: status ?? this.status,
      error: error,
      suggestions: suggestions ?? this.suggestions,
      history: history ?? this.history,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchState<T> &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          status == other.status &&
          listEquals(results, other.results);

  @override
  int get hashCode => Object.hash(query, status, results.length);
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
