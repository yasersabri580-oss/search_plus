# search_plus

Production-grade, highly customizable Flutter search with async API search, local/offline search, hybrid search, rich UI widgets, theming, animations, and localization.

## Features
- 🔍 Core search engine with debouncing, cancellation, history, and suggestions
- 🧩 Adapters for local, remote (async/API), and hybrid search; build custom adapters easily
- 🎨 Ready-made UI (search bar, scaffold, results list) with theming and animation presets
- 🌐 Localization-friendly strings and error states
- ⚡ Ranking, fuzzy matching, and pagination support

## Install
Add to `pubspec.yaml`:
```yaml
dependencies:
  search_plus: ^1.0.0
```
Then run `flutter pub get`.

## Quickstart
```dart
import 'package:search_plus/search_plus.dart';

final controller = SearchPlusController<Product>(
  adapter: LocalSearchAdapter<Product>(
    items: products,
    searchableFields: (p) => [p.name, p.description],
    toResult: (p) => SearchResult(id: p.id, title: p.name, data: p),
    enableFuzzySearch: true,
  ),
);

class ProductSearchPage extends StatelessWidget {
  const ProductSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchScaffold<Product>(
      controller: controller,
      searchBar: const SearchBarWidget(),
      resultsBuilder: (context, state) => SearchResultsWidget<Product>(
        state: state,
        itemBuilder: (context, result) => ListTile(
          title: Text(result.title),
          subtitle: Text(result.subtitle ?? ''),
        ),
      ),
    );
  }
}
```

## Adapters
- **LocalSearchAdapter**: In-memory list search with ranking, fuzzy matching, and suggestions.
- **RemoteSearchAdapter**: Wrap an async/API call; returns `List<SearchResult<T>>`.
- **HybridSearchAdapter**: Combine local and remote sources (e.g., local cache + API).
- **Custom adapters**: Implement `SearchAdapter<T>` and its `search` (and optional `suggest`) methods.

### Remote example
```dart
final adapter = RemoteSearchAdapter<Product>(
  fetch: (query, {limit, offset}) async {
    final response = await api.searchProducts(query, limit: limit, offset: offset);
    return response.items
        .map((p) => SearchResult(id: p.id, title: p.name, subtitle: p.description, data: p))
        .toList();
  },
);
```

## UI building blocks
- `SearchScaffold`: High-level layout wiring search bar + results to a controller.
- `SearchBarWidget`: Debounced search input with clear and suggest hooks.
- `SearchResultsWidget`: Renders loading, empty, error, and success states.
- `SearchStates` helpers: Convenient widgets for different states.

## Theming & animations
- `SearchTheme`: Colors, typography, paddings, borders, and spacing overrides.
- `AnimationPresets`: Fade/slide/scale presets to quickly animate transitions.
- Apply via `SearchScaffold(theme: SearchTheme(...), animations: AnimationPresets.fadeIn)`.

## Localization
- Strings live in `search_localizations.dart`. Provide your own `SearchLocalizations` or use Flutter localization delegates to override labels, empty/error messages, and button text.

## State & history
- `SearchPlusController` exposes `state`, `results`, `status`, `isLoading`, `hasError`, `hasResults`.
- Built-in history: `addToHistory`, `clearHistory`, and `state.history`.
- Suggestions: `controller.suggest(query)` delegates to the adapter.

## Testing tips
- Use `SearchEngine` directly in unit tests with a fake adapter.
- For widgets, provide a mock adapter and pump `SearchScaffold` with `WidgetTester`.

## Publishing to pub.dev (Dart Pub) guide
1. **Prepare metadata**: Update `pubspec.yaml` with correct `version`, `description`, `homepage`, `repository`, `issue_tracker`, and `license` file.
2. **Docs**: Ensure `README.md` (this file) and `CHANGELOG.md` exist and are up to date; include usage examples.
3. **Format & analyze**: Run `dart format .` and `dart analyze` (or `flutter analyze`); run `flutter test` if tests exist.
4. **Verify assets**: Remove large/unneeded files; ensure screenshots are in `assets/` and referenced if required.
5. **Dry run**: `dart pub publish --dry-run` (or `flutter pub publish --dry-run`) and fix any reported issues.
6. **Authenticate once**: Run `dart pub login` (opens a browser) if not already authenticated.
7. **Publish**: `dart pub publish` (or `flutter pub publish`), confirm the prompt. Tag the release in git for traceability.
8. **Post-publish**: Verify the package page, add a release note, and announce if desired.

## License
This project is available under the terms of the license in the `LICENSE` file.
