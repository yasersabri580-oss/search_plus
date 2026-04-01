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
        data: SearchThemeData(
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
        child: SearchScaffold<Product>(
          controller: _controller,
          hintText: 'Search products…',
          animationConfig: const SearchAnimationConfig(
            preset: SearchAnimationPreset.staggered,
            staggerDelay: Duration(milliseconds: 40),
          ),
          density: SearchResultDensity.rich,
          itemBuilder: (context, result, index) {
            final rating = (result.metadata['rating'] as num?)?.toDouble() ?? 0;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: HighlightText(
                text: result.title,
                query: _controller.query,
                highlightStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              subtitle: Text(result.subtitle ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('Tapped: ${result.title}')),
                  );
              },
            );
          },
        ),
      ),
    );
  }
}
