# Tasks: PWA Hosting & CI/CD Pipeline

**Input**: Design documents from `/specs/005-pwa-cicd/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Constitution**: Test-First (NON-NEGOTIABLE) — this feature adds no new Dart behaviour; no new Dart tests are required. The CI pipeline itself serves as the integration acceptance test (the `test` job runs the existing 94-test suite as the gate).

**Organization**: Three user stories. US1 (web app on Pages, P1) and US2 (installable PWA, P1) are co-equal and both required for MVP. US3 (APK artifact, P2) adds the build-apk CI job.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the web platform directory and CI workflow directory before any configuration begins.

- [x] T001 Run `flutter create --platforms=web .` in the repository root to scaffold `web/index.html`, `web/manifest.json`, `web/favicon.png`, and `web/icons/` — verify these files are created without changes to `lib/`, `test/`, or `android/`
- [x] T002 [P] Create `.github/workflows/` directory in the repository root (needed for T005)

**Checkpoint**: `web/` directory and `.github/workflows/` directory exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify the web build target works before writing any configuration.

**⚠️ CRITICAL**: No user story work can begin until the web build succeeds.

- [x] T003 Run `flutter pub get` then `flutter build web --release --base-href=/niessl.org.recipes/` and confirm the build completes without errors and `build/web/index.html` contains `<base href="/niessl.org.recipes/">` — this smoke-tests the web target before any manifest/icon/workflow work begins

**Checkpoint**: Web build succeeds locally. User story work can begin.

---

## Phase 3: User Story 1 — Public Web App on GitHub Pages (Priority: P1) 🎯 MVP

**Goal**: A CI workflow that runs on merge to main, gates on tests passing, and deploys the Flutter web build to GitHub Pages.

**Independent Test**: After merging to main, navigate to `https://antipodos.github.io/niessl.org.recipes/` in any browser. App loads within 5 seconds, recipe list is visible, search and tag filter work, tapping a tile opens the detail screen. (See quickstart.md US1 section.)

### Implementation for User Story 1

- [x] T004 [US1] Create `.github/workflows/ci.yml` with:
  - `on: push: branches: [main]`
  - Root `permissions: { contents: read, pages: write, id-token: write }`
  - `test` job: `runs-on: ubuntu-latest`, `timeout-minutes: 15`; steps: `actions/checkout@v4`, `subosito/flutter-action@v4` with `flutter-version: 3.35.6 / channel: stable / cache: true`, `flutter pub get`, `flutter analyze`, `flutter test`
  - `build-web` job: `needs: test`, `runs-on: ubuntu-latest`, `timeout-minutes: 20`; `environment: { name: github-pages, url: "${{ steps.deployment.outputs.page_url }}" }`; steps: checkout, flutter setup (same config as test job), `flutter pub get`, `flutter build web --release --base-href=/niessl.org.recipes/`, `actions/upload-pages-artifact@v3` (`path: build/web`), `actions/deploy-pages@v4` (`id: deployment`)

**Checkpoint**: US1 complete — CI workflow deploys web app on merge to main.

---

## Phase 4: User Story 2 — Installable PWA (Priority: P1)

**Goal**: The deployed web app meets the PWA criteria: correct manifest metadata, logo icons, and Apple meta tags so browsers show an "Add to Home Screen" prompt.

**Independent Test**: Open `https://antipodos.github.io/niessl.org.recipes/` in Chrome on a mobile device. Browser offers "Add to Home Screen" / install prompt. After installing, app launches standalone (no browser chrome) with the niessl.org logo. Lighthouse PWA audit passes all checklist items. (See quickstart.md US2 section.)

### Implementation for User Story 2

- [x] T005 [US2] Update `web/manifest.json` — replace scaffolded defaults with:
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
      { "src": "icons/Icon-192.png",          "sizes": "192x192", "type": "image/png", "purpose": "any" },
      { "src": "icons/Icon-512.png",          "sizes": "512x512", "type": "image/png", "purpose": "any" },
      { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
      { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
    ]
  }
  ```
- [x] T006 [P] [US2] Add Apple PWA meta tags to `web/index.html` inside `<head>` (after the existing `<link rel="manifest" href="manifest.json">`):
  ```html
  <meta name="theme-color" content="#B85C38">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="niessl.org recipes">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  ```
- [x] T007 [US2] Update `flutter_launcher_icons:` section in `pubspec.yaml`: change `web: generate: false` to `web: generate: true` and add `web.image_path: "assets/logo.png"` and `web.background_color: "#F5EFE7"` — full section becomes:
  ```yaml
  flutter_launcher_icons:
    android: true
    ios: true
    image_path: "assets/logo.png"
    adaptive_icon_background: "#FFFFFF"
    adaptive_icon_foreground: "assets/logo.png"
    min_sdk_android: 21
    web:
      generate: true
      image_path: "assets/logo.png"
      background_color: "#F5EFE7"
  ```
- [x] T008 [US2] Run `dart run flutter_launcher_icons` to generate `web/icons/Icon-192.png`, `web/icons/Icon-512.png`, `web/icons/Icon-maskable-192.png`, `web/icons/Icon-maskable-512.png` from `assets/logo.png` (depends on T007)

**Checkpoint**: US2 complete — manifest, Apple meta tags, and logo icons are in place. Run `flutter build web --release --base-href=/niessl.org.recipes/` and verify `build/web/manifest.json` and `build/web/icons/Icon-192.png` are present in the output.

---

## Phase 5: User Story 3 — Android APK Artifact from CI (Priority: P2)

**Goal**: A downloadable APK artifact attached to every successful merge-to-main CI run.

**Independent Test**: Open the GitHub Actions run for a merge-to-main commit. Find the `niessl-recipes-apk` artifact in the Artifacts section. Download and install on an Android device (API 21+). App launches and functions normally. (See quickstart.md US3 section.)

### Implementation for User Story 3

- [x] T009 [US3] Add `build-apk` job to `.github/workflows/ci.yml` (append after `build-web` job):
  ```yaml
  build-apk:
    name: Build Android APK
    needs: test
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v4
        with:
          flutter-version: '3.35.6'
          channel: 'stable'
          cache: true
      - name: Get dependencies
        run: flutter pub get
      - name: Build APK
        run: flutter build apk --release
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        if: success()
        with:
          name: niessl-recipes-apk
          path: build/app/outputs/apk/release/app-release.apk
          retention-days: 90
          if-no-files-found: error
  ```

**Checkpoint**: US3 complete — `build-apk` job runs in parallel with `build-web` after `test` passes.

---

## Phase 6: Polish & Quality Gates

**Purpose**: Enforce all quality gates before the feature is considered complete.

- [x] T010 Run `flutter analyze` — must report zero issues
- [x] T011 [P] Run `dart format --set-exit-if-changed .` — must report zero diffs
- [x] T012 [P] Run `flutter test` and confirm all 94 tests still pass (web platform addition must not break any existing tests)
- [x] T013 Run `flutter build web --release --base-href=/niessl.org.recipes/` locally and verify: `build/web/manifest.json` contains `"name": "niessl.org recipes"` and `"theme_color": "#B85C38"` and `"start_url": "/niessl.org.recipes/"`; `build/web/icons/Icon-192.png` exists
- [ ] T014 Enable GitHub Pages on the repository (one-time, manual): GitHub → Settings → Pages → Source: **GitHub Actions** (not "Deploy from a branch") — required before first deploy; the Actions workflow manages all deployment
- [x] T015 [P] Push `005-pwa-cicd` branch and open a PR; confirm the Actions tab shows the workflow file is valid (green parse, all 3 jobs visible in the UI) without merging yet — smoke-tests the YAML syntax

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — T001 and T002 can run in parallel
- **Foundational (Phase 2)**: T003 depends on T001 (needs `web/` to exist)
- **US1 (Phase 3)**: T004 depends on T002 (needs `.github/workflows/` directory) and T003 (confirms web target works)
- **US2 (Phase 4)**: T005 depends on T001; T006 depends on T001; T007 and T008 are sequential (T008 runs the generator configured in T007); T005 and T006 can run in parallel with each other
- **US3 (Phase 5)**: T009 depends on T004 (appends to existing `ci.yml`)
- **Polish (Phase 6)**: Depends on all phases complete; T010–T012 can run in parallel; T013 runs after T008

### Within Each User Story

```
US1: T004 (single task — write complete ci.yml with test + build-web jobs)

US2: T005 ─┐
            ├→ (both depend on T001, can run in parallel)
       T006 ─┘
       T007 → T008 (sequential: configure then generate)

US3: T009 (depends on T004 — appends to ci.yml)
```

### Parallel Opportunities

- T001 and T002 (setup): parallel
- T005 and T006 (manifest and index.html): parallel (different files)
- T010, T011, T012 (quality gates): parallel
- T013 and T015 (build verification and PR push): parallel

---

## Parallel Example: User Story 2

```bash
# T005 and T006 can start simultaneously (different files):
Task T005: Update web/manifest.json with PWA metadata
Task T006: Add Apple meta tags to web/index.html

# After T005 and T006 complete — T007 then T008 must be sequential:
Task T007: Update pubspec.yaml flutter_launcher_icons web section
Task T008: Run dart run flutter_launcher_icons (generates web/icons/)
```

---

## Implementation Strategy

### MVP First (US1 + US2 together — both P1)

1. Complete Phase 1: Setup (T001 + T002 in parallel)
2. Complete Phase 2: Foundational (T003)
3. Complete Phase 3: US1 — write CI workflow with test + web deploy jobs (T004)
4. Complete Phase 4: US2 — manifest, meta tags, icons (T005–T008)
5. **STOP and VALIDATE locally**: verify `build/web/manifest.json` is correct
6. Enable GitHub Pages (T014) and push branch (T015)

### Adding P2 (US3)

7. Complete Phase 5: US3 — add APK job to workflow (T009)
8. Complete Phase 6: Polish (T010–T015)
9. Merge to main; verify live deployment

### Incremental Delivery

- After Phase 3 (US1 CI merged): App is live on GitHub Pages on every merge
- After Phase 4 (US2 PWA config): App is installable from the browser
- After Phase 5 (US3 APK artifact): Every merge also produces a downloadable APK

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- No new Dart tests required — the existing 94-test suite is the gate for all CI jobs
- `flutter create --platforms=web .` is safe to run on an existing project — it only adds the `web/` directory and does not modify `lib/`, `android/`, or any existing files
- `dart run flutter_launcher_icons` regenerates Android/iOS icons too — this is harmless (they were already correct after feature 004)
- T014 (GitHub Pages settings) is a one-time manual step in the GitHub UI; it cannot be automated via the workflow itself
- The `permissions` block in `ci.yml` must be at the root level (not per-job) so that `build-web` can inherit `pages: write` and `id-token: write`
