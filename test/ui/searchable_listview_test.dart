import 'package:flutter/material.dart' hide SearchBarThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:search_plus/search_plus.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  const fruits = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'];

  SearchResult<String> toResult(String item) =>
      SearchResult<String>(id: item, title: item, data: item);

  group('SearchableListView', () {
    testWidgets('renders search bar with default hint', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
          ),
        ),
      );

      // Default hint text from SearchPlusBar (falls back to localizations)
      expect(find.byType(SearchPlusBar), findsOneWidget);
    });

    testWidgets('renders with custom hint text', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
            hintText: 'Search fruits…',
          ),
        ),
      );

      expect(find.text('Search fruits…'), findsOneWidget);
    });

    testWidgets('shows results when typing a query', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
            debounceDuration: Duration.zero,
            animationConfig: SearchAnimationConfig.none,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Apple');
      // Allow the debounce + async search to complete.
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsWidgets);
    });

    testWidgets('calls onQueryChanged when text changes', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
            onQueryChanged: (q) => lastQuery = q,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Ban');
      expect(lastQuery, 'Ban');
    });

    testWidgets('calls onItemTap when a result is tapped', (tester) async {
      SearchResult<String>? tappedResult;

      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
            debounceDuration: Duration.zero,
            animationConfig: SearchAnimationConfig.none,
            onItemTap: (result) => tappedResult = result,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Cherry');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cherry').last);
      expect(tappedResult?.title, 'Cherry');
    });

    testWidgets('applies custom theme', (tester) async {
      final customTheme = SearchPlusThemeData(
        searchBarTheme: SearchBarThemeData(
          borderRadius: BorderRadius.circular(0),
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
            theme: customTheme,
          ),
        ),
      );

      expect(find.byType(SearchPlusBar), findsOneWidget);
    });

    testWidgets('applies custom localizations', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
            localizations: const SearchLocalizations(hintText: 'Buscar…'),
          ),
        ),
      );

      expect(find.text('Buscar…'), findsOneWidget);
    });

    testWidgets('shows idle builder when no query', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          SearchableListView<String>(
            items: fruits,
            searchableFields: (item) => [item],
            toResult: toResult,
            idleBuilder: (context) =>
                const Center(child: Text('Type to search')),
          ),
        ),
      );

      expect(find.text('Type to search'), findsOneWidget);
    });
  });
}
