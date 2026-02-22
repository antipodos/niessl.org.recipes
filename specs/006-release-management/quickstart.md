# Quickstart & Verification: Release Management (006)

**Branch**: `006-release-management` | **Date**: 2026-02-22

---

## US1 — Controlled Release Trigger

### Prerequisite
- Both `ci.yml` (updated) and `release.yml` (new) are merged to `main`.

### Verify: Plain push does NOT build APK

1. Make any trivial commit to `main` (e.g., update a comment):
   ```bash
   git commit --allow-empty -m "chore: verify ci pipeline"
   git push origin main
   ```
2. Open the repository on GitHub → **Actions** tab.
3. Observe the running workflow is named **"CI"** (from `ci.yml`).
4. Confirm the workflow has exactly 2 jobs: `test` and `build-web`.
5. Confirm **no job named `build-apk` or `create-release` appears**.
6. Confirm **no new GitHub Release** is created (Releases tab remains unchanged).

**Pass criteria**: Workflow completes green with 2 jobs only. No APK. No GitHub Release.

---

### Verify: Tag push DOES create a GitHub Release with APK

1. Create and push a semver tag:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```
2. Open the repository on GitHub → **Actions** tab.
3. Observe the running workflow is named **"Release"** (from `release.yml`).
4. Confirm the workflow has 4 jobs: `test`, `build-web`, `build-apk`, `create-release`.
5. Wait for completion (~10–12 min including APK build).
6. Open the **Releases** tab and confirm:
   - A release named `v0.1.0` exists.
   - The release body contains the version number and the web app link.
   - An APK file is attached as a downloadable asset.

**Pass criteria**: GitHub Release `v0.1.0` exists with APK asset and correct body.

---

## US2 — Semantic Version Management

### Prerequisite
- US1 verified: release pipeline runs on tag push.

### Verify: APK versionName matches the tag

1. Download the APK from the GitHub Release assets.
2. Rename it to `app.apk` and run:
   ```bash
   # Using aapt (Android SDK build-tools)
   aapt dump badging app.apk | grep versionName
   ```
   Expected output includes: `versionName='0.1.0'`

3. Or install the APK on an Android device/emulator and check:
   - **Settings → Apps → niessl.org recipes → App info**
   - Version should read `0.1.0`

**Pass criteria**: versionName reported by the APK matches the tag that triggered the build (e.g., `v0.1.0` → `0.1.0`).

### Verify: Two sequential releases are distinct

1. Push tag `v0.1.0` (already done above).
2. Push tag `v0.2.0`:
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```
3. Check **Releases** tab — two distinct releases should exist: `v0.1.0` and `v0.2.0`.
4. Each has its own APK with the correct `versionName`.

**Pass criteria**: Both releases coexist; assets are not overwritten.

---

## US3 — Informative README

### Verify: README covers all required content

Open `README.md` (or view it on GitHub) and confirm each of the following is present within 30 seconds of reading:

| Item | Where to find it |
|------|-----------------|
| App description | First paragraph / header |
| Live web PWA link | Near the top — links to `https://antipodos.github.io/niessl.org.recipes/` |
| APK download instructions | "Getting the Android app" section → points to Releases page |
| Release guide (how to tag) | "Creating a release" section → `git tag v1.0.0 && git push origin v1.0.0` |
| Spec-driven development note | "About this project" or "Development" section → link to speckit |

**Pass criteria**: A developer unfamiliar with the project can understand all 5 items without reading source code or CI YAML.

---

## Edge Case Verification

### Tag with failing tests

1. Temporarily introduce a failing test (e.g., change an expected value in a unit test).
2. Push the tag:
   ```bash
   git tag v0.0.1-bad
   git push origin v0.0.1-bad
   ```
3. Confirm the `test` job fails in the release workflow.
4. Confirm `build-apk` and `create-release` jobs do **not** run (they have `needs: test`).
5. Confirm **no GitHub Release is created** for `v0.0.1-bad`.

**Pass criteria**: No release artifact produced from a failed build.

### Invalid tag format

1. Push a non-semver tag:
   ```bash
   git tag release-1
   git push origin release-1
   ```
2. Confirm **no workflow triggers** in the Actions tab.

**Pass criteria**: The `release.yml` trigger pattern `v[0-9]+.[0-9]+.[0-9]+` does not match `release-1`; no run starts.
