import 'package:flutter/material.dart' hide SearchBarThemeData;
import 'package:search_plus/search_plus.dart';

import '../api/fake_search_api.dart';

/// Advanced example: remote API search with suggestions, history,
/// custom empty/error states, and grid layout support.
class AdvancedExample extends StatefulWidget {
  const AdvancedExample({super.key});

  @override
  State<AdvancedExample> createState() => _AdvancedExampleState();
}

class _AdvancedExampleState extends State<AdvancedExample> {
  final _api = FakeSearchApi(
    minDelay: const Duration(milliseconds: 200),
    maxDelay: const Duration(milliseconds: 800),
  );

  late final SearchPlusController<AppUser> _controller;
  var _layout = SearchResultsLayout.list;

  @override
  void initState() {
    super.initState();
    _controller = SearchPlusController<AppUser>(
      adapter: RemoteSearchAdapter<AppUser>(
        searchFunction: (query, limit, offset) => _api.searchUsers(query, limit: limit, offset: offset),
        suggestFunction: _api.suggestUsers,
      ),
      debounceDuration: const Duration(milliseconds: 400),
      maxHistoryItems: 8,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Example'),
        actions: [
          IconButton(
            tooltip: 'Toggle layout',
            icon: Icon(
              _layout == SearchResultsLayout.list
                  ? Icons.grid_view_rounded
                  : Icons.view_list_rounded,
            ),
            onPressed: () {
              setState(() {
                _layout = _layout == SearchResultsLayout.list
                    ? SearchResultsLayout.grid
                    : SearchResultsLayout.list;
              });
            },
          ),
        ],
      ),
      body: SearchTheme(
        data: SearchThemeData(
          searchBarTheme: SearchBarThemeData(
            borderRadius: BorderRadius.circular(28),
            backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(80),
            focusedBorderColor: colorScheme.primary,
          ),
          resultTheme: SearchResultThemeData(
            highlightColor: colorScheme.primary.withAlpha(40),
          ),
        ),
        child: SearchScaffold<AppUser>(
          controller: _controller,
          hintText: 'Search people…',
          layout: _layout,
          gridCrossAxisCount: 2,
          gridChildAspectRatio: 0.85,
          animationConfig: const SearchAnimationConfig(
            preset: SearchAnimationPreset.fadeSlideUp,
            duration: Duration(milliseconds: 350),
          ),
          showShimmer: true,
          idleBuilder: (context) => _IdleView(
            controller: _controller,
            onSearch: (q) => _controller.search(q),
          ),
          emptyState: const SearchEmptyState(
            icon: Icon(Icons.person_search, size: 64),
            title: 'No users found',
            subtitle: 'Try searching by name or username.',
          ),
          errorState: SearchErrorState(
            icon: const Icon(Icons.cloud_off, size: 64),
            message: 'Could not reach the server.',
            onRetry: () => _controller.searchImmediate(_controller.query),
          ),
          itemBuilder: (context, result, index) {
            final user = result.data;
            final isVerified =
                (result.metadata['verified'] as bool?) ?? false;
            return _UserTile(
              result: result,
              query: _controller.query,
              isVerified: isVerified,
              avatarUrl: user?.avatarUrl ?? '',
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle view — recent searches + trending
// ---------------------------------------------------------------------------

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.controller,
    required this.onSearch,
  });

  final SearchPlusController<AppUser> controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (controller.state.history.isNotEmpty) ...[
              _SectionHeader(
                title: 'Recent Searches',
                trailing: TextButton(
                  onPressed: controller.clearHistory,
                  child: const Text('Clear'),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: controller.state.history
                    .map(
                      (q) => ActionChip(
                        label: Text(q),
                        avatar: const Icon(Icons.history, size: 16),
                        onPressed: () => onSearch(q),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            const _SectionHeader(title: 'Trending'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: trendingSearches
                  .map(
                    (t) => ActionChip(
                      label: Text(t),
                      avatar: Icon(
                        Icons.trending_up,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () => onSearch(t),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User tile
// ---------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.result,
    required this.query,
    required this.isVerified,
    required this.avatarUrl,
  });

  final SearchResult<AppUser> result;
  final String query;
  final bool isVerified;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          result.title.isNotEmpty ? result.title[0].toUpperCase() : '?',
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: HighlightText(
              matchedText: query,
              text: result.title,
              query: query,
              highlightStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.verified,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ],
      ),
      subtitle: Text(
        result.subtitle ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
