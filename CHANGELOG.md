# Changelog

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
