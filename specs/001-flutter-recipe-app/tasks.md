---

description: "Task list for Flutter Recipe Companion App"
---

# Tasks: Flutter Recipe Companion App

**Input**: Design documents from `/specs/001-flutter-recipe-app/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Included in every phase — Constitution Principle II (Test-First) is NON-NEGOTIABLE.
Tests are written and confirmed to fail before each implementation block.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story this task belongs to (US1–US4)
- Exact file paths included in every description

## Path Conventions

All paths are relative to the repository root. The Flutter project is initialized at
the repository root (single project structure per plan.md).

---

## Phase 1: Setup

**Purpose**: Create Flutter project and configure all tooling.

- [x] T001 Initialize Flutter project at repository root: `flutter create --org org.niessl --project-name niessl_recipes .` (skip if pubspec.yaml already exists)
- [x] T002 Update pubspec.yaml: set name to `niessl_recipes`, description to "Recipe companion app for dinner.niessl.org"; add dependencies: `flutter_riverpod: ^2.4.0`, `http: ^1.2.0`, `flutter_markdown: ^0.7.0`, `shared_preferences: ^2.3.0`, `wakelock_plus: ^1.2.0`; add dev dependencies: `flutter_lints: ^4.0.0`, `integration_test: {sdk: flutter}`
- [x] T003 [P] Update analysis_options.yaml at repository root: include `package:flutter_lints/flutter.yaml`; add `prefer_const_constructors`, `prefer_const_literals_to_create_immutables` to lints
- [x] T004 [P] Add WAKE_LOCK permission to android/app/src/main/AndroidManifest.xml inside `<manifest>` tag: `<uses-permission android:name="android.permission.WAKE_LOCK"/>`
- [x] T005 Run `flutter pub get` at repository root; verify zero errors and zero warnings

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data layer and shared UI infrastructure that ALL user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

> **Constitution Principle II — Tests FIRST**: Write and confirm tests fail before implementing.

### Tests for Foundational Layer

- [x] T006 [P] Write failing unit tests in test/unit/recipe_service_test.dart: test `RecipeSummary.fromJson` (valid JSON, missing `tags` defaults to empty list), `RecipeDetail.fromJson` (valid, empty `recipe` string), `Tag.fromJson` (valid); test `RecipeService.buildTagMap` (correct URL-to-tag mapping from mock tag index responses); test cache serialization round-trip (encode → decode → equals original)
- [x] T007 [P] Write failing unit tests in test/unit/filter_logic_test.dart: test case-insensitive search (partial match, no match, empty query returns all), test tag OR filter (single tag, multiple tags, no tags selected returns all), test combined search + tag filter (AND across the two), test alphabetical sort

### Foundational Implementation

- [x] T008 [P] Create lib/models/recipe.dart: define `RecipeSummary({required String name, required String url, List<String> tags = const []})` with `fromJson` factory and `copyWith(tags:)` method; define `RecipeDetail({required String name, required String recipe})` with `fromJson` factory; define `Tag({required String name, required String url})` with `fromJson` factory; all classes use `const` constructors
- [x] T009 [P] Create lib/theme.dart: define `appLightTheme` and `appDarkTheme` as `ThemeData` with `useMaterial3: true`, `colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB85C38), brightness: Brightness.light/dark)`; no hardcoded raw colors anywhere — all values derived from `colorScheme`
- [x] T010 [P] Create shared widgets: lib/widgets/loading_view.dart (centered `CircularProgressIndicator.adaptive()` with padding); lib/widgets/error_view.dart (Column: icon + `message` Text + `ElevatedButton('Retry', onPressed: onRetry)`); lib/widgets/empty_state_view.dart (Column: icon + "No recipes found" Text + optional hint Text); all widgets use only theme-derived colors
- [x] T011 Create lib/services/recipe_service.dart with `RecipeService` class: (1) `Future<({List<RecipeSummary> recipes, List<Tag> tags})> fetchAll()` — reads `shared_preferences` cache first (keys: `cache_recipes_index`, `cache_tags_map`), fetches `/recipes/index.json` and `/tags/index.json` in parallel via `http.get` with 10-second timeout, then fetches all 6 tag indices in parallel, builds `Map<String, List<String>>` tagName→[recipeUrl], enriches `RecipeSummary` list with tags, sorts alphabetically by name, writes result to cache; (2) `Future<RecipeDetail> fetchRecipeDetail(String url)` — reads from `shared_preferences` cache (key: `cache_recipe_${base64Url(url)}`), fetches if not cached, writes to cache
- [x] T012 Create lib/providers/providers.dart with Riverpod providers: `recipeServiceProvider` (plain `Provider` returning `RecipeService()`); `appDataProvider` (`FutureProvider` calling `recipeService.fetchAll()`); `recipeDetailProvider` (`FutureProvider.family<RecipeDetail, String>` calling `recipeService.fetchRecipeDetail(url)`); `searchQueryProvider` (`StateProvider<String>` initialized to `''`); `selectedTagsProvider` (`StateProvider<Set<String>>` initialized to `{}`); `filteredRecipesProvider` (`Provider<AsyncValue<List<RecipeSummary>>>` deriving from `appDataProvider`, `searchQueryProvider`, `selectedTagsProvider` — case-insensitive name contains AND (selectedTags.isEmpty OR tags.any(selectedTags.contains)), sorted alphabetically)
- [x] T013 Create lib/main.dart: wrap app in `ProviderScope`; `MaterialApp` with `title: 'Recipes'`, `theme: appLightTheme`, `darkTheme: appDarkTheme`, `themeMode: ThemeMode.system`, `home: const RecipeListScreen()`; import `recipe_list_screen.dart` (file created in Phase 3 — create a stub if needed to keep app compilable during development)

**Checkpoint**: Run `flutter test test/unit/` — all foundational unit tests MUST pass before proceeding.

---

## Phase 3: User Story 1 — Browse the Recipe Collection (Priority: P1) 🎯 MVP

**Goal**: User can see a scrollable recipe list and tap into full recipe detail.

**Independent Test**: Launch app → recipe list appears → tap any recipe → full content shown → back restores scroll. Runnable without US2/US3/US4.

> **Constitution Principle II — Tests FIRST**: Write and confirm integration tests fail before implementing screens.

### Tests for User Story 1

- [x] T014 [P] [US1] Write failing integration tests in integration_test/app_test.dart for US1: (a) app launches and `RecipeTile` widgets appear within 3 seconds; (b) tapping a recipe tile navigates to detail screen showing `MarkdownBody` with ingredients and directions; (c) pressing back from detail restores the list at the same scroll position; (d) run in airplane mode after cache is warm — list still displays

### Implementation for User Story 1

- [x] T015 [P] [US1] Create lib/widgets/recipe_tile.dart: `StatelessWidget` wrapping `ListTile`; `title: Text(recipe.name)` using `Theme.of(context).textTheme.bodyLarge`; `trailing: Row` of small tag label chips (if recipe.tags is non-empty, show up to 2 tags as small Text widgets with theme background); `onTap` callback parameter; no hardcoded colors or sizes
- [x] T016 [US1] Create lib/screens/recipe_list_screen.dart: `ConsumerWidget`; `Scaffold` with `AppBar(title: Text('Recipes'))`; body watches `filteredRecipesProvider`; `AsyncValue.when`: loading → `LoadingView()`, error → `ErrorView(message: ..., onRetry: () => ref.invalidate(appDataProvider))`, data → `RefreshIndicator(onRefresh: () async => ref.invalidate(appDataProvider), child: ListView.builder(controller: _scrollController, itemCount: recipes.length, itemBuilder: (_, i) => RecipeTile(recipe: recipes[i], onTap: () => Navigator.push(...RecipeDetailScreen(url: recipes[i].url, name: recipes[i].name)))))`; `ScrollController` stored in widget state for scroll restoration
- [x] T017 [US1] Create lib/screens/recipe_detail_screen.dart: `ConsumerWidget` receiving `url` and `name` as constructor parameters; `Scaffold` with `AppBar(title: Text(name))`; body watches `recipeDetailProvider(url)`; `AsyncValue.when`: loading → `LoadingView()`, error → `ErrorView(message: ..., onRetry: () => ref.invalidate(recipeDetailProvider(url)))`, data → `SingleChildScrollView(padding: EdgeInsets.all(16), child: MarkdownBody(data: detail.recipe, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))))`
- [x] T018 [US1] Wire navigation in lib/screens/recipe_list_screen.dart: `RecipeTile.onTap` calls `Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(url: recipe.url, name: recipe.name)))`; `ScrollController` captures offset before push and scrolls to it after `await Navigator.push` returns

**Checkpoint**: Run `flutter test integration_test/app_test.dart` — US1 scenarios MUST pass independently.

---

## Phase 4: User Story 2 — Search for a Specific Recipe (Priority: P2)

**Goal**: User types in a search field and the recipe list filters in real time.

**Independent Test**: Type partial name → list filters immediately → clear → list restores. No tag filter needed.

### Tests for User Story 2

- [x] T019 [P] [US2] Add failing integration tests for US2 to integration_test/app_test.dart: (a) entering "pan" in search field shows only recipes whose names contain "pan" (case-insensitive); (b) entering "zzzzz" shows `EmptyStateView`; (c) clearing the search field restores the full recipe list

### Implementation for User Story 2

- [x] T020 [P] [US2] Create lib/widgets/search_bar_widget.dart: `ConsumerWidget`; `TextField` with `InputDecoration(hintText: 'Search recipes...', prefixIcon: Icon(Icons.search), suffixIcon: query.isNotEmpty ? IconButton(icon: Icon(Icons.clear), onPressed: () => ref.read(searchQueryProvider.notifier).state = '') : null)`; `onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v`; uses only theme-derived decoration colors
- [x] T021 [US2] Integrate SearchBarWidget into lib/screens/recipe_list_screen.dart: add `SearchBarWidget()` as the first item in a `Column` above the `ListView.builder` (or use `SliverList` with a header); ensure `filteredRecipesProvider` is already wired (it already consumes `searchQueryProvider`); show `EmptyStateView(hint: 'Try a different search term')` when filtered list is empty

**Checkpoint**: Verify US2 works independently — search with no tags selected should filter the full list.

---

## Phase 5: User Story 3 — Filter Recipes by Category (Priority: P3)

**Goal**: User taps category chips to filter the recipe list; multiple chips use OR logic.

**Independent Test**: Tap "indian" chip → only Indian recipes shown. Tap "sweet" also → recipes in either category shown. Deselect all → full list. Testable without US2 active.

### Tests for User Story 3

- [x] T022 [P] [US3] Add failing integration tests for US3 to integration_test/app_test.dart: (a) all 6 tag chips are visible; (b) tapping "indian" chip shows only the 10 Indian recipes; (c) tapping "sweet" additionally shows recipes from either tag (OR); (d) tapping both chips again to deselect restores the full list; (e) with search "masala" active and "indian" tag selected — only "Chana Masala", "Paneer Butter Masala", etc. are shown (intersection of both filters)

### Implementation for User Story 3

- [x] T023 [P] [US3] Create lib/widgets/tag_chip_bar.dart: `ConsumerWidget`; `SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, children: tags.map((tag) => Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: FilterChip(label: Text(tag.name), selected: selectedTags.contains(tag.name), onSelected: (v) => ref.read(selectedTagsProvider.notifier).update((s) => v ? {...s, tag.name} : s.difference({tag.name}))))).toList()))`; uses `Theme.of(context).colorScheme` for chip colors
- [x] T024 [US3] Integrate TagChipBar into lib/screens/recipe_list_screen.dart: add `TagChipBar()` between `SearchBarWidget` and the `ListView.builder`; `filteredRecipesProvider` already combines both filters (no provider changes needed); confirm `EmptyStateView` shows when both filters combine to zero results with hint 'Try removing some filters'

**Checkpoint**: Verify US3 works independently — tag filter with no search term should work correctly.

---

## Phase 6: User Story 4 — Keep the Screen On While Cooking (Priority: P4)

**Goal**: User enables a toggle in the recipe detail view to prevent screen sleep.

**Independent Test**: Open any recipe → enable toggle → screen stays on → back → normal timeout resumes.

### Tests for User Story 4

- [x] T025 [P] [US4] Add failing integration tests for US4 to integration_test/app_test.dart: (a) recipe detail screen has a wakelock toggle icon button in the AppBar; (b) tapping it changes its icon state (visual feedback); (c) navigating back from detail screen while wakelock is active does not throw an error (tests that `dispose()` calls `WakelockPlus.disable()`)

### Implementation for User Story 4

- [x] T026 [US4] Add wakelock toggle to lib/screens/recipe_detail_screen.dart: convert to `StatefulConsumerWidget` (or use local state via `useState` if hooks are available); add `bool _keepAwake = false` state; add `IconButton` to `AppBar.actions`: `icon: Icon(_keepAwake ? Icons.lightbulb : Icons.lightbulb_outline)`, `tooltip: _keepAwake ? 'Screen will stay on' : 'Keep screen on'`, `onPressed: () async { setState(() => _keepAwake = !_keepAwake); if (_keepAwake) { await WakelockPlus.enable(); } else { await WakelockPlus.disable(); } }`; override `dispose()` to call `WakelockPlus.disable()` unconditionally

**Checkpoint**: All four user stories should now be independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, quality gates, and final validation.

- [x] T027 [P] Add `Semantics` labels to interactive widgets: `RecipeTile` — wrap with `Semantics(label: '${recipe.name}, tap to view recipe')`; `TagChipBar` chips — `FilterChip` already announces selected state; verify tooltip text; `SearchBarWidget` — `TextField` already has hint; add explicit `semanticsLabel` to clear button; wakelock `IconButton` — `tooltip` already provides label; verify with TalkBack/VoiceOver
- [x] T028 [P] Run `flutter analyze` at repository root; fix ALL reported issues (zero warnings policy per Constitution Principle I)
- [x] T029 [P] Run `dart format --set-exit-if-changed .` at repository root; fix ALL formatting issues (zero diffs required per Constitution Principle I)
- [x] T030 Run `flutter test --coverage` at repository root; check `coverage/lcov.info`; verify ≥80% line coverage on `lib/`; add targeted unit or widget tests for any uncovered public logic until threshold is met
- [x] T031 Run full integration test suite on Android emulator: `flutter test integration_test/app_test.dart`; all US1–US4 scenarios MUST pass
- [ ] T032 [P] Run full integration test suite on iOS simulator (macOS only): `flutter test integration_test/app_test.dart`; all US1–US4 scenarios MUST pass
- [ ] T033 Manually validate all scenarios in quickstart.md on a connected physical device or high-fidelity emulator; confirm dark mode, offline mode, pull-to-refresh, and wakelock all behave correctly

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 completion — **BLOCKS all user stories**
- **Phase 3 (US1)**: Depends on Phase 2 — MVP deliverable
- **Phase 4 (US2)**: Depends on Phase 2; builds on Phase 3 screens (but independently testable)
- **Phase 5 (US3)**: Depends on Phase 2; builds on Phase 3 screens (but independently testable)
- **Phase 6 (US4)**: Depends on Phase 3 (needs RecipeDetailScreen to exist)
- **Phase 7 (Polish)**: Depends on all user story phases being complete

### User Story Dependencies

- **US1 (P1)**: Directly after Foundational — no story dependencies
- **US2 (P2)**: Directly after Foundational — `SearchBarWidget` + `searchQueryProvider` are new, independent of US1 widgets (though integrated into same screen)
- **US3 (P3)**: Directly after Foundational — `TagChipBar` + `selectedTagsProvider` are new, independent of US2 widgets
- **US4 (P4)**: Requires `RecipeDetailScreen` from US1 to exist

### Within Each Phase

1. Tests MUST be written and confirmed failing before implementation tasks
2. Models before services (T008 → T011)
3. Providers after models and service (T012 after T008, T011)
4. main.dart after providers (T013 after T012)
5. Widgets before screens (T015, T016 in Phase 3 — RecipeTile before RecipeListScreen makes sense, but both can start after foundational is done)

### Parallel Opportunities

#### Phase 2 — Parallel within Foundational
```
T006 (model tests)      ── can run simultaneously
T007 (filter tests)     ──
T008 (models)           ── can run simultaneously after T006 exists
T009 (theme)            ──
T010 (shared widgets)   ──
                 ↓
T011 (RecipeService)    ── sequential (needs T008 models)
T012 (providers)        ── sequential (needs T008, T011)
T013 (main.dart)        ── sequential (needs T012)
```

#### Phase 3 — Parallel within US1
```
T014 (integration tests) ── can run simultaneously as T015
T015 (RecipeTile widget) ──
                 ↓
T016 (RecipeListScreen)  ── sequential (needs T015)
T017 (RecipeDetailScreen)── can run in parallel with T016
                 ↓
T018 (wire navigation)   ── sequential (needs T016 + T017)
```

#### Phases 4–6 — Stories in Parallel (if multiple developers)
```
After Phase 2 completes:
  Developer A: Phase 3 (US1) → Phase 6 (US4)
  Developer B: Phase 4 (US2) → Phase 5 (US3)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational — CRITICAL, blocks everything
3. Complete Phase 3: US1 (Browse + Detail)
4. **STOP and VALIDATE**: Run integration tests, manually validate quickstart.md US1 scenarios
5. App is now demonstrable end-to-end

### Incremental Delivery

1. Setup + Foundational → Core data layer ready
2. Add US1 → Recipe list + detail → **MVP demo ready**
3. Add US2 → Search → test independently → demo
4. Add US3 → Tag filter → test independently → demo
5. Add US4 → Wakelock → test independently → demo
6. Polish → lint, format, coverage, accessibility → merge-ready

### Single Developer Sequence

```
Phase 1 → Phase 2 → Phase 3 (US1) → Phase 4 (US2) → Phase 5 (US3) → Phase 6 (US4) → Phase 7
```

At each user story phase end: run tests, validate independently, commit.

---

## Notes

- `[P]` tasks affect different files — they can be worked in parallel by separate developers
- Constitution Principle II is non-negotiable: every `[P]` test task MUST be written and confirmed failing before the corresponding implementation tasks begin
- All `lib/` code MUST use `Theme.of(context)` values — zero raw `Color(0x...)` literals in widget files
- `RecipeService` fetches from `https://dinner.niessl.org` — an internet connection is required for non-cached flows; use a mock `http.Client` in unit tests
- `integration_test/` directory at repo root (not `test/integration/`) — required by the `integration_test` SDK package for device execution
- Pull-to-refresh calls `ref.invalidate(appDataProvider)` which re-triggers the `FutureProvider` and refreshes all 8 remote indices
- `WakelockPlus.disable()` MUST be called in `dispose()` of `RecipeDetailScreen` — this is a safety net for any navigation path that skips the toggle tap
