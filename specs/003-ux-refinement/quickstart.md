# Quickstart / Acceptance Scenarios: UX Refinement (003-ux-refinement)

## US1 — Branded Splash Screen

**Setup**: Cold-launch the app (kill process + restart).

**Scenario 1.1 — Branded animation on cold launch**
1. Kill the app process.
2. Launch the app.
3. ✓ A warm-cream background appears immediately (no Flutter logo).
4. ✓ The EqualizerLoadingView animation plays centred on screen.
5. ✓ The recipe list screen appears once loading completes.
6. ✓ No back-navigation to the splash screen is possible from the list.

**Scenario 1.2 — No splash on warm navigation**
1. With the app open, tap a recipe to open the detail screen.
2. Press back.
3. ✓ The recipe list screen reappears — the splash screen is NOT shown.

---

## US2 — Square Two-Column Grid

**Setup**: Open the recipe list (normal launch or after splash).

**Scenario 2.1 — Two tiles per row**
1. Open the recipe list.
2. ✓ Tiles appear in a 2-column layout.
3. ✓ Each tile is square (equal width and height).
4. ✓ Recipe name text is readable (larger than previous single-column design).
5. ✓ Name text has a semi-transparent gradient overlay ensuring readable contrast against the photo.

**Scenario 2.2 — Grid maintained after filter**
1. Tap any tag in the tag chip bar.
2. ✓ Remaining tiles reflow in 2-column square layout.

**Scenario 2.3 — Grid maintained after search**
1. Type a search term.
2. ✓ Matching tiles are shown in 2-column square layout.

---

## US3 — Fast Image Browsing

**Setup**: First launch (cold cache). Requires network access.

**Scenario 3.1 — Instant re-display after scroll**
1. Open the recipe list and wait for images to load.
2. Scroll to the bottom, then scroll back to the top.
3. ✓ Images that were already loaded appear instantly (no placeholder shimmer visible).

**Scenario 3.2 — Images survive list↔detail navigation**
1. Open a recipe (detail screen loads its photo).
2. Press back.
3. ✓ The tile photo is immediately visible without reloading.

---

## US4 — Recipe Name and Tags on Detail Screen

**Setup**: Open any recipe detail screen.

**Scenario 4.1 — Name overlay on photo**
1. Open a recipe with a photo.
2. ✓ The recipe name is visible as an overlay at the bottom of the hero photo.
3. ✓ A gradient background behind the name text ensures readable contrast.
4. ✓ There is NO duplicate standalone name heading below the photo.

**Scenario 4.2 — Tags shown near source**
1. Open a recipe that has at least one tag.
2. ✓ Tag chips (labelled with tag names) are visible below the photo, above the source link.
3. ✓ The source link (if present) still appears below the tags.

**Scenario 4.3 — No tag section when recipe has no tags**
1. Open a recipe with no tags.
2. ✓ No tag chip area is shown (no empty section).

**Scenario 4.4 — Tag chip navigates back with filter applied**
1. Open a recipe detail screen.
2. Tap a tag chip.
3. ✓ The app navigates back to the recipe list with that tag pre-selected as a filter.

**Scenario 4.5 — Long recipe name on detail photo**
1. Open a recipe with a long name (>30 characters).
2. ✓ The name wraps or truncates gracefully; the photo is still partially visible.
