# Quickstart: Flutter Recipe App

**Branch**: `001-flutter-recipe-app` | **Date**: 2026-02-19

---

## Prerequisites

- Flutter SDK ≥3.19 installed and on PATH (`flutter --version` to verify)
- Dart SDK (bundled with Flutter)
- Xcode 15+ (for iOS builds, macOS only)
- Android Studio / Android SDK (for Android builds)
- A connected device or simulator

---

## Setup

```bash
# 1. Clone the repository
git clone <repo-url>
cd niessl.org.recipes

# 2. Check out the feature branch
git checkout 001-flutter-recipe-app

# 3. Install dependencies
flutter pub get

# 4. Verify setup
flutter doctor
flutter analyze   # must report zero issues (Constitution gate I)
dart format --set-exit-if-changed .   # must report no changes
```

---

## Run the App

```bash
# List available devices
flutter devices

# Run on a connected device/emulator (debug mode)
flutter run

# Run on a specific device
flutter run -d <device-id>

# Run in release mode (tests performance budgets)
flutter run --release
```

On first launch:
1. App shows a loading indicator while fetching recipes.
2. Recipe list appears within ~3 seconds (SC-002).
3. Tag filter chips appear at the top of the list.
4. Search bar is immediately interactive.

---

## Run Tests

```bash
# Unit tests (fast, no device needed)
flutter test test/unit/

# Widget tests (no device needed)
flutter test test/widget/

# All tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html   # optional HTML report

# Integration tests (requires a connected device/emulator)
flutter test integration_test/app_test.dart
```

**Coverage gate**: `flutter test --coverage` MUST report ≥80% line coverage on
changed code before any merge (Constitution gate II).

---

## Lint & Format

```bash
# Lint (zero warnings required — Constitution gate I)
flutter analyze

# Format check (zero diffs required — Constitution gate I)
dart format --set-exit-if-changed .

# Auto-format
dart format .
```

---

## Manual Validation by User Story

### US1 — Browse the Recipe Collection

1. Launch the app on a fresh emulator (no cached data).
2. Verify: recipe list appears within 3 seconds (SC-002).
3. Tap "Financiers" — verify full ingredients and directions are displayed.
4. Tap back — verify scroll position is preserved.
5. Enable airplane mode, force-close, relaunch — verify list is shown from cache
   (SC-009).

**Expected**: ✅ All four scenarios from spec.md US1 pass.

---

### US2 — Search for a Specific Recipe

1. On the recipe list screen, tap the search bar.
2. Type "pan" — verify only recipes containing "pan" (case-insensitive) are shown
   (e.g., "Paneer Butter Masala", "Topfenpalatschinken").
3. Type a nonsense string ("zzz") — verify the empty-state message appears.
4. Clear the search — verify all recipes are immediately restored.

**Expected**: ✅ All three scenarios from spec.md US2 pass.

---

### US3 — Filter Recipes by Category

1. On the recipe list screen, locate the tag filter chips.
2. Tap the "indian" chip — verify only the 10 Indian recipes are shown.
3. Tap the "sweet" chip as well — verify recipes matching either tag are shown
   (inclusive OR).
4. Tap both chips again to deselect — verify the full list is restored.
5. With a search term active AND a tag selected — verify only recipes matching
   BOTH criteria are shown.

**Expected**: ✅ All five scenarios from spec.md US3 pass.

---

### US4 — Keep the Screen On While Cooking

1. Open any recipe detail screen.
2. Enable the "keep screen on" toggle (icon button in AppBar or footer).
3. Leave the device idle for longer than the standard screen timeout (typically
   30–60 s) — verify the screen stays on.
4. Navigate back — verify normal screen timeout resumes.
5. Reopen any recipe and toggle off — verify normal timeout resumes immediately.

**Expected**: ✅ All three scenarios from spec.md US4 pass.

---

## Build for Distribution

```bash
# iOS (requires code signing)
flutter build ipa

# Android (release APK)
flutter build apk --release

# Android (app bundle for Play Store)
flutter build appbundle --release
```

---

## Performance Validation

```bash
# Profile mode build (closer to release performance)
flutter run --profile

# In DevTools (opens automatically or at http://127.0.0.1:9100):
#   → Performance tab: verify no jank on list scroll
#   → CPU profiler: verify no blocking calls on main isolate
#   → Memory: verify no leaks after navigating list → detail → back 10 times
```

**Performance gates** (Constitution Principle IV, adapted for mobile):
- Cold start to interactive list: ≤3 seconds (SC-002).
- Search filter response: <16 ms per frame = no perceptible lag (SC-003).
- No synchronous blocking calls on the main isolate (verify via CPU profiler).

---

## Accessibility Validation

```bash
# Run with TalkBack (Android) or VoiceOver (iOS) enabled.
# Verify:
#   - All recipe names are announced correctly.
#   - Search bar has a descriptive label.
#   - Tag chips announce their name and selected state.
#   - "Keep screen on" toggle announces its state.
#   - Error and empty-state messages are announced.
```

**Accessibility gate** (Constitution Principle III): No critical or serious
accessibility regressions before any merge.
