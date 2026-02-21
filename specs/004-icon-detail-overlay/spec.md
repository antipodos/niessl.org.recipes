# Feature Specification: App Icon Branding & Detail Photo Overlay Redesign

**Feature Branch**: `004-icon-detail-overlay`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "one final round of ui/ux improvements. A) Use the logo from niessl.org as the app icon and splash screen. B) On the recipe detail page, remove the name from the photo overlay (redundant, already in the nav bar). Instead, move both the tags and the source link onto the photo at the bottom, on a semi-transparent white bar for contrast. Tags should look like the source link — icon plus plain text, not chip buttons."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Branded App Icon & Splash (Priority: P1)

A user installs the app and sees the niessl.org logo as the home screen icon. When they launch the app, the startup screen displays the same logo, giving a consistent and polished first impression.

**Why this priority**: Brand consistency at launch is the first thing a user sees; it establishes trust and recognition before any content loads.

**Independent Test**: Install the app on a device. Verify the home screen icon shows the niessl.org logo. Tap it and verify the splash/startup screen also shows the same logo.

**Acceptance Scenarios**:

1. **Given** the app is installed, **When** the user views their device home screen, **Then** the app icon shows the niessl.org logo (not a generic Flutter or placeholder icon).
2. **Given** the user taps the app icon, **When** the app is loading, **Then** the startup/splash screen displays the niessl.org logo.
3. **Given** the device is in dark mode, **When** the app is launched, **Then** the logo remains clearly visible and legible against the splash background.

---

### User Story 2 — Decluttered Detail Photo with Overlay Bar (Priority: P1)

A user opens a recipe detail screen. The photo now shows a semi-transparent white bar at the bottom containing the recipe's tags and source link — styled as icon + plain text — instead of the recipe name (which is already shown in the navigation bar).

**Why this priority**: Removes visual redundancy (duplicate recipe name) and surfaces useful navigational information (tags, source) in a prominent, glanceable position without extra scrolling.

**Independent Test**: Open any recipe with a photo, tags, and a source URL. Verify the name is gone from the photo overlay, and that the bar at the bottom of the photo shows tags and source instead.

**Acceptance Scenarios**:

1. **Given** a recipe detail screen with a photo, **When** the screen loads, **Then** the recipe name does NOT appear overlaid on the photo.
2. **Given** a recipe with tags and a source URL, **When** the detail screen is shown, **Then** a semi-transparent bar at the bottom of the photo displays both the tags and the source link.
3. **Given** the overlay bar, **When** the user views it, **Then** tags are rendered as an icon + plain text (not as tappable chip buttons), matching the visual style of the source link.
4. **Given** a recipe with no tags, **When** the detail screen is shown, **Then** only the source link appears in the overlay bar.
5. **Given** a recipe with no source URL, **When** the detail screen is shown, **Then** only the tags appear in the overlay bar.
6. **Given** a recipe with neither tags nor source, **When** the detail screen is shown, **Then** the overlay bar is not rendered.

---

### Edge Cases

- What happens when a recipe has no photo? The overlay bar should not render (no photo surface to overlay).
- What happens when a recipe has many tags? Tags must not overflow — they should wrap or truncate within the bar without breaking the layout.
- What happens with very long tag names or a very long source URL? Text should be clipped or ellipsised gracefully.
- What happens on small screens? The bar and its contents must remain readable at minimum supported screen sizes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app icon displayed on the device home screen MUST use the niessl.org logo.
- **FR-002**: The startup/splash screen MUST display the niessl.org logo, consistent with the home screen icon.
- **FR-003**: The recipe detail screen MUST NOT display the recipe name overlaid on the photo.
- **FR-004**: The recipe detail screen photo MUST display a semi-transparent white bar at the bottom of the image when the recipe has at least one tag or a source URL.
- **FR-005**: Tags within the overlay bar MUST be displayed as an icon followed by plain text — not as chip or button widgets.
- **FR-006**: The source link within the overlay bar MUST use the same visual presentation style as the tags (icon + plain text).
- **FR-007**: The overlay bar MUST provide sufficient contrast so that text is legible over both light and dark photos.
- **FR-008**: The overlay bar MUST NOT appear when the recipe has no photo.
- **FR-009**: The recipe name MUST remain visible in the navigation bar (AppBar title) on the detail screen — this is unchanged.

### Assumptions

- The niessl.org logo is available as a downloadable asset from the public website.
- The logo will be adapted to the required platform icon sizes using the project's existing splash/icon toolchain.
- The semi-transparent bar opacity will be determined visually during implementation (approximately 60–75% white).
- A label or tag icon from the standard icon set will be used for tags, visually consistent with the external link icon used for source.
- Tags in the overlay bar are read-only indicators; tapping them does NOT trigger filter navigation (that behaviour is removed from this location to keep the overlay uncluttered).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The app icon on the device home screen shows the niessl.org logo — verified visually on both light and dark home screen backgrounds.
- **SC-002**: The startup screen shows the niessl.org logo — no blank white flash or placeholder icon visible during launch.
- **SC-003**: The recipe name does not appear anywhere on the photo area of the detail screen.
- **SC-004**: For any recipe with a photo and at least one tag or source URL, the overlay bar is visible and legible without any user interaction.
- **SC-005**: Tags and source link in the overlay bar use a visually identical presentation style (icon + text), confirmed by inspection.
- **SC-006**: All existing automated tests continue to pass without regression.
