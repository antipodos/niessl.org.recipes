# Tasks: UX Polish & Visual Refinement

**Input**: Design documents from `/specs/002-ux-polish/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅
**Branch**: `002-ux-polish`

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no task dependencies)
- **[Story]**: Which user story this task belongs to
- All file paths are relative to the repository root

---

## Phase 1: Setup

**Purpose**: Add new package dependencies and required native configuration.

- [x] T001 Add `cached_network_image: ^3.3.0` and `url_launcher: ^6.2.0` to the `dependencies` section of `pubspec.yaml`; run `flutter pub get` and confirm zero errors
- [x] T002 Add `<queries>` block inside `<manifest>` (before `<application>`) in `android/app/src/main/AndroidManifest.xml` for Android 11+ url_launcher support: `<queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent></queries>`

---

## Phase 2: Foundational — Data Model & Theme

**Purpose**: Updated models and warm theme are shared by ALL user stories. Must be complete before any user story implementation begins.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

### Tests for Foundational Layer (write first — must FAIL before T006+)

- [x] T003 Write failing unit tests in `test/unit/recipe_service_test.dart`: `RecipeSummary.fromJson` with `picture` present sets the field; with `picture` absent → null; with `picture: ''` → null; `RecipeSummary` cache round-trip (encode → decode) preserves `picture` value
- [x] T004 [P] Write failing unit tests in `test/unit/recipe_service_test.dart`: `RecipeDetail.fromJson` with `picture` and `source` present sets both; with both absent → both null; `RecipeDetail` cache round-trip preserves `picture` and `source`
- [x] T005 Run `flutter test test/unit/recipe_service_test.dart` and confirm T003/T004 tests **fail** (expected — models not yet updated)

### Implementation

- [x] T006 Update `RecipeSummary` class in `lib/models/recipe.dart`: add `final String? picture` field; update `fromJson` to read `picture` (treat absent or empty string as null); update `toJson` to include `picture`; update `copyWith` to accept `picture`
- [x] T007 [P] Update `RecipeDetail` class in `lib/models/recipe.dart`: add `final String? picture` and `final String? source` fields; update `fromJson` (treat absent or empty as null for both); update `toJson` to include both
- [x] T008 Verify `RecipeService._fetchAndCache()` in `lib/services/recipe_service.dart`: confirm that `encodeRecipes`/`decodeRecipes` round-trips are driven by `RecipeSummary.toJson`/`fromJson` (no service-level changes expected); update if any manual field mapping is present that would silently drop `picture`
- [x] T009 [P] Verify `RecipeService.fetchRecipeDetail()` in `lib/services/recipe_service.dart`: confirm that `detail.toJson()` / `RecipeDetail.fromJson` drives cache serialisation (no service-level changes expected); update if any manual field mapping drops `picture` or `source`
- [x] T010 Update `lib/theme.dart`: add named constants `const _warmCreamSurface = Color(0xFFF5EFE7)` and `const _warmDarkSurface = Color(0xFF2B1F1A)`; update `appLightTheme` to append `.copyWith(surface: _warmCreamSurface)` to `ColorScheme.fromSeed(...)`; update `appDarkTheme` to append `.copyWith(surface: _warmDarkSurface)`
- [x] T011 Run `flutter test test/unit/` — confirm all unit tests pass (T003/T004 tests are now green); run `flutter analyze` — zero issues
- [x] T012 Run `dart format --set-exit-if-changed .` — zero changes

**Checkpoint**: Models and theme are updated. All unit tests green. User story implementation can begin.

---

## Phase 3: User Story 1 + US4 + US5 — Recipe List Polish (Priority: P1 + P3)

**Goal**: Photo-first recipe tiles with name overlay; branded app bar; smooth slide/fade navigation transition; animated equalizer loading screen. US4 (header + transition) and US5 (equalizer) are implemented together with US1 because all three modify `recipe_list_screen.dart`.

**Independent Test**: Launch the app. The recipe list shows photo tiles with name overlays, no tag chips on tiles. The app bar reads "niessl.org recipes". Tapping any tile transitions smoothly to the detail screen. On a cold launch (cleared app data), vertical animated bars are shown instead of a spinner.

### Tests for US1 + US4 + US5 (write first — must FAIL before T017+)

- [x] T013Write failing widget tests in `test/widget/screens_widget_test.dart`: `RecipeTile` built with a `RecipeSummary` with non-null `picture` renders a `Hero` widget and a `CachedNetworkImage`; `RecipeTile` with null `picture` renders a `Hero` widget and an `Icon(Icons.restaurant)` placeholder; `RecipeTile` renders no `FilterChip` or tag-related widgets
-[x] T014 [P] Write failing widget tests in `test/widget/screens_widget_test.dart`: `RecipeListScreen` AppBar title text is `'niessl.org recipes'`; when `filteredRecipesProvider` is overridden to loading state, `EqualizerLoadingView` is found in the widget tree (not `CircularProgressIndicator`)
-[x] T015 [P] Write failing widget smoke test in `test/widget/screens_widget_test.dart`: `EqualizerLoadingView` pumped standalone renders without throwing; `AnimatedBuilder` widgets are present in the subtree
-[x] T016 Run `flutter test test/widget/` — confirm T013/T014/T015 tests **fail** (expected)

### Implementation for US1 + US4 + US5

-[x] T017 [US1] [US5] Create `lib/widgets/equalizer_loading_view.dart`: `EqualizerLoadingView` (`StatefulWidget` + `SingleTickerProviderStateMixin`) with one `AnimationController` (`duration: 1400 ms`, `repeat()`); 5 `_EqualizerBar` private `StatelessWidget`s arranged in a `Row`, each using `CurvedAnimation` with `Interval(i * 0.15, i * 0.15 + 0.35, curve: Curves.easeInOut)` and `Tween<double>(begin: 0.3, end: 1.0)` driving `Transform.scale(scaleY:, alignment: Alignment.bottomCenter)` on a `Container(width: 5, height: 50, color: colorScheme.primary, borderRadius: 2.5)`; center the Row in a `Column` with a `Text('niessl.org recipes', style: bodySmall, color: onSurfaceVariant)` beneath
-[x] T018 [P] [US1] Update `lib/widgets/recipe_tile.dart`: replace `ListTile` with `Hero(tag: 'recipe_photo_\${recipe.url}') → InkWell → Padding(all:8) → ClipRRect(borderRadius:12) → Stack`; Stack children: `AspectRatio(1.6)` containing either `CachedNetworkImage(imageUrl: recipe.picture!, fit: BoxFit.cover, placeholder: warm surfaceVariant Container, errorWidget: Icon(Icons.restaurant) Container)` when `picture != null` or `Container(color: colorScheme.surfaceVariant, child: Icon(Icons.restaurant, color: onSurfaceVariant))` when null; and `Positioned(bottom:0,left:0,right:0)` containing a `Container` with `LinearGradient(colors:[Colors.transparent, colorScheme.scrim.withOpacity(0.55)])` and `Padding(h:12,v:10)` with `Text(recipe.name, style: titleSmall.copyWith(color:Colors.white), maxLines:2, overflow:ellipsis)`; remove all tag rendering
-[x] T019 [US1] [US4] [US5] Update `lib/screens/recipe_list_screen.dart`: (a) change `AppBar(title: const Text('niessl.org recipes'))`; (b) change loading state to `const EqualizerLoadingView()`; (c) update `Navigator.push` call to use `_RecipePageRoute` and pass `photoUrl: recipes[i].picture` to `RecipeDetailScreen`; (d) add private `_RecipePageRoute<T> extends PageRouteBuilder<T>` at bottom of file with `pageBuilder` returning the child, `transitionsBuilder` combining `SlideTransition(position: Tween(begin: Offset(1.0, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)))` and `FadeTransition(opacity: animation)`, `transitionDuration: Duration(milliseconds: 350)`
-[x] T020 Run `flutter test` — all tests pass (T013/T014/T015 now green, all 58+ prior tests still passing)
-[x] T021 Run `flutter analyze` and `dart format --set-exit-if-changed .` — zero issues

**Checkpoint**: Recipe list is visually polished. Photo tiles, branded header, equalizer loading, and transition all functional. Test independently by running the app.

---

## Phase 4: User Story 2 + US3 — Recipe Detail Polish (Priority: P2 + P3)

**Goal**: Detail screen shows a prominent photo header, recipe name as a content heading, tappable source attribution, larger body text, and a clearly labelled screen-on toggle with snackbar feedback.

**Independent Test**: Tap any recipe tile. The detail screen opens with a photo at the top, the recipe name as a large heading, source link (if available), and larger body text. The app bar shows a "Screen off" button. Tapping it changes the label to "Screen on" and shows a snackbar.

### Tests for US2 + US3 (write first — must FAIL before T025+)

-[x] T022 Write failing widget tests in `test/widget/screens_widget_test.dart` for `RecipeDetailScreen` loaded state (override `recipeDetailProvider` with `RecipeDetail` that has `picture` + `source`): recipe name `Text` widget found in body column (not only in AppBar); `Hero` widget present; source `InkWell` row present (find by `Icons.open_in_new`); `Divider` present before markdown
-[x] T023 [P] Write failing widget test in `test/widget/screens_widget_test.dart`: `RecipeDetailScreen` loaded state with `source == null` — source `InkWell` row is NOT in the widget tree
-[x] T024 [P] Write failing widget tests in `test/widget/screens_widget_test.dart`: `RecipeDetailScreen` AppBar actions contain a `TextButton` (or descendant) with label text `'Screen off'` (initial inactive state); after tapping the toggle, a `SnackBar` appears in the widget tree
-[x] T025 Run `flutter test test/widget/` — confirm T022/T023/T024 tests **fail** (expected)

### Implementation for US2

-[x] T026 [US2] Add `final String? photoUrl` constructor parameter to `RecipeDetailScreen` in `lib/screens/recipe_detail_screen.dart`; update `const RecipeDetailScreen({super.key, required this.url, required this.name, this.photoUrl})`
-[x] T027 [US2] Update `RecipeDetailScreen` AppBar in `lib/screens/recipe_detail_screen.dart`: `title: Text(widget.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)`
-[x] T028 [US2] Replace the `data:` branch body in `lib/screens/recipe_detail_screen.dart` with `SingleChildScrollView → Column` containing: (1) `Hero(tag: 'recipe_photo_\${widget.url}') → AspectRatio(16/9)` with `CachedNetworkImage(imageUrl: widget.photoUrl!, ...)` if `photoUrl != null` else warm `surfaceVariant Container`; (2) `Padding(horizontal:16, top:16) → Text(widget.name, style: headlineMedium)`; (3) if `detail.source != null && detail.source!.isNotEmpty`: `Padding(horizontal:16, bottom:8) → InkWell(onTap: () => launchUrl(Uri.parse(detail.source!))) → Row([Icon(Icons.open_in_new, size:14, color:primary), SizedBox(width:4), Text(Uri.parse(detail.source!).host, style: bodySmall.copyWith(color:primary))])`; (4) `const Divider()`; (5) `Padding(all:16) → MarkdownBody(data: detail.recipe, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(p: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 17, height: 1.5)))`

### Implementation for US3

-[x] T029 [US3] Replace AppBar `actions` in `lib/screens/recipe_detail_screen.dart`: replace `IconButton` with `TextButton.icon(icon: Icon(_keepAwake ? Icons.visibility : Icons.visibility_off), label: Text(_keepAwake ? 'Screen on' : 'Screen off'), onPressed: _toggleWakelock, style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface))`; update `_toggleWakelock` to call `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_keepAwake ? 'Screen will stay on while cooking' : 'Screen timeout restored'), duration: Duration(seconds: 2)))` before the setState (note: `_keepAwake` still holds the old value when snackbar message is composed — adjust message accordingly)
-[x] T030 Run `flutter test` — all tests pass (T022/T023/T024 now green, all prior tests still passing); run `flutter analyze` — zero issues

**Checkpoint**: Detail screen fully polished. US2 + US3 independently testable by running the app and navigating to any recipe.

---

## Phase 5: Integration & Final Polish

**Purpose**: End-to-end acceptance, coverage verification, and final quality gates.

-[x] T031 Write new integration test group `'US5 and US6: photo tiles and polished detail'` in `integration_test/app_test.dart`: (US5) after app loads, verify no `FilterChip` or tag text widgets visible on the recipe list tiles; tap the first tile and verify `RecipeDetailScreen` is in the tree; (US6) on the detail screen, verify a `Text` widget with the recipe name exists in the body scroll area; verify an `Icon(Icons.open_in_new)` OR the `Divider` is in the tree; press back and verify return to list
-[x] T032 Run full integration test suite on `Medium_Phone_API_36.1`: `flutter test integration_test/app_test.dart -d Medium_Phone_API_36.1` — all existing US1–US4 tests AND new US5–US6 group pass
-[x] T033 Run `flutter test --coverage` — confirm ≥80% line coverage on all changed files (`lib/models/recipe.dart`, `lib/services/recipe_service.dart`, `lib/theme.dart`, `lib/widgets/equalizer_loading_view.dart`, `lib/widgets/recipe_tile.dart`, `lib/screens/recipe_list_screen.dart`, `lib/screens/recipe_detail_screen.dart`)
-[x] T034 [P] Run `dart format --set-exit-if-changed .` — zero changes
-[x] T035 [P] Run `flutter analyze` — zero issues; no warnings

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Requires Phase 1 (pubspec installed) — BLOCKS all user story phases
- **Phase 3 (US1+US4+US5)**: Requires Phase 2 complete — models and theme must exist
- **Phase 4 (US2+US3)**: Requires Phase 2 complete; Phase 3 must be done first because `RecipeDetailScreen` now receives `photoUrl` from `RecipeTile` navigation (added in T019)
- **Phase 5 (Integration)**: Requires all preceding phases complete

### Within Each Phase

- Tests (T003–T005, T013–T016, T022–T025, T031) MUST be written and confirmed failing BEFORE their corresponding implementation tasks
- Within Phase 2: T006 and T007 can run in parallel (both in `lib/models/recipe.dart` but separate classes — verify no merge conflicts); T008 and T009 can run in parallel
- Within Phase 3: T017 and T018 can run in parallel (different files); T019 depends on T017 (imports EqualizerLoadingView)
- Within Phase 4: T026 → T027 → T028 must be sequential (all in same file, build on each other); T029 is independent within the same file once T026 is done

### Parallel Opportunities per Phase

```
Phase 2 parallel group A: T003 + T004 (write tests simultaneously, different test cases)
Phase 2 parallel group B: T006 + T007 (model updates — different classes in same file)
Phase 2 parallel group C: T008 + T009 (service verification — different methods)

Phase 3 parallel group A: T013 + T014 + T015 (write tests simultaneously)
Phase 3 parallel group B: T017 + T018 (equalizer widget + recipe tile — different files)

Phase 4 parallel group A: T022 + T023 + T024 (write tests simultaneously)

Phase 5 parallel group: T034 + T035 (format + analyze — independent)
```

---

## Implementation Strategy

### MVP Scope (Phase 1 + 2 + 3 only)

1. Complete Phase 1: Setup (pubspec + manifest)
2. Complete Phase 2: Models + theme (US6 theme, data model)
3. Complete Phase 3: Recipe list polish (US1 photo tiles, US4 header + transition, US5 equalizer)
4. **STOP and VALIDATE**: Run app — photo tiles visible, title correct, equalizer on cold launch, smooth transition ✅
5. This delivers the highest-impact visual change immediately

### Full Delivery (All Phases)

1. Setup → Foundational → Recipe List Polish → Recipe Detail Polish → Integration
2. Each phase checkpoint is independently demonstrable
3. Phase 4 adds the richest per-recipe content (photo header + source link)

---

## Notes

- [P] tasks = different files or independent content; no ordering dependency
- All test tasks must confirm FAILURE before the corresponding implementation tasks begin (Constitution Principle II, non-negotiable)
- `CachedNetworkImage` in widget tests: verify widget type is in tree (`find.byType(CachedNetworkImage)`); do not depend on network loading completing in tests
- `url_launcher` in widget tests: verify `InkWell` and `Icons.open_in_new` are in tree; do not call `launchUrl` in widget tests (platform channel not available)
- `WakelockPlus` MethodChannel mock already in place in existing widget tests — reuse the same mock setup for new toggle tests
- If ADB goes offline between runs: `adb kill-server && adb start-server`
- `_EqualizerBar` is a private class — test `EqualizerLoadingView` by finding `AnimatedBuilder` widgets in the tree rather than `_EqualizerBar`
- Commit after each checkpoint (after T012, T021, T030, T035) with `dart format` and `flutter analyze` both clean
