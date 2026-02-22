# niessl.org recipes

A Flutter recipe companion app for [dinner.niessl.org](https://dinner.niessl.org). Browse, search, and filter recipes by tag — with a warm, food-friendly Material Design 3 UI. Available as a web PWA and an Android APK.

## Live Web App

**[https://antipodos.github.io/niessl.org.recipes/](https://antipodos.github.io/niessl.org.recipes/)**

The web app is a Progressive Web App (PWA) — you can install it to your home screen from any browser that supports PWA installation.

## Getting the Android APK

The Android APK is published with every release and can be sideloaded on any Android device.

1. Go to the [Releases page](https://github.com/antipodos/niessl.org.recipes/releases).
2. Download `app-release.apk` from the latest release assets.
3. On your Android device, enable **Install unknown apps** for your browser or file manager.
4. Open the downloaded APK and tap **Install**.

> **Note**: The APK is not published to the Play Store and must be sideloaded manually.

## Creating a Release

Releases are triggered by pushing a [semantic version](https://semver.org) tag to the repository. This automatically builds and publishes both the web PWA and the Android APK.

```bash
# Tag the current commit with a version number
git tag v1.0.0

# Push the tag to trigger the release pipeline
git push origin v1.0.0
```

The release pipeline will:
1. Run all tests and static analysis
2. Build and deploy the web PWA to GitHub Pages
3. Build the Android APK with the correct version number
4. Publish a GitHub Release with the APK attached

Plain commits to `main` run tests and deploy the web app only — no APK is built unless a version tag is pushed.

## Development Setup

**Prerequisites**: [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.35.6+

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

## About This Project

This app is an experiment in **spec-driven development** using [spec-kit](https://github.com/github/spec-kit) — a workflow for writing feature specifications before implementation, ensuring every piece of code traces back to a user story.

All feature specifications live in the [`specs/`](specs/) directory, organized by feature branch.
