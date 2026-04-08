/// A production-grade, highly customizable Flutter search package.
///
/// Supports async API search, local/offline search, hybrid search,
/// rich UI, theming, animations, overlay mode, and localization.
///
/// ## Ecosystem Modules
///
/// - **Core**: Search engine, controllers, state management
/// - **Adapters**: Local, remote, hybrid, cached, enhanced remote
/// - **Cache**: Memory cache with TTL, cached adapter decorator
/// - **Remote**: Retry strategies, cancellation, deduplication, analytics
/// - **UI Pro**: Skeleton loading, text highlighting, glassmorphism, premium screen
/// - **DevTools**: Enhanced debug panel with logs, results preview, performance metrics
library;

// Core
export 'src/core/search_controller.dart';
export 'src/core/search_result.dart';
export 'src/core/search_state.dart';
export 'src/core/search_config.dart';
export 'src/core/search_plus_config.dart';
export 'src/core/search_history_storage.dart';

// Adapters
export 'src/adapters/search_adapter.dart';
export 'src/adapters/local_search_adapter.dart';
export 'src/adapters/remote_search_adapter.dart';
export 'src/adapters/hybrid_search_adapter.dart';

// Cache
export 'src/cache/search_cache.dart';
export 'src/cache/cached_search_adapter.dart';

// Remote (Enhanced)
export 'src/remote/remote_search_config.dart';
export 'src/remote/retry_strategy.dart';
export 'src/remote/cancellable_operation.dart';
export 'src/remote/query_deduplicator.dart';
export 'src/remote/enhanced_remote_adapter.dart';

// UI
export 'src/ui/search_bar_widget.dart';
export 'src/ui/search_results_widget.dart';
export 'src/ui/search_scaffold.dart';
export 'src/ui/search_overlay.dart';
export 'src/ui/states/search_states.dart';
export 'src/ui/suggestion_chips.dart';
export 'src/ui/search_history_list.dart';
export 'src/ui/scroll_to_top_button.dart';
export 'src/ui/searchable_listview.dart';

// UI Pro
export 'src/ui/pro/skeleton_loading.dart';
export 'src/ui/pro/highlight_text.dart';
export 'src/ui/pro/glassmorphism_container.dart';
export 'src/ui/pro/search_plus_screen.dart';

// Theme
export 'src/theme/search_theme.dart';

// Animations
export 'src/animations/animation_presets.dart';

// Localization
export 'src/l10n/search_localizations.dart';

// Utilities
export 'src/utils/search_logger.dart';

// Debug
export 'src/ui/debug/search_debug_panel.dart';

// DevTools (Enhanced)
export 'src/ui/devtools/search_devtools_panel.dart';

