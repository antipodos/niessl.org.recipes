# Feature Specification: UX Refinement — Splash, Grid, Images & Detail

**Feature Branch**: `003-ux-refinement`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "Another UX iteration — animated splash screen, square 2-column tile grid, image prefetch/cache, recipe name overlaid on detail photo, tags shown on detail page."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Branded Splash Screen (Priority: P1)

A user launches the app and sees a branded animated intro instead of the generic Flutter default logo. The animation plays briefly and transitions into the recipe list. This is the very first impression of the app and establishes brand identity immediately.

**Why this priority**: The splash screen is shown on every cold launch. Replacing the default Flutter logo with a branded animation makes the app feel polished and professional. It is fully independent of all other screens.

**Independent Test**: Can be fully tested by cold-launching the app and verifying the branded animation plays and transitions to the recipe list.

**Acceptance Scenarios**:

1. **Given** the app is cold-launched, **When** the OS loads the app, **Then** a branded animated logo is shown instead of the default Flutter splash.
2. **Given** the splash animation is playing, **When** the animation completes, **Then** the app transitions smoothly into the recipe list screen.
3. **Given** the app is already running (warm launch / navigation), **When** the user navigates, **Then** the splash screen is NOT shown again.

---

### User Story 2 - Square Two-Column Recipe Grid (Priority: P2)

A user browsing the recipe list sees a compact 2-column square grid instead of a single-column tall card list. More recipes are visible at once, the recipe name text is large enough to read comfortably, and the name is always readable regardless of the photo behind it due to a semi-transparent background overlay.

**Why this priority**: The grid view maximises information density and improves scannability — the user can see twice as many recipes before scrolling. This is the core browsing experience.

**Independent Test**: Can be fully tested by opening the recipe list and verifying 2 tiles per row, square aspect ratio, readable name text with contrast-enhancing overlay.

**Acceptance Scenarios**:

1. **Given** the recipe list is loaded, **When** the user views it, **Then** tiles are arranged in 2 equal-width columns.
2. **Given** a tile is displayed, **When** the user views it, **Then** the tile is square (1:1 aspect ratio).
3. **Given** a tile has a photo, **When** the recipe name is overlaid, **Then** the name text is larger than in the previous design and has a semi-transparent background that ensures readable contrast against any photo.
4. **Given** a tile has no photo, **When** the user views it, **Then** the placeholder and name are still clearly visible with adequate contrast.
5. **Given** the user applies a filter or search, **When** the grid reflows, **Then** the 2-column square layout is maintained.

---

### User Story 3 - Fast Image Browsing (Priority: P3)

A user scrolls through the recipe grid or switches between tag filters and sees recipe photos load instantly (or near-instantly) rather than showing placeholder shimmer repeatedly. Photos that were already seen do not need to reload.

**Why this priority**: Perceived speed is a key quality indicator. Slow image loading during scroll and filter transitions breaks immersion and makes the app feel sluggish.

**Independent Test**: Can be fully tested by scrolling through the recipe list and applying filters, verifying that previously-viewed images do not reload from scratch.

**Acceptance Scenarios**:

1. **Given** the recipe list is loaded, **When** the user scrolls down and back up, **Then** photos that were already displayed appear immediately without re-fetching.
2. **Given** images are loading for the first time, **When** they are downloaded, **Then** they are stored locally and survive app navigation (back/forward to detail screen does not re-fetch).
3. **Given** the user switches between tag filters, **When** previously-seen tiles re-appear, **Then** their photos load without visible delay.

---

### User Story 4 - Recipe Name and Tags on Detail Screen (Priority: P4)

A user viewing a recipe detail page sees the recipe name prominently displayed over the hero photo at the top, making the identity of the recipe immediately clear. Below the photo, they see the source attribution (if available) and a row of tags indicating the recipe's categories.

**Why this priority**: This improves information hierarchy on the detail screen — the name is immediately associated with the visual. Tags give users quick context about the recipe without reading the full content.

**Independent Test**: Can be fully tested by opening any recipe detail screen and verifying the name overlays the photo, the source link appears below, and applicable tags are shown.

**Acceptance Scenarios**:

1. **Given** a recipe detail screen is opened, **When** the photo header is visible, **Then** the recipe name is displayed as an overlay on the photo with a semi-transparent background ensuring readability.
2. **Given** the recipe has a source URL, **When** the user views below the photo, **Then** the source attribution link is displayed (unchanged from current position).
3. **Given** the recipe belongs to one or more tags, **When** the user views the detail screen, **Then** the tags are displayed near the source attribution as labelled chips or similar compact indicators.
4. **Given** the recipe has no tags, **When** the user views the detail screen, **Then** the tag row is not shown (no empty section).
5. **Given** the recipe name is long, **When** it is overlaid on the photo, **Then** it wraps or truncates gracefully without obscuring the entire photo.

---

### Edge Cases

- What happens when a recipe has no photo and the name needs to overlay a placeholder?
- What happens when the splash animation asset is missing or fails to load?
- What happens when a tag has a very long name — does it overflow the chip row?
- What happens when the recipe list contains only 1 recipe — is the single tile full-width or half-width?
- What happens to the detail screen heading (currently below photo) after the name moves to overlay the photo — is there a duplicate?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display a branded animated splash screen on cold launch, replacing the default Flutter logo.
- **FR-002**: The splash animation MUST complete and transition to the recipe list without requiring user interaction.
- **FR-003**: The recipe list MUST display tiles in a 2-column grid layout with square (1:1) tiles.
- **FR-004**: Each tile MUST display the recipe name with a semi-transparent background overlay that ensures readable contrast against the tile photo.
- **FR-005**: The recipe name text on tiles MUST be visually larger than in the previous single-column design.
- **FR-006**: The app MUST prefetch and locally cache recipe photos so that previously-viewed images display without re-fetching.
- **FR-007**: Cached photos MUST persist across navigation between the list and detail screens within a session.
- **FR-008**: On the recipe detail screen, the recipe name MUST be displayed as an overlay on the hero photo with a semi-transparent background.
- **FR-009**: The standalone recipe name heading below the photo (current design) MUST be removed to avoid duplication.
- **FR-010**: The recipe detail screen MUST display the recipe's tags near the source attribution when tags are available.
- **FR-011**: When a recipe has no tags, the tag area MUST NOT be shown on the detail screen.
- **FR-012**: The animated splash screen MUST use the app's existing branded animation (the animated equalizer-style loading indicator with "niessl.org recipes" label already present in the app) displayed centred on a warm background matching the app's colour scheme. If that animation is unsuitable for a splash context, the static niessl.org site logo MUST be used with a simple fade-in and scale-up entrance animation.

### Key Entities

- **Splash Asset**: The animated brand graphic shown at launch. Format and content depend on what asset the user provides or approves.
- **Recipe Tile (grid)**: A square visual card in the 2-column grid, containing a photo (or placeholder), recipe name overlay, and tap target.
- **Tag Chip**: A compact label on the detail screen representing a recipe category (e.g., "Italian", "Vegan").

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On cold launch, the branded splash animation is visible and completes before the recipe list appears — verifiable on 100% of cold launches.
- **SC-002**: The recipe list shows at least 2 recipes per row on any standard phone screen size (portrait orientation).
- **SC-003**: Recipe name text on grid tiles is legible at arm's length — contrast ratio between name text and its background meets WCAG AA standard (≥4.5:1).
- **SC-004**: Scrolling back through a previously-loaded list results in 0 visible image reload placeholders for already-fetched photos.
- **SC-005**: On any recipe detail screen with tags, all applicable tags are displayed and tappable within the visible below-photo area.
- **SC-006**: The recipe name is visible over the hero photo on the detail screen without requiring the user to scroll.

## Assumptions

- The user has (or will provide) an animated logo asset for the splash screen. If none exists, a simple animation using the existing app brand colour and a placeholder icon will be used as a fallback.
- Tags displayed on the detail screen are the same tags already loaded from the tag indices (no new API call needed).
- The 2-column grid replaces the existing single-column list entirely (not an optional toggle).
- Image caching for the list screen builds on the existing `CachedNetworkImage` library already in use — no additional caching library is required.
- A single recipe with an odd position in the grid occupies one cell (half-width), not a full-width promoted tile.
- The source attribution position (below the photo) is unchanged as explicitly requested.
