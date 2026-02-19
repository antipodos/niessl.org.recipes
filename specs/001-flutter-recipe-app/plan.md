# Implementation Plan: Flutter Recipe Companion App

**Branch**: `001-flutter-recipe-app` | **Date**: 2026-02-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-flutter-recipe-app/spec.md`

## Summary

Build a clean, modern, cross-platform Flutter mobile app (iOS + Android) that
consumes the existing dinner.niessl.org static JSON API to display, search, and
filter ~89 recipes. The app has 2 screens, uses Riverpod 2.x for state management,
and renders recipe Markdown content. User emphasis: simple, beautiful, not overengineered.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.19+
**Primary Dependencies**: flutter_riverpod ^2.4.0, http ^1.2.0, flutter_markdown ^0.7.0, shared_preferences ^2.3.0, wakelock_plus ^1.2.0
**Storage**: shared_preferences (local JSON cache; remote API is the source of truth)
**Testing**: flutter_test (unit + widget), integration_test (US acceptance flows)
**Target Platform**: iOS 16+ and Android API 24+ (mobile only)
**Project Type**: mobile (single Flutter project at repository root)
**Performance Goals**: Cold start to interactive list ≤3 s; search filter <16 ms/frame; detail screen load ≤2 s on WiFi
**Constraints**: Offline-capable (cache-first), no authentication, no backend, no user accounts
**Scale/Scope**: ~89 recipes, 6 tags, 2 screens, 5 dependencies, single developer

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Code Quality ✅ PASS

- Single Flutter project; each file has one clearly stated responsibility (SRP).
- `flutter_lints` enforces code standards; `dart format` enforces consistent formatting.
- No commented-out code or dead code policy enforced in PR review.
- All public interfaces named for intent (e.g., `RecipeService`, `filteredRecipesProvider`).
- Flat structure (no premature repository/use-case layers) — Rule of Three applied:
  abstraction only if the same pattern appears 3+ times.
- All 5 added dependencies are official or well-maintained packages reviewed in research.md.

### II. Test-First ✅ PASS

- Tests written before implementation in every task group (tasks.md enforces this).
- Unit tests cover filter logic, cache serialization, and service parsing.
- Integration tests cover all 4 user story acceptance scenarios from spec.md.
- Tests are independent: no shared mutable state between test cases.
- ≥80% line coverage required on changed code (CI gate).

### III. User Experience Consistency ✅ PASS

- Material Design 3 is the single enforced design system (`useMaterial3: true`).
- All colours, spacing, and typography come from `ThemeData`; no hard-coded values in widgets.
- Loading, error, and empty states are shared widgets (`loading_view.dart`, `error_view.dart`,
  `empty_state_view.dart`) — consistent across all screens.
- Accessibility: `Semantics` widgets on interactive elements; WCAG 2.1 AA target.
- Dark mode: `ThemeMode.system` automatically applied.

### IV. Performance by Default ✅ PASS (mobile adaptation)

> **Exception documented**: Lighthouse/LCP/TTI/CLS are web-specific metrics. This is a
> native mobile app. The following mobile-equivalent commitments apply instead. Exception
> is permanent for this project type.

- **Cold start ≤3 s**: Cache-first loading — cached data shown instantly; network refresh
  runs in background.
- **Search <16 ms/frame**: Client-side in-memory filtering of 89 items; no network call.
- **Detail load ≤2 s**: Single ~1–2 KB JSON fetch per recipe on demand.
- **No blocking main isolate**: All HTTP and cache I/O is async (`async/await`).
- **ListView.builder**: Lazy rendering — only visible tiles are built.
- **CI gate**: Profile-mode build on each PR; DevTools CPU profiler must show no jank on
  list scroll (no frame budget violations).

## Project Structure

### Documentation (this feature)

```text
specs/001-flutter-recipe-app/
├── plan.md              # This file
├── research.md          # Phase 0 — package decisions, API structure
├── data-model.md        # Phase 1 — entities, loading sequence, cache schema
├── quickstart.md        # Phase 1 — setup, run, test, manual validation
├── contracts/
│   └── api-contracts.md # Phase 1 — endpoint schemas, error handling
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/
├── main.dart                       # App entry point; MaterialApp; router
├── theme.dart                      # ThemeData — Material 3, warm seed color, dark mode
├── models/
│   └── recipe.dart                 # RecipeSummary, RecipeDetail, Tag; fromJson factories
├── services/
│   └── recipe_service.dart         # HTTP fetching + shared_preferences cache logic
├── providers/
│   └── providers.dart              # All Riverpod providers (recipes, tags, filter state)
├── screens/
│   ├── recipe_list_screen.dart     # US1 list + US2 search + US3 tag filter
│   └── recipe_detail_screen.dart   # US1 detail view + US4 wakelock toggle
└── widgets/
    ├── recipe_tile.dart            # Single list item
    ├── tag_chip_bar.dart           # Horizontal scrolling tag filter chips
    ├── search_bar_widget.dart      # Search text field
    ├── loading_view.dart           # Shared loading indicator
    ├── error_view.dart             # Shared error + retry button
    └── empty_state_view.dart       # Shared "no results" state

test/
├── unit/
│   ├── recipe_service_test.dart    # Mocked HTTP; cache read/write; JSON parsing
│   └── filter_logic_test.dart     # Search (case-insensitive), tag OR logic, combined filter
└── integration/
    └── app_test.dart               # US1–US4 full acceptance flows (device/emulator)

android/
└── app/src/main/AndroidManifest.xml  # WAKE_LOCK permission (wakelock_plus)
ios/
└── Runner/Info.plist                 # No extra config needed for wakelock_plus on iOS
pubspec.yaml                          # Project manifest with all dependencies
analysis_options.yaml                 # Linting — flutter_lints
```

**Structure Decision**: Single Flutter project at repository root. No separate packages,
no backend, no monorepo. Two screens, one service, one providers file, shared widgets.
Deliberately flat to honour the "keep it simple, not overengineered" constraint and the
Rule of Three from Constitution Principle I.

## Complexity Tracking

> No Constitution violations — no entries required.

## Phase 0: Research Summary

All NEEDS CLARIFICATION items resolved. See [research.md](research.md) for full details.

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | Riverpod 2.x (no codegen) | Simple, testable, reactive |
| HTTP client | `http` ^1.2.0 | GET-only; minimal dependencies |
| Markdown rendering | `flutter_markdown` ^0.7.0 | Official; works out of the box |
| Local cache | `shared_preferences` ^2.3.0 | Sufficient for <100 KB JSON data |
| Screen wakelock | `wakelock_plus` ^1.2.0 | Cross-platform standard |
| Typography | Material 3 system fonts | No extra dependency |
| Tag loading | All 6 tag indices on startup | Instant client-side filtering |

## Phase 1: Design Summary

### Data Model

Three entities: `RecipeSummary` (list item + tags), `RecipeDetail` (full markdown),
`Tag` (filter label). Tag membership built at load time — recipe URL is the join key.

Full details: [data-model.md](data-model.md)

### Loading Sequence

```
startup
  ├─ serve cached AppData immediately (if available)
  ├─ [parallel] fetch /recipes/index.json
  ├─ [parallel] fetch /tags/index.json
  └─ on both complete:
       [parallel × 6] fetch each tag's recipe list
       build tag→URL map
       enrich RecipeSummary with tags, sort alphabetically
       update UI; persist to shared_preferences
```

### Screen Architecture

**RecipeListScreen** — hosts US1 (browse), US2 (search), US3 (tag filter)
```
SliverAppBar: "Recipes"
SearchBarWidget
TagChipBar (FilterChip row, horizontal scroll)
Body (AsyncValue.when):
  loading → LoadingView
  error   → ErrorView + retry
  data    → ListView.builder of RecipeTile
             + RefreshIndicator (pull-to-refresh)
```

**RecipeDetailScreen** — hosts US1 (detail), US4 (wakelock)
```
AppBar: recipe.name | actions: [WakelockToggleButton]
Body (AsyncValue.when):
  loading → LoadingView
  error   → ErrorView
  data    → SingleChildScrollView > Padding > MarkdownBody
```

### API Contracts

4 GET endpoints. All public, static JSON. 10-second timeout. Cache-first fallback.

Full details: [contracts/api-contracts.md](contracts/api-contracts.md)

### pubspec.yaml (relevant excerpt)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  http: ^1.2.0
  flutter_markdown: ^0.7.0
  shared_preferences: ^2.3.0
  wakelock_plus: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  integration_test:
    sdk: flutter
```

### Constitution Check (Post-Design) ✅ All PASS

No new violations introduced by the design. Flat structure, single service, shared
widget pattern, and Material 3 theme tokens all satisfy Principles I–IV.

## Quickstart

See [quickstart.md](quickstart.md) for full setup, run, test, and manual validation
instructions for each user story.
