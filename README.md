# 🔍 Search Plus

![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-blue)

**Production-grade Flutter search — local, remote, and hybrid — with polished UI, overlay mode, theming, animations, persistent history, and a developer experience you'll love.**

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
| 🪟 **Overlay / Dropdown Mode** | `SearchOverlay` — floating results panel with auto-dismiss |
| 🎞️ **7 Animation Presets** | Fade, slide, scale, staggered — plus shimmer loading |
| 🎨 **Deep Theming** | 30+ customizable properties with Material 3 defaults |
| ⚙️ **SearchConfig** | Advanced behavior: debounce, trim, case, capitalization, limits |
| 💽 **Persistent History** | Pluggable storage (in-memory, secure, or custom) |
| 🌍 **Localization Ready** | 13 customizable strings via `SearchLocalizations` |
| 🧠 **Suggestions + History** | Built-in support in controller and adapters |
| ♿ **Accessible** | Semantic labels, tooltips, keyboard-friendly |
| 📱 **Responsive** | Adaptive layouts for phone, tablet, and desktop |

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

The `/example` app ships with **seven runnable examples**, from minimal to full showcase. Run them with:

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

The comprehensive demo: local + remote + hybrid modes, theme switching, localization overrides, animation presets, keyboard navigation, and density settings.

### 6. Overlay Example

Floating dropdown results that appear above page content. Demonstrates the `SearchOverlay` widget with auto-dismiss on outside tap and smooth animations.

```dart
SearchOverlay<Product>(
  controller: controller,
  hintText: 'Search products…',
  maxOverlayHeight: 350,
  animationConfig: const SearchAnimationConfig(
    preset: SearchAnimationPreset.fadeSlideUp,
  ),
  onItemTap: (result) => print('Selected: ${result.title}'),
)
```

### 7. 🧪 Interactive Demo (`searchplus_demo.dart`)

A dedicated test/demo screen with a **control panel drawer** for:

- **Dataset**: Products / Users / Articles
- **Style**: Minimal / Modern SaaS / Dark / Social / Glass / Dark Premium (6 styles)
- **Animation**: All 7 presets
- **Layout**: List / Grid
- **Density**: Compact / Comfortable / Rich
- **Forced State**: Auto / Loading / Empty / Error
- **Result Mode**: Inline / Overlay dropdown toggle
- **API Delay**: 100 ms → 3000 ms slider

Perfect for recording demo videos.

---

## ⚙️ Configuration Options

Use `SearchConfig` for advanced control over search behavior:

```dart
const config = SearchConfig(
  debounceDuration: Duration(milliseconds: 400),
  minQueryLength: 2,
  maxResultCount: 30,
  trimInput: true,
  caseSensitive: false,
  inputTransformation: InputTransformation.lowercase,
  autoCorrect: true,
  textCapitalization: TextCapitalization.none,
  searchInTitle: true,
  searchInSubtitle: true,
  searchInTags: true,
  recentHistoryEnabled: true,
  maxHistoryItems: 10,
  overlayEnabled: false,
  overlayMaxHeight: 400,
  animationEnabled: true,
);
```

### Config Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `debounceDuration` | `Duration` | 300ms | Debounce delay before search triggers |
| `minQueryLength` | `int` | 1 | Min characters before search starts |
| `maxResultCount` | `int` | 50 | Maximum results returned |
| `trimInput` | `bool` | `true` | Trim whitespace from input |
| `caseSensitive` | `bool` | `false` | Case-sensitive matching |
| `inputTransformation` | `InputTransformation` | `none` | Transform query: none, lowercase, uppercase |
| `autoCorrect` | `bool` | `true` | Enable autocorrect on text field |
| `textCapitalization` | `TextCapitalization` | `none` | Input capitalization mode |
| `searchInTitle` | `bool` | `true` | Search in result titles |
| `searchInSubtitle` | `bool` | `true` | Search in subtitles |
| `searchInTags` | `bool` | `true` | Search in tags/metadata |
| `recentHistoryEnabled` | `bool` | `true` | Enable search history |
| `maxHistoryItems` | `int` | 10 | Max history items to keep |
| `overlayEnabled` | `bool` | `false` | Use overlay dropdown mode |
| `overlayMaxHeight` | `double` | 400 | Max height of overlay panel |
| `animationEnabled` | `bool` | `true` | Enable animations |

---

## 🪟 Overlay Mode

Search Plus offers two result presentation modes:

### Inline Mode (Default)

Results appear below the search bar in the page flow:

```dart
SearchScaffold<Product>(
  controller: controller,
  hintText: 'Search...',
)
```

### Overlay / Dropdown Mode

Results float above page content in a dismissible panel:

```dart
SearchOverlay<Product>(
  controller: controller,
  hintText: 'Search products…',
  maxOverlayHeight: 400,
  overlayElevation: 8,
  closeOnSelect: true,
  animationConfig: const SearchAnimationConfig(
    preset: SearchAnimationPreset.fadeSlideUp,
  ),
  onItemTap: (result) => handleSelection(result),
  itemBuilder: (context, result, index) => ListTile(
    title: Text(result.title),
    subtitle: Text(result.subtitle ?? ''),
  ),
)
```

**Overlay behavior:**

- Opens when results become available
- Closes on outside tap, Escape, or focus loss
- Smooth fade-in/out animation
- Respects all theming and animation configs
- Works on mobile, tablet, and desktop

---

## 💽 Search History Storage

Search Plus provides a pluggable history storage system:

### In-Memory (Default)

History lives only in memory — lost on app restart:

```dart
final manager = SearchHistoryManager(maxItems: 10);
await manager.add('flutter widgets');
print(manager.items); // ['flutter widgets']
```

### Custom Persistent Storage

Implement `SearchHistoryStorage` for any backend:

```dart
class SharedPrefsHistoryStorage extends SearchHistoryStorage {
  final SharedPreferences prefs;
  SharedPrefsHistoryStorage(this.prefs);

  @override
  Future<List<String>> load() async {
    return prefs.getStringList('search_history') ?? [];
  }

  @override
  Future<void> save(List<String> history) async {
    await prefs.setStringList('search_history', history);
  }

  @override
  Future<void> clear() async {
    await prefs.remove('search_history');
  }
}
```

### Secure Fallback Storage

For secure storage backends:

```dart
final storage = SecureFallbackHistoryStorage(
  readFn: () => secureStorage.read(key: 'history') ?? '',
  writeFn: (data) => secureStorage.write(key: 'history', value: data),
  deleteFn: () => secureStorage.delete(key: 'history'),
);

final manager = SearchHistoryManager(
  maxItems: 10,
  storage: storage,
);
await manager.load(); // Load from storage on startup
```

### History Features

- **Deduplication**: Same query won't appear twice
- **Max count**: Oldest entries are dropped automatically
- **Remove individual**: `manager.remove('old query')`
- **Clear all**: `manager.clearAll()`
- **Persistent**: Survives app restarts with custom storage

---

## 🧩 Fake API / Demo Mode

The example app includes a `FakeSearchApi` for realistic demos:

```dart
final api = FakeSearchApi(
  minDelay: Duration(milliseconds: 200),
  maxDelay: Duration(milliseconds: 800),
  errorRate: 0.0, // Set > 0 to simulate errors
);

// Search users, products, or articles
final results = await api.searchUsers('sarah');
final products = await api.searchProducts('keyboard');
final articles = await api.searchArticles('flutter');

// Suggestions
final suggestions = await api.suggestProducts('wire');
```

**Features:**

- Configurable simulated delay
- Configurable error rate for error state testing
- Three datasets: users (10 items), products (12 items), articles (8 items)
- Trending searches and recent search samples included
- Deterministic results for reproducible demos

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

### 6 Built-in Style Presets (in Demo)

| Preset | Look & Feel |
|--------|------------|
| **Minimal** | Clean flat borders, zero elevation |
| **Modern SaaS** | Rounded bars, subtle shadows, primary highlights |
| **Dark** | Dark backgrounds, teal accents |
| **Social** | Pill-shaped bar, compact items |
| **Glass** | Glassmorphism on gradient background |
| **Dark Premium** | Deep navy + red accent, elevated shadows |

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
  density: isCompact
      ? SearchResultDensity.compact
      : SearchResultDensity.comfortable,
)
```

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
| 9 | **Overlay mode** | Toggle overlay on, search products |
| 10 | **Dark Premium** | Premium style, staggered animation |

---

## 📊 Performance Notes

- Use **local adapter** for low-latency offline search
- **Debouncing** reduces unnecessary network calls for remote APIs
- Keep `maxResults` realistic for your UI layout and device class
- Consider **caching** remote results for hybrid experiences
- Use **sectioned** or paged strategies for very large datasets
- Fuzzy search adds overhead — enable only when needed

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

For persistent history, use `SearchHistoryManager` with a custom `SearchHistoryStorage`.

---

## 🧩 Extensibility

Implement `SearchAdapter<T>` to integrate any data source:

```dart
class AlgoliaSearchAdapter extends SearchAdapter<Product> {
  @override
  Future<List<SearchResult<Product>>> search(
    String query, {int limit = 50, int offset = 0}
  ) async {
    final response = await algolia.search(query);
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

## 📤 API Reference

### Core Classes

| Class | Purpose |
|-------|---------|
| `SearchPlusController<T>` | Main controller — manages search, debouncing, history |
| `SearchResult<T>` | Immutable result model with score, metadata, source |
| `SearchState<T>` | Immutable state: query, results, status, suggestions, history |
| `SearchStatus` | Enum: `idle`, `loading`, `success`, `empty`, `error` |
| `SearchConfig` | Advanced behavior options: debounce, trim, case, limits |
| `SearchHistoryManager` | Manages history with dedup, limits, and persistence |
| `SearchHistoryStorage` | Abstract interface for history storage backends |

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
| `SearchOverlay<T>` | Floating dropdown result panel |
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

## 🧠 Developer Notes

### Architecture Overview

```
lib/
├── search_plus.dart              # Public API barrel file
└── src/
    ├── adapters/                 # Data source abstractions
    │   ├── search_adapter.dart
    │   ├── local_search_adapter.dart
    │   ├── remote_search_adapter.dart
    │   └── hybrid_search_adapter.dart
    ├── animations/               # Animation system
    │   └── animation_presets.dart
    ├── core/                     # Business logic
    │   ├── search_controller.dart
    │   ├── search_result.dart
    │   ├── search_state.dart
    │   ├── search_config.dart
    │   └── search_history_storage.dart
    ├── l10n/                     # Localization
    │   └── search_localizations.dart
    ├── theme/                    # Theming
    │   └── search_theme.dart
    └── ui/                       # Widgets
        ├── search_scaffold.dart
        ├── search_bar_widget.dart
        ├── search_results_widget.dart
        ├── search_overlay.dart
        └── states/
            └── search_states.dart
```

### Clean Code Philosophy

- **Separation of concerns**: UI, state, and data are fully decoupled
- **Immutable state**: `SearchState` and `SearchResult` are immutable
- **Generic types**: Full type safety with `SearchAdapter<T>`, `SearchResult<T>`
- **No external dependencies**: Zero runtime dependencies beyond Flutter SDK
- **Tree-shakeable**: Import only what you use

---

## 🛠 Troubleshooting

### Search returns "No results found" unexpectedly

- Verify your `searchableFields` callback returns the right strings
- Check `minQueryLength` — queries shorter than this won't trigger search
- Ensure your fake/remote API actually matches the query (case-insensitive by default)

### Overlay doesn't close on outside tap

- `SearchOverlay` auto-closes on focus loss with a 150ms delay
- If using custom focus management, ensure the focus node can lose focus

### Animations are not visible

- Check `animationConfig.enabled` is `true`
- Ensure `animationConfig.preset` is not `SearchAnimationPreset.none`
- Try increasing `duration` for more noticeable effects

### History isn't persisted

- The default `InMemoryHistoryStorage` loses data on restart
- Use `SecureFallbackHistoryStorage` or implement `SearchHistoryStorage` for persistence

### Import conflicts with Flutter's `SearchBarThemeData`

- Use `import 'package:flutter/material.dart' hide SearchBarThemeData;` to resolve conflicts

---

## License

MIT — see [`LICENSE`](LICENSE).

---

_Made with ❤️ for the Flutter community_
