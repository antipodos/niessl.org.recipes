# Data Model: Release Management (006)

**Branch**: `006-release-management` | **Date**: 2026-02-22

This feature has no persistent application data model (no database, no server-side storage). The "entities" are the configuration artifacts and pipeline outputs managed by this feature.

---

## Artifact Entities

### CI Workflow (`ci.yml`)

| Field | Value / Description |
|-------|-------------------|
| File path | `.github/workflows/ci.yml` |
| Trigger | `push: branches: [main]` |
| Jobs | `test`, `build-web` |
| Removed | `build-apk` (no longer in this file) |
| Outputs | GitHub Pages deployment |

### Release Workflow (`release.yml`)

| Field | Value / Description |
|-------|-------------------|
| File path | `.github/workflows/release.yml` |
| Trigger | `push: tags: ['v[0-9]+.[0-9]+.[0-9]+']` |
| Jobs | `test`, `build-web`, `build-apk`, `create-release` |
| Outputs | GitHub Pages deployment + GitHub Release with APK asset |
| Required permissions | `contents: write`, `pages: write`, `id-token: write` |

### Release Tag

| Field | Value / Description |
|-------|-------------------|
| Format | `vMAJOR.MINOR.PATCH` (e.g., `v1.2.0`) |
| Pattern match | `v[0-9]+.[0-9]+.[0-9]+` |
| Created by | Developer locally: `git tag v1.2.0 && git push origin v1.2.0` |
| Carries | Version string used throughout the release pipeline |
| Uniqueness | Each tag name must be unique in the repo; re-pushing an existing tag triggers a new run but may overwrite the GitHub Release |

### App Version (derived)

| Field | Value / Description |
|-------|-------------------|
| Source | Release Tag (git tag name) |
| Version string | `MAJOR.MINOR.PATCH` (e.g., `1.2.0`) — `v` prefix stripped |
| Extraction | `${GITHUB_REF_NAME#v}` in bash |
| versionName (Android) | Same as version string (e.g., `1.2.0`) |
| versionCode (Android) | `MAJOR × 10000 + MINOR × 100 + PATCH` (e.g., `10200` for `1.2.0`) |
| Max safe versionCode | `214748×10000` — far beyond any realistic version number |

### GitHub Release

| Field | Value / Description |
|-------|-------------------|
| Title | Tag name (e.g., `v1.2.0`) |
| Body | Fixed template: version number + web app link + APK download note |
| Asset | `app-release.apk` uploaded from `build/app/outputs/apk/release/app-release.apk` |
| Created by | `softprops/action-gh-release@v2` |
| Draft | `false` |
| Pre-release | `false` |

### APK Artifact

| Field | Value / Description |
|-------|-------------------|
| Build command | `flutter build apk --build-name=$VERSION --build-number=$BUILD_NUMBER --release` |
| Output path | `build/app/outputs/apk/release/app-release.apk` |
| versionName | Derived from tag (e.g., `1.2.0`) |
| versionCode | Derived from tag (e.g., `10200`) |
| Uploaded to | GitHub Release assets |
| Retention | Permanent (part of GitHub Release, no expiry) |

### README (`README.md`)

| Field | Value / Description |
|-------|-------------------|
| File path | `README.md` (repo root) |
| Replaces | Generic Flutter template README |
| Required sections | App overview, live web link, APK download instructions, release guide (how to tag), spec-driven development note with speckit link |
| Speckit URL | `[SPECKIT_URL]` — placeholder; developer must fill in before merging |

---

## State Transitions

```
Developer pushes commit to main
  → ci.yml triggers
    → test (flutter analyze + flutter test)
    → build-web (flutter build web → GitHub Pages)
    [APK build: SKIPPED]

Developer pushes tag v1.2.0
  → release.yml triggers
    → test (flutter analyze + flutter test)
    → build-web (flutter build web → GitHub Pages)
    → build-apk (flutter build apk --build-name=1.2.0 --build-number=10200)
    → create-release (softprops/action-gh-release → GitHub Release v1.2.0 + APK asset)
```
