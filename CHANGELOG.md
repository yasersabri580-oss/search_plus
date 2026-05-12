# Changelog

## 3.3.2

- **Fix**: `AppBarSearchButton` icon no longer shifts vertically (~20 px) when the search field expands or collapses.
  - The widget is now wrapped in a `SizedBox` whose height equals `inputHeight`, giving the AppBar a stable, constant-height anchor throughout the animation.
  - The icon `SizedBox` now uses `inputHeight` for both width and height (instead of the hard-coded `40`) so that custom `inputHeight` values are respected correctly.
  - `crossAxisAlignment: CrossAxisAlignment.center` is now set explicitly on the internal `Row` to guarantee vertical centering regardless of layout context.
- **Theme**: Added `activeIconColor` to `SearchBarThemeData` — controls the search-icon color when the field is expanded or focused, independently of `focusedBorderColor`.
  - Defaults to `ColorScheme.primary`.
  - `copyWith` and `resolve` updated accordingly.
  - `AppBarSearchButton` now interpolates the icon color between `iconColor` (collapsed) and `activeIconColor` (expanded) instead of using `focusedBorderColor` for the icon.

## 3.3.1

- Added `textFieldBorder` and `textFieldFocusedBorder` (`InputBorder?`) to `SearchBarThemeData` for full control over the inner `TextField`'s border in all states.
  - Both default to `InputBorder.none`, eliminating the unwanted blue focus ring that Flutter's ambient `InputDecorationTheme` would otherwise draw inside the search bar.
  - Override either property to apply a custom `OutlineInputBorder`, `UnderlineInputBorder`, or any other `InputBorder` subclass.
  - Applied in both `AppBarSearchButton` and `SearchPlusBar`.
- Added `copyWith` method to `SearchBarThemeData` for convenient partial updates.

## 3.3.0

- Added `AppBarSearchButton`: a compact animated search action for `AppBar.actions`.
  - Renders a search icon by default; smoothly expands into a full text input on hover (desktop/web) or tap.
  - Collapses automatically when the field is empty and both hover and focus are removed.
  - Persistent expanded state while text is present.
  - Fully integrated with `SearchTheme` / `SearchPlusThemeData` for consistent styling.
  - Smooth `SizeTransition` + `FadeTransition` + icon color animation driven by a single `AnimationController`.
  - Responsive — hover-expand on desktop/web, tap-expand on mobile.
  - New example `AppBarSearchExample` added to the example app.

## 3.2.3

- Readme.md file updated
