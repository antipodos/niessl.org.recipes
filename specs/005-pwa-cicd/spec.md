# Feature Specification: PWA Hosting & CI/CD Pipeline

**Feature Branch**: `005-pwa-cicd`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "I want to turn this into a progressive web app. Honestly I don't know what is necessary, but I would like to have a gitaction that builds apk and progressive web app and hosts the pwa on a static github page. all of that on merge to main. Doable?"

## Overview

Every time a change is merged to the main branch, an automated pipeline runs that:
1. Verifies all tests still pass
2. Publishes the recipe app as a web app on a public URL (GitHub Pages), installable from a browser like a native app
3. Produces a downloadable Android APK for direct device installation

This eliminates manual build steps and ensures the hosted web app is always in sync with the latest code.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Public Web App on GitHub Pages (Priority: P1)

A user visits a stable public URL in any desktop or mobile browser and can use the full recipe app — browsing, searching, filtering, and reading recipes — without installing anything.

**Why this priority**: This is the primary deliverable. Hosting the app on the web makes it accessible to anyone with a browser link, removing the Android-only constraint.

**Independent Test**: Navigate to `https://antipodos.github.io/niessl.org.recipes/` in a browser. The app loads, recipe list appears, search and tag filter work, and tapping a recipe opens its detail view.

**Acceptance Scenarios**:

1. **Given** a merge to main has completed, **When** a user visits the GitHub Pages URL, **Then** the recipe app loads and is fully functional within 5 seconds on a standard connection
2. **Given** the app is open in a mobile browser, **When** the user navigates between screens, **Then** all interactions work as they do on Android
3. **Given** a new version is merged to main, **When** the pipeline completes, **Then** the GitHub Pages URL serves the updated version within 10 minutes

---

### User Story 2 — Installable PWA (Priority: P1)

A user on a mobile or desktop browser can add the recipe app to their home screen / app shelf, where it launches full-screen like a native app with the correct name and icon.

**Why this priority**: Being installable is the defining characteristic of a Progressive Web App. Without it, the web version is just a website.

**Independent Test**: Open the GitHub Pages URL in Chrome or Safari on a mobile device. The browser shows an "Add to Home Screen" prompt (or the option is available in the browser menu). After installing, the app launches full-screen with the niessl.org logo as the icon and "niessl.org recipes" as the name.

**Acceptance Scenarios**:

1. **Given** the user opens the app in a supported mobile browser, **When** they tap "Add to Home Screen", **Then** a shortcut is created with the niessl.org logo icon
2. **Given** the PWA is installed on the home screen, **When** the user taps it, **Then** the app launches full-screen (no browser chrome) within 3 seconds
3. **Given** the app is launched from the home screen without a network connection, **Then** a readable offline message is shown (the app shell loads; recipe data requires connectivity)

---

### User Story 3 — Android APK Artifact from CI (Priority: P2)

After a merge to main, a developer or tester can download a ready-to-install Android APK directly from the GitHub Actions run — no local build environment needed.

**Why this priority**: Useful for testing on real Android devices without going through the Play Store. Lower priority than web hosting because the Android app can already be built locally.

**Independent Test**: Navigate to the GitHub Actions run for a merge-to-main commit. Find and download the APK artifact. Install it on an Android device and confirm the app works.

**Acceptance Scenarios**:

1. **Given** a merge to main has completed, **When** a developer opens the corresponding GitHub Actions run, **Then** a downloadable APK artifact is attached to the run
2. **Given** the APK is downloaded and installed on an Android device (API 21+), **When** the app is launched, **Then** it functions identically to a locally-built version
3. **Given** any pipeline step fails (tests, build, deploy), **Then** the failure is clearly reported in the GitHub Actions UI and no broken artifact is published

---

### Edge Cases

- What happens when the recipe API (dinner.niessl.org) is unreachable in the web browser? The app shows its standard error view with a retry button — same as on Android.
- What happens if the GitHub Pages deploy step fails while the APK build succeeded? Each job is independent; partial failures are reported clearly in the Actions UI.
- What if the app URL path changes? The web build must be configured for the correct subdirectory path so all assets and routing resolve correctly.
- What if a browser does not support PWA installation (e.g., Firefox on iOS)? The app is still fully usable as a web page; the installation prompt simply does not appear.
- What happens if the pipeline is triggered but tests fail? No deployment or artifact upload occurs; the failure is visible in the Actions tab.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The pipeline MUST trigger automatically on every merge to the `main` branch
- **FR-002**: The pipeline MUST run the full automated test suite before any deployment step; if tests fail, no deployment occurs and no artifact is uploaded
- **FR-003**: The pipeline MUST build the web version of the app and deploy it to a publicly accessible static URL after tests pass
- **FR-004**: The deployed web app MUST be installable as a PWA: it must include a web manifest declaring the app name ("niessl.org recipes"), the niessl.org logo as icon, and the warm terracotta theme colour
- **FR-005**: The deployed web app MUST include a service worker so the app shell (UI assets) loads on repeat visits, even on a slow connection; recipe data from the API is not required to be cached offline
- **FR-006**: The pipeline MUST build an Android APK and attach it as a downloadable artifact to the pipeline run
- **FR-007**: The APK artifact MUST be installable on any Android device running API level 21 or higher
- **FR-008**: The pipeline MUST display a clear success or failure status visible in the repository's GitHub Actions tab
- **FR-009**: The pipeline configuration MUST be stored as code in the repository so it is versioned alongside the app

### Key Entities

- **Pipeline**: The automated workflow triggered on merge to main; consists of a test job, a web-build-and-deploy job, and an APK-build job
- **Web Build**: The compiled web output of the recipe app, configured for hosting at the repository's GitHub Pages URL
- **APK Artifact**: The compiled Android package produced by the pipeline, retained for download for a reasonable period (90 days)
- **Web Manifest**: The configuration file that makes the web app installable — declares app name, icons, theme colour, and display mode (standalone/fullscreen)
- **Service Worker**: The background script that enables offline shell loading and fast repeat visits

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Within 10 minutes of a merge to main, the GitHub Pages URL serves the updated version of the app
- **SC-002**: The web app passes a PWA audit (Lighthouse or equivalent) with all PWA checklist items satisfied in a standard browser
- **SC-003**: The APK artifact is available for download from the GitHub Actions run within 15 minutes of merge
- **SC-004**: A user with no development tools can access and fully use the recipe app using only a browser and the GitHub Pages URL
- **SC-005**: A failed test causes the pipeline to halt with a visible failure status; no deployment or artifact upload occurs

---

## Assumptions

- The GitHub repository is `antipodos/niessl.org.recipes` and GitHub Pages is enabled (public repository, free tier)
- The APK is an unsigned or debug build suitable for direct device installation (sideloading); Play Store publishing is out of scope
- Recipe data is fetched live from the existing API (dinner.niessl.org); offline data caching is out of scope
- The web app is hosted at the default GitHub Pages URL (`https://antipodos.github.io/niessl.org.recipes/`); a custom domain is out of scope
- The existing `assets/logo.png` serves as the PWA icon source
- No authentication is required to view the hosted web app (fully public)
- The pipeline runs on GitHub-hosted runners (no self-hosted infrastructure required)

---

## Out of Scope

- Play Store or App Store publishing
- Custom domain for the PWA
- Offline caching of recipe API data
- iOS IPA build
- Push notifications
- Analytics or crash reporting
