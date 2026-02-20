# Feature Specification: Recipe Companion App

**Feature Branch**: `001-flutter-recipe-app`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "Cross-platform Flutter recipe app for dinner.niessl.org with search, tag filtering, and screen keep-alive"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse the Recipe Collection (Priority: P1)

A user opens the app for the first time and is greeted by a beautiful, clean list of
all available recipes. The list is visually engaging — each recipe is clearly named
and the overall layout feels modern and uncluttered. The user scrolls through and
taps a recipe to read the full ingredient list and step-by-step directions.

**Why this priority**: This is the core value of the app. Without the ability to
browse and read recipes, nothing else matters. It is the minimum viable experience.

**Independent Test**: Launching the app on a fresh install shows the complete recipe
list; tapping any recipe shows its full content. This can be demonstrated end-to-end
without search or filtering being present.

**Acceptance Scenarios**:

1. **Given** the app is launched with an internet connection, **When** the home screen
   loads, **Then** a complete, scrollable list of all available recipes is displayed
   within 3 seconds, each showing the recipe name.
2. **Given** the recipe list is visible, **When** the user taps a recipe name,
   **Then** the full recipe content is displayed, including a clearly formatted
   ingredient list and numbered step-by-step directions.
3. **Given** a recipe detail is open, **When** the user navigates back,
   **Then** the recipe list is restored at the same scroll position.
4. **Given** the app was previously opened and recipes were loaded, **When** the app
   is reopened without an internet connection, **Then** the previously loaded recipe
   list is accessible from local cache.

---

### User Story 2 - Search for a Specific Recipe (Priority: P2)

A user knows the name of a recipe they want to cook. They type a few letters into a
search field and the list immediately narrows to show only matching recipes. Clearing
the search restores the full list.

**Why this priority**: Search dramatically reduces the time to find a specific recipe
in a catalog of 89+ items. It is the next most important interaction after basic
browsing.

**Independent Test**: The search field is visible on the recipe list screen. Typing
a partial name filters the list in real time. Clearing the field restores all recipes.
This can be tested without tag filtering existing.

**Acceptance Scenarios**:

1. **Given** the recipe list is displayed, **When** the user types characters into
   the search field, **Then** the list is filtered in real time to show only recipes
   whose names contain the typed text (case-insensitive).
2. **Given** a search term is entered, **When** no recipes match the term,
   **Then** a friendly empty-state message is shown (e.g., "No recipes found").
3. **Given** a search is active, **When** the user clears the search field,
   **Then** the full unfiltered recipe list is immediately restored.

---

### User Story 3 - Filter Recipes by Category (Priority: P3)

A user is in the mood for something sweet or wants to explore Indian dishes. They
tap one or more category tags and the recipe list updates to show only recipes that
belong to the selected categories. Deselecting a tag removes that filter.

**Why this priority**: Tags provide thematic navigation that complements text search.
With a defined set of categories, filtering helps users discover recipes they might
not know by name.

**Independent Test**: Category tags are visible and tappable. Selecting a tag filters
the recipe list. Deselecting it restores the broader list. Can be demonstrated without
the search feature.

**Acceptance Scenarios**:

1. **Given** the recipe list is displayed, **When** the user views the available
   filters, **Then** all available category tags are shown in a visually clear and
   tappable format.
2. **Given** category tags are visible, **When** the user selects one tag,
   **Then** the recipe list updates to show only recipes belonging to that category.
3. **Given** one tag is selected, **When** the user selects an additional tag,
   **Then** the recipe list expands to show recipes matching either tag (inclusive
   filter — recipes in any selected category are shown).
4. **Given** one or more tags are selected, **When** the user deselects all tags,
   **Then** the full unfiltered recipe list is restored.
5. **Given** search and tag filter are both active simultaneously, **When** recipes
   are displayed, **Then** only recipes matching both the search term AND at least
   one selected tag are shown.

---

### User Story 4 - Keep the Screen On While Cooking (Priority: P4)

A user is actively following a recipe — hands covered in flour — and needs the screen
to stay on so they can read the next step without touching the device. They toggle
a control in the recipe detail view to prevent the screen from turning off.

**Why this priority**: This directly addresses a real cooking frustration. It is
a small but high-value feature that significantly improves the in-kitchen experience.

**Independent Test**: A toggle is visible on the recipe detail screen. When enabled,
the device screen does not turn off automatically. Toggling it off restores normal
screen timeout behaviour.

**Acceptance Scenarios**:

1. **Given** a recipe detail view is open, **When** the user enables the "keep screen
   on" option, **Then** the device screen no longer turns off automatically due to
   inactivity.
2. **Given** "keep screen on" is active, **When** the user navigates back to the
   recipe list or closes the app, **Then** the normal device screen timeout is
   automatically restored.
3. **Given** "keep screen on" is active, **When** the user taps the control again,
   **Then** the screen timeout returns to the device's default behaviour immediately.

---

### Edge Cases

- What happens when the app is launched with no internet connection and no cached data?
- What if a recipe's content is empty or contains only whitespace?
- What if the recipe catalog fails to load mid-session (e.g., connection drops during
  browsing)?
- What happens when search and tag filters are combined and produce zero results?
- What if the list of category tags fails to load independently of the recipe list?
- How does the layout behave on very small screens (compact phones) and very large
  screens (tablets)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display a complete, scrollable list of all available
  recipes by name when it opens.
- **FR-002**: Users MUST be able to tap any recipe in the list to view its full
  content, including a formatted ingredient list and numbered preparation steps.
- **FR-003**: The app MUST provide a search field on the recipe list screen that
  filters the visible recipes in real time as the user types (case-insensitive).
- **FR-004**: The app MUST display all available category tags and allow users to
  select or deselect them to filter the recipe list using inclusive (OR) logic.
- **FR-005**: When both a search term and category tags are active simultaneously,
  the app MUST apply both filters together (recipes must match the search term AND
  belong to at least one selected tag).
- **FR-006**: The app MUST render recipe content with clear visual hierarchy:
  ingredient quantities presented as a list and directions as numbered steps.
- **FR-007**: The app MUST display a clear, friendly empty-state when no recipes
  match the active search or filter criteria.
- **FR-008**: The app MUST notify the user with a friendly message when content
  cannot be loaded due to a network error, and offer a retry action.
- **FR-009**: Users MUST be able to enable a "keep screen on" mode from the recipe
  detail view to prevent automatic screen timeout while cooking.
- **FR-010**: The "keep screen on" mode MUST be automatically deactivated when the
  user leaves the recipe detail view.
- **FR-011**: The app MUST cache the recipe list and previously viewed recipe content
  so that they remain accessible without an internet connection.
- **FR-012**: The app MUST support both light mode and dark mode, following the
  device's system preference automatically.
- **FR-013**: The app MUST allow users to manually refresh the recipe list (e.g.,
  via pull-to-refresh) to retrieve newly published recipes.

### Key Entities *(include if feature involves data)*

- **Recipe Summary**: A recipe as it appears in the browsable list — defined by its
  display name and a link to its full content. Used to populate the list screen and
  drive navigation to the detail view.
- **Recipe Detail**: The complete cooking content for one recipe, consisting of a
  formatted ingredient section (quantities and items) and an ordered sequence of
  preparation steps. Rendered from the recipe's source content.
- **Category Tag**: A thematic label used to group recipes by type (e.g., sweet,
  Indian, main, snack, fish). Tags drive the filter experience on the list screen.
  A recipe may belong to zero or more tags.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can launch the app, locate a specific recipe by name, and begin
  reading its full content in under 30 seconds from a cold start.
- **SC-002**: The full recipe list is visible and interactive within 3 seconds of
  launching the app on a standard mobile connection.
- **SC-003**: Search filtering is instantaneous: results appear with no perceptible
  delay as each character is typed.
- **SC-004**: 100% of published recipes are browsable, searchable, and readable
  within the app without requiring any action outside the app.
- **SC-005**: All available category tags are surfaced and functional for filtering.
- **SC-006**: The "keep screen on" control reliably prevents auto-dimming and screen
  lock for the duration of an active recipe detail session.
- **SC-007**: The app is visually consistent and fully functional across both target
  mobile platforms and across a range of screen sizes from compact phone to tablet.
- **SC-008**: 95% or more of first-time users can find and open a recipe successfully
  without any onboarding instructions.
- **SC-009**: When content has been previously loaded, the app remains usable with
  cached content during offline sessions — no crash or blank screen on launch.

## Assumptions

- The recipe catalog is served from a stable public endpoint requiring no authentication.
- Tag filtering uses inclusive (OR) logic: showing recipes that belong to any selected
  tag. This suits the small number of categories and avoids quickly arriving at an
  empty list.
- The recipe list and tag list are refreshed automatically each time the app is opened;
  users can also trigger a manual refresh via pull-to-refresh.
- Recipes are presented in alphabetical order by default.
- The "keep screen on" setting is per-session only and is not persisted across app
  restarts.
- The app targets mobile devices (phones and tablets) as the primary form factor.

## Out of Scope

- User accounts, login, or personalisation (favourites, notes, ratings).
- Recipe submission or editing by users.
- Shopping list generation or ingredient quantity scaling.
- Push notifications or background refresh.
- Desktop or web platform targets (mobile only for this version).
