# Changelog

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
