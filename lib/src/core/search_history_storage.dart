import 'dart:convert';

/// Abstract interface for persisting search history.
///
/// Implement this interface to provide custom storage backends
/// (e.g., SharedPreferences, Hive, flutter_secure_storage).
///
/// The default [InMemoryHistoryStorage] keeps history in memory only.
///
/// ```dart
/// class SharedPrefsHistoryStorage extends SearchHistoryStorage {
///   final SharedPreferences prefs;
///   SharedPrefsHistoryStorage(this.prefs);
///
///   @override
///   Future<List<String>> load() async {
///     return prefs.getStringList('search_history') ?? [];
///   }
///
///   @override
///   Future<void> save(List<String> history) async {
///     await prefs.setStringList('search_history', history);
///   }
///
///   @override
///   Future<void> clear() async {
///     await prefs.remove('search_history');
///   }
/// }
/// ```
abstract class SearchHistoryStorage {
  /// Loads persisted history items.
  Future<List<String>> load();

  /// Saves the given history items.
  Future<void> save(List<String> history);

  /// Clears all persisted history.
  Future<void> clear();
}

/// In-memory implementation of [SearchHistoryStorage].
///
/// History is lost when the app restarts. Use this as a fallback
/// when no persistent storage is available.
class InMemoryHistoryStorage extends SearchHistoryStorage {
  final List<String> _items = [];

  @override
  Future<List<String>> load() async => List.unmodifiable(_items);

  @override
  Future<void> save(List<String> history) async {
    _items
      ..clear()
      ..addAll(history);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

/// A secure file-based history storage abstraction.
///
/// This implementation encodes history as JSON and stores it via
/// a save/load callback pair. You can wire it to any file-based
/// or secure storage mechanism.
///
/// ```dart
/// final storage = SecureFallbackHistoryStorage(
///   readFn: () async => await secureStorage.read(key: 'history') ?? '',
///   writeFn: (data) async => await secureStorage.write(key: 'history', value: data),
///   deleteFn: () async => await secureStorage.delete(key: 'history'),
/// );
/// ```
class SecureFallbackHistoryStorage extends SearchHistoryStorage {
  /// Creates a secure fallback storage.
  SecureFallbackHistoryStorage({
    required this.readFn,
    required this.writeFn,
    required this.deleteFn,
  });

  /// Reads the raw string data from storage.
  final Future<String> Function() readFn;

  /// Writes the raw string data to storage.
  final Future<void> Function(String data) writeFn;

  /// Deletes the data from storage.
  final Future<void> Function() deleteFn;

  @override
  Future<List<String>> load() async {
    try {
      final raw = await readFn();
      if (raw.isEmpty) return [];
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<String> history) async {
    final encoded = json.encode(history);
    await writeFn(encoded);
  }

  @override
  Future<void> clear() async {
    await deleteFn();
  }
}

/// Manages search history with deduplication, limits, and optional persistence.
///
/// Use this to add, remove, and clear history items, with automatic
/// persistence through any [SearchHistoryStorage] implementation.
class SearchHistoryManager {
  /// Creates a history manager.
  SearchHistoryManager({
    this.maxItems = 10,
    SearchHistoryStorage? storage,
  }) : _storage = storage ?? InMemoryHistoryStorage();

  /// Maximum number of history items to keep.
  final int maxItems;

  final SearchHistoryStorage _storage;
  final List<String> _items = [];

  /// The current history items (most recent first).
  List<String> get items => List.unmodifiable(_items);

  /// Loads history from storage.
  Future<void> load() async {
    final loaded = await _storage.load();
    _items
      ..clear()
      ..addAll(loaded.take(maxItems));
  }

  /// Adds a query to history. Removes duplicates and enforces max count.
  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _items.remove(trimmed);
    _items.insert(0, trimmed);
    if (_items.length > maxItems) {
      _items.removeLast();
    }
    await _storage.save(List.unmodifiable(_items));
  }

  /// Removes a specific item from history.
  Future<void> remove(String query) async {
    _items.remove(query);
    await _storage.save(List.unmodifiable(_items));
  }

  /// Clears all history.
  Future<void> clearAll() async {
    _items.clear();
    await _storage.clear();
  }
}
