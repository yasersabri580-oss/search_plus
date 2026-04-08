import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

/// Demonstrates [SearchableListView] — the simplest way to combine a search
/// bar with a list of items. No manual controller or adapter setup required.
class SearchableListViewExample extends StatelessWidget {
  const SearchableListViewExample({super.key});

  static const _fruits = [
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Honeydew',
    'Kiwi',
    'Lemon',
    'Mango',
    'Nectarine',
    'Orange',
    'Papaya',
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Watermelon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SearchableListView Example')),
      body: SearchableListView<String>(
        items: _fruits,
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult<String>(
          id: item,
          title: item,
          data: item,
        ),
        hintText: 'Search fruits…',
        debounceDuration: Duration.zero,
        animationConfig: SearchAnimationConfig.none,
        onItemTap: (result) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('Selected: ${result.title}')),
            );
        },
      ),
    );
  }
}
