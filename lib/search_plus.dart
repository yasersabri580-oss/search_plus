/// A production-grade, highly customizable Flutter search package.
///
/// Supports async API search, local/offline search, hybrid search,
/// rich UI, theming, animations, overlay mode, and localization.
library;

// Core
export 'src/core/search_controller.dart';
export 'src/core/search_result.dart';
export 'src/core/search_state.dart';
export 'src/core/search_config.dart';
export 'src/core/search_history_storage.dart';

// Adapters
export 'src/adapters/search_adapter.dart';
export 'src/adapters/local_search_adapter.dart';
export 'src/adapters/remote_search_adapter.dart';
export 'src/adapters/hybrid_search_adapter.dart';

// UI
export 'src/ui/search_bar_widget.dart';
export 'src/ui/search_results_widget.dart';
export 'src/ui/search_scaffold.dart';
export 'src/ui/search_overlay.dart';
export 'src/ui/states/search_states.dart';

// Theme
export 'src/theme/search_theme.dart';

// Animations
export 'src/animations/animation_presets.dart';

// Localization
export 'src/l10n/search_localizations.dart';

