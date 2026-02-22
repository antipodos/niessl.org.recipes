# Implementation Plan: Release Management & README

**Branch**: `006-release-management` | **Date**: 2026-02-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-release-management/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command.

## Summary

Restructure the CI/CD pipeline into two distinct workflows: a fast **CI** workflow (test + analyze + web deploy on every push to `main`) and a **Release** workflow (CI + APK build + GitHub Release creation, triggered only by `v*.*.*` semver tags). Add automatic semantic version injection into the APK build from the git tag. Rewrite the README with project overview, web/APK links, release instructions, and a spec-driven development acknowledgement.

## Technical Context

**Language/Version**: Dart 3.9.2 / Flutter 3.35.6 (existing)
**Primary Dependencies**:
- `subosito/flutter-action@v2` (existing)
- `softprops/action-gh-release@v2` (new — GitHub Release creation)
- `actions/deploy-pages@v4` (existing)
- `actions/upload-pages-artifact@v3` (existing)

**Storage**: N/A — no application data. GitHub Pages + GitHub Releases are the output targets.
**Testing**: Manual acceptance testing via CI run observation; existing `flutter test` suite unchanged.
**Target Platform**: GitHub Actions (ubuntu-latest), GitHub Pages (web), Android APK.
**Project Type**: Flutter mobile + web (CI/CD infrastructure change only; no Dart code changes).
**Performance Goals**: CI run (no APK) completes in < 5 minutes. Release run completes in < 15 minutes.
**Constraints**: APK build MUST be entirely absent from `ci.yml`. Release MUST gate on green tests. No pubspec.yaml editing required in CI for versioning.
**Scale/Scope**: 1 developer, tag-driven releases, sequential (no concurrent release requirements).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Code Quality** | ✅ PASS | Workflow YAML files have single-responsibility jobs. Variable names (`VERSION`, `BUILD_NUMBER`) are self-documenting. No dead code. |
| **II. Test-First** | ✅ PASS (adapted) | This feature modifies CI infrastructure and README — no Flutter application code is written. The "failing test" is the current state (APK builds on every push, violating FR-001); the "green test" is verified by observing CI run behavior. Existing 92/92 Flutter tests are unaffected. |
| **III. UX Consistency** | ✅ N/A | No UI changes. |
| **IV. Performance by Default** | ✅ PASS | No app code changes that affect LCP/TTI/CLS. The CI change actually improves developer experience by removing the ~9-min APK build from the daily pipeline. |

No violations. No complexity tracking required.

## Project Structure

### Documentation (this feature)

```text
specs/006-release-management/
├── plan.md          ✅ This file
├── research.md      ✅ Phase 0 output
├── data-model.md    ✅ Phase 1 output
├── quickstart.md    ✅ Phase 1 output
└── tasks.md         (Phase 2 — /speckit.tasks)
```

### Source Code (modified/created files)

```text
.github/
└── workflows/
    ├── ci.yml           # MODIFIED: remove build-apk job
    └── release.yml      # NEW: semver tag trigger; test+web+apk+release

README.md                # REPLACED: project overview, links, release guide
```

No changes to `lib/`, `test/`, `android/`, `web/`, or `pubspec.yaml`.

## Phase 1: CI Restructuring (US1 — FR-001, FR-002, FR-008)

### 1.1 Modify `ci.yml` — Remove APK build

Remove the `build-apk` job entirely from `.github/workflows/ci.yml`. The remaining jobs are `test` and `build-web`.

**Before** (current state — 3 jobs):
```
test → build-web
     → build-apk  ← REMOVE
```

**After** (2 jobs):
```
test → build-web
```

Keep existing permissions (`contents: read`, `pages: write`, `id-token: write`).

### 1.2 Create `release.yml` — Release Workflow

New file: `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'

permissions:
  contents: write
  pages: write
  id-token: write

jobs:
  test:
    name: Test & Analyze
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.6'
          channel: 'stable'
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build-web:
    name: Build & Deploy Web
    needs: test
    runs-on: ubuntu-latest
    timeout-minutes: 20
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.6'
          channel: 'stable'
          cache: true
      - run: flutter pub get
      - run: flutter build web --release --base-href=/niessl.org.recipes/
      - uses: actions/upload-pages-artifact@v3
        with:
          path: build/web
      - id: deployment
        uses: actions/deploy-pages@v4

  build-apk:
    name: Build Release APK
    needs: test
    runs-on: ubuntu-latest
    timeout-minutes: 25
    outputs:
      apk-path: build/app/outputs/apk/release/app-release.apk
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.6'
          channel: 'stable'
          cache: true
      - run: flutter pub get
      - name: Extract version from tag
        run: |
          VERSION=${GITHUB_REF_NAME#v}
          MAJOR=$(echo $VERSION | cut -d. -f1)
          MINOR=$(echo $VERSION | cut -d. -f2)
          PATCH=$(echo $VERSION | cut -d. -f3)
          BUILD_NUMBER=$((MAJOR * 10000 + MINOR * 100 + PATCH))
          echo "VERSION=$VERSION" >> $GITHUB_ENV
          echo "BUILD_NUMBER=$BUILD_NUMBER" >> $GITHUB_ENV
      - name: Build APK
        run: |
          flutter build apk \
            --build-name=$VERSION \
            --build-number=$BUILD_NUMBER \
            --release
      - uses: actions/upload-artifact@v4
        with:
          name: niessl-recipes-apk-${{ github.ref_name }}
          path: build/app/outputs/apk/release/app-release.apk
          retention-days: 1

  create-release:
    name: Create GitHub Release
    needs: [build-web, build-apk]
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: niessl-recipes-apk-${{ github.ref_name }}
      - uses: softprops/action-gh-release@v2
        with:
          name: ${{ github.ref_name }}
          body: |
            ## niessl.org recipes ${{ github.ref_name }}

            🌐 **Web app**: https://antipodos.github.io/niessl.org.recipes/
            📱 **Android APK**: Download from the assets below.
          files: app-release.apk
          draft: false
          prerelease: false
```

## Phase 2: README Rewrite (US3 — FR-007)

Replace the generic Flutter template `README.md` with a project-specific document covering:

1. **Project overview** — what the app is, who it's for
2. **Live web app link** — `https://antipodos.github.io/niessl.org.recipes/`
3. **Getting the Android APK** — link to Releases page; explain sideloading
4. **Creating a release** — step-by-step: `git tag vX.Y.Z && git push origin vX.Y.Z`
5. **Development setup** — brief flutter setup / run instructions
6. **About this project / spec-driven development** — note + `[SPECKIT_URL]` placeholder

Speckit URL: `https://github.com/github/spec-kit`

## Phase 3: Post-Implementation Verification

Follow `quickstart.md` acceptance scenarios for US1, US2, and US3.

## Key Technical Reference

| Topic | Decision |
|-------|---------|
| Release action | `softprops/action-gh-release@v2` |
| Version extraction | `${GITHUB_REF_NAME#v}` (bash parameter expansion) |
| versionName flag | `flutter build apk --build-name=$VERSION` |
| versionCode flag | `flutter build apk --build-number=$BUILD_NUMBER` |
| versionCode formula | `MAJOR×10000 + MINOR×100 + PATCH` |
| Tag trigger pattern | `v[0-9]+.[0-9]+.[0-9]+` |
| APK output path | `build/app/outputs/apk/release/app-release.apk` |
| Release permissions | `contents: write` + `pages: write` + `id-token: write` |
| Speckit URL | `https://github.com/github/spec-kit` |

## Testing Strategy

This feature has no new Flutter unit/widget tests (no Dart code changes). Validation is via:

1. **CI acceptance**: Push a plain commit to `main` → observe only `test` + `build-web` jobs run in the CI workflow.
2. **Release acceptance**: Push a semver tag → observe all 4 jobs run in the Release workflow; verify GitHub Release exists with correct APK asset and version.
3. **APK version verification**: Install APK on device/emulator; confirm `versionName` matches the tag.
4. **README readability**: Open README on GitHub; confirm all 5 required sections are findable within 30 seconds.

Refer to `quickstart.md` for detailed step-by-step verification procedures.
