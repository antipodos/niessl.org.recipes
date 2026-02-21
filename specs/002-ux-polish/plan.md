# Implementation Plan: UX Polish & Visual Refinement

**Branch**: `002-ux-polish` | **Date**: 2026-02-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-ux-polish/spec.md`

## Summary

Elevate the recipe app from MVP to polished product through six targeted changes: (1) photo-first recipe tiles with `Hero` fly-in animation, (2) enriched detail screen with photo header, source attribution link, and larger body text, (3) animated equalizer-bar loading screen using the niessl.org logo motif, (4) warm cream surface theme with matching dark mode, (5) branded "niessl.org recipes" header and smooth slide/fade page transition, (6) labelled screen-on toggle with snackbar feedback. Two packages are added (`cached_network_image`, `url_launcher`). All changes are additive; existing tests and data flows are preserved.

## Technical Context

**Language/Version**: Dart 3.9.2 / Flutter 3.35.6
**Primary Dependencies**: flutter_riverpod 2.6.1, http 1.6.0, cached_network_image ^3.3.0 (new), url_launcher ^6.2.0 (new), flutter_markdown 0.7.7+1, wakelock_plus 1.4.0, shared_preferences 2.5.4
**Storage**: SharedPreferences — existing cache-first strategy unchanged; model serialisation updated to include new fields
**Testing**: flutter_test (unit + widget), integration_test (Android emulator `Medium_Phone_API_36.1`)
**Target Platform**: Android primary (API 36.1), iOS secondary
**Project Type**: Mobile Flutter app, flat source structure at repository root
**Performance Goals**: Photo tiles scroll at ≥60 fps; `Transform.scale` animation at 60 fps (GPU-accelerated); images loaded from disk cache on second visit
**Constraints**: Offline-capable (cache-first); no blocking in render path; ≥80% coverage on changed code

## Constitution Check

| Principle | Requirement | Status |
|-----------|-------------|--------|
| I. Code Quality | All colour values as named constants in `theme.dart`. New widgets have single responsibility. No dead code. Public names express intent. `RecipePhotoWidget` not created (only 2 use-sites — Rule of Three); photo logic inlined. | ✅ |
| II. Test-First | Unit tests for updated `RecipeSummary`/`RecipeDetail` models written first. Widget tests for `EqualizerLoadingView` and updated `RecipeTile`/`RecipeDetailScreen` written first. Integration tests for photo tile navigation and source link written first. Non-negotiable. | ✅ |
| III. UX Consistency | All colours via `colorScheme` tokens or named constants — no raw hex in widget files. Gradient scrim uses `colorScheme.scrim.withOpacity(0.55)`. Wakelock toggle uses `TextButton.icon` (theme typography). Accessible contrast: white text over dark gradient (>4.5:1 checked). | ✅ |
| IV. Performance | `CachedNetworkImage` disk cache prevents re-fetching. `Transform.scale` GPU-accelerated. Custom `PageRouteBuilder` transition uses platform GPU-backed animation layer. `url_launcher` is async — no blocking in render path. | ✅ |

*Post-design re-check*: No violations after reviewing data model and structure. Complexity Tracking section not required.

## Project Structure

### Documentation (this feature)

```text
specs/002-ux-polish/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code

```text
lib/
├── main.dart                             (no changes)
├── theme.dart                            (update: warm surfaces, page transition theme)
├── models/
│   └── recipe.dart                       (update: add picture?, source? to both models)
├── services/
│   └── recipe_service.dart               (update: parse picture/source; update cache serialisation)
├── providers/
│   └── providers.dart                    (no changes)
├── screens/
│   ├── recipe_list_screen.dart           (update: title, EqualizerLoadingView, custom route)
│   └── recipe_detail_screen.dart         (update: photoUrl param, photo header, source link,
│                                          larger font, TextButton.icon toggle, snackbar)
└── widgets/
    ├── equalizer_loading_view.dart       (NEW)
    ├── recipe_tile.dart                  (update: photo tile + Hero)
    ├── search_bar_widget.dart            (no changes)
    ├── tag_chip_bar.dart                 (no changes)
    ├── loading_view.dart                 (no changes)
    ├── error_view.dart                   (no changes)
    └── empty_state_view.dart             (no changes)

android/
└── app/src/main/AndroidManifest.xml      (update: add <queries> for url_launcher)

test/
├── unit/
│   ├── recipe_service_test.dart          (update: add picture/source parsing tests)
│   └── filter_logic_test.dart            (no changes)
└── widget/
    └── screens_widget_test.dart          (update: new tests for updated screens + equalizer)

integration_test/
└── app_test.dart                         (update: new tests for photo tile + source link)
```

**Structure Decision**: Single-project flat Flutter layout preserved. One new widget file only (`equalizer_loading_view.dart`). No new directories.

## Phase 0: Research

*See [research.md](research.md) for full findings.*

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Image caching | `cached_network_image: ^3.3.0` | Industry standard; disk + memory cache; Hero-compatible |
| Page transitions | Custom `PageRouteBuilder` (slide + fade, 350 ms) | Zero dependencies; equivalent polish to `animations` package |
| Equalizer animation | Single `AnimationController` + `Interval` stagger + `Transform.scale` | GPU-accelerated; 60 fps on mid-range device; minimal memory |
| Loading screen insertion | Replace `LoadingView` in `filteredAsync.when(loading:)` | No extra navigator stack; idiomatic Riverpod |
| Warm surface (light) | `ColorScheme.fromSeed(...).copyWith(surface: _warmCreamSurface)` | Auto-propagates to Scaffold, AppBar, Card |
| Warm surface (dark) | `...copyWith(surface: _warmDarkSurface)` | Warm brown matches light mode intent |
| Source URL | `url_launcher: ^6.2.0` | Standard; requires `<queries>` in AndroidManifest for API 30+ |
| Wakelock toggle | `TextButton.icon` with label + `ScaffoldMessenger` snackbar | Clear label (FR-008), distinct active state (FR-009), feedback (FR-010) |

## Phase 1: Design & Contracts

*See [data-model.md](data-model.md) for entity details.*

No API contracts required — this feature is purely client-side and the dinner.niessl.org API already provides all required fields (`picture`, `source`).

### Component Designs

#### `lib/widgets/equalizer_loading_view.dart` (NEW)

```
EqualizerLoadingView (StatefulWidget + SingleTickerProviderStateMixin)
│
├── AnimationController _controller (1400 ms, repeat())
│
└── Center
    └── Column
        ├── Row [5 × _EqualizerBar]
        │   └── _EqualizerBar (StatelessWidget)
        │       └── AnimatedBuilder
        │           └── Transform.scale(scaleY: 0.3→1.0, alignment: bottomCenter)
        │               └── Container(width: 5, height: 50, rounded, color: colorScheme.primary)
        └── SizedBox(height: 16)
        └── Text('niessl.org recipes', style: bodySmall, color: onSurfaceVariant)

Animation per bar i:
  CurvedAnimation(parent: _controller,
    curve: Interval(i*0.15, i*0.15+0.35, curve: Curves.easeInOut))
```

#### `lib/widgets/recipe_tile.dart` (updated)

```
Hero(tag: 'recipe_photo_${recipe.url}')
└── InkWell(onTap: navigator push with custom route)
    └── Padding(all: 8)
        └── ClipRRect(borderRadius: 12)
            └── Stack
                ├── AspectRatio(1.6)
                │   └── recipe.picture != null
                │       ? CachedNetworkImage(imageUrl: picture, fit: cover,
                │           placeholder: warm Container, errorWidget: icon Container)
                │       : Container(color: colorScheme.surfaceVariant,
                │           child: Icon(Icons.restaurant, color: onSurfaceVariant))
                └── Positioned(bottom: 0, left: 0, right: 0)
                    └── Container(gradient: scrim → transparent)
                        └── Padding(horizontal: 12, vertical: 10)
                            └── Text(recipe.name, style: titleSmall, color: white,
                                 maxLines: 2, overflow: ellipsis)
```

No tags rendered on tile (FR-002).

#### `lib/screens/recipe_detail_screen.dart` (updated)

New constructor parameter: `photoUrl: String?` (passed from tile, used for Hero before API loads).

```
Scaffold
├── AppBar
│   ├── title: Text(widget.name, maxLines: 2, overflow: ellipsis)
│   └── actions: [
│       TextButton.icon(
│         icon: Icon(_keepAwake ? Icons.visibility : Icons.visibility_off),
│         label: Text(_keepAwake ? 'Screen on' : 'Screen off'),
│         onPressed: _toggleWakelock  // also shows ScaffoldMessenger snackbar
│       )
│     ]
└── body: detailAsync.when(
    loading: () => LoadingView(),   // still shows during detail fetch
    error: (e, _) => ErrorView(...),
    data: (detail) => SingleChildScrollView
        └── Column
            ├── // Photo header (Hero)
            │   Hero(tag: 'recipe_photo_${widget.url}')
            │   └── AspectRatio(16/9)
            │       └── [CachedNetworkImage or placeholder — same pattern as tile]
            ├── // Recipe name heading
            │   Padding(h:16, top:16)
            │   └── Text(widget.name, style: headlineMedium)
            ├── // Source attribution (only if detail.source != null)
            │   Padding(h:16, bottom:8)
            │   └── InkWell(onTap: launchUrl(Uri.parse(detail.source!)))
            │       └── Row [Icon(Icons.open_in_new, size:14), SizedBox(4),
            │               Text(domain, style: bodySmall.copyWith(color: primary))]
            ├── Divider
            └── // Recipe markdown
                Padding(all:16)
                └── MarkdownBody(data: detail.recipe,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: bodyMedium.copyWith(fontSize: 17, height: 1.5)))
```

#### `lib/theme.dart` (updated)

```dart
const _seedColor      = Color(0xFFB85C38);   // existing
const _warmCreamSurface = Color(0xFFF5EFE7); // NEW — light mode surface
const _warmDarkSurface  = Color(0xFF2B1F1A); // NEW — dark mode surface

appLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seedColor)
    .copyWith(surface: _warmCreamSurface),
);

appDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark)
    .copyWith(surface: _warmDarkSurface),
);
```

#### `lib/screens/recipe_list_screen.dart` (updated)

- `AppBar(title: const Text('niessl.org recipes'))`
- `loading: () => const EqualizerLoadingView()`
- Navigation: `Navigator.push(context, _RecipePageRoute(child: RecipeDetailScreen(..., photoUrl: recipe.picture)))`
- `_RecipePageRoute<T>` private class in same file: `PageRouteBuilder` with `SlideTransition` (right-to-left) + `FadeTransition`, 350 ms, `Curves.easeInOutCubic`

### Test Strategy

#### Unit tests (`test/unit/recipe_service_test.dart` — additions)
- `RecipeSummary.fromJson` parses `picture` when present
- `RecipeSummary.fromJson` sets `picture = null` when field absent
- `RecipeSummary.fromJson` sets `picture = null` when field is empty string
- `RecipeDetail.fromJson` parses `picture` and `source` when present
- `RecipeDetail.fromJson` sets both `null` when fields absent
- Cache round-trip: `RecipeSummary` with `picture` encodes → decodes to equal value
- Cache round-trip: `RecipeDetail` with `picture` + `source` encodes → decodes to equal value

#### Widget tests (`test/widget/screens_widget_test.dart` — additions)
- `EqualizerLoadingView` renders without error
- `RecipeTile` with a non-null `picture` renders a `CachedNetworkImage`
- `RecipeTile` with a null `picture` renders the placeholder container
- `RecipeDetailScreen` in loaded state shows recipe name as heading in body
- `RecipeDetailScreen` in loaded state shows source link when `source != null`
- `RecipeDetailScreen` in loaded state does NOT show source link when `source == null`
- Wakelock toggle `TextButton.icon` has label text visible
- Wakelock toggle shows snackbar on tap

#### Integration tests (`integration_test/app_test.dart` — new US5–US6 group)
- **US5**: Recipe list shows tiles (no tag chips visible); tapping navigates to detail with transition
- **US6**: Detail screen shows photo area, recipe name heading, source link; tapping source link does not crash the app

All US1–US4 existing integration tests must continue to pass unchanged.
