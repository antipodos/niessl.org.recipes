# Tasks: App Icon Branding & Detail Photo Overlay Redesign

**Input**: Design documents from `/specs/004-icon-detail-overlay/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Constitution**: Test-First (NON-NEGOTIABLE) — tests must be written and confirmed failing before implementation for all changed behaviour. App icon and native splash are build-time assets verified visually; widget-testable behaviour (detail overlay) follows strict Red-Green-Refactor.

**Organization**: Two user stories, both P1. US1 (icon + splash) is pure build config — no Dart code. US2 (detail overlay) follows full TDD cycle.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1, US2)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Download logo asset and configure build tooling in pubspec.yaml before any generation or implementation begins.

- [x] T001 Create `assets/` directory and download logo from `https://niessl.org/img/logo.png` to `assets/logo.png`
- [x] T002 Add `flutter_launcher_icons: ^0.14.0` to `dev_dependencies` in `pubspec.yaml` and add `flutter_launcher_icons:` config section (android: true, ios: true, image_path: "assets/logo.png", adaptive_icon_background: "#FFFFFF", adaptive_icon_foreground: "assets/logo.png")
- [x] T003 Add `image: assets/logo.png` to the `flutter_native_splash:` section in `pubspec.yaml` (both root level and under `android_12:`) — run after T002 (same file)

**Checkpoint**: `pubspec.yaml` updated, `assets/logo.png` present on disk.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Resolve dependencies and generate all platform icon/splash assets. Must complete before any emulator verification.

**⚠️ CRITICAL**: No user story work can begin until `flutter pub get` succeeds.

- [x] T004 Run `flutter pub get` to resolve `flutter_launcher_icons` dependency
- [x] T005 Run `dart run flutter_launcher_icons` to generate Android `mipmap-*/ic_launcher*.png` and iOS `AppIcon.appiconset/` from `assets/logo.png`
- [x] T006 Run `dart run flutter_native_splash:create` to regenerate native splash drawables (Android) and storyboard (iOS) with `assets/logo.png` centered on warm cream/dark backgrounds

**Checkpoint**: Icon and splash assets generated in `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/`.

---

## Phase 3: User Story 1 — App Icon & Splash Branding (Priority: P1) 🎯 MVP

**Goal**: App home screen icon and native startup screen both display the niessl.org logo.

**Independent Test**: Install the app on the emulator. Verify the launcher icon shows the niessl.org logo (not a generic Flutter icon). Tap the icon and verify the splash shows the logo on the warm cream background. Verify dark-mode splash (toggle emulator dark mode) shows logo on the dark brown background.

> ⚠️ App icon and native splash are platform-native assets; they cannot be covered by `flutter_test` widget tests. Visual inspection on the emulator is the acceptance test for this story.

### Implementation for User Story 1

- [ ] T007 [US1] Visual acceptance test on emulator: launch app, confirm launcher icon shows niessl.org logo on both light and dark home screen backgrounds; confirm native splash displays logo on warm cream (light) and dark brown (dark) backgrounds; confirm no blank white flash  ← deferred to T023

**Checkpoint**: US1 complete — app icon and splash branded with niessl.org logo.

---

## Phase 4: User Story 2 — Detail Photo Overlay Redesign (Priority: P1)

**Goal**: Recipe detail screen photo shows a semi-transparent white bar at its bottom containing tags (label icon + plain text) and source link (link icon + plain text), replacing the name overlay. No FilterChip widgets remain in the detail screen.

**Independent Test**: Open a recipe with a photo, tags, and a source URL. Verify: (1) recipe name is NOT on the photo, (2) a white translucent bar at the photo bottom shows `Icons.label_outline` + tag name text for each tag and `Icons.open_in_new` + source hostname text, (3) no FilterChip exists anywhere in the detail screen.

### Tests for User Story 2 (Test-First — write BEFORE implementation)

> **Constitution II — NON-NEGOTIABLE: Write these tests first and confirm they FAIL before touching production code.**

- [x] T008 [US2] Write failing widget tests for overlay bar presence/absence in `test/widget/screens_widget_test.dart` `RecipeDetailScreen` group: (a) when `tags` is non-empty and `photoUrl` is set, `Icons.label_outline` + tag text appear inside the Hero subtree; (b) when `photoUrl` is null (no photo), `Icons.label_outline` is absent from the Hero subtree — FR-004 and FR-008
- [x] T009 [US2] Write failing widget test: recipe name text does NOT appear inside the Hero subtree (only in AppBar) — add to `RecipeDetailScreen` group in `test/widget/screens_widget_test.dart`
- [x] T010 [US2] Write failing widget test: `Icons.open_in_new` appears inside the Hero subtree (source in overlay bar, not below photo) for a detail with a valid source — add to `RecipeDetailScreen` group in `test/widget/screens_widget_test.dart`
- [x] T011 [US2] Update existing widget test `loaded state with media shows Hero, name heading, source link, Divider` → rename to `loaded state with media shows Hero, overlay bar with source, and Divider`; replace assertion `find.text(widget.name)` inside Hero with `find.byIcon(Icons.open_in_new)` inside Hero subtree — `test/widget/screens_widget_test.dart`
- [x] T012 [US2] Update existing widget test `shows FilterChip for each tag when tags provided` → replace `find.widgetWithText(FilterChip, 'Italian')` with `find.text('Italian')` + `find.byIcon(Icons.label_outline)` — `test/widget/screens_widget_test.dart`
- [x] T013 [US2] Remove existing widget test `recipe name appears inside Hero subtree when loaded` — this behaviour is intentionally eliminated — `test/widget/screens_widget_test.dart`
- [x] T014 [US2] Update existing widget test `standalone name heading below photo is removed after overlay added` → simplify: verify `find.descendant(of: find.byType(Hero), matching: find.text('Pancakes'))` finds nothing; verify AppBar still shows name — `test/widget/screens_widget_test.dart`
- [x] T015 [US2] Update integration test: remove `US4: tapping a detail tag chip returns to filtered list` (tags are now read-only); update `US6: detail screen shows name heading, photo area, and Divider` to verify `find.byType(Hero)` and `find.byType(Divider)` without asserting name inside Hero — `integration_test/app_test.dart`
- [x] T016 [US2] Run `flutter test` and confirm all new/updated tests FAIL (Red phase confirmed before implementation)

### Implementation for User Story 2

- [x] T017 [US2] In `lib/screens/recipe_detail_screen.dart`: remove the gradient scrim `Positioned` widget (the `LinearGradient` `Container` of height 100) and remove the name text `Positioned` widget from the Hero `Stack`
- [x] T018 [US2] In `lib/screens/recipe_detail_screen.dart`: remove the `FilterChip` tags `Wrap` section (currently below the Hero, lines ~172–192) and remove the source `InkWell` section (currently below the FilterChip block, lines ~194–219) from the `Column` body
- [x] T019 [US2] In `lib/screens/recipe_detail_screen.dart`: add a `Positioned(bottom: 0, left: 0, right: 0)` overlay bar inside the Hero `Stack` — `Container` with `Colors.white.withValues(alpha: 0.78)` background, `Padding(all: 8)`, `Wrap(spacing: 12, runSpacing: 4)` containing: for each tag a `Semantics(label: tag, child: Row(Icon(Icons.label_outline, size:14, color: colorScheme.onSurface, semanticLabel: ''), SizedBox(4), Text(tag, bodySmall, color: colorScheme.onSurface, overflow: TextOverflow.ellipsis)))`; if source is valid a `GestureDetector(onTap: launchUrl)` wrapping `Semantics(label: 'Source: ${Uri.parse(source).host}', child: Row(Icon(Icons.open_in_new, size:14, color: colorScheme.primary, semanticLabel: ''), SizedBox(4), Text(hostname, bodySmall, color: colorScheme.primary, overflow: TextOverflow.ellipsis)))`; render bar only when `photoUrl != null` AND (tags non-empty OR source valid) — addresses FR-007, FR-008, EC-002, EC-003, WCAG AA (D1)
- [x] T020 [US2] Run `flutter test` and confirm all previously failing tests now pass (Green phase)

**Checkpoint**: US2 complete — detail screen shows new overlay bar, no FilterChip, no name on photo.

---

## Phase 5: Polish & Quality Gates

**Purpose**: Enforce all constitution quality gates before the feature is considered complete.

- [x] T021 Run `flutter analyze` — must report zero issues; run `dart format --set-exit-if-changed .` — must report zero diffs
- [x] T022 Run `flutter test --coverage` and confirm: all tests pass (≥92), coverage ≥ 80% on changed code
- [x] T023 [P] Visual end-to-end verification on emulator: (1) launcher icon = niessl.org logo, (2) splash shows logo on warm cream background, (3) detail screen photo has white semi-transparent bar with label+tag text and link icon+hostname, (4) no name on photo, (5) no FilterChip in detail screen

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately; T002 and T003 can run in parallel
- **Foundational (Phase 2)**: Depends on Phase 1 completion; T005 and T006 can run in parallel after T004
- **US1 (Phase 3)**: Depends on Phase 2; visual-only acceptance, no code changes
- **US2 (Phase 4)**: Can begin test-writing (T008–T015) in parallel with Phase 2/3; implementation (T017–T019) must follow T016
- **Polish (Phase 5)**: Depends on all phases complete

### Within US2

```
T008–T015 (write tests) → T016 (confirm fail) → T017–T019 (implement) → T020 (confirm pass)
```

### Parallel Opportunities

- T002 then T003 sequentially (both edit `pubspec.yaml` — cannot run in parallel)
- T005 and T006 (icon + splash generators) — run in parallel after T004
- T008–T015 (test updates) — edit the same file; do sequentially in any order within a single session (or batch to one agent at a time if parallelising)
- T021 and T023 (analyze + visual check) — run in parallel after T022

---

## Parallel Example: User Story 2 Tests

```
# All test writes can proceed in parallel (same file, different test blocks):
T008: overlay bar with label icons test
T009: no name in Hero test
T010: source icon in Hero test
T011: update "loaded state with media" test
T012: update "shows FilterChip for tags" test
T013: remove "name in Hero" test
T014: update "standalone name heading" test
T015: update integration test
```

---

## Implementation Strategy

### MVP First (Both stories are P1 — complete together)

1. Complete Phase 1: Setup (asset + pubspec)
2. Complete Phase 2: Foundational (pub get + generate)
3. Complete Phase 3: US1 — verify icon + splash visually
4. Complete Phase 4: US2 — TDD cycle for detail overlay
5. Complete Phase 5: Polish — all quality gates

### Incremental Delivery

- After Phase 2+3: App is brandable with logo (ship icon independently if needed)
- After Phase 4: Detail screen is redesigned
- After Phase 5: Feature ready for PR

---

## Notes

- [P] tasks = different files or independent sections, no blocking dependency
- Constitution Principle II (Test-First) is NON-NEGOTIABLE: T016 (Red confirm) must precede T017–T019
- Native app icon and splash cannot be covered by `flutter_test`; T007 and T023 are visual acceptance tasks
- Source filtering rule (non-null, non-empty, not `"unknown"`) is already implemented in the detail screen — preserve it in the overlay bar
- Tags in the overlay bar are read-only (no `selectedTagsProvider` update, no `Navigator.pop`) — this is an intentional design decision per research.md
