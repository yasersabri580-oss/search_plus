# search_plus

> 🚀 **Production-grade Flutter search for local, async, and hybrid data sources** — with polished UI widgets, theming, localization, and animation-first UX.

`search_plus` helps you ship fast, high-quality search experiences across mobile, web, and desktop using a clean adapter architecture and ready-to-use Material 3 components.

---

## ✨ Features

- ⚡ **Async API search** with debouncing, cancellation-safe state updates, and pagination parameters
- 💾 **Local search** with ranked matching (exact, prefix, contains, fuzzy)
- 🔀 **Hybrid search** that merges local + remote results with weighting and deduplication
- 🧩 **Composable architecture** via `SearchAdapter<T>` for full extensibility
- 🖼️ **Built-in UI system** (`SearchScaffold`, `SearchPlusBar`, `SearchResultsWidget`)
- 🎞️ **Animation presets** (fade, slide, scale, staggered) + shimmer loading
- 🎨 **Theme system** with Material 3-friendly defaults and deep customization
- 🌍 **Localization-ready** text via `SearchLocalizations`
- 🧠 **Suggestions + search history** support in controller and adapters
- ♿ **Accessibility-friendly controls** with semantic labels and tooltips

---

## 🎥 Preview

> Replace these placeholders with your own GIFs/screenshots before release.

- Local search demo: `https://your-cdn.example/search-plus-local.gif`
- Async API search demo: `https://your-cdn.example/search-plus-api.gif`
- Hybrid search + theming demo: `https://your-cdn.example/search-plus-hybrid-theme.gif`

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  search_plus: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## ⚡ Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

final products = ['iPhone', 'Pixel', 'Galaxy', 'Xperia'];

class QuickStartPage extends StatefulWidget {
  const QuickStartPage({super.key});

  @override
  State<QuickStartPage> createState() => _QuickStartPageState();
}

class _QuickStartPageState extends State<QuickStartPage> {
  late final SearchPlusController<String> controller;

  @override
  void initState() {
    super.initState();
    controller = SearchPlusController<String>(
      adapter: LocalSearchAdapter<String>(
        items: products,
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult(id: item, title: item, data: item),
        enableFuzzySearch: true,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchScaffold<String>(
      controller: controller,
      hintText: 'Search products...',
    );
  }
}
```

---

## 🧠 Advanced Usage

### 1) Async API search

```dart
final remoteAdapter = RemoteSearchAdapter<Product>(
  searchFunction: (query, limit, offset) async {
    final response = await api.searchProducts(
      query,
      limit: limit,
      offset: offset,
    );

    return response.items
        .map(
          (item) => SearchResult<Product>(
            id: item.id,
            title: item.name,
            subtitle: item.description,
            data: item,
          ),
        )
        .toList();
  },
  suggestFunction: (query) => api.suggestProducts(query),
);

final controller = SearchPlusController<Product>(
  adapter: remoteAdapter,
  debounceDuration: const Duration(milliseconds: 450),
);
```

### 2) Local search

```dart
final localAdapter = LocalSearchAdapter<Article>(
  items: articles,
  searchableFields: (a) => [a.title, a.body, a.tags.join(' ')],
  toResult: (a) => SearchResult(
    id: a.id,
    title: a.title,
    subtitle: a.excerpt,
    data: a,
  ),
  enableFuzzySearch: true,
  rankingConfig: const SearchRankingConfig(
    boostExactMatch: 1.2,
    boostPrefixMatch: 1.1,
    fuzzyThreshold: 0.35,
  ),
);
```

### 3) Hybrid search

```dart
final hybridAdapter = HybridSearchAdapter<Item>(
  localAdapter: localAdapter,
  remoteAdapter: remoteAdapter,
  localWeight: 1.2,
  remoteWeight: 1.0,
  deduplicateById: true,
);

final controller = SearchPlusController<Item>(adapter: hybridAdapter);
```

---

## 🎨 Theming Guide

Use `SearchTheme` with `SearchThemeData` to customize search visuals globally in a subtree:

```dart
SearchTheme(
  data: SearchThemeData(
    searchBarTheme: SearchBarThemeData(
      borderRadius: BorderRadius.circular(18),
      focusedBorderColor: Colors.deepPurple,
    ),
    resultTheme: SearchResultThemeData(
      highlightColor: Colors.deepPurple.shade100,
    ),
  ),
  child: SearchScaffold<String>(controller: controller),
)
```

You can customize:

- Search bar shape, elevation, border, icon/text styles
- Result typography, spacing, highlight style/color, and section headers
- Animation duration/curve defaults at the theme level

---

## 🌍 Localization Guide

Override package strings with `SearchLocalizationsProvider`:

```dart
SearchLocalizationsProvider(
  localizations: const SearchLocalizations(
    hintText: 'Buscar...',
    emptyResultsText: 'Sin resultados',
    retryText: 'Reintentar',
  ),
  child: SearchScaffold<String>(controller: controller),
)
```

You can localize search hints, empty/error labels, retry/clear actions, and results count text.

---

## 🎞 Animation Customization

Use built-in presets with `SearchAnimationConfig`:

```dart
SearchScaffold<String>(
  controller: controller,
  animationConfig: const SearchAnimationConfig(
    preset: SearchAnimationPreset.staggered,
    duration: Duration(milliseconds: 280),
    staggerDelay: Duration(milliseconds: 40),
  ),
)
```

Available presets:

- `none`
- `fade`
- `slideUp`
- `slideRight`
- `scale`
- `fadeSlideUp`
- `staggered`

---

## 🧩 Extensibility

Implement `SearchAdapter<T>` to integrate any data source or ranking strategy:

- SQL / Isar / Hive local stores
- REST / GraphQL / gRPC APIs
- Enterprise search backends (Elastic/OpenSearch/Algolia-like wrappers)
- Domain-specific relevance or permission-aware filtering

This keeps UI and search logic decoupled and reusable.

---

## 📊 Performance Notes

- Prefer local adapter for low-latency offline search paths.
- Use debouncing for remote APIs to reduce unnecessary network calls.
- Keep `maxResults` realistic for your UI layout and device class.
- Consider caching remote results for hybrid experiences.
- Use sectioned or paged strategies for very large datasets.

---

## Example App

See `/example` for a full showcase including:

- local search
- async remote search
- hybrid search
- theme switching
- localization overrides
- animation presets
- search history and suggestions

---

## License

MIT — see [`LICENSE`](LICENSE).
