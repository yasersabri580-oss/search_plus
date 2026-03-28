import 'package:flutter/foundation.dart';

/// Represents a single search result item.
///
/// Generic type [T] allows attaching any data model to the result.
@immutable
class SearchResult<T> implements Comparable<SearchResult<T>> {
  /// Creates a search result.
  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.data,
    this.score = 0.0,
    this.source = SearchResultSource.local,
    this.metadata = const {},
  });

  /// Unique identifier for this result.
  final String id;

  /// Primary display text.
  final String title;

  /// Secondary display text.
  final String? subtitle;

  /// Optional image URL for rich display.
  final String? imageUrl;

  /// The original data object associated with this result.
  final T? data;

  /// Relevance score (higher is more relevant). Used for ranking.
  final double score;

  /// Source of this result (local, remote, or merged).
  final SearchResultSource source;

  /// Arbitrary metadata for extensibility.
  final Map<String, dynamic> metadata;

  /// Creates a copy with the given fields replaced.
  SearchResult<T> copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    T? data,
    double? score,
    SearchResultSource? source,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult<T>(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      score: score ?? this.score,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  int compareTo(SearchResult<T> other) => other.score.compareTo(score);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult<T> &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SearchResult(id: $id, title: $title, score: $score)';
}

/// Indicates the origin of a search result.
enum SearchResultSource {
  /// Result from local/in-memory search.
  local,

  /// Result from remote/API search.
  remote,

  /// Result merged from multiple sources.
  merged,
}

/// A group of search results under a section header.
@immutable
class SearchResultSection<T> {
  /// Creates a result section.
  const SearchResultSection({
    required this.title,
    required this.results,
    this.icon,
    this.isExpanded = true,
  });

  /// Section header title.
  final String title;

  /// Results in this section.
  final List<SearchResult<T>> results;

  /// Optional icon for the section header.
  final dynamic icon;

  /// Whether this section is initially expanded.
  final bool isExpanded;
}
