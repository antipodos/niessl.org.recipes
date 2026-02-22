# Feature Specification: Release Management & README

**Feature Branch**: `006-release-management`
**Created**: 2026-02-22
**Status**: Draft
**Input**: User description:

## Clarifications

### Session 2026-02-22

- Q: Should the APK be built on every CI run or only during releases? → A: APK is ONLY built during releases (version tag pushes). The APK build step must not exist in the normal CI pipeline at all.
- Q: Should web deployment to GitHub Pages also move to release-only, or continue on every push to `main`? → A: Web deployment continues on every push to `main` (continuous web deployment). Only APK build moves to release-only.
- Q: What should the GitHub Release body contain? → A: A fixed minimal template: version number, link to the live web app, and a note to download the APK below. No auto-generated changelog.
- Q: Should the README mention the development methodology? → A: Yes — the README must include a section explaining that the project is an experiment in spec-driven development, with a link to the speckit tool.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Controlled Release Trigger (Priority: P1)

As a developer, I want to decide exactly when a new APK release happens — not have every commit to `main` produce one. The web PWA continues to deploy on every push to `main` (fast, low cost), but the APK — which takes many minutes to build — is only produced when I deliberately tag a commit with a version number (e.g., `v1.2.0`). Tagging also attaches the APK to a new GitHub Release with the version clearly labeled.

**Why this priority**: The APK build is the expensive operation. Controlling it prevents wasted CI minutes and keeps the daily development pipeline fast. This is the foundational change all other release management depends on.

**Independent Test**: Can be verified by pushing a plain commit to `main` and confirming the web PWA deploys but no APK or GitHub Release is produced, then pushing a version tag and confirming both web and APK are released.

**Acceptance Scenarios**:

1. **Given** a commit is pushed directly to `main` without a version tag, **When** the CI pipeline runs, **Then** tests, static analysis, and web deployment to GitHub Pages run — but no APK is built and no GitHub Release is created.
2. **Given** a developer pushes a tag matching the pattern `v*.*.*` (e.g., `v1.0.0`) to the repository, **When** the CI pipeline runs, **Then** the web PWA is deployed to GitHub Pages AND a release APK is attached to a new GitHub Release.
3. **Given** a tag is pushed, **When** the GitHub Release is created, **Then** the release title and body include the version number and a link to the deployed web app.

---

### User Story 2 - Semantic Version Management (Priority: P2)

As a developer, I want the app's displayed version number to automatically reflect the Git tag that triggered the release. When I release `v1.2.0`, the pubspec.yaml version and the app's `+build` number are updated consistently, so both the APK metadata and any in-app version display are accurate.

**Why this priority**: Without consistent versioning, it's impossible to trace which code is running in a given deployment. Builds on top of US1 (requires the tag-based trigger to exist first).

**Independent Test**: Can be verified by triggering a release with tag `v1.2.0` and confirming the produced APK reports version `1.2.0` in its metadata.

**Acceptance Scenarios**:

1. **Given** a tag `v1.2.0` is pushed, **When** the release pipeline runs, **Then** the web build and APK are produced using version `1.2.0` (major.minor.patch) with no manual pubspec.yaml edit required.
2. **Given** a tag `v2.0.0` is pushed, **When** the APK is installed on a device, **Then** the Android package version name reads `2.0.0`.
3. **Given** two sequential releases `v1.0.0` and `v1.1.0`, **When** both are complete, **Then** each GitHub Release is distinct, clearly labeled with its version, and the artifacts are not overwritten.

---

### User Story 3 - Informative README (Priority: P3)

As a visitor or new contributor to the repository, I want to read a README that explains what the app does, how to get it, and how the release process works. The current README is the default Flutter template and gives no project-specific information.

**Why this priority**: Documentation is valuable but doesn't block releasing. Can be written independently of the CI pipeline changes.

**Independent Test**: Can be verified by reading the README in isolation and confirming it covers: project purpose, live web link, APK download instructions, and how to cut a release.

**Acceptance Scenarios**:

1. **Given** a visitor opens the repository on GitHub, **When** they read the README, **Then** they can understand the app's purpose, find a direct link to the live web PWA, and see a note that the project was built using spec-driven development with speckit.
2. **Given** a user wants to install the APK, **When** they read the README, **Then** they find clear instructions directing them to the GitHub Releases page to download the latest APK.
3. **Given** a developer wants to cut a new release, **When** they read the README, **Then** they find a step-by-step guide explaining how to tag a commit to trigger the automated release pipeline.

---

### Edge Cases

- What happens when a tag is pushed but the test job fails? The release job must not proceed — only green builds produce releases.
- What happens when two tags are pushed in quick succession? Each tag triggers an independent pipeline run; both releases are created with their respective versions.
- What happens if the tag format is invalid (e.g., `v1` or `release-1.0`)? The release workflow only matches `v*.*.*` — invalid tags trigger nothing.
- What happens if a tag is deleted and re-pushed? The re-push triggers a new release run; the implementation should handle (or warn about) overwriting an existing GitHub Release.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On plain commits to `main`, the CI pipeline MUST run tests, static analysis, and web deployment to GitHub Pages. The APK build step MUST be entirely absent from this run — it is never triggered by a plain push.
- **FR-002**: The CI pipeline MUST trigger a full release when a Git tag matching the pattern `vMAJOR.MINOR.PATCH` (semantic version) is pushed to the repository.
- **FR-003**: A release MUST produce both a deployed web PWA (GitHub Pages) and an APK attached to a GitHub Release in a single pipeline run. The APK is ONLY built during this release pipeline.
- **FR-004**: The version embedded in the release artifacts MUST be derived automatically from the pushed Git tag — no manual version editing required.
- **FR-005**: Each GitHub Release MUST include: the version tag as the release title, a fixed-template body containing the version number and a link to the live web app, and the APK as a downloadable asset. No auto-generated changelog is required.
- **FR-006**: The APK Android version name MUST match the semantic version from the tag (e.g., tag `v1.2.0` → version name `1.2.0`).
- **FR-007**: The README MUST describe the app's purpose, provide a link to the live web PWA, explain how to download the latest APK, document how to trigger a release, and include a section acknowledging that the project is an experiment in spec-driven development with a link to the speckit tool.
- **FR-008**: The release pipeline MUST only run if the test and analysis gates pass (no releases from broken builds).

### Key Entities

- **Release Tag**: A Git tag in `vMAJOR.MINOR.PATCH` format that is the sole trigger for a production release. Carries the version number used throughout the pipeline.
- **GitHub Release**: A versioned release entry on GitHub containing a title (version), description body, and downloadable APK asset.
- **CI Pipeline**: The automated workflow operating in two modes — (1) continuous integration on every push to `main`: tests + analysis + web deployment, no APK; (2) release on version tag push: tests + analysis + web deployment + APK build + GitHub Release.
- **App Version**: The semantic version string (e.g., `1.2.0`) embedded in the APK metadata and web build. Derived from the release tag.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero unintended APK builds — a plain commit to `main` produces no APK and no GitHub Release. Web deployment still occurs as expected (verified by observing CI run outcome).
- **SC-002**: A single `git tag v1.0.0 && git push origin v1.0.0` command triggers a complete release with no additional manual steps.
- **SC-003**: The APK version name reported on an Android device matches the version tag that triggered the build (100% accuracy).
- **SC-004**: A new contributor can locate the live web app link, APK download instructions, and the spec-driven development context (with speckit link) in the README within 30 seconds.
- **SC-005**: A developer can initiate a release following only the README instructions, without prior knowledge of the CI pipeline internals.

## Assumptions

- The repository is hosted on GitHub with GitHub Actions and GitHub Pages already configured (as established in spec 005-pwa-cicd).
- Releases are developer-initiated only; no automated version bumping or changelog generation is in scope for this feature.
- The build number (Android `versionCode`) will be set to a monotonically increasing integer derived from the patch/minor/major components of the version tag; a simple formula (e.g., `MAJOR*10000 + MINOR*100 + PATCH`) is acceptable.
- GitHub Pages continues to host the single latest web deployment; there is no requirement to preserve multiple web versions simultaneously.
- The README will be written in English, in Markdown, and hosted on GitHub where it renders automatically.
