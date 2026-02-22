# Tasks: Release Management & README

**Input**: Design documents from `/specs/006-release-management/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Tests**: No new Flutter unit/widget tests (no Dart code changes). Acceptance verified by observing CI pipeline behavior and README content per quickstart.md.

**Organization**: 3 user stories — US1 (CI restructuring), US2 (version injection), US3 (README). US3 is fully independent. US2 builds on US1's release.yml.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other [P] tasks (different files, no dependencies)
- **[Story]**: User story mapping (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Understand the current state of `.github/workflows/ci.yml` before editing

- [ ] T001 Read `.github/workflows/ci.yml` and note its current 3-job structure (test, build-web, build-apk) and trigger configuration

---

## Phase 2: US1 — Controlled Release Trigger (Priority: P1) 🎯 MVP

**Goal**: Restructure CI into two workflows — fast CI on every push to `main` (no APK), release pipeline only on semver tags.

**Independent Test**: Push a plain commit to `main` → observe only 2 jobs in Actions tab (test + build-web, no build-apk). Then push `v0.1.0` tag → observe 4 jobs in release.yml run and a GitHub Release appears.

- [ ] T002 [US1] Modify `.github/workflows/ci.yml` — remove the `build-apk` job entirely; rename workflow to `CI`; keep `test` and `build-web` jobs unchanged; verify permissions remain `contents: read`, `pages: write`, `id-token: write`
- [ ] T003 [US1] Create `.github/workflows/release.yml` with: trigger `on: push: tags: ['v[0-9]+.[0-9]+.[0-9]+']`; permissions `contents: write`, `pages: write`, `id-token: write`; 4 jobs in order: (1) `test` (flutter analyze + flutter test, timeout 15min), (2) `build-web` (needs: test; flutter build web --release --base-href=/niessl.org.recipes/; upload-pages-artifact@v3; deploy-pages@v4), (3) `build-apk` (needs: test; flutter build apk --release; upload-artifact@v4 name `niessl-recipes-apk-${{ github.ref_name }}` retention-days: 1), (4) `create-release` (needs: [build-web, build-apk]; download-artifact@v4; softprops/action-gh-release@v2 with name `${{ github.ref_name }}`, fixed body "## niessl.org recipes ${{ github.ref_name }}\n\n🌐 **Web app**: https://antipodos.github.io/niessl.org.recipes/\n📱 **Android APK**: Download from the assets below.", files: app-release.apk, draft: false, prerelease: false); all jobs use `subosito/flutter-action@v2` with `flutter-version: '3.35.6'`

**Checkpoint**: ci.yml now has 2 jobs only. release.yml exists and is syntactically valid.

---

## Phase 3: US2 — Semantic Version Management (Priority: P2)

**Goal**: APK versionName and versionCode are automatically derived from the pushed git tag — no manual editing.

**Independent Test**: After a release triggered by `v1.2.0`, download the APK and confirm `aapt dump badging app-release.apk | grep versionName` returns `versionName='1.2.0'`.

- [ ] T004 [US2] Add version extraction to `build-apk` job in `.github/workflows/release.yml` — insert a step before `flutter build apk` that runs: `VERSION=${GITHUB_REF_NAME#v}`, `MAJOR=$(echo $VERSION | cut -d. -f1)`, `MINOR=$(echo $VERSION | cut -d. -f2)`, `PATCH=$(echo $VERSION | cut -d. -f3)`, `BUILD_NUMBER=$((MAJOR * 10000 + MINOR * 100 + PATCH))`, `echo "VERSION=$VERSION" >> $GITHUB_ENV`, `echo "BUILD_NUMBER=$BUILD_NUMBER" >> $GITHUB_ENV`; update `flutter build apk` command to `flutter build apk --build-name=$VERSION --build-number=$BUILD_NUMBER --release`

**Checkpoint**: release.yml build-apk job derives versionName from tag (e.g., tag `v1.2.0` → `--build-name=1.2.0 --build-number=10200`).

---

## Phase 4: US3 — Informative README (Priority: P3)

**Goal**: Replace the generic Flutter template README with project-specific documentation.

**Independent Test**: Open `README.md` on GitHub and confirm within 30 seconds: app purpose is clear, web link is present, APK download path is described, release instructions are provided, speckit is linked.

- [ ] T005 [P] [US3] Write `README.md` — replace Flutter template with 5 required sections: (1) H1 "niessl.org recipes" + 1-paragraph app description (recipe companion app for dinner.niessl.org); (2) "Live web app" section with direct link to `https://antipodos.github.io/niessl.org.recipes/`; (3) "Getting the Android app" section explaining to visit the GitHub Releases page and sideload the APK; (4) "Creating a release" section with step-by-step instructions (`git tag vX.Y.Z && git push origin vX.Y.Z`) explaining this triggers the automated release pipeline; (5) "About this project" section noting it is an experiment in spec-driven development, linking to `https://github.com/github/spec-kit`

**Checkpoint**: README renders correctly on GitHub with all 5 sections visible.

---

## Phase 5: Polish & Verification

**Purpose**: Commit, validate CI behavior, and perform acceptance verification.

- [ ] T006 Commit changes to branch `006-release-management` — stage `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `README.md`; run `flutter analyze` to confirm no issues introduced
- [ ] T007 Push branch `006-release-management`; open PR to `main`; observe CI workflow in Actions tab — confirm it runs under name "CI" with exactly 2 jobs (`test` and `build-web`) and no `build-apk` job
- [ ] T008 Merge PR to `main`; push tag `v0.1.0` (`git tag v0.1.0 && git push origin v0.1.0`); verify in Actions tab that "Release" workflow runs with 4 jobs; verify GitHub Releases tab shows release `v0.1.0` with APK asset and correct body containing the web app link

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (US1)**: Depends on Phase 1 (T001 informs T002/T003)
- **Phase 3 (US2)**: Depends on T003 (release.yml must exist to add version extraction)
- **Phase 4 (US3)**: Independent — can run in parallel with Phases 2 and 3
- **Phase 5 (Polish)**: Depends on all implementation tasks (T002–T005)

### User Story Dependencies

- **US1 (P1)**: After reading ci.yml (T001); no other dependencies
- **US2 (P2)**: After US1's T003 (modifies release.yml); extends the build-apk job
- **US3 (P3)**: Fully independent — can be written at any time

### Within Each User Story

- T002 before T003 (understand ci.yml before creating release.yml — shared pattern)
- T003 before T004 (release.yml must exist before adding version extraction)
- T005 has no ordering constraints (README is standalone)

### Parallel Opportunities

- T005 [US3] can run in parallel with any of T001–T004 (different file, no dependencies)
- T006 must follow all of T002–T005

---

## Parallel Example

```text
# Once T001 is done, these can proceed:
Parallel track A: T002 → T003 → T004  (.github/workflows/ files)
Parallel track B: T005                (README.md — fully independent)

# When both tracks complete:
Sequential:       T006 → T007 → T008  (commit → PR → verify release)
```

---

## Implementation Strategy

### MVP (US1 only — fastest path to value)

1. T001 — read ci.yml
2. T002 — remove build-apk from ci.yml
3. T003 — create release.yml (without version injection)
4. T006 → T007 — commit and verify CI is fast again
5. **STOP and VALIDATE**: APK no longer builds on every push ✅

### Full Delivery (all 3 stories)

1. MVP above
2. T004 — add version extraction to release.yml
3. T005 — write README.md
4. T008 — push tag and verify complete release pipeline

### Notes

- No new Flutter unit tests needed — all validation is via CI observation and README review
- The `[P]` marker on T005 signals it can be worked on at any point alongside CI changes
- T008 is the key end-to-end acceptance test — a real `v0.1.0` tag should be pushed to verify everything works together before closing this feature branch
