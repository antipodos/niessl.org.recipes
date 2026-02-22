# Research: Release Management (006)

**Branch**: `006-release-management` | **Date**: 2026-02-22

---

## Decision 1: Workflow Topology

**Decision**: Two separate workflow files — `ci.yml` (CI on push to `main`) and `release.yml` (release on semver tag push).

**Rationale**: Clean separation of intent. `ci.yml` = "validate every commit fast"; `release.yml` = "ship a versioned build." No `if:` conditionals needed; each file is self-documenting. The tradeoff (minor test-job duplication) is acceptable for the clarity gain.

**Alternatives considered**:
- Single `ci.yml` with `if: startsWith(github.ref, 'refs/tags/')` conditions — avoids duplication but creates a file that does two unrelated things; harder to read at a glance.
- Single file with reusable workflow call — over-engineered for this scale.

---

## Decision 2: GitHub Release Creation Action

**Decision**: `softprops/action-gh-release@v2`

**Rationale**: Most widely adopted maintained action for creating GitHub Releases and uploading file assets in a single step. Handles file globbing, draft/prerelease flags, and auto-generates release name from the tag. The native `gh release create` CLI is a valid alternative but requires shell scripting around file uploads.

**Alternatives considered**:
- `actions/create-release@v1` — **deprecated**, do not use.
- `gh release create` CLI — valid but requires extra shell script; no advantage here.

---

## Decision 3: Version Extraction from Git Tag

**Decision**: Use `${GITHUB_REF_NAME#v}` in bash to strip the `v` prefix from the tag name.

**Rationale**: `GITHUB_REF_NAME` is set automatically by GitHub Actions to the tag name (e.g., `v1.2.0`). The `#v` bash parameter expansion strips the leading `v`, yielding `1.2.0`. No extra tooling required.

**Exact syntax**:
```bash
VERSION=${GITHUB_REF_NAME#v}   # e.g., "1.2.0"
MAJOR=$(echo $VERSION | cut -d. -f1)
MINOR=$(echo $VERSION | cut -d. -f2)
PATCH=$(echo $VERSION | cut -d. -f3)
BUILD_NUMBER=$((MAJOR * 10000 + MINOR * 100 + PATCH))
```

**Alternatives considered**:
- `github.run_number` for versionCode — monotonically increasing but not tied to the version; harder to trace which code version a given versionCode came from.

---

## Decision 4: Flutter APK Version Injection

**Decision**: `flutter build apk --build-name=$VERSION --build-number=$BUILD_NUMBER --release`

**Rationale**: `--build-name` maps directly to Android `versionName` (e.g., `1.2.0`); `--build-number` maps to `versionCode` (e.g., `10200`). This is the standard Flutter CLI approach — no pubspec.yaml editing required in CI.

**APK output path**: `build/app/outputs/apk/release/app-release.apk`

**Alternatives considered**:
- Edit `pubspec.yaml` in CI and commit back — fragile, creates CI commits on the tag, not recommended.
- Use `flutter_distributor` — over-engineered for this scale.

---

## Decision 5: Tag Pattern for Release Trigger

**Decision**: `push.tags: ['v[0-9]+.[0-9]+.[0-9]+']`

**Rationale**: Strict semver pattern prevents accidental triggers from informal tags (e.g., `backup-1`, `v1`). More explicit than `v*` glob.

**Workflow trigger**:
```yaml
on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
```

---

## Decision 6: Required Permissions

**Decision**: Release workflow needs `contents: write` (to create GitHub Releases and upload assets) plus `pages: write` + `id-token: write` (for GitHub Pages deployment, same as existing CI).

```yaml
permissions:
  contents: write
  pages: write
  id-token: write
```

---

## Decision 7: GitHub Release Body Template

**Decision**: Fixed inline template (no auto-generated changelog). Body set via `softprops/action-gh-release` `body` field:

```
Release ${{ github.ref_name }}

🌐 Web app: https://antipodos.github.io/niessl.org.recipes/
📱 Download the APK from the assets below.
```

**Rationale**: Simple, zero extra tooling, always consistent. Matches the clarification decision (fixed template, no changelog).

---

## Decision 8: Speckit Tool URL

**Decision**: `https://github.com/github/spec-kit`

**Rationale**: Confirmed by the project owner. Use this URL in the README's spec-driven development section.

**Action**: No placeholder needed — use the URL directly in the README implementation task.
