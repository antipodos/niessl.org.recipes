# Quickstart: UX Polish & Visual Refinement

**Branch**: `002-ux-polish`

## Prerequisites

- Flutter 3.35.6 / Dart 3.9.2 installed and on PATH
- Android emulator `Medium_Phone_API_36.1` available (or physical device)
- Working directory: repository root

## Install Dependencies

After updating `pubspec.yaml` with new packages:

```bash
flutter pub get
```

New packages added: `cached_network_image: ^3.3.0`, `url_launcher: ^6.2.0`

## Run Unit + Widget Tests

```bash
flutter test
```

Expected: all tests pass (58 existing + new tests for this feature). Run after every task group.

## Run with Code Coverage

```bash
flutter test --coverage
```

Coverage report at `coverage/lcov.info`. Threshold: ≥80% on changed files.

## Static Analysis & Format

```bash
flutter analyze
dart format --set-exit-if-changed .
```

Both must report zero issues before any commit.

## Run on Emulator

```bash
flutter run -d Medium_Phone_API_36.1
```

Verify visually:
- Recipe list shows photo tiles with name overlay
- Tapping a tile triggers slide + fade transition and shows photo header in detail
- Source attribution link is visible and tappable
- Screen-on toggle shows label and snackbar on toggle
- Cold launch (clear app data) shows equalizer animation

## Run Integration Tests

```bash
flutter test integration_test/app_test.dart -d Medium_Phone_API_36.1
```

If emulator ADB goes offline: `adb kill-server && adb start-server`

## Android Manifest Update Required

After adding `url_launcher`, add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>` (before `<application>`):

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

This is required for Android 11+ (API 30+) to resolve browser intents.

## Key Files Changed in This Feature

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `cached_network_image`, `url_launcher` |
| `android/app/src/main/AndroidManifest.xml` | Add `<queries>` for url_launcher |
| `lib/theme.dart` | Warm surfaces, page transition theme |
| `lib/models/recipe.dart` | Add `picture?`, `source?` fields |
| `lib/services/recipe_service.dart` | Parse `picture`, `source` from JSON; update cache serialisation |
| `lib/widgets/equalizer_loading_view.dart` | NEW — animated loading |
| `lib/widgets/recipe_tile.dart` | Photo tile with Hero + overlay |
| `lib/screens/recipe_list_screen.dart` | Updated title, tile navigation, loading state |
| `lib/screens/recipe_detail_screen.dart` | Photo header, source link, font size, toggle UX |
| `test/unit/recipe_service_test.dart` | New tests for picture/source parsing |
| `test/widget/screens_widget_test.dart` | New widget tests for updated screens |
| `integration_test/app_test.dart` | New integration tests for photo tile + source link |
