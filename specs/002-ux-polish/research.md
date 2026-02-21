# Phase 0 Research: UX Polish & Visual Refinement

**Branch**: `002-ux-polish` | **Date**: 2026-02-21

---

## Decision 1: Image Caching Package

**Decision**: Use `cached_network_image: ^3.3.0`

**Rationale**: Industry standard for Flutter image loading from network URLs. Handles memory + disk caching transparently, provides built-in `placeholder` and `errorWidget` callbacks, and integrates cleanly with `Hero` animations via `CachedNetworkImageProvider`. Null URL handling must be done before calling the widget (the package does not accept null URLs).

**Alternatives considered**:
- `Image.network` — no disk caching, would re-fetch on every cold launch; unacceptable for a recipe list with 80+ photos.
- `flutter_cache_manager` directly — lower-level API, more boilerplate; `cached_network_image` wraps it and is sufficient.

---

## Decision 2: Equalizer Animation Architecture

**Decision**: Single `AnimationController` with `Interval`-based staggering + `Transform.scale` + `AnimatedBuilder`

**Rationale**: One controller drives all 5 bars via offset `Interval` curves. `Transform.scale` uses GPU matrix transforms (no layout reflow), ensuring 60 fps on mid-range devices. `_controller.repeat()` loops indefinitely with clean disposal.

Key parameters confirmed by research:
- Cycle duration: **1400 ms** (natural audio feel)
- Stagger: **15% per bar** (210 ms offset; 5 bars span 840 ms)
- Segment: **35% of cycle per bar** (490 ms per bar animation)
- Scale range: **0.3 → 1.0** (bars never disappear)
- Curve: **`Curves.easeInOut`**

**Alternatives considered**:
- Multiple `AnimationController` instances — timing drift, memory overhead, harder to synchronize.
- `SizeTransition` — triggers layout recalculation on every frame, causes jank.
- Separate `SplashScreen` widget with navigation — adds navigator stack complexity; existing Riverpod `filteredAsync.when(loading: ...)` pattern is the correct insertion point.

**Architecture**: `EqualizerLoadingView` replaces `LoadingView` in the `recipe_list_screen.dart` loading state. No separate splash screen navigation needed.

---

## Decision 3: Page Transitions

**Decision**: Custom `PageRouteBuilder` with `SlideTransition` + `FadeTransition` — **no additional package dependency**

**Rationale**: A `PageRouteBuilder` with `SlideTransition(Offset(1.0, 0.0) → Offset.zero)` and `FadeTransition` using `Curves.easeInOutCubic` at 350 ms achieves the desired polish without adding a dependency. The user prefers lean architecture ("not overengineered").

**Alternatives considered**:
- `animations: ^2.0.0` (`SharedAxisPageTransitionsBuilder`) — Material Design 3 compliant but adds a dependency purely for transitions; the custom approach achieves equivalent quality.

**Implementation**: Create a reusable `_RecipePageRoute<T>` private class used only in `recipe_list_screen.dart`. Not a shared utility (single use-site → Rule of Three respected).

---

## Decision 4: Warm Surface Colour

**Decision**: `ColorScheme.fromSeed(...).copyWith(surface: const Color(0xFFF5EFE7))` for light; `...copyWith(surface: const Color(0xFF2B1F1A))` for dark

**Rationale**: `0xFFF5EFE7` (RGB 245,239,231) is a warm cream that harmonises with the terracotta seed without competing. Material Design 3 components (`Scaffold`, `AppBar`, `Card`, `BottomSheet`) all inherit `colorScheme.surface` automatically. Named constants defined in `theme.dart` — no raw hex values in widget files.

**Alternatives considered**:
- `0xFFFBF8F3` — almost white, not warm enough.
- `0xFFF0E8DC` — slightly too warm; readable but may affect text contrast.

---

## Decision 5: Source URL Opening

**Decision**: Use `url_launcher: ^6.2.0`

**Rationale**: Standard Flutter package for opening URLs in the system browser. Required for FR-005 (tappable source link). Requires an `<queries>` block in `AndroidManifest.xml` for Android 11+ (API 30+).

**Alternatives considered**:
- Display source as non-tappable text — does not satisfy FR-005.
- `flutter_inappwebview` — heavyweight; opening in system browser is more appropriate for attribution links.

---

## Decision 6: Photo Tile Structure

**Decision**: `ListView.builder` with `InkWell → Padding → ClipRRect(r:12) → Stack → [AspectRatio(1.6) + CachedNetworkImage + Positioned gradient overlay with name]`

**Rationale**: `ListView.builder` keeps the existing flat-list pattern (simple, well-tested). `AspectRatio(1.6)` (approx 16:10, wider than square) gives a generous photo crop while fitting 3–4 tiles on screen. `ClipRRect` clips the image to rounded corners. `Positioned` anchors the gradient + name at the bottom. `Hero` wraps the `CachedNetworkImage` for the fly-in animation to the detail screen.

Tags are not shown on tiles (FR-002) but filtering remains fully functional.

**Alternatives considered**:
- `GridView.builder` (2 columns) — smaller tiles, less visual impact per recipe photo; can be switched later without changing tile widget.
- `AspectRatio(1.0)` (square) — too tall on standard phones; 16:10 is closer to food photography format.

---

## Decision 7: Wakelock Toggle Improvement

**Decision**: Replace `IconButton(Icons.lightbulb*)` with `TextButton.icon` in AppBar actions, showing label "Screen on" / "Screen off"

**Rationale**: FR-008 requires a clear label; FR-009 requires a visually distinct active state; FR-010 requires snackbar feedback. A `TextButton.icon` with an icon + label text gives both discoverability and clear active/inactive distinction. Snackbar confirms state change. Constitution III (UX consistency): uses theme typography, not custom styles.

**Alternatives considered**:
- `ElevatedButton` — too heavy for an app bar action.
- Tooltip-only approach — tooltip is not visible unless long-pressed; insufficient for discoverability.

---

## API Structure Confirmed

Both endpoints already return all required fields — no server-side changes needed:

**Index** (`/recipes/index.json`): `name`, `picture`, `url`
**Detail** (`/recipes/{slug}/index.json`): `name`, `picture`, `recipe`, `source`

`picture` and `source` may be absent/null for some recipes (no photo, no external source). Model fields are nullable.

---

## New Dependencies Summary

| Package | Version | Purpose |
|---------|---------|---------|
| `cached_network_image` | `^3.3.0` | Network image loading with disk cache |
| `url_launcher` | `^6.2.0` | Open source URL in system browser |
