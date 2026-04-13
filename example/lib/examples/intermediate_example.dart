import 'package:flutter/material.dart' hide SearchBarThemeData;
import 'package:search_plus/search_plus.dart';

import '../api/fake_search_api.dart';

/// Intermediate example: custom item builder, theming, and animations.
class IntermediateExample extends StatefulWidget {
  const IntermediateExample({super.key});

  @override
  State<IntermediateExample> createState() => _IntermediateExampleState();
}

class _IntermediateExampleState extends State<IntermediateExample> {
  late final SearchPlusController<Product> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<Product>(
      adapter: LocalSearchAdapter<Product>(
        items: sampleProducts,
        searchableFields: (p) => [p.name, p.category],
        toResult: (p) => SearchResult<Product>(
          id: p.id,
          title: p.name,
          subtitle: '${p.category} · \$${p.price.toStringAsFixed(2)}',
          data: p,
          metadata: {'rating': p.rating},
        ),
        enableFuzzySearch: true,
        rankingConfig: const SearchRankingConfig(
          boostExactMatch: 2.0,
          boostPrefixMatch: 1.5,
        ),
      ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Intermediate Example')),
      body: SearchTheme(
        data: SearchPlusThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(16),
            focusedBorderColor: colorScheme.primary,
            elevation: 0,
            focusedElevation: 2,
          ),
          resultTheme: SearchResultThemeData(
            highlightColor: colorScheme.primaryContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        child: SizedBox(
          height: 300,
          child: SearchScaffold<Product>(
            showClearButton: true,

            footerBuilder: (context, state) {
              if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading more...'),
                    ],
                  ),
                );
              } else if (state.hasMoreResults) {
                return TextButton(
                  onPressed: () => _controller.loadMore(),
                  child: const Text('Load More'),
                );
              }
              return const SizedBox.shrink();
            },
            emptyBuilder: (context, query) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results for "$query"',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
            headerBuilder: (context, state) {
              if (state.isIdle) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Welcome! Start typing to search products.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              } else if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Searching...'),
                    ],
                  ),
                );
              } else if (state.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${state.error}',
                    style: TextStyle(color: colorScheme.error),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            controller: _controller,
            hintText: 'Search products…',
            animationConfig: const SearchAnimationConfig(
              preset: SearchAnimationPreset.staggered,
              staggerDelay: Duration(milliseconds: 40),
            ),
            density: SearchResultDensity.rich,
            itemBuilder: (context, result, index) {
              final product = result.data;
              final rating =
                  (result.metadata['rating'] as num?)?.toDouble() ?? 0.0;
              final hasDiscount = (product?.price ?? 0) > 20; // example logic
              final discountedPrice = hasDiscount
                  ? (product?.price ?? 0) * 0.85
                  : null;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text('Tapped: ${result.title}')),
                        );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Product Image / Placeholder ---
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 70,
                              height: 70,
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // --- Product Details ---
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title with highlight
                                HighlightText(
                                  text: result.title,
                                  query: _controller.query,
                                  highlightStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Category as chip
                                Chip(
                                  label: Text(
                                    product?.category ?? '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withOpacity(0.7),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(
                                    horizontal: -4,
                                    vertical: -4,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Price row with discount
                                Row(
                                  children: [
                                    if (hasDiscount) ...[
                                      Text(
                                        '\$${product?.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '\$${discountedPrice!.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          '-15%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        '\$${product?.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // --- Rating & Favorite Icon ---
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber.shade600,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.favorite_border,
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Add to wishlist logic
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to wishlist'),
                                    ),
                                  );
                                },
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
