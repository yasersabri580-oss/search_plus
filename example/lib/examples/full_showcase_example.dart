import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

import '../api/fake_search_api.dart';

/// 🔥 Full Showcase — demonstrates every feature of search_plus in a single
/// screen optimized for video recording and demo presentations.
///
/// Features demonstrated:
/// - Debounced search input with live results
/// - Search suggestions & recent searches
/// - Trending items
/// - Empty, loading, error states
/// - Smooth transitions & stagger animations
/// - Custom item builders
/// - Filters (category chips)
/// - Dark / light mode
/// - Glassmorphism style variant
class FullShowcaseExample extends StatefulWidget {
  const FullShowcaseExample({super.key});

  @override
  State<FullShowcaseExample> createState() => _FullShowcaseExampleState();
}

class _FullShowcaseExampleState extends State<FullShowcaseExample>
    with TickerProviderStateMixin {
  // -- Data & API --
  final _api = FakeSearchApi(
    minDelay: const Duration(milliseconds: 400),
    maxDelay: const Duration(milliseconds: 1000),
  );

  late final SearchPlusController<Product> _controller;
  late final TabController _tabController;

  // -- State --
  String? _activeCategory;
  final _allCategories = <String>{};
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();

    // Collect unique categories from sample data.
    for (final p in sampleProducts) {
      _allCategories.add(p.category);
    }

    _tabController = TabController(length: 3, vsync: this);

    _controller = SearchPlusController<Product>(
      adapter: RemoteSearchAdapter<Product>(
        searchFunction: _filteredSearch,
        suggestFunction: _api.suggestProducts,
      ),
      debounceDuration: const Duration(milliseconds: 350),
      maxHistoryItems: 10,
    );
  }

  Future<List<SearchResult<Product>>> _filteredSearch(
    String query,
    int limit,
    int offset,
  ) async {
    final results = await _api.searchProducts(
      query,
      limit: limit,
      offset: offset,
    );
    if (_activeCategory == null) return results;
    return results
        .where((r) => r.metadata['category'] == _activeCategory)
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // -- Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const BackButton(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Discover',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showFilters
                          ? Icons.filter_list_off
                          : Icons.filter_list,
                    ),
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SearchPlusBar(
                onChanged: (q) => _controller.search(q),
                onSubmitted: (q) {
                  _controller.addToHistory(q);
                  _controller.searchImmediate(q);
                },
                hintText: 'Search products, categories…',
                leading: const Icon(Icons.search),
              ),
            ),

            // Category filter chips
            if (_showFilters)
              _CategoryChips(
                categories: _allCategories.toList()..sort(),
                selected: _activeCategory,
                onSelected: (cat) {
                  setState(() {
                    _activeCategory = cat == _activeCategory ? null : cat;
                  });
                  if (_controller.query.isNotEmpty) {
                    _controller.searchImmediate(_controller.query);
                  }
                },
              ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Results'),
                Tab(text: 'Suggestions'),
                Tab(text: 'Trending'),
              ],
            ),

            // Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Results
                  _ResultsTab(controller: _controller),
                  // Tab 2: Suggestions
                  _SuggestionsTab(controller: _controller),
                  // Tab 3: Trending
                  _TrendingTab(
                    onTap: (q) {
                      _tabController.animateTo(0);
                      _controller.search(q);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chips
// ---------------------------------------------------------------------------

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return FilterChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelected(cat),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Results
// ---------------------------------------------------------------------------

class _ResultsTab extends StatelessWidget {
  const _ResultsTab({required this.controller});

  final SearchPlusController<Product> controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SearchTheme(
      data: SearchThemeData(
        resultTheme: SearchResultThemeData(
          highlightColor: colorScheme.primary.withAlpha(40),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      child: SearchResultsWidget<Product>(
        state: controller.state,
        animationConfig: const SearchAnimationConfig(
          preset: SearchAnimationPreset.staggered,
          staggerDelay: Duration(milliseconds: 50),
          duration: Duration(milliseconds: 300),
        ),
        showShimmer: true,
        emptyState: const SearchEmptyState(
          icon: Icon(Icons.inventory_2_outlined, size: 64),
          title: 'No products found',
          subtitle: 'Adjust your search or remove filters.',
        ),
        errorState: SearchErrorState(
          icon: const Icon(Icons.wifi_off_rounded, size: 64),
          message: 'Network error — tap retry.',
          onRetry: () => controller.searchImmediate(controller.query),
        ),
        itemBuilder: (context, result, index) {
          final rating =
              (result.metadata['rating'] as num?)?.toDouble() ?? 0.0;
          return _ProductCard(
            result: result,
            rating: rating,
            query: controller.query,
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.result,
    required this.rating,
    required this.query,
  });

  final SearchResult<Product> result;
  final double rating;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightText(
                    text: result.title,
                    query: query,
                    highlightStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.subtitle ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Suggestions
// ---------------------------------------------------------------------------

class _SuggestionsTab extends StatelessWidget {
  const _SuggestionsTab({required this.controller});

  final SearchPlusController<Product> controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final suggestions = controller.state.suggestions;
        if (suggestions.isEmpty) {
          return const Center(
            child: Text('Type to see suggestions…'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, i) {
            return ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(suggestions[i]),
              onTap: () => controller.search(suggestions[i]),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Trending
// ---------------------------------------------------------------------------

class _TrendingTab extends StatelessWidget {
  const _TrendingTab({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trendingSearches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            trendingSearches[i],
            style: theme.textTheme.titleSmall,
          ),
          trailing: Icon(
            Icons.trending_up,
            color: theme.colorScheme.primary,
          ),
          onTap: () => onTap(trendingSearches[i]),
        );
      },
    );
  }
}
