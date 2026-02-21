# Feature Specification: UX Polish & Visual Refinement

**Feature Branch**: `002-ux-polish`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "I want to iterate over the UX, so this feature is mostly about UX improvements. The whole app should look less like an MVP version more like a polished app. for this I have a couple of suggestions that I want to write the spec for."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Photo-First Recipe List (Priority: P1)

A user opens the app and sees a visually rich grid or tile layout where each recipe is represented by its photo with the recipe name overlaid — similar to how the dinner.niessl.org website presents recipes. The screen feels immediately appetising and well-designed rather than a plain text list.

**Why this priority**: The list is the entry point for every session. Replacing the plain text rows with photo tiles has the highest visual impact and most closely mirrors the polished look of the website.

**Independent Test**: Can be fully tested by launching the app and scrolling through the recipe list without tapping any entry.

**Acceptance Scenarios**:

1. **Given** the recipe list has loaded, **When** the user views the list, **Then** each recipe is shown as a tile with its photo and the recipe name overlaid on or beneath the image.
2. **Given** a recipe tile is displayed, **When** the user views it, **Then** no tag chips are shown on the tile (tags remain active for filtering but are not rendered on tiles).
3. **Given** the list is displayed, **When** the user scrolls, **Then** spacing and alignment are consistent across all tiles.
4. **Given** a recipe has no available photo, **When** the tile is displayed, **Then** a tasteful placeholder fills the image area without breaking the layout.

---

### User Story 2 - Polished Recipe Detail with Photo & Source (Priority: P2)

A user taps a recipe and is taken to a detail screen that opens with a food photo prominently displayed, followed by the recipe content. The recipe source (original URL attribution) is also visible, and the content text is comfortably sized for reading while cooking.

**Why this priority**: The detail screen is where users spend the most time. Adding the photo and source transforms it from a raw text dump into a complete, well-attributed recipe page.

**Independent Test**: Can be fully tested by navigating to any single recipe and reading the full content.

**Acceptance Scenarios**:

1. **Given** a recipe detail loads, **When** the user views the screen, **Then** the recipe's photo is displayed prominently near the top of the content.
2. **Given** a recipe has a source URL, **When** the detail screen is shown, **Then** the source attribution is visible (e.g., "Source: [domain]") and tappable, opening the original page in a browser.
3. **Given** the recipe body text is rendered, **When** compared to the current MVP, **Then** the base font size is noticeably larger and easier to read.
4. **Given** a recipe with a long name, **When** shown in the detail screen's app bar, **Then** the title wraps or truncates gracefully without overflow or visual clipping.

---

### User Story 3 - Clear Screen-On Toggle (Priority: P3)

A user reading a recipe wants to prevent the screen from going dark. The screen-on toggle is discoverable, clearly labelled, and its current state is immediately obvious — users do not need to guess what it does.

**Why this priority**: The wakelock feature is a key cooking-time utility but currently uses an ambiguous icon with no visible label. Making it self-explanatory is a quick, high-value polish fix.

**Independent Test**: Can be fully tested by opening any recipe detail and interacting with the screen-on toggle.

**Acceptance Scenarios**:

1. **Given** the detail screen is open, **When** the user sees the app bar, **Then** the screen-on toggle has a visible label or tooltip that clearly communicates its function (e.g., "Keep screen on").
2. **Given** the screen-on feature is active, **When** the user looks at the toggle, **Then** its active state is visually distinct from the inactive state (not just outlined vs filled icon).
3. **Given** the user taps the toggle, **When** the state changes, **Then** a brief confirmation (e.g., a snackbar or label change) confirms what just happened.

---

### User Story 4 - Branded Header & Navigation Transition (Priority: P3)

A user sees the app name "niessl.org recipes" in the header rather than the generic "Recipes" title. Navigating into a recipe uses a smooth transition that feels intentional, not abrupt.

**Why this priority**: Branding and transitions are finishing touches that raise perceived quality without affecting functionality.

**Independent Test**: Can be fully tested by viewing the list screen header and tapping any recipe to observe the transition.

**Acceptance Scenarios**:

1. **Given** the app is open on the list screen, **When** the user views the header, **Then** the app name "niessl.org recipes" (or a refined version of this) is displayed.
2. **Given** the user taps a recipe tile, **When** the detail screen opens, **Then** the transition is smooth and feels native (e.g., a slide or fade, not an abrupt cut).
3. **Given** the user presses back from the detail screen, **When** returning to the list, **Then** the reverse transition matches the forward transition.

---

### User Story 5 - Animated Splash / Loading Screen (Priority: P3)

On cold launch, while data is being fetched, the user sees a branded loading screen featuring the niessl.org logo rendered as animated equalizer-style bars. The animation gives the app a distinctive, playful identity from the very first moment.

**Why this priority**: A branded loading screen turns unavoidable wait time into a positive brand moment and signals that this is a polished, intentional app.

**Independent Test**: Can be fully tested by killing the app and relaunching on a slow connection (or with cleared cache).

**Acceptance Scenarios**:

1. **Given** the app launches cold, **When** data is being fetched, **Then** a branded screen is shown featuring the niessl.org logo mark.
2. **Given** the branded loading screen is shown, **When** the animation plays, **Then** vertical bars animate in an equalizer-like pattern (rising and falling at different rates).
3. **Given** data has finished loading, **When** the content is ready, **Then** the loading screen transitions smoothly into the recipe list.
4. **Given** the cache already has data, **When** the app launches, **Then** the splash/loading screen is skipped or shown only briefly, not blocking access to cached content.

---

### User Story 6 - Polished Colour & Visual Theme (Priority: P2)

The overall visual design feels considered and warm rather than default Material Design. The colour palette, surface treatments, and component styling are refined to feel like a food app, not a generated scaffold.

**Why this priority**: The current warm terracotta seed colour is a good foundation, but the default Material component rendering leaves the app looking generic. Surface, card, and typography polish elevates the whole experience.

**Independent Test**: Can be fully tested by browsing the list and detail screens and comparing against a reference polished food app.

**Acceptance Scenarios**:

1. **Given** the app is open on any screen, **When** the user views it, **Then** the visual design feels cohesive and warm — not a default Material Design scaffold.
2. **Given** the app is viewed in light mode, **When** the user sees cards or surfaces, **Then** background surfaces have a warm, off-white or cream tint rather than pure white.
3. **Given** the app is viewed in dark mode, **When** the user sees the UI, **Then** the dark theme also feels warm and intentional, not just a colour inversion.

---

### Edge Cases

- What if a recipe has no photo available? The tile must degrade gracefully with a placeholder.
- What if the source URL is missing for a recipe? The source attribution row should not appear rather than showing an empty or broken link.
- Should the animated logo bars use the exact niessl.org logo shapes, or can they be an interpretation? (Assumed: close interpretation is acceptable.)
- What if loading completes before the splash animation finishes — should the animation always play to completion, or can it cut short? (Assumed: minimum display of ~1 second to avoid a flash.)
- Do all visual improvements apply consistently in both light and dark themes?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The recipe list MUST display recipes as photo tiles with the recipe name visible on or beneath each image.
- **FR-002**: Tag chips MUST NOT be shown on recipe list tiles; tag filtering functionality MUST remain fully intact.
- **FR-003**: Each recipe tile MUST display a tasteful placeholder image when no photo is available.
- **FR-004**: The recipe detail screen MUST display the recipe's photo prominently near the top of the content area.
- **FR-005**: The recipe detail screen MUST display the recipe source as a tappable attribution that opens the original URL in the device browser.
- **FR-006**: When a recipe has no source URL, the source attribution MUST NOT be shown.
- **FR-007**: The recipe detail screen body text MUST be rendered at a noticeably larger base size than the current MVP.
- **FR-008**: The screen-on toggle on the detail screen MUST have a clear label or descriptive tooltip communicating its function.
- **FR-009**: The screen-on toggle MUST have a visually distinct active state that is unambiguous without relying solely on icon fill.
- **FR-010**: A brief feedback indicator MUST be shown when the screen-on state changes (e.g., snackbar or label transition).
- **FR-011**: The app bar on the list screen MUST display the app name "niessl.org recipes" (or an approved refinement).
- **FR-012**: Navigation from the list to the detail screen MUST use a smooth animated transition (e.g., slide or fade).
- **FR-013**: The reverse transition (back navigation) MUST match the forward transition.
- **FR-014**: On cold launch with no cached data, a branded loading screen with an animated equalizer-bar logo MUST be shown while data is fetching.
- **FR-015**: The loading animation MUST feature vertical bars that animate in an equalizer-like rising-and-falling pattern.
- **FR-016**: When cached data is available, the branded loading screen MUST NOT block access to content (it may be skipped or shown only briefly).
- **FR-017**: The overall colour palette and surface treatments MUST feel warm and food-appropriate in both light and dark themes.
- **FR-018**: In light mode, background surfaces MUST have a warm, off-white or cream tint rather than pure white.
- **FR-019**: All existing functionality (search, tag filtering, pull-to-refresh, navigation) MUST remain fully intact after all visual changes.
- **FR-020**: All visual improvements MUST apply consistently in both light and dark themes.
- **FR-021**: Long recipe names in the detail screen app bar MUST wrap or truncate gracefully without overflow or clipping.

### Assumptions

- The dinner.niessl.org API already includes `picture` (photo URL) and `source` fields in both the recipe index and detail JSON responses. No additional data fetching or HTML parsing is required.
- Recipes that have no photo in the API will also have no photo in the app; placeholders are used in those cases.
- The niessl.org logo consists of vertical bars (equalizer-style shapes). The animated splash screen may interpret this shape rather than pixel-perfectly replicating it.
- The animated loading splash shows for a minimum of approximately 1 second to prevent a distracting flash, even if data loads faster.
- The existing warm terracotta Material Design 3 seed colour is the correct base; this feature refines component-level polish within that system rather than replacing the design language.
- "niessl.org recipes" is the working app name; a refined capitalisation or formatting (e.g., "niessl.org Recipes") may be used if it renders more cleanly.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All previously passing acceptance tests (US1–US4 from feature 001) continue to pass without modification.
- **SC-002**: A user can identify a recipe and its visual appeal from its tile on the list screen in a single glance.
- **SC-003**: A user reading the recipe detail screen can identify the source attribution without scrolling past the recipe content.
- **SC-004**: A user interacting with the screen-on toggle understands its function and current state without reading any documentation.
- **SC-005**: The animated loading screen plays a complete equalizer animation cycle before transitioning to the recipe list on cold launch.
- **SC-006**: No text overflow, clipping, or layout breakage occurs on any screen for any recipe name length.
- **SC-007**: The visual design is consistent and polished across both light and dark themes.
- **SC-008**: The app name "niessl.org recipes" (or approved variant) is visible in the list screen header on every launch.
