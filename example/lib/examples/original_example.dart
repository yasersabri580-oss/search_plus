import 'package:flutter/material.dart' hide SearchBarThemeData;
import 'package:flutter/services.dart';
import 'package:search_plus/search_plus.dart';

/// The original comprehensive example that ships with search_plus.
///
/// Demonstrates local, remote, and hybrid search with theming, localization,
/// animation presets, and search history — all in a single screen.

enum _SearchMode { local, remote, hybrid }

class OriginalExample extends StatefulWidget {
  const OriginalExample({super.key});

  @override
  State<OriginalExample> createState() => _OriginalExampleState();
}

class _OriginalExampleState extends State<OriginalExample> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _themeMode == ThemeMode.dark
          ? ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6A4CFF),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            )
          : ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF6A4CFF)),
              useMaterial3: true,
            ),
      child: SearchDemoPage(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}

class SearchDemoPage extends StatefulWidget {
  const SearchDemoPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SearchDemoPage> createState() => _SearchDemoPageState();
}

class _SearchDemoPageState extends State<SearchDemoPage> {
  late final LocalSearchAdapter<_CatalogItem> _localAdapter;
  late final RemoteSearchAdapter<_CatalogItem> _remoteAdapter;
  late final HybridSearchAdapter<_CatalogItem> _hybridAdapter;

  _SearchMode _mode = _SearchMode.hybrid;
  bool _spanishLocale = false;
  bool _denseMode = false;
  int _keyboardIndex = 0;
  List<String> _liveSuggestions = const [];

  late SearchPlusController<_CatalogItem> _controller;

  @override
  void initState() {
    super.initState();
    _localAdapter = LocalSearchAdapter<_CatalogItem>(
      items: _catalog,
      searchableFields: (item) => [
        item.title,
        item.subtitle,
        item.tags.join(' '),
      ],
      toResult: (item) => SearchResult<_CatalogItem>(
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        data: item,
        metadata: {
          'category': item.category,
          'price': item.price,
        },
      ),
      enableFuzzySearch: true,
      rankingConfig: const SearchRankingConfig(
        titleWeight: 1.2,
        subtitleWeight: 0.7,
        fuzzyThreshold: 0.35,
      ),
    );

    _remoteAdapter = RemoteSearchAdapter<_CatalogItem>(
      searchFunction: _searchRemote,
      suggestFunction: _suggestRemote,
    );

    _hybridAdapter = HybridSearchAdapter<_CatalogItem>(
      localAdapter: _localAdapter,
      remoteAdapter: _remoteAdapter,
      localWeight: 1.1,
      remoteWeight: 1.0,
      deduplicateById: true,
    );

    _controller = _createControllerForMode(_mode);
  }

  @override
  void dispose() {
    _controller.dispose();
    _hybridAdapter.dispose();
    super.dispose();
  }

  SearchPlusController<_CatalogItem> _createControllerForMode(_SearchMode mode) {
    switch (mode) {
      case _SearchMode.local:
        return SearchPlusController<_CatalogItem>(
          adapter: _localAdapter,
          debounceDuration: const Duration(milliseconds: 120),
          maxResults: 30,
        );
      case _SearchMode.remote:
        return SearchPlusController<_CatalogItem>(
          adapter: _remoteAdapter,
          debounceDuration: const Duration(milliseconds: 450),
          maxResults: 30,
        );
      case _SearchMode.hybrid:
        return SearchPlusController<_CatalogItem>(
          adapter: _hybridAdapter,
          debounceDuration: const Duration(milliseconds: 250),
          maxResults: 40,
        );
    }
  }

  void _changeMode(_SearchMode mode) {
    if (mode == _mode) return;

    final old = _controller;
    setState(() {
      _mode = mode;
      _keyboardIndex = 0;
      _liveSuggestions = const [];
      _controller = _createControllerForMode(mode);
    });
    old.dispose();
  }

  Future<List<SearchResult<_CatalogItem>>> _searchRemote(
    String query,
    int limit,
    int offset,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final filtered = _catalog.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();

    final sorted = filtered
      ..sort((a, b) {
        final aStarts = a.title.toLowerCase().startsWith(q) ? 1 : 0;
        final bStarts = b.title.toLowerCase().startsWith(q) ? 1 : 0;
        if (aStarts != bStarts) return bStarts.compareTo(aStarts);
        return a.title.compareTo(b.title);
      });

    final page = sorted.skip(offset).take(limit).toList();

    return page
        .asMap()
        .entries
        .map(
          (entry) => SearchResult<_CatalogItem>(
            id: entry.value.id,
            title: entry.value.title,
            subtitle: '${entry.value.subtitle} • API result',
            data: entry.value,
            score: 0.8 - (entry.key * 0.01),
            metadata: {
              'category': entry.value.category,
              'price': entry.value.price,
            },
          ),
        )
        .toList();
  }

  Future<List<String>> _suggestRemote(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final suggestions = <String>{};

    for (final item in _catalog) {
      if (item.title.toLowerCase().startsWith(q)) {
        suggestions.add(item.title);
      }
      for (final tag in item.tags) {
        if (tag.toLowerCase().startsWith(q)) {
          suggestions.add(tag);
        }
      }
      if (suggestions.length >= 6) break;
    }

    return suggestions.take(6).toList();
  }

  Future<void> _updateSuggestions(String query) async {
    final suggestions = await _controller.suggest(query);
    if (!mounted) return;
    setState(() {
      _liveSuggestions = suggestions;
    });
  }

  void _onArrowDown() {
    final results = _controller.results;
    if (results.isEmpty) return;

    setState(() {
      _keyboardIndex = (_keyboardIndex + 1) % results.length;
    });
  }

  void _onArrowUp() {
    final results = _controller.results;
    if (results.isEmpty) return;

    setState(() {
      final next = _keyboardIndex - 1;
      _keyboardIndex = next < 0 ? results.length - 1 : next;
    });
  }

  void _onEnter() {
    final results = _controller.results;
    if (results.isEmpty || _keyboardIndex >= results.length) return;

    final result = results[_keyboardIndex];
    _controller.addToHistory(result.title);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${result.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _spanishLocale
        ? const SearchLocalizations(
            hintText: 'Buscar productos, categorías o etiquetas...',
            emptyResultsText: 'No se encontraron resultados',
            emptyResultsSubtext: 'Intenta con otro término',
            errorText: 'Algo salió mal',
            retryText: 'Reintentar',
            clearText: 'Limpiar',
            cancelText: 'Cancelar',
            searchHistoryTitle: 'Búsquedas recientes',
            suggestionsTitle: 'Sugerencias',
            loadingText: 'Buscando...',
            resultsCountText: '{count} resultados',
            voiceSearchTooltip: 'Búsqueda por voz',
            clearSearchTooltip: 'Limpiar búsqueda',
          )
        : const SearchLocalizations();

    final accent = _mode == _SearchMode.remote
        ? const Color(0xFF0077B6)
        : _mode == _SearchMode.local
            ? const Color(0xFF2E7D32)
            : const Color(0xFF6A4CFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('search_plus showcase'),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            initialValue: widget.themeMode,
            onSelected: widget.onThemeModeChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text('System theme'),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text('Light theme'),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark theme'),
              ),
            ],
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: 'Toggle localization',
            onPressed: () => setState(() => _spanishLocale = !_spanishLocale),
            icon: const Icon(Icons.language_rounded),
          ),
          IconButton(
            tooltip: 'Toggle density',
            onPressed: () => setState(() => _denseMode = !_denseMode),
            icon: const Icon(Icons.view_agenda_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Local'),
                  selected: _mode == _SearchMode.local,
                  onSelected: (_) => _changeMode(_SearchMode.local),
                ),
                ChoiceChip(
                  label: const Text('Async API'),
                  selected: _mode == _SearchMode.remote,
                  onSelected: (_) => _changeMode(_SearchMode.remote),
                ),
                ChoiceChip(
                  label: const Text('Hybrid'),
                  selected: _mode == _SearchMode.hybrid,
                  onSelected: (_) => _changeMode(_SearchMode.hybrid),
                ),
              ],
            ),
          ),
          Expanded(
            child: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.arrowDown): _ArrowDownIntent(),
                SingleActivator(LogicalKeyboardKey.arrowUp): _ArrowUpIntent(),
                SingleActivator(LogicalKeyboardKey.enter): _EnterIntent(),
              },
              child: Actions(
                actions: {
                  _ArrowDownIntent: CallbackAction<_ArrowDownIntent>(
                    onInvoke: (_) {
                      _onArrowDown();
                      return null;
                    },
                  ),
                  _ArrowUpIntent: CallbackAction<_ArrowUpIntent>(
                    onInvoke: (_) {
                      _onArrowUp();
                      return null;
                    },
                  ),
                  _EnterIntent: CallbackAction<_EnterIntent>(
                    onInvoke: (_) {
                      _onEnter();
                      return null;
                    },
                  ),
                },
                child: Focus(
                  autofocus: true,
                  child: SearchScaffold<_CatalogItem>(
                    controller: _controller,
                    hintText:
                        'Search products, categories, tags... (${_mode.name})',
                    density: _denseMode
                        ? SearchResultDensity.compact
                        : SearchResultDensity.rich,
                    animationConfig: SearchAnimationConfig(
                      preset: _mode == _SearchMode.remote
                          ? SearchAnimationPreset.fade
                          : SearchAnimationPreset.staggered,
                      duration: const Duration(milliseconds: 280),
                      staggerDelay: const Duration(milliseconds: 36),
                    ),
                    localizations: l10n,
                    showShimmer: true,
                    addToHistoryOnSubmit: true,
                    onSubmitted: _updateSuggestions,
                    headerBuilder: (context, state) {
                      final history = state.history.take(5).toList();
                      final activeSuggestions = state.query.isEmpty
                          ? _liveSuggestions
                          : _liveSuggestions.take(6).toList();

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.speed_rounded,
                                    color: accent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_mode.name.toUpperCase()} mode • ${state.query.isEmpty ? 'Type to search' : l10n.formatResultsCount(state.results.length)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  if (state.hasResults)
                                    Text(
                                      '⌨ ↑ ↓ Enter',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            if (history.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                l10n.searchHistoryTitle,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: history
                                    .map(
                                      (item) => ActionChip(
                                        label: Text(item),
                                        avatar: const Icon(
                                          Icons.history_rounded,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          _controller.search(item);
                                          _updateSuggestions(item);
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if (activeSuggestions.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                l10n.suggestionsTitle,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: activeSuggestions
                                    .map(
                                      (item) => ActionChip(
                                        label: Text(item),
                                        avatar: const Icon(
                                          Icons.lightbulb_outline,
                                          size: 16,
                                        ),
                                        onPressed: () {
                                          _controller.search(item);
                                          _updateSuggestions(item);
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    idleBuilder: (context) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.travel_explore_rounded,
                              size: 52,
                              color: accent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _spanishLocale
                                  ? 'Explora catálogos con búsqueda inteligente'
                                  : 'Explore catalog data with intelligent search',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    itemBuilder: (context, result, index) {
                      final selected = index == _keyboardIndex;
                      final item = result.data;

                      return Semantics(
                        selected: selected,
                        label: '${result.title}, ${result.subtitle ?? ''}',
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: selected
                              ? accent.withValues(alpha: 0.14)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLowest,
                          child: ListTile(
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_iconForCategory(item?.category),
                                  color: accent),
                            ),
                            title: HighlightText(
                              text: result.title,
                              query: _controller.query,
                              highlightColor: accent.withValues(alpha: 0.18),
                            ),
                            subtitle: Text(
                              '${result.subtitle ?? ''}${item != null ? ' • ${item.category}' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: item != null
                                ? Text(
                                    '\$${item.price.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  )
                                : null,
                            onTap: () {
                              _controller.addToHistory(result.title);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Selected: ${result.title}'),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    theme: SearchThemeData(
                      searchBarTheme: SearchBarThemeData(
                        borderRadius: BorderRadius.circular(18),
                        focusedBorderColor: accent,
                        focusedElevation: 3,
                        backgroundColor: accent.withValues(alpha: 0.08),
                        focusedBackgroundColor: accent.withValues(alpha: 0.11),
                      ),
                      resultTheme: SearchResultThemeData(
                        highlightColor: accent.withValues(alpha: 0.18),
                        highlightStyle: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      animationDuration: const Duration(milliseconds: 280),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowDownIntent extends Intent {
  const _ArrowDownIntent();
}

class _ArrowUpIntent extends Intent {
  const _ArrowUpIntent();
}

class _EnterIntent extends Intent {
  const _EnterIntent();
}

class _CatalogItem {
  const _CatalogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.tags,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final double price;
  final List<String> tags;
}

IconData _iconForCategory(String? category) {
  switch (category) {
    case 'Audio':
      return Icons.headphones_rounded;
    case 'Wearables':
      return Icons.watch_rounded;
    case 'Home':
      return Icons.home_rounded;
    case 'Computing':
      return Icons.computer_rounded;
    case 'Accessories':
      return Icons.cable_rounded;
    default:
      return Icons.inventory_2_outlined;
  }
}

const _catalog = <_CatalogItem>[
  _CatalogItem(
    id: '1',
    title: 'AeroPods Pro',
    subtitle: 'Adaptive noise cancellation earbuds',
    category: 'Audio',
    price: 199,
    tags: ['audio', 'wireless', 'earbuds'],
  ),
  _CatalogItem(
    id: '2',
    title: 'Pulse Watch X',
    subtitle: 'Health tracking and AMOLED display',
    category: 'Wearables',
    price: 279,
    tags: ['watch', 'fitness', 'wearable'],
  ),
  _CatalogItem(
    id: '3',
    title: 'Nimbus Speaker Mini',
    subtitle: 'Portable smart speaker with voice control',
    category: 'Audio',
    price: 89,
    tags: ['speaker', 'smart home', 'bluetooth'],
  ),
  _CatalogItem(
    id: '4',
    title: 'Luma Desk Lamp',
    subtitle: 'Ambient desk lamp with color scenes',
    category: 'Home',
    price: 59,
    tags: ['lamp', 'desk', 'lighting'],
  ),
  _CatalogItem(
    id: '5',
    title: 'Quantum Keyboard 75',
    subtitle: 'Mechanical keyboard with hot-swap switches',
    category: 'Computing',
    price: 149,
    tags: ['keyboard', 'mechanical', 'typing'],
  ),
  _CatalogItem(
    id: '6',
    title: 'Orbit Mouse Air',
    subtitle: 'Ergonomic wireless productivity mouse',
    category: 'Computing',
    price: 69,
    tags: ['mouse', 'wireless', 'office'],
  ),
  _CatalogItem(
    id: '7',
    title: 'Fusion USB-C Hub',
    subtitle: '8-in-1 connectivity hub for creators',
    category: 'Accessories',
    price: 79,
    tags: ['usb-c', 'hub', 'adapter'],
  ),
  _CatalogItem(
    id: '8',
    title: 'Frame Webcam HD',
    subtitle: '1080p autofocus streaming webcam',
    category: 'Computing',
    price: 99,
    tags: ['webcam', 'video', 'streaming'],
  ),
  _CatalogItem(
    id: '9',
    title: 'Nova Charger 65W',
    subtitle: 'Fast GaN charger for multi-device setups',
    category: 'Accessories',
    price: 49,
    tags: ['charger', 'gan', 'power'],
  ),
  _CatalogItem(
    id: '10',
    title: 'Silk Sleeve 14"',
    subtitle: 'Premium laptop sleeve with magnetic lock',
    category: 'Accessories',
    price: 39,
    tags: ['laptop', 'sleeve', 'bag'],
  ),
  _CatalogItem(
    id: '11',
    title: 'Nest Thermostat Go',
    subtitle: 'Energy-saving smart thermostat',
    category: 'Home',
    price: 219,
    tags: ['thermostat', 'smart home', 'climate'],
  ),
  _CatalogItem(
    id: '12',
    title: 'Calm Diffuser',
    subtitle: 'Smart aroma diffuser with timer modes',
    category: 'Home',
    price: 45,
    tags: ['home', 'aroma', 'wellness'],
  ),
];
