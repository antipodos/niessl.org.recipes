# Tasks: UX Refinement — Splash, Grid, Images & Detail

**Input**: Design documents from `/specs/003-ux-refinement/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, quickstart.md ✓

**Tests**: Constitution Principle II is NON-NEGOTIABLE — tests MUST be written and confirmed failing before each implementation block.

**Organization**: Phases ordered by dependency. US1 (splash) and US4 (detail) are independent. US3 (prefetch) depends on US2 (grid) as they share `recipe_list_screen.dart`.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup — Native Splash Assets

**Purpose**: Configure and generate the native splash screen (shown before Flutter initialises). Zero runtime overhead — dev dependency only.

- [X] T001 Add `flutter_native_splash: ^5.0.0` to `dev_dependencies` in `pubspec.yaml` and add config block: `color: "#F5EFE7"`, `color_dark: "#2B1F1A"`, `android_12` with same colours, `android: true`, `ios: true`, `fullscreen: false`
- [X] T002 Run `flutter pub get` to install the new dev dependency
- [X] T003 Run `dart run flutter_native_splash:create` to generate native launch screen files in `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/`

**Checkpoint**: Native splash assets generated. Running the app on device shows warm cream background immediately on launch instead of the Flutter logo.

---

## Phase 2: Foundational — RecipeDetailScreen Tags Parameter

**Purpose**: Add the `tags` parameter to `RecipeDetailScreen` *before* US2 and US4 work begins. US2 passes it during navigation; US4 uses it to render chips. Both phases require it to compile.

**⚠️ CRITICAL**: US2 and US4 cannot compile without this.

- [X] T004 Write failing widget test in `test/widget/screens_widget_test.dart` — verify `RecipeDetailScreen` can be constructed with `tags: ['Italian', 'Vegan']`; test fails because `tags` parameter does not yet exist (compile error)
- [X] T005 Add `final List<String> tags` parameter (default `const []`) to `RecipeDetailScreen` constructor in `lib/screens/recipe_detail_screen.dart`; no UI changes yet — parameter is accepted but ignored
- [X] T006 Run `flutter test` to confirm T004 tests pass

**Checkpoint**: `RecipeDetailScreen` accepts `tags` parameter. All existing tests still pass.

---

## Phase 3: User Story 1 — Branded Splash Screen (Priority: P1) 🎯 MVP

**Goal**: Replace the default Flutter launch screen with the app's own branded animated splash that plays while data loads, then transitions to the recipe list.

**Independent Test**: Cold-launch the app — branded animation plays, recipe list appears, back navigation from list does not return to splash.

### Tests for User Story 1 ⚠️ Write FIRST — must FAIL before T009

- [X] T007 [US1] Write failing widget tests for `SplashScreen` in `test/widget/screens_widget_test.dart`:
  - (1) `SplashScreen` renders `EqualizerLoadingView` when `appDataProvider` is in loading state
  - (2) `SplashScreen` renders `ErrorView` with retry button when `appDataProvider` errors
  - (3) `SplashScreen` navigates to `RecipeListScreen` when `appDataProvider` returns data (use `mockNavigatorObserver` or verify `find.byType(RecipeListScreen)` after `pumpAndSettle`)
  - Tests FAIL because `SplashScreen` class does not exist (import error)
- [X] T008 [US1] Confirm T007 tests fail with compile error (`SplashScreen` not found)

### Implementation for User Story 1

- [X] T009 [US1] Create `lib/screens/splash_screen.dart` — `ConsumerStatefulWidget`; `Scaffold(backgroundColor: Theme.of(context).colorScheme.surface)` (warm cream in light mode); body is `Center(child: const EqualizerLoadingView())`; use `ref.listen(appDataProvider, (_, next) { next.whenData((_) => Navigator.pushReplacement(... RecipeListScreen())); next.whenError(...)  })` to navigate on completion; show `ErrorView` on error state
- [X] T010 [US1] Update `lib/main.dart` — add `import 'screens/splash_screen.dart'`; change `home: const RecipeListScreen()` to `home: const SplashScreen()`
- [X] T011 [US1] Run `flutter test` to confirm T007 tests pass

**Checkpoint**: US1 complete. Cold launch shows branded animation. Back-stack does not include splash.

---

## Phase 4: User Story 2 — Square Two-Column Grid (Priority: P2)

**Goal**: Replace the single-column 1.6:1 tile list with a 2-column square grid. Recipe names are visually larger with better contrast. Tags are passed through for navigation to detail screen.

**Independent Test**: Open recipe list — 2 tiles per row, square aspect ratio, readable name text with gradient overlay.

### Tests for User Story 2 ⚠️ Write FIRST — must FAIL before T015

- [X] T012 [US2] Write failing widget tests in `test/widget/screens_widget_test.dart`:
  - (1) `RecipeTile` renders with `AspectRatio` value of `1.0` (not `1.6`)
  - (2) `RecipeTile` recipe name `Text` uses `titleMedium` style (not `titleSmall`)
  - (3) `RecipeListScreen` with data renders `GridView` (not `ListView`)
  - (4) `RecipeListScreen` navigates to `RecipeDetailScreen` with `tags` non-null on tile tap (verify via `mockNavigatorObserver` or `find.byType(RecipeDetailScreen)` after tap)
  - Tests FAIL because `AspectRatio` is still `1.6`, `titleSmall` is still used, and `ListView` is still present
- [X] T013 [US2] Confirm T012 tests fail

### Implementation for User Story 2

- [X] T014 [US2] Update `lib/widgets/recipe_tile.dart` — change `AspectRatio(aspectRatio: 1.6)` to `AspectRatio(aspectRatio: 1.0)`; change `Text` style from `textTheme.titleSmall` to `textTheme.titleMedium`; no other changes (gradient, Hero, CachedNetworkImage remain unchanged)
- [X] T015 [US2] Update `lib/screens/recipe_list_screen.dart` — replace `ListView.builder` (and its outer `RefreshIndicator`) with `GridView.builder` inside `RefreshIndicator`; grid delegate: `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0, crossAxisSpacing: 8, mainAxisSpacing: 8)`; add `padding: const EdgeInsets.all(8)` to `GridView`; update navigation call to pass `tags: recipes[i].tags` to `RecipeDetailScreen`
- [X] T016 [US2] Run `flutter test` to confirm T012 tests pass

**Checkpoint**: US2 complete. Recipe list shows 2-column square grid with larger recipe names.

---

## Phase 5: User Story 3 — Fast Image Browsing (Priority: P3)

**Goal**: Recipe photos load instantly on scroll-back and after filter changes by prefetching the first 10 images when the list loads.

**Independent Test**: Scroll the recipe list down then back up — no placeholder shimmer visible for already-seen images.

**Depends on**: T015 (US2) — adds to the same `recipe_list_screen.dart` data branch

### Tests for User Story 3 ⚠️ Write FIRST — must FAIL before T018

- [X] T017 [US3] Write failing unit test in `test/unit/prefetch_test.dart` — test `@visibleForTesting` function `pickRecipePictureUrls(List<RecipeSummary> recipes, {int limit})` exported from `lib/screens/recipe_list_screen.dart`:
  - Returns at most `limit` (default 10) URLs
  - Excludes recipes with `null` picture
  - Returns URLs in original list order
  - Handles fewer than 10 recipes gracefully
  - Test FAILS because `pickRecipePictureUrls` does not exist yet (compile error)

### Implementation for User Story 3

- [X] T018 [US3] Update `lib/screens/recipe_list_screen.dart` — add `import 'package:cached_network_image/cached_network_image.dart'`; add `@visibleForTesting` top-level function `pickRecipePictureUrls(List<RecipeSummary> recipes, {int limit = 10})` returning first `limit` non-null picture URLs; add `bool _prefetchDone = false` state field; in the `data:` branch, after rendering, call `_prefetchImages(recipes)` the first time via `if (!_prefetchDone) { _prefetchDone = true; WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { for (final url in pickRecipePictureUrls(recipes)) { precacheImage(CachedNetworkImageProvider(url), context).ignore(); } } }); }`
- [X] T019 [US3] Run `flutter test` to confirm T017 tests pass

**Checkpoint**: US3 complete. Image prefetch runs once on first data load.

---

## Phase 6: User Story 4 — Recipe Name and Tags on Detail Screen (Priority: P4)

**Goal**: Recipe name appears as a gradient overlay at the bottom of the hero photo. Recipe tags appear as tappable FilterChips above the source attribution. Standalone name heading below photo is removed.

**Independent Test**: Open a tagged recipe — name is overlaid on photo, tags appear below photo, no duplicate name heading.

### Tests for User Story 4 ⚠️ Write FIRST — must FAIL before T022

- [X] T020 [US4] Write failing widget tests in `test/widget/screens_widget_test.dart`:
  - (1) `RecipeDetailScreen(tags: ['Italian'])` loaded state — `find.text('Italian')` finds a `FilterChip` descendant (`find.widgetWithText(FilterChip, 'Italian')` works)
  - (2) `RecipeDetailScreen(tags: [])` loaded state — `find.byType(FilterChip)` finds nothing; no empty tag row
  - (3) `RecipeDetailScreen(tags: ['Italian'])` loaded state — recipe name appears inside the `Hero` subtree (use `find.descendant(of: find.byType(Hero), matching: find.text(recipeName))`)
  - (4) `RecipeDetailScreen(tags: ['Italian'])` loaded state — standalone `headlineMedium` name `Text` below photo is GONE (no `Text` with `headlineMedium` style outside the `Hero`)
  - Tests FAIL because no `FilterChip`, no name overlay in Hero, and standalone `headlineMedium` heading still present
- [X] T021 [US4] Confirm T020 tests fail

### Implementation for User Story 4

- [X] T022 [US4] Update `lib/screens/recipe_detail_screen.dart`:
  - **Name overlay**: Inside the existing `Hero` `Stack`, add two new `Positioned(bottom: 0)` children — (a) a `Container` with `LinearGradient(transparent → colorScheme.scrim.withValues(alpha: 0.65))` at height 100; (b) a `Padding(EdgeInsets.symmetric(horizontal:16, vertical:12))` containing `Text(widget.name, style: textTheme.headlineSmall?.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)`
  - **Remove heading**: Delete the `Padding(child: Text(widget.name, style: theme.textTheme.headlineMedium))` block that currently appears below the Hero
  - **Tags section**: In the `data:` column, between the `Hero` and the source attribution `Padding`, add `if (widget.tags.isNotEmpty) Padding(EdgeInsets.fromLTRB(16, 12, 16, 0), child: Wrap(spacing: 8, runSpacing: 6, children: widget.tags.map((tag) => FilterChip(label: Text(tag), onSelected: (_) { ref.read(selectedTagsProvider.notifier).update((s) => {...s, tag}); Navigator.pop(context); })).toList()))`
- [X] T023 [US4] Run `flutter test` to confirm T020 tests pass

**Checkpoint**: US4 complete. Detail screen shows name on photo, tags below photo, no duplicate heading.

---

## Phase 7: Polish & Integration

**Purpose**: Integration tests, quality gates, and final checkpoint commit.

- [X] T024 Update `integration_test/app_test.dart` — add/update scenarios:
  - US1: cold-launch shows `EqualizerLoadingView` then recipe list; no splash on back from detail
  - US2: recipe list has `GridView`; at least 2 tiles visible per row in portrait
  - US4: detail screen name overlay visible inside Hero; FilterChips shown for tagged recipes; tapping a chip returns to filtered list
- [X] T025 [P] Run `flutter test` — all unit + widget tests pass (0 failures)
- [ ] T026 Run integration tests on emulator (`flutter test integration_test/app_test.dart -d <emulator>`) — all scenarios pass
- [X] T027 [P] Run `flutter test --coverage` — verify ≥80% line coverage on all changed files: `splash_screen.dart`, `recipe_tile.dart`, `recipe_list_screen.dart`, `recipe_detail_screen.dart`, `main.dart`
- [X] T028 [P] Run `dart format . --set-exit-if-changed` — 0 changes
- [X] T029 [P] Run `flutter analyze` — no issues
- [ ] T030 Commit Phase checkpoint: all T001–T029 complete, all quality gates green

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS** US2 and US4 navigation compilation
- **Phase 3 (US1)**: Depends on Phase 1 only — independent of US2/US3/US4
- **Phase 4 (US2)**: Depends on Phase 2 — needs `tags` parameter on `RecipeDetailScreen`
- **Phase 5 (US3)**: Depends on Phase 4 (T015) — shares `recipe_list_screen.dart`
- **Phase 6 (US4)**: Depends on Phase 2 — uses `tags` parameter; independent of US2/US3
- **Phase 7 (Polish)**: Depends on all phases complete

### User Story Dependencies

- **US1 (P1)**: Independent — only touches `splash_screen.dart` (new) and `main.dart`
- **US2 (P2)**: Needs Phase 2 complete — touches `recipe_tile.dart` and `recipe_list_screen.dart`
- **US3 (P3)**: Needs US2 complete — additive change to `recipe_list_screen.dart`
- **US4 (P4)**: Needs Phase 2 complete — touches `recipe_detail_screen.dart` only

### Parallel Opportunities

- US1 and US2 can start in parallel after Phase 2 (different files)
- US1 and US4 can proceed in parallel (completely different files)
- T025, T027, T028, T029 (Polish) can run in parallel

---

## Parallel Example: US1 + US4 after Phase 2

```
After T006 (Phase 2 checkpoint):
  → Start T007–T011 (US1: splash_screen.dart + main.dart)   [in parallel with]
  → Start T020–T023 (US4: recipe_detail_screen.dart)
  → Start T012–T016 (US2: recipe_tile.dart + recipe_list_screen.dart)

After US2 complete (T016):
  → Start T017–T019 (US3: additive to recipe_list_screen.dart)
```

---

## Implementation Strategy

### MVP First (US1 — Splash Screen Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T006)
3. Complete Phase 3: US1 (T007–T011)
4. **STOP and VALIDATE**: App cold-launches with branded animation
5. Proceed to US2 if splash is accepted

### Incremental Delivery

1. Phase 1 + Phase 2 → foundation ready
2. US1 → branded splash, independently demonstrable
3. US2 → square grid, independently demonstrable
4. US3 → image prefetch (enhancement, no visible UI change — test by scrolling)
5. US4 → detail name overlay + tags, independently demonstrable

---

## Notes

- `[P]` tasks touch different files with no cross-task dependencies
- `[US1]`–`[US4]` maps each task to its user story for traceability
- Constitution Principle II: never skip the "confirm tests fail" step
- `flutter_native_splash` is dev-only — no APK size impact; run `dart run flutter_native_splash:create` once after config
- `pickRecipePictureUrls` must be `@visibleForTesting` and at file scope (not inside the State class) to be unit-testable
- After T003 (native splash generation), add the generated Android/iOS files to git — they are required for correct native launch behaviour
