import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:search_plus/search_plus.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('SearchPlusBar', () {
    testWidgets('renders with default hint text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SearchPlusBar(),
      ));

      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('renders with custom hint text', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SearchPlusBar(hintText: 'Find items...'),
      ));

      expect(find.text('Find items...'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;
      await tester.pumpWidget(_buildTestApp(
        SearchPlusBar(onChanged: (value) => changedValue = value),
      ));

      await tester.enterText(find.byType(TextField), 'hello');
      expect(changedValue, 'hello');
    });

    testWidgets('calls onSubmitted when submitted', (tester) async {
      String? submittedValue;
      await tester.pumpWidget(_buildTestApp(
        SearchPlusBar(onSubmitted: (value) => submittedValue = value),
      ));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submittedValue, 'test');
    });

    testWidgets('shows clear button when text is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SearchPlusBar(),
      ));

      // No clear button initially
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Type some text
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('clear button clears text', (tester) async {
      String? changedValue;
      await tester.pumpWidget(_buildTestApp(
        SearchPlusBar(onChanged: (value) => changedValue = value),
      ));

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(changedValue, '');
    });

    testWidgets('renders with custom localizations', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchLocalizationsProvider(
            localizations: const SearchLocalizations(
              hintText: 'Buscar...',
            ),
            child: const SearchPlusBar(),
          ),
        ),
      ));

      expect(find.text('Buscar...'), findsOneWidget);
    });

    testWidgets('renders search icon', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SearchPlusBar(),
      ));

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });
  });

  group('SearchResultsWidget', () {
    testWidgets('shows empty state when status is empty', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SearchResultsWidget(
          state: SearchState(
            query: 'test',
            status: SearchStatus.empty,
          ),
        ),
      ));

      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('shows error state when status is error', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const SearchResultsWidget(
          state: SearchState(
            query: 'test',
            status: SearchStatus.error,
            error: 'Network error',
          ),
        ),
      ));

      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('shows results when status is success', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        SearchResultsWidget<String>(
          state: SearchState<String>(
            query: 'test',
            status: SearchStatus.success,
            results: [
              const SearchResult(id: '1', title: 'Result One'),
              const SearchResult(id: '2', title: 'Result Two'),
            ],
          ),
          animationConfig: SearchAnimationConfig.none,
        ),
      ));

      expect(find.text('Result One'), findsOneWidget);
      expect(find.text('Result Two'), findsOneWidget);
    });

    testWidgets('calls onItemTap when result is tapped', (tester) async {
      SearchResult<String>? tappedResult;
      await tester.pumpWidget(_buildTestApp(
        SearchResultsWidget<String>(
          state: SearchState<String>(
            query: 'test',
            status: SearchStatus.success,
            results: const [
              SearchResult(id: '1', title: 'Result One'),
            ],
          ),
          animationConfig: SearchAnimationConfig.none,
          onItemTap: (result) => tappedResult = result,
        ),
      ));

      await tester.tap(find.text('Result One'));
      expect(tappedResult?.id, '1');
    });

    testWidgets('shows retry button on error', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_buildTestApp(
        SearchResultsWidget<String>(
          state: const SearchState(
            query: 'test',
            status: SearchStatus.error,
            error: 'Failed',
          ),
          onRetry: () => retried = true,
        ),
      ));

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('SearchScaffold', () {
    testWidgets('renders search bar and handles input', (tester) async {
      final controller = SearchPlusController<String>(
        adapter: LocalSearchAdapter<String>(
          items: ['Apple', 'Banana', 'Cherry'],
          searchableFields: (item) => [item],
          toResult: (item) =>
              SearchResult(id: item, title: item, data: item),
        ),
        debounceDuration: Duration.zero,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchScaffold<String>(
            controller: controller,
            hintText: 'Search fruits...',
            animationConfig: SearchAnimationConfig.none,
          ),
        ),
      ));

      expect(find.text('Search fruits...'), findsOneWidget);

      controller.dispose();
    });
  });

  group('HighlightText', () {
    testWidgets('renders text without query', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const HighlightText(text: 'Hello World', query: ''),
      ));

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders highlighted text with query', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const HighlightText(text: 'Hello World', query: 'World'),
      ));

      // The widget should render as a RichText
      expect(find.byType(RichText), findsOneWidget);
    });
  });

  group('SearchTheme', () {
    testWidgets('provides default theme', (tester) async {
      late SearchThemeData capturedTheme;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            capturedTheme = SearchTheme.of(context);
            return const SizedBox();
          },
        ),
      ));

      expect(capturedTheme.searchBarTheme.borderRadius, isNotNull);
      expect(capturedTheme.resultTheme.titleStyle, isNotNull);
    });

    testWidgets('overrides with custom theme', (tester) async {
      late SearchThemeData capturedTheme;

      await tester.pumpWidget(MaterialApp(
        home: SearchTheme(
          data: SearchThemeData(
            searchBarTheme: SearchBarThemeData(
              borderRadius: BorderRadius.circular(0),
            ),
          ),
          child: Builder(
            builder: (context) {
              capturedTheme = SearchTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ));

      expect(capturedTheme.searchBarTheme.borderRadius,
          BorderRadius.circular(0));
    });
  });

  group('SearchLocalizations', () {
    testWidgets('provides default English localizations', (tester) async {
      late SearchLocalizations capturedL10n;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            capturedL10n = SearchLocalizationsProvider.of(context);
            return const SizedBox();
          },
        ),
      ));

      expect(capturedL10n.hintText, 'Search...');
      expect(capturedL10n.emptyResultsText, 'No results found');
    });

    test('formatResultsCount works', () {
      const l10n = SearchLocalizations();
      expect(l10n.formatResultsCount(42), '42 results');
    });
  });
}
