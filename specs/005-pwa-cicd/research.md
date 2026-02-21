# Research: PWA Hosting & CI/CD Pipeline

**Feature**: 005-pwa-cicd
**Date**: 2026-02-21
**Sources**: Flutter web PWA configuration research, GitHub Actions CI/CD patterns research

---

## Decision 1: GitHub Actions — Flutter Setup Action

**Decision**: Use `subosito/flutter-action@v2`

**Rationale**: This is the current stable community-maintained action for Flutter. `v2` supports `cache: true` to cache Dart pub dependencies and Flutter artifacts (~500 MB saved), reducing run time significantly. Pinned to `flutter-version: '3.35.6'` with `channel: 'stable'` for reproducible builds.

**Note**: `v4` does not exist — the research phase incorrectly suggested it. The real latest tag is `v2`.

**Alternatives considered**:
- `flutter-action@v1` — older, less maintained
- Manually installing Flutter via `curl` — fragile, no caching, unnecessary complexity

---

## Decision 2: GitHub Pages Deployment Strategy

**Decision**: Use `actions/upload-pages-artifact@v3` + `actions/deploy-pages@v4` (official GitHub approach)

**Rationale**: These are GitHub's own first-party actions for Pages deployment. They use OIDC tokens (`id-token: write` permission) instead of a `GITHUB_TOKEN` secret, which is the modern and more secure approach. No `gh-pages` branch needs to be manually created; GitHub manages the Pages environment automatically.

**Alternatives considered**:
- `peaceiris/actions-gh-pages@v3` — third-party, requires `GITHUB_TOKEN` secret, requires manual `gh-pages` branch setup; not recommended for new projects in 2026
- Pushing to `gh-pages` branch manually — error-prone, no environment tracking in Actions UI

---

## Decision 3: Flutter Web Base Path

**Decision**: `flutter build web --release --base-href=/niessl.org.recipes/`

**Rationale**: The GitHub Pages URL is `https://antipodos.github.io/niessl.org.recipes/` — a subdirectory under the GitHub Pages domain. Without `--base-href`, all asset paths (JS, CSS, icons) would resolve against the root (`/`) and return 404. This flag injects the correct base path into the generated `index.html`.

**Alternatives considered**:
- Custom domain at root — explicitly out of scope per spec assumptions
- Manually editing `web/index.html` `<base href>` — brittle; overwritten on next build

---

## Decision 4: PWA Web Platform Enablement

**Decision**: Run `flutter create --platforms=web .` once to scaffold the `web/` directory

**Rationale**: The project currently has no `web/` directory (confirmed by inspection). Flutter does not include web support files (`web/index.html`, `web/manifest.json`, `web/icons/`) until web is added as a target platform. Running `flutter create --platforms=web .` in the project root adds the `web/` directory without touching existing source code.

**Alternatives considered**:
- Manually creating `web/index.html` and `web/manifest.json` from scratch — error-prone and misses service worker registration wiring that Flutter injects into `index.html`
- Copying from another Flutter project — same risk of mismatched versions

---

## Decision 5: PWA Manifest Configuration

**Decision**: Update `web/manifest.json` (after scaffold) with project-specific metadata

**Key values**:
```json
{
  "name": "niessl.org recipes",
  "short_name": "Recipes",
  "start_url": "/niessl.org.recipes/",
  "scope": "/niessl.org.recipes/",
  "display": "standalone",
  "background_color": "#F5EFE7",
  "theme_color": "#B85C38",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

**Rationale**: `start_url` and `scope` must match the `--base-href` path so the browser recognises the PWA boundary correctly. `theme_color` matches the warm terracotta seed colour (`0xFFB85C38`). `background_color` matches `_warmCreamSurface`. `display: "standalone"` hides the browser chrome on launch (US2 acceptance criterion).

**Alternatives considered**:
- `display: "fullscreen"` — hides status bar; `standalone` is more appropriate for a utility app and has broader browser support

---

## Decision 6: PWA Icons

**Decision**: Update `flutter_launcher_icons` config in `pubspec.yaml` to enable web icon generation (`web.generate: true`), then run `dart run flutter_launcher_icons`

**Rationale**: `flutter_launcher_icons` already generates Android/iOS icons from `assets/logo.png` (done in feature 004). The same tool can generate the `web/icons/Icon-*.png` files by setting `web.generate: true`. This keeps icon generation in one place and avoids manual image resize steps.

**Current state**: `pubspec.yaml` has `web: generate: false` — this must be changed to `true`.

**Alternatives considered**:
- ImageMagick/ffmpeg manual resize — extra tooling dependency, not reproducible in CI
- Using Flutter's default web icons (Flutter logo) — does not satisfy FR-004 (niessl.org logo required)

---

## Decision 7: Service Worker

**Decision**: Rely on Flutter's auto-generated service worker; no custom service worker code needed

**Rationale**: `flutter build web --release` auto-generates `flutter_service_worker.js` and injects the registration script into `index.html`. This covers FR-005: caches all UI assets (JS, CSS, fonts, icons) for fast repeat visits and offline shell loading. Recipe API data is explicitly out of scope for offline caching per spec assumptions.

**Alternatives considered**:
- Workbox custom service worker — unnecessary complexity; Flutter's built-in caching satisfies all spec requirements
- `serviceWorkerVersion: null` in `flutter_service_worker.js` to disable — would break FR-005

---

## Decision 8: APK Build

**Decision**: `flutter build apk --release` producing `build/app/outputs/apk/release/app-release.apk`

**Rationale**: This produces an unsigned release APK suitable for sideloading (direct install). The spec explicitly states "unsigned or debug build suitable for direct device installation". The release variant is preferred over debug because it is smaller, not annotated with debug info, and closer to a production build.

**Note**: The APK is signed with Flutter's built-in debug keystore during `--release` when no signing config is provided in `android/app/build.gradle`. This is acceptable for sideloading per spec assumption.

**Alternatives considered**:
- `flutter build apk` (debug) — larger binary, debug annotations; not preferred
- `flutter build appbundle` — Google Play Store format; explicitly out of scope

---

## Decision 9: Workflow Structure (Job Topology)

**Decision**: 3-job DAG: `test` → `build-web` (parallel) + `build-apk` (parallel)

```
test (ubuntu-latest)
  ↓
  ├→ build-web → upload-pages-artifact → deploy-pages
  └→ build-apk → upload APK artifact (90-day retention)
```

**Rationale**: `build-web` and `build-apk` both have `needs: test`, so no deployment or artifact upload occurs if tests fail (FR-002, SC-005). Running `build-web` and `build-apk` in parallel after `test` saves ~4–5 minutes compared to sequential execution. Total estimated runtime: ~9–11 minutes.

**Alternatives considered**:
- Single job (sequential) — simpler YAML but ~15 min total; `build-apk` blocked while web deploys
- `build-web` and `build-apk` with no `needs` guard — violates FR-002

---

## Decision 10: Workflow Trigger

**Decision**: Trigger on `push` to `main` only (not on PRs)

**Rationale**: The spec states "triggered automatically on every merge to the main branch" (FR-001). Deploying from PRs would overwrite the live GitHub Pages with in-progress work and upload untested APK artifacts. PR builds are out of scope.

**Alternatives considered**:
- Trigger on `push` to all branches — too broad; pollutes artifact list with branch builds
- Trigger on `pull_request` as well — useful for test feedback on PRs but deployment steps must be conditional; adds complexity not in scope

---

## Decision 11: `index.html` Meta Tags

**Decision**: Add Apple PWA meta tags to `web/index.html` after scaffold

**Required additions**:
```html
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="niessl.org recipes">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
```

**Rationale**: Safari on iOS does not read `manifest.json` for Add to Home Screen. These tags are required for the iOS "Add to Home Screen" flow (US2 acceptance criterion: "Chrome or Safari on a mobile device").

---

## Estimated CI Runtime

| Job | Duration |
|-----|----------|
| test: checkout + Flutter setup (cached) | ~45 s |
| test: `flutter pub get` + `flutter analyze` | ~50 s |
| test: `flutter test` (94 tests) | ~3–4 min |
| build-web: `flutter build web --release` | ~4–5 min |
| build-web: deploy to Pages | ~30 s |
| build-apk: `flutter build apk --release` | ~3–4 min |
| build-apk: upload artifact | ~20 s |
| **Total (parallel jobs after test)** | **~9–11 min** |

SC-001 (within 10 min) and SC-003 (within 15 min) are satisfied.
