# Quickstart: App Icon Branding & Detail Photo Overlay Redesign

**Branch**: `004-icon-detail-overlay` | **Date**: 2026-02-21

---

## Prerequisites

- Flutter 3.35.6 / Dart 3.9.2 installed
- Android emulator running (use `Medium_Phone_API_36.1` if Pixel_8a fails)
- Git on branch `004-icon-detail-overlay`

---

## Setup Steps

### 1. Get dependencies

```bash
flutter pub get
```

### 2. Download the logo asset

```bash
# From repo root — creates assets/logo.png
mkdir -p assets
curl -L https://niessl.org/img/logo.png -o assets/logo.png
```

Verify the file is a valid PNG (non-zero size):

```bash
ls -lh assets/logo.png
```

### 3. Generate app icons

```bash
dart run flutter_launcher_icons
```

This generates all icon density variants under `android/app/src/main/res/mipmap-*/` and `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

### 4. Generate native splash assets

```bash
dart run flutter_native_splash:create
```

This regenerates the native launch screen assets (Android drawable + iOS storyboard) with the logo centered on the warm cream / dark background.

### 5. Run tests

```bash
# Unit + widget tests
flutter test

# Coverage check (must be ≥ 80%)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 6. Run on emulator

```bash
flutter run -d <emulator-id>
```

Verify:
- Home screen icon shows the niessl.org logo
- Tapping the icon shows the logo on the splash screen
- Opening any recipe detail:
  - Recipe name NOT on the photo
  - Semi-transparent white bar at bottom of photo with tags (label icon + text) and source (link icon + text)
  - No FilterChip widgets in the detail screen body

---

## Key Files Changed

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_launcher_icons` dev dep + config section; add `image:` to `flutter_native_splash` |
| `assets/logo.png` | New — logo downloaded from niessl.org |
| `lib/screens/recipe_detail_screen.dart` | Replace name overlay + separate tag/source sections with unified photo overlay bar |
| `test/widget/screens_widget_test.dart` | Update 4 tests for new overlay design |
| `integration_test/app_test.dart` | Update US4 (remove tag-chip-tap test); update US6 assertion |

---

## Troubleshooting

**Icon not updating on emulator**: Cold boot the emulator (`-no-snapshot-load`) or uninstall and reinstall the app.

**Logo PNG has solid white background**: The icon will look fine on dark home screens but may appear as a white square on light ones. If this is unacceptable, the logo may need manual background removal before adding to `assets/`.

**Splash logo too large / small**: Adjust `android_12.image_padding_percent` in the `flutter_native_splash` pubspec config section (0–100, default 0) and re-run `dart run flutter_native_splash:create`.

**ADB offline after failed install**: `Stop-Process -Name 'emulator' -Force` in PowerShell, then relaunch with `-no-snapshot-load`.
