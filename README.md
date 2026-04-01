# 🔍 Search Plus

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-blue" alt="Platform" />
</p>

**Production-grade Flutter search — local, remote, and hybrid — with polished UI, theming, animations, and a developer experience you'll love.**

Ship fast, beautiful search experiences across mobile, web, and desktop using a clean adapter architecture and ready-to-use Material 3 components.

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| ⚡ **Async API Search** | Debounced, cancellation-safe, paginated remote search |
| 💾 **Local Search** | Ranked matching — exact, prefix, contains, and fuzzy (Levenshtein) |
| 🔀 **Hybrid Search** | Merge local + remote results with weighting and deduplication |
| 🧩 **Adapter Architecture** | Plug in any data source via `SearchAdapter<T>` |
| 🖼️ **Built-in UI System** | `SearchScaffold`, `SearchPlusBar`, `SearchResultsWidget` |
| 🎞️ **7 Animation Presets** | Fade, slide, scale, staggered — plus shimmer loading |
| 🎨 **Deep Theming** | 30+ customizable properties with Material 3 defaults |
| 🌍 **Localization Ready** | 13 customizable strings via `SearchLocalizations` |
| 🧠 **Suggestions + History** | Built-in support in controller and adapters |
| ♿ **Accessible** | Semantic labels, tooltips, keyboard-friendly |
| 📱 **Responsive** | Adaptive layouts for phone, tablet, and desktop |

---

## 🎥 Preview

> Replace the placeholders below with your own GIFs/screenshots.

| Local Search | Remote API Search | Hybrid + Theme |
|:---:|:---:|:---:|
| ![Local](https://via.placeholder.com/280x500/6A4CFF/fff?text=Local+Search) | ![Remote](https://via.placeholder.com/280x500/6A4CFF/fff?text=Remote+Search) | ![Hybrid](https://via.placeholder.com/280x500/6A4CFF/fff?text=Hybrid+Theme) |

| Interactive Demo | Full Showcase | Dark Mode |
|:---:|:---:|:---:|
| ![Demo](https://via.placeholder.com/280x500/6A4CFF/fff?text=Demo+Screen) | ![Showcase](https://via.placeholder.com/280x500/6A4CFF/fff?text=Showcase) | ![Dark](https://via.placeholder.com/280x500/6A4CFF/fff?text=Dark+Mode) |

---

## 📦 Installation

Add `search_plus` to your `pubspec.yaml`:

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

Get a working search in under 30 seconds:

```dart
import 'package:flutter/material.dart';
import 'package:search_plus/search_plus.dart';

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
        items: ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'],
        searchableFields: (item) => [item],
        toResult: (item) => SearchResult(id: item, title: item, data: item),
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
    return Scaffold(
      body: SearchScaffold<String>(
        controller: controller,
        hintText: 'Search fruits...',
      ),
    );
  }
}
```

That's it — debouncing, state management, empty/loading/error states, and animations are handled automatically.

---

## 🧩 Examples

The `/example` app ships with **six runnable examples**, from minimal to full showcase. Run them with:

```bash
cd example
flutter run
```

### 1. Basic Example

Minimal local search with a flat string list and zero custom UI.

```dart
SearchPlusController<String>(
  adapter: LocalSearchAdapter<String>(
    items: fruits,
    searchableFields: (item) => [item],
    toResult: (item) => SearchResult(id: item, title: item, data: item),
  ),
);
```

### 2. Intermediate Example

Custom item builder, theming, fuzzy search, and stagger animations.

```dart
SearchTheme(
  data: SearchThemeData(
    searchBarTheme: SearchBarThemeData(
      borderRadius: BorderRadius.circular(16),
      focusedBorderColor: colorScheme.primary,
    ),
    resultTheme: SearchResultThemeData(
      highlightColor: colorScheme.primaryContainer,
    ),
  ),
  child: SearchScaffold<Product>(
    controller: controller,
    animationConfig: const SearchAnimationConfig(
      preset: SearchAnimationPreset.staggered,
    ),
    density: SearchResultDensity.rich,
    itemBuilder: (context, result, index) => MyProductTile(result),
  ),
)
```

### 3. Advanced Example

Remote API search with suggestions, search history, trending items, and a toggleable list/grid layout.

```dart
SearchPlusController<AppUser>(
  adapter: RemoteSearchAdapter<AppUser>(
    searchFunction: api.searchUsers,
    suggestFunction: api.suggestUsers,
  ),
  debounceDuration: const Duration(milliseconds: 400),
  maxHistoryItems: 8,
);
```

### 4. Full Showcase

A complete screen with **tabs** (Results / Suggestions / Trending), **category filter chips**, custom product cards, and all states (loading, empty, error, results).

### 5. Original Example

The comprehensive demo: local + remote + hybrid modes, theme switching, localization overrides, animation presets, and density settings.

### 6. 🧪 Interactive Demo (`searchplus_demo.dart`)

A dedicated test/demo screen with a **control panel drawer** for:

- **Dataset**: Products / Users / Articles
- **Style**: Minimal / Modern SaaS / Dark / Social / Glassmorphism
- **Animation**: All 7 presets
- **Layout**: List / Grid
- **Density**: Compact / Comfortable / Rich
- **Forced State**: Auto / Loading / Empty / Error
- **API Delay**: 100 ms → 3000 ms slider

Perfect for recording demo videos.

---

## 🧠 Core Concepts

### Adapter Architecture

```
┌──────────────────┐
│  SearchAdapter<T> │  ← Abstract base
└────────┬─────────┘
         │
    ┌────┴────────────────────┬──────────────────────┐
    │                         │                      │
┌───┴──────────┐  ┌──────────┴─────────┐  ┌────────┴───────────┐
│ LocalSearch  │  │  RemoteSearch      │  │   HybridSearch     │
│ Adapter<T>   │  │  Adapter<T>        │  │   Adapter<T>       │
│              │  │                    │  │                    │
│ In-memory    │  │ Future-based       │  │ Merges local +     │
│ with ranking │  │ async delegation   │  │ remote with dedup  │
└──────────────┘  └────────────────────┘  └────────────────────┘
```

**Local adapter** ranks results using a scoring strategy:

- **Exact match** → 1.0 × `boostExactMatch`
- **Prefix match** → 0.9 × `boostPrefixMatch`
- **Word-start match** → 0.8
- **Contains match** → 0.6
- **Fuzzy match** → similarity × 0.4

**Remote adapter** wraps any `Future`-based search function.

**Hybrid adapter** runs both in parallel, merges results, and deduplicates by ID.

### State Machine

```
idle  ──search()──▸  loading  ──results──▸  success
                       │                       │
                       └──no results──▸ empty   │
                       │                       │
                       └──error──▸ error ◂─────┘
```

Every state transition is smooth — the UI handles each automatically with customizable widgets.

---

## 🎨 Theming Guide

Wrap any search widget in `SearchTheme` to customize visuals:

```dart
SearchTheme(
  data: SearchThemeData(
    searchBarTheme: SearchBarThemeData(
      borderRadius: BorderRadius.circular(18),
      focusedBorderColor: Colors.deepPurple,
      elevation: 0,
      focusedElevation: 4,
    ),
    resultTheme: SearchResultThemeData(
      highlightColor: Colors.deepPurple.shade100,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
  child: SearchScaffold<String>(controller: controller),
)
```

### Available Theme Properties

**Search Bar** (`SearchBarThemeData`):
`backgroundColor`, `focusedBackgroundColor`, `borderRadius`, `elevation`, `focusedElevation`, `padding`, `height`, `textStyle`, `hintStyle`, `iconColor`, `cursorColor`, `borderColor`, `focusedBorderColor`, `borderWidth`, `shadowColor`

**Results** (`SearchResultThemeData`):
`backgroundColor`, `selectedColor`, `hoveredColor`, `titleStyle`, `subtitleStyle`, `highlightColor`, `highlightStyle`, `dividerColor`, `iconColor`, `sectionHeaderStyle`, `sectionHeaderBackgroundColor`, `contentPadding`, `itemSpacing`, `imageSize`, `imageBorderRadius`

---

## 🎞️ Animations

Seven built-in animation presets:

| Preset | Effect |
|--------|--------|
| `none` | No animation |
| `fade` | Fade in |
| `slideUp` | Slide up from bottom |
| `slideRight` | Slide in from left |
| `scale` | Scale from small to full |
| `fadeSlideUp` | Combined fade + slide up |
| `staggered` | Each item animates with a delay |

```dart
SearchScaffold<String>(
  controller: controller,
  animationConfig: const SearchAnimationConfig(
    preset: SearchAnimationPreset.staggered,
    duration: Duration(milliseconds: 280),
    staggerDelay: Duration(milliseconds: 40),
    curve: Curves.easeOutCubic,
  ),
)
```

Shimmer loading is enabled by default — disable it with `showShimmer: false`.

---

## 🌍 Localization

Override any string with `SearchLocalizationsProvider`:

```dart
SearchLocalizationsProvider(
  localizations: const SearchLocalizations(
    hintText: 'Buscar...',
    emptyResultsText: 'Sin resultados',
    errorText: 'Algo salió mal',
    retryText: 'Reintentar',
    loadingText: 'Buscando...',
    resultsCountText: '{count} resultados',
  ),
  child: SearchScaffold<String>(controller: controller),
)
```

All 13 strings are customizable: `hintText`, `emptyResultsText`, `emptyResultsSubtext`, `errorText`, `retryText`, `clearText`, `cancelText`, `searchHistoryTitle`, `suggestionsTitle`, `loadingText`, `resultsCountText`, `voiceSearchTooltip`, `clearSearchTooltip`.

---

## 📱 Responsive Behavior

Search Plus adapts to any screen size:

- **Mobile** (< 600dp): Full-width search bar, list layout, comfortable density
- **Tablet** (600–900dp): Wider content area, optional grid layout
- **Desktop** (> 900dp): Constrained max-width, grid layouts shine

Switch layouts dynamically:

```dart
SearchScaffold<Product>(
  controller: controller,
  layout: isWide ? SearchResultsLayout.grid : SearchResultsLayout.list,
  gridCrossAxisCount: isWide ? 3 : 2,
  density: isCompact ? SearchResultDensity.compact : SearchResultDensity.comfortable,
)
```

---

## 🔍 Search System Explained

### Debouncing

Every keystroke is debounced (default: 300 ms). Only the **latest** query's results are shown — stale responses from earlier keystrokes are automatically discarded.

```dart
SearchPlusController<T>(
  adapter: adapter,
  debounceDuration: const Duration(milliseconds: 450),
  minQueryLength: 2,
  maxResults: 30,
);
```

### Suggestions

Both `LocalSearchAdapter` and `RemoteSearchAdapter` support suggestions:

```dart
// Local: prefix-based suggestions come built-in
// Remote: provide your own
RemoteSearchAdapter<T>(
  searchFunction: api.search,
  suggestFunction: (query) => api.suggest(query),
);
```

### Search History

The controller automatically tracks search history:

```dart
controller.addToHistory('flutter');
controller.state.history; // ['flutter']
controller.clearHistory();
```

---

## 🎯 Use Cases

### E-Commerce Product Search

```dart
LocalSearchAdapter<Product>(
  items: products,
  searchableFields: (p) => [p.name, p.brand, p.category, p.sku],
  toResult: (p) => SearchResult(
    id: p.id, title: p.name,
    subtitle: '\$${p.price}',
    imageUrl: p.imageUrl, data: p,
  ),
  enableFuzzySearch: true,
)
```

### Social App People Search

```dart
RemoteSearchAdapter<User>(
  searchFunction: (query, limit, offset) => api.searchUsers(query),
  suggestFunction: (query) => api.suggestUsers(query),
)
```

### Knowledge Base / Help Center

```dart
HybridSearchAdapter<Article>(
  localAdapter: localArticles,     // Cached articles
  remoteAdapter: remoteArticles,   // API for latest
  localWeight: 1.2,                // Prefer local (faster)
  remoteWeight: 1.0,
  deduplicateById: true,
)
```

### Settings / Preference Search

```dart
LocalSearchAdapter<Setting>(
  items: allSettings,
  searchableFields: (s) => [s.title, s.description, s.keywords.join(' ')],
  toResult: (s) => SearchResult(id: s.key, title: s.title, subtitle: s.description),
)
```

---

## 🧩 Extensibility

Implement `SearchAdapter<T>` to integrate any data source:

```dart
class AlgoliaSearchAdapter extends SearchAdapter<Product> {
  @override
  Future<List<SearchResult<Product>>> search(
    String query, {int limit = 50, int offset = 0}
  ) async {
    final response = await algolia.search(query, hitsPerPage: limit, page: offset ~/ limit);
    return response.hits.map((hit) => SearchResult<Product>(
      id: hit.objectID,
      title: hit['name'],
      subtitle: hit['description'],
      score: hit.score,
      data: Product.fromAlgolia(hit),
    )).toList();
  }
}
```

Works with: **REST**, **GraphQL**, **gRPC**, **Hive**, **Isar**, **SQLite**, **Elasticsearch**, **Algolia**, and more.

---

## 🎬 Demo Video Scenarios

Use the **Interactive Demo** screen to record these scenarios:

| # | Scenario | Settings |
|---|----------|----------|
| 1 | **Basic search** | Products, SaaS style, fadeSlideUp, List |
| 2 | **Loading state** | Force: Loading, 2000 ms delay |
| 3 | **Empty state** | Search "xyz", observe empty UI |
| 4 | **Error & retry** | Force: Error, then tap retry |
| 5 | **Grid layout** | Products, Grid, Rich density |
| 6 | **Dark mode** | Dark style, staggered animation |
| 7 | **Glassmorphism** | Glass style, scale animation |
| 8 | **Social app feel** | Users dataset, Social style |
| 9 | **Fast local** | 100 ms delay, minimal style |
| 10 | **Slow network** | 3000 ms delay, shimmer visible |

---

## 📊 Performance Notes

- Use **local adapter** for low-latency offline search
- **Debouncing** reduces unnecessary network calls for remote APIs
- Keep `maxResults` realistic for your UI layout and device class
- Consider **caching** remote results for hybrid experiences
- Use **sectioned** or paged strategies for very large datasets
- Fuzzy search adds overhead — enable only when needed

---

## 🧠 Developer Notes

### Clean Code Philosophy

- **Separation of concerns**: UI, state, and data are fully decoupled
- **Immutable state**: `SearchState` and `SearchResult` are immutable
- **Generic types**: Full type safety with `SearchAdapter<T>`, `SearchResult<T>`
- **No external dependencies**: Zero runtime dependencies beyond Flutter SDK
- **Tree-shakeable**: Import only what you use

### Architecture Overview

```
lib/
├── search_plus.dart              # Public API barrel file
└── src/
    ├── adapters/                 # Data source abstractions
    │   ├── search_adapter.dart   # Base interface + ranking config
    │   ├── local_search_adapter.dart
    │   ├── remote_search_adapter.dart
    │   └── hybrid_search_adapter.dart
    ├── animations/               # Animation system
    │   └── animation_presets.dart
    ├── core/                     # Business logic
    │   ├── search_controller.dart
    │   ├── search_result.dart
    │   └── search_state.dart
    ├── l10n/                     # Localization
    │   └── search_localizations.dart
    ├── theme/                    # Theming
    │   └── search_theme.dart
    └── ui/                       # Widgets
        ├── search_scaffold.dart
        ├── search_bar_widget.dart
        ├── search_results_widget.dart
        └── states/
            └── search_states.dart
```

---

## 📤 API Reference

### Core Classes

| Class | Purpose |
|-------|---------|
| `SearchPlusController<T>` | Main controller — manages search, debouncing, history |
| `SearchResult<T>` | Immutable result model with score, metadata, source |
| `SearchState<T>` | Immutable state: query, results, status, suggestions, history |
| `SearchStatus` | Enum: `idle`, `loading`, `success`, `empty`, `error` |

### Adapters

| Adapter | Purpose |
|---------|---------|
| `SearchAdapter<T>` | Abstract base — implement for custom sources |
| `LocalSearchAdapter<T>` | In-memory with ranked matching |
| `RemoteSearchAdapter<T>` | Wraps any async search function |
| `HybridSearchAdapter<T>` | Merges local + remote with deduplication |
| `SearchRankingConfig` | Tuning: weights, fuzzy threshold, boost factors |

### UI Widgets

| Widget | Purpose |
|--------|---------|
| `SearchScaffold<T>` | Complete search UI (bar + results + states) |
| `SearchPlusBar` | Standalone Material 3 search input |
| `SearchResultsWidget<T>` | Results display (list / grid / sectioned) |
| `SearchEmptyState` | No-results UI |
| `SearchErrorState` | Error UI with retry |
| `SearchLoadingState` | Loading UI with shimmer |
| `HighlightText` | Highlights matching query in text |
| `AnimatedSearchItem` | Wraps items with animation |
| `ShimmerLoading` | Skeleton loading effect |

### Theming & Localization

| Class | Purpose |
|-------|---------|
| `SearchTheme` | InheritedWidget for theme propagation |
| `SearchThemeData` | Theme configuration container |
| `SearchBarThemeData` | Search bar visual properties |
| `SearchResultThemeData` | Result item visual properties |
| `SearchLocalizationsProvider` | InheritedWidget for l10n propagation |
| `SearchLocalizations` | All customizable strings |

---

## License

MIT — see [`LICENSE`](LICENSE).

---

_Made with ❤️ for the Flutter community_
