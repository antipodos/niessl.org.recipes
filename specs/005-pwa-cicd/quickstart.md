# Quickstart & Acceptance Test Guide: PWA Hosting & CI/CD Pipeline

**Feature**: 005-pwa-cicd
**Date**: 2026-02-21

---

## Prerequisites

- GitHub repository: `antipodos/niessl.org.recipes` (public)
- GitHub Pages enabled: Settings → Pages → Source: **GitHub Actions**
- Flutter 3.35.6 installed locally (for local verification steps)
- Android device or emulator with USB debugging (for APK verification)

---

## US1 — Verify: Public Web App on GitHub Pages

### After a merge to main completes:

1. Navigate to `https://antipodos.github.io/niessl.org.recipes/` in any browser
2. **Expected**: App loads within 5 seconds; recipe list grid is visible
3. **Expected**: Search bar is functional — type a recipe name and list filters
4. **Expected**: Tap a tag chip — list filters to that tag
5. **Expected**: Tap a recipe tile — detail screen opens with recipe content

### Verify deployment timing (SC-001):
- Note the time the GitHub Actions run completes (Actions tab)
- Reload the GitHub Pages URL
- **Expected**: Updated version visible within 10 minutes of run completion

### Verify API error state (edge case):
- Disable network on device/browser
- Reload the page
- **Expected**: Error view with retry button appears (same as Android)

---

## US2 — Verify: Installable PWA

### On Chrome (Android or desktop):

1. Open `https://antipodos.github.io/niessl.org.recipes/`
2. **Expected**: Install prompt appears in the browser address bar (or "Add to Home Screen" in the browser menu)
3. Tap "Install" / "Add to Home Screen"
4. **Expected**: App icon appears on home screen with niessl.org logo (not Flutter default)
5. Tap the installed icon
6. **Expected**: App launches in standalone mode (no browser address bar, no browser chrome)
7. **Expected**: Launch completes within 3 seconds

### On Safari (iOS):

1. Open `https://antipodos.github.io/niessl.org.recipes/` in Safari
2. Tap the Share button → "Add to Home Screen"
3. **Expected**: Shortcut created with niessl.org logo icon and "niessl.org recipes" as the name
4. Tap the shortcut
5. **Expected**: App opens full-screen (standalone mode)

### Verify offline shell (after first visit):

1. Open the installed PWA
2. Disable network / airplane mode
3. Close and reopen the app
4. **Expected**: App shell (loading spinner or error view) appears — UI assets load from cache
5. **Expected**: Recipe list shows error/retry (live API data is not cached — this is expected per spec)

### Verify Lighthouse PWA audit (SC-002):

1. Open `https://antipodos.github.io/niessl.org.recipes/` in Chrome
2. Open DevTools → Lighthouse tab
3. Run audit with "Progressive Web App" category selected
4. **Expected**: All PWA checklist items pass (green)

---

## US3 — Verify: Android APK Artifact from CI

### From a GitHub Actions run:

1. Navigate to `https://github.com/antipodos/niessl.org.recipes/actions`
2. Open the latest workflow run triggered by a merge to main
3. Scroll to the "Artifacts" section at the bottom of the run summary
4. **Expected**: `niessl-recipes-apk` artifact is listed
5. Download the artifact ZIP; extract `app-release.apk`

### Install on Android device:

1. Transfer the APK to an Android device (API 21+)
2. Enable "Install from unknown sources" if not already enabled
3. Install the APK
4. Launch the app
5. **Expected**: App functions identically to the locally-built version:
   - Recipe list loads
   - Search and filter work
   - Detail screen opens with photo, overlay bar, markdown recipe

### Verify pipeline failure halts deployment (SC-005):

1. Introduce a deliberate test failure on a branch (e.g., add `expect(1, 2)` to any test)
2. Merge to main (or simulate by pushing directly)
3. **Expected**: `test` job fails; `build-web` and `build-apk` jobs show "Skipped"
4. **Expected**: No new deployment appears on GitHub Pages
5. **Expected**: No new APK artifact is uploaded
6. Revert the deliberate failure

---

## Local Verification: Web Build

To verify the web build locally before pushing:

```bash
# Build web with the correct base-href
flutter build web --release --base-href=/niessl.org.recipes/

# Serve locally (requires a static file server)
# Option 1: Python
python -m http.server 8080 --directory build/web

# Option 2: npx serve
npx serve build/web -p 8080
```

Open `http://localhost:8080/niessl.org.recipes/` in a browser.

**Note**: The `start_url` in `manifest.json` points to `/niessl.org.recipes/` — if serving locally without a subdirectory path, the manifest install prompt may not appear. This is expected and does not indicate a bug.

---

## Local Verification: PWA Manifest

After running `flutter build web --release --base-href=/niessl.org.recipes/`:

1. Open `build/web/manifest.json` and verify:
   - `"name": "niessl.org recipes"`
   - `"theme_color": "#B85C38"`
   - `"display": "standalone"`
   - `"start_url": "/niessl.org.recipes/"`
   - Icons array contains 192x192 and 512x512 entries

2. Open `build/web/index.html` and verify:
   - `<base href="/niessl.org.recipes/">` is present
   - `<meta name="theme-color" content="#B85C38">` is present
   - `<link rel="manifest" href="manifest.json">` is present

---

## GitHub Pages Settings (one-time setup)

In the GitHub repository:
1. Settings → Pages
2. Source: **GitHub Actions** (NOT "Deploy from a branch")
3. No custom domain (leave blank)

This is required for `actions/deploy-pages@v4` to work. The Actions workflow handles all deployment; no manual branch setup is needed.
