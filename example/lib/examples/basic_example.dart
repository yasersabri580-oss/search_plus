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
  String _getFruitIcon(String fruit) {
    switch (fruit.toLowerCase()) {
      case 'apple':
        return '🍎';
      case 'banana':
        return '🍌';
      case 'cherry':
        return '🍒';
      case 'date':
        return '🌴';
      case 'elderberry':
        return '🫐';
      case 'fig':
        return '🟣';
      case 'grape':
        return '🍇';
      case 'honeydew':
        return '🍈';
      case 'kiwi':
        return '🥝';
      case 'lemon':
        return '🍋';
      case 'mango':
        return '🥭';
      case 'nectarine':
        return '🍑';
      case 'orange':
        return '🍊';
      case 'papaya':
        return '🧡';
      case 'raspberry':
        return '🍓';
      case 'strawberry':
        return '🍓';
      case 'tangerine':
        return '🍊';
      case 'watermelon':
        return '🍉';
      default:
        return '🍏';
    }
  }

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
        toResult: (item) =>
            SearchResult<String>(id: item, title: item, data: item),
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
      body: SearchDebugPanel<String>(
        controller: _controller,
        child: SearchScaffold<String>(
          controller: _controller,
          itemBuilder: (context, result, index) {
            final fruit = result.title;
            // Pick a consistent icon or emoji for each fruit
            final icon = _getFruitIcon(fruit);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(
                  fruit,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Fresh and delicious',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => {}, // Triggers onItemTap
              ),
            );
          },
          hintText: 'Search fruits\u2026',
          onItemTap: (result) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('Selected: ${result.title}')),
              );
          },
        ),
      ),
    );
  }
}
