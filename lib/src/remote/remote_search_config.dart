/// HTTP methods supported by [EnhancedRemoteAdapter].
enum HttpMethod {
  /// HTTP GET.
  get,

  /// HTTP POST.
  post,
}

/// Configuration for the enhanced remote search adapter.
///
/// Provides fine-grained control over networking behavior including
/// retry strategies, timeouts, caching, and debouncing.
///
/// ```dart
/// final config = RemoteSearchConfig(
///   endpoint: '/api/search',
///   method: HttpMethod.get,
///   debounce: Duration(milliseconds: 300),
///   timeout: Duration(seconds: 10),
///   retryCount: 3,
///   enableCache: true,
/// );
/// ```
class RemoteSearchConfig {
  /// Creates a remote search configuration.
  const RemoteSearchConfig({
    this.endpoint,
    this.method = HttpMethod.get,
    this.debounce = const Duration(milliseconds: 300),
    this.timeout = const Duration(seconds: 15),
    this.retryCount = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.useExponentialBackoff = true,
    this.maxBackoffDelay = const Duration(seconds: 30),
    this.enableCache = false,
    this.cacheTtl = const Duration(minutes: 5),
    this.enableDeduplication = true,
    this.enableRequestCancellation = true,
    this.headers = const {},
    this.queryParameterName = 'q',
    this.limitParameterName = 'limit',
    this.offsetParameterName = 'offset',
  });

  /// The API endpoint path (e.g., '/api/search').
  final String? endpoint;

  /// The HTTP method to use.
  final HttpMethod method;

  /// Debounce duration before sending the request.
  final Duration debounce;

  /// Request timeout duration.
  final Duration timeout;

  /// Number of retry attempts on failure (0 = no retries).
  final int retryCount;

  /// Delay between retry attempts (base delay for exponential backoff).
  final Duration retryDelay;

  /// Whether to use exponential backoff for retries.
  final bool useExponentialBackoff;

  /// Maximum delay between retries when using exponential backoff.
  final Duration maxBackoffDelay;

  /// Whether to cache results.
  final bool enableCache;

  /// TTL for cached results.
  final Duration cacheTtl;

  /// Whether to deduplicate identical concurrent queries.
  final bool enableDeduplication;

  /// Whether to cancel previous in-flight requests on new queries.
  final bool enableRequestCancellation;

  /// Custom HTTP headers.
  final Map<String, String> headers;

  /// Name of the query parameter in the URL.
  final String queryParameterName;

  /// Name of the limit parameter in the URL.
  final String limitParameterName;

  /// Name of the offset parameter in the URL.
  final String offsetParameterName;

  /// Creates a copy with the given fields replaced.
  RemoteSearchConfig copyWith({
    String? endpoint,
    HttpMethod? method,
    Duration? debounce,
    Duration? timeout,
    int? retryCount,
    Duration? retryDelay,
    bool? useExponentialBackoff,
    Duration? maxBackoffDelay,
    bool? enableCache,
    Duration? cacheTtl,
    bool? enableDeduplication,
    bool? enableRequestCancellation,
    Map<String, String>? headers,
    String? queryParameterName,
    String? limitParameterName,
    String? offsetParameterName,
  }) {
    return RemoteSearchConfig(
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      debounce: debounce ?? this.debounce,
      timeout: timeout ?? this.timeout,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
      useExponentialBackoff: useExponentialBackoff ?? this.useExponentialBackoff,
      maxBackoffDelay: maxBackoffDelay ?? this.maxBackoffDelay,
      enableCache: enableCache ?? this.enableCache,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      enableDeduplication: enableDeduplication ?? this.enableDeduplication,
      enableRequestCancellation:
          enableRequestCancellation ?? this.enableRequestCancellation,
      headers: headers ?? this.headers,
      queryParameterName: queryParameterName ?? this.queryParameterName,
      limitParameterName: limitParameterName ?? this.limitParameterName,
      offsetParameterName: offsetParameterName ?? this.offsetParameterName,
    );
  }
}
