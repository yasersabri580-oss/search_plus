import '../core/search_result.dart';
import 'search_adapter.dart';

/// A search adapter that delegates to a remote API or async data source.
///
/// Users provide a [searchFunction] that performs the actual network call.
///
/// ```dart
/// final adapter = RemoteSearchAdapter<Product>(
///   searchFunction: (query, limit, offset) async {
///     final response = await api.search(query, limit: limit, offset: offset);
///     return response.map((p) => SearchResult(
///       id: p.id,
///       title: p.name,
///       data: p,
///     )).toList();
///   },
/// );
/// ```
class RemoteSearchAdapter<T> extends SearchAdapter<T> {
  /// Creates a remote search adapter.
  RemoteSearchAdapter({
    required this.searchFunction,
    this.suggestFunction,
  });

  /// The async function to perform remote search.
  final Future<List<SearchResult<T>>> Function(
    String query,
    int limit,
    int offset,
  ) searchFunction;

  /// Optional function to provide remote suggestions.
  final Future<List<String>> Function(String query)? suggestFunction;

  @override
  Future<List<SearchResult<T>>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final results = await searchFunction(query, limit, offset);
    return results
        .map((r) => r.copyWith(source: SearchResultSource.remote))
        .toList();
  }

  @override
  Future<List<String>> suggest(String query) async {
    if (suggestFunction != null) {
      return suggestFunction!(query);
    }
    return const [];
  }
}
