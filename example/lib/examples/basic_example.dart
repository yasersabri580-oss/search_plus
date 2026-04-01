import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

/// A minimal example showing the simplest possible search_plus integration.
///
/// Uses [LocalSearchAdapter] with a flat string list and zero custom UI.
class BasicExample extends StatefulWidget {
  const BasicExample({super.key});

  @override
  State<BasicExample> createState() => _BasicExampleState();
}

class _BasicExampleState extends State<BasicExample> {
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

  late final SearchPlusController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<String>(
      adapter: LocalSearchAdapter<String>(
        items: _fruits,
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult<String>(
          id: item,
          title: item,
          data: item,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Example')),
      body: SearchScaffold<String>(
        controller: _controller,
        hintText: 'Search fruits…',
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
