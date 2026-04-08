import 'package:flutter/material.dart' hide SearchBarThemeData;
import 'package:search_plus/search_plus.dart';

import '../api/fake_search_api.dart';

/// Overlay example: search results appear in a floating dropdown
/// beneath the search bar, dismissible on outside tap.
class OverlayExample extends StatefulWidget {
  const OverlayExample({super.key});

  @override
  State<OverlayExample> createState() => _OverlayExampleState();
}

class _OverlayExampleState extends State<OverlayExample> {
  late final SearchPlusController<Product> _controller;
  final _api = FakeSearchApi(
    minDelay: const Duration(milliseconds: 200),
    maxDelay: const Duration(milliseconds: 600),
  );

  SearchResult<Product>? _selectedResult;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<Product>(
      adapter: RemoteSearchAdapter<Product>(
        searchFunction: (q, limit, offset) =>
            _api.searchProducts(q, limit: limit, offset: offset),
        suggestFunction: _api.suggestProducts,
      ),
      debounceDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Overlay Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search with Overlay Dropdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Results appear in a floating panel. Tap outside or press Escape to dismiss.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // The overlay search widget
            SearchTheme(
              data: SearchPlusThemeData(
                searchBarTheme: SearchBarThemeData(
                  borderRadius: BorderRadius.circular(16),
                  focusedBorderColor: colorScheme.primary,
                  elevation: 0,
                  focusedElevation: 2,
                ),
              ),
              child: SearchPlusOverlay<Product>(
                controller: _controller,
                hintText: 'Search products…',
                maxOverlayHeight: 350,
                animationConfig: const SearchAnimationConfig(
                  preset: SearchAnimationPreset.fadeSlideUp,
                  duration: Duration(milliseconds: 250),
                ),
                onItemTap: (result) {
                  setState(() => _selectedResult = result);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('Selected: ${result.title}')),
                    );
                },
                itemBuilder: (context, result, index) {
                  final rating =
                      (result.metadata['rating'] as num?)?.toDouble() ?? 0;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedResult = result);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 20,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HighlightText(
                                  text: result.title,
                                  query: _controller.query,
                                  style: theme.textTheme.bodyMedium,
                                  highlightStyle:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  result.subtitle ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 14, color: Colors.amber.shade700),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Selected result detail
            if (_selectedResult != null)
              _SelectedProductCard(result: _selectedResult!)
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Search and select a product',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedProductCard extends StatelessWidget {
  const _SelectedProductCard({required this.result});

  final SearchResult<Product> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = result.data;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        result.subtitle ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (product != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: product.category,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.star_rounded,
                    label: product.rating.toStringAsFixed(1),
                  ),
                  const Spacer(),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
