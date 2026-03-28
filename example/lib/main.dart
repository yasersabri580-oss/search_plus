import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

void main() {
  runApp(const SearchPlusExampleApp());
}

class SearchPlusExampleApp extends StatelessWidget {
  const SearchPlusExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SearchPlus Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SearchPlus Examples')),
      body: ListView(
        children: [
          _DemoTile(
            title: 'Basic Local Search',
            subtitle: 'Search through a list of countries',
            icon: Icons.list_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasicSearchDemo()),
            ),
          ),
          _DemoTile(
            title: 'API Search (Simulated)',
            subtitle: 'Async remote search with debounce',
            icon: Icons.cloud_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApiSearchDemo()),
            ),
          ),
          _DemoTile(
            title: 'Rich Result Items',
            subtitle: 'Image + subtitle + actions layout',
            icon: Icons.view_agenda_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RichSearchDemo()),
            ),
          ),
          _DemoTile(
            title: 'Custom Theme',
            subtitle: 'Fully themed search experience',
            icon: Icons.palette_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemedSearchDemo()),
            ),
          ),
          _DemoTile(
            title: 'Grid Layout',
            subtitle: 'Search results in a grid',
            icon: Icons.grid_view_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GridSearchDemo()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// --- Demo 1: Basic Local Search ---

const _countries = [
  'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
  'Austria', 'Bangladesh', 'Belgium', 'Brazil', 'Canada',
  'Chile', 'China', 'Colombia', 'Croatia', 'Czech Republic',
  'Denmark', 'Egypt', 'Estonia', 'Ethiopia', 'Finland',
  'France', 'Germany', 'Greece', 'Hungary', 'Iceland',
  'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland',
  'Israel', 'Italy', 'Japan', 'Kenya', 'Latvia',
  'Lithuania', 'Malaysia', 'Mexico', 'Morocco', 'Netherlands',
  'New Zealand', 'Nigeria', 'Norway', 'Pakistan', 'Peru',
  'Philippines', 'Poland', 'Portugal', 'Romania', 'Russia',
  'Saudi Arabia', 'Singapore', 'South Africa', 'South Korea', 'Spain',
  'Sweden', 'Switzerland', 'Thailand', 'Turkey', 'Ukraine',
  'United Arab Emirates', 'United Kingdom', 'United States', 'Vietnam',
];

class BasicSearchDemo extends StatefulWidget {
  const BasicSearchDemo({super.key});

  @override
  State<BasicSearchDemo> createState() => _BasicSearchDemoState();
}

class _BasicSearchDemoState extends State<BasicSearchDemo> {
  late final SearchPlusController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<String>(
      adapter: LocalSearchAdapter<String>(
        items: _countries,
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult(id: item, title: item, data: item),
        enableFuzzySearch: true,
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
      appBar: AppBar(title: const Text('Basic Local Search')),
      body: SearchScaffold<String>(
        controller: _controller,
        hintText: 'Search countries...',
        autofocus: true,
        density: SearchResultDensity.compact,
        onItemTap: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected: ${result.title}')),
          );
        },
      ),
    );
  }
}

// --- Demo 2: API Search (Simulated) ---

class ApiSearchDemo extends StatefulWidget {
  const ApiSearchDemo({super.key});

  @override
  State<ApiSearchDemo> createState() => _ApiSearchDemoState();
}

class _ApiSearchDemoState extends State<ApiSearchDemo> {
  late final SearchPlusController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<String>(
      adapter: RemoteSearchAdapter<String>(
        searchFunction: (query, limit, offset) async {
          // Simulate API call with delay
          await Future.delayed(const Duration(milliseconds: 800));
          // Simulate results
          return _countries
              .where(
                  (c) => c.toLowerCase().contains(query.toLowerCase()))
              .take(limit)
              .map((c) => SearchResult<String>(
                    id: c,
                    title: c,
                    subtitle: 'Found via API search',
                    data: c,
                  ))
              .toList();
        },
      ),
      debounceDuration: const Duration(milliseconds: 500),
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
      appBar: AppBar(title: const Text('API Search')),
      body: SearchScaffold<String>(
        controller: _controller,
        hintText: 'Search via API...',
        autofocus: true,
        animationConfig: const SearchAnimationConfig(
          preset: SearchAnimationPreset.staggered,
        ),
      ),
    );
  }
}

// --- Demo 3: Rich Result Items ---

class _Product {
  const _Product(this.name, this.description, this.price);
  final String name;
  final String description;
  final double price;
}

const _products = [
  _Product('Wireless Headphones', 'Premium noise-cancelling audio', 199.99),
  _Product('Smart Watch', 'Fitness tracking and notifications', 299.99),
  _Product('Laptop Stand', 'Ergonomic aluminum stand', 49.99),
  _Product('Mechanical Keyboard', 'Cherry MX switches, RGB', 129.99),
  _Product('USB-C Hub', '7-in-1 multiport adapter', 39.99),
  _Product('Webcam HD', '1080p with auto-focus', 79.99),
  _Product('Mouse Pad XL', 'Extended desk mat', 24.99),
  _Product('Monitor Light', 'Screen bar LED light', 59.99),
  _Product('Cable Organizer', 'Desk cable management', 14.99),
  _Product('Phone Stand', 'Adjustable aluminum holder', 19.99),
];

class RichSearchDemo extends StatefulWidget {
  const RichSearchDemo({super.key});

  @override
  State<RichSearchDemo> createState() => _RichSearchDemoState();
}

class _RichSearchDemoState extends State<RichSearchDemo> {
  late final SearchPlusController<_Product> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<_Product>(
      adapter: LocalSearchAdapter<_Product>(
        items: _products,
        searchableFields: (p) => [p.name, p.description],
        toResult: (p) => SearchResult(
          id: p.name,
          title: p.name,
          subtitle: p.description,
          data: p,
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
      appBar: AppBar(title: const Text('Rich Results')),
      body: SearchScaffold<_Product>(
        controller: _controller,
        hintText: 'Search products...',
        autofocus: true,
        density: SearchResultDensity.rich,
        itemBuilder: (context, result, index) {
          final product = result.data!;
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: HighlightText(
              text: result.title,
              query: _controller.query,
            ),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${result.title} to cart')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- Demo 4: Custom Theme ---

class ThemedSearchDemo extends StatefulWidget {
  const ThemedSearchDemo({super.key});

  @override
  State<ThemedSearchDemo> createState() => _ThemedSearchDemoState();
}

class _ThemedSearchDemoState extends State<ThemedSearchDemo> {
  late final SearchPlusController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<String>(
      adapter: LocalSearchAdapter<String>(
        items: _countries,
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult(id: item, title: item, data: item),
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
      appBar: AppBar(title: const Text('Custom Theme')),
      body: SearchScaffold<String>(
        controller: _controller,
        hintText: 'Search with custom theme...',
        autofocus: true,
        theme: SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(16),
            backgroundColor: Colors.deepPurple.shade50,
            focusedBorderColor: Colors.deepPurple,
          ),
          resultTheme: SearchResultThemeData(
            highlightColor: Colors.deepPurple.shade100,
            highlightStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Demo 5: Grid Layout ---

class GridSearchDemo extends StatefulWidget {
  const GridSearchDemo({super.key});

  @override
  State<GridSearchDemo> createState() => _GridSearchDemoState();
}

class _GridSearchDemoState extends State<GridSearchDemo> {
  late final SearchPlusController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<String>(
      adapter: LocalSearchAdapter<String>(
        items: _countries,
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult(id: item, title: item, data: item),
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
      appBar: AppBar(title: const Text('Grid Layout')),
      body: SearchScaffold<String>(
        controller: _controller,
        hintText: 'Search countries...',
        autofocus: true,
        layout: SearchResultsLayout.grid,
        gridCrossAxisCount: 2,
        gridChildAspectRatio: 2.5,
        itemBuilder: (context, result, index) {
          return Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: HighlightText(
                  text: result.title,
                  query: _controller.query,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
