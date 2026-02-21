# Research: UX Refinement (003-ux-refinement)

## Decision 1: Splash Screen Architecture

**Decision**: Two-layer hybrid approach — `flutter_native_splash` (dev dependency) for the native layer + a Flutter-side `SplashScreen` widget showing `EqualizerLoadingView` while `appDataProvider` loads.

**Rationale**:
- Without a native splash, users see the OS default (Flutter logo / blank screen) for 200–500 ms before Dart initialises. Replacing this with a solid warm-cream background + optional static image eliminates the jarring brand mismatch.
- The Flutter-side animated splash (EqualizerLoadingView, already in codebase) then plays while recipes and tags load, providing perceived progress.
- `flutter_native_splash` is a **dev** dependency only — zero APK size impact. It generates native XML/storyboard files from a simple pubspec.yaml config block.
- Reusing EqualizerLoadingView means no new animation widget is needed.

**Implementation sketch**:
1. Add `flutter_native_splash: ^5.0.0` to `dev_dependencies`.
2. Add config block to `pubspec.yaml`: warm cream background (`#F5EFE7`), no image.
3. Run `dart run flutter_native_splash:create` to generate native files.
4. Create `lib/screens/splash_screen.dart` — shows `EqualizerLoadingView` centred on warm scaffold; `ConsumerWidget` watches `appDataProvider`; navigates to `RecipeListScreen` once data arrives.
5. Update `lib/main.dart` to set `SplashScreen` as initial route (home widget).

**Alternatives considered**:
- *Manual native XML editing*: Possible but error-prone for both Android/iOS. `flutter_native_splash` handles both with one config. Rejected for complexity.
- *Skip native splash entirely*: Brief Flutter logo flash remains. Rejected — it's the specific user complaint.
- *Lottie animation*: No Lottie asset available; adds a runtime dependency. Rejected — EqualizerLoadingView is sufficient.

---

## Decision 2: 2-Column Square Grid

**Decision**: Replace `ListView.builder` in `RecipeListScreen` with `GridView.builder` using `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0, crossAxisSpacing: 8, mainAxisSpacing: 8)`.

**Rationale**:
- `childAspectRatio: 1.0` produces exact square tiles (width = screenWidth/2 − spacing).
- `GridView.builder` lazily builds only visible items — same memory efficiency as the current `ListView.builder`.
- Odd-numbered recipe counts leave the last tile at normal half-width (default behaviour); no special casing needed per spec.

**RecipeTile changes**:
- Change `AspectRatio` from `1.6` to `1.0` (square).
- Increase name text from `titleSmall` to `titleMedium` (one step up).
- Gradient height stays proportionally similar; `0.55` scrim alpha retained.
- No structural change — the Stack + Positioned + gradient pattern is unchanged.

**Alternatives considered**:
- *Staggered grid*: Different heights per tile. Rejected — user explicitly requested square.
- *Horizontal scrolling*: Not a standard recipe browsing pattern. Rejected.

---

## Decision 3: Image Prefetching

**Decision**: Use Flutter's built-in `precacheImage(CachedNetworkImageProvider(url), context).ignore()` for the first 10 recipe images, triggered once from `RecipeListScreen` when the filtered list first loads with data.

**Rationale**:
- `CachedNetworkImageProvider` is already imported (part of `cached_network_image ^3.3`). No new package required.
- `precacheImage()` populates the same in-memory image cache that `CachedNetworkImage` reads from, so images appear instantly when scrolled into view.
- `cached_network_image` also writes to disk (30-day default), so cache survives app restarts.
- Fire-and-forget with `.ignore()` prevents prefetch errors from affecting UI.
- Limit to 10 images avoids battery/data drain on slow networks; remaining images load on demand via the normal CachedNetworkImage placeholder flow.

**Where to call**:
- In `RecipeListScreen` state, in the `data:` branch of `filteredRecipesProvider.when(...)`, using a `WidgetsBinding.addPostFrameCallback` or a `ref.listen` triggered once per data change, checking `mounted`.

**Alternatives considered**:
- *Prefetch all recipes*: Wastes bandwidth; most users never scroll to bottom. Rejected.
- *Custom CacheManager config*: Reduces default 30-day / 200 MB limits. Optional optimisation, deferred.
- *flutter_cache_manager direct API*: More complex API, same result. Rejected — `precacheImage` is simpler.

---

## Decision 4: Detail Screen — Name Overlay on Photo

**Decision**: Move the recipe name from a standalone `headlineMedium` heading below the photo to a `Positioned(bottom: 0)` overlay inside the existing `Hero` Stack, using the same `LinearGradient(transparent → scrim.withValues(alpha: 0.65))` pattern already used in `RecipeTile`. Remove the standalone heading to avoid duplication.

**Rationale**:
- Visual consistency: the tile and the detail hero use the same gradient overlay pattern — the Hero transition is seamless.
- Gradient height ~100 px (taller than tile since it's 16:9 full-width, not a small square). Text: `headlineSmall`, white, `maxLines: 2`, `overflow: ellipsis`.
- The existing `Padding(child: Text(widget.name, style: headlineMedium))` block is removed (FR-009).

**Alternatives considered**:
- *Solid semi-transparent container*: Blocks more of the photo. Rejected — gradient is more elegant.
- *Keep name below photo as well*: Creates duplication. Rejected per spec.

---

## Decision 5: Tags on Detail Screen

**Decision**: Display recipe tags as a `Wrap` of `FilterChip` widgets below the photo and above the source attribution. Tags come from `RecipeSummary.tags` (a `List<String>` already populated by `buildTagMap()` at startup) passed to `RecipeDetailScreen` as a new `final List<String> tags` parameter.

**Rationale**:
- `RecipeSummary.tags` is already populated — zero new API calls or providers needed.
- `Wrap` is Flutter's idiomatic multi-line chip layout; handles 1–8 tags gracefully without horizontal scrolling.
- `FilterChip` (Material 3) applies correct colours from the existing `ColorScheme.fromSeed` automatically.
- Tapping a chip sets `selectedTagsProvider` and pops back to the list — consistent with the existing filter bar behaviour.
- Tags section is conditionally rendered: `if (widget.tags.isNotEmpty)` per FR-011.

**Where in layout**: Between the photo Hero block and the source attribution row (both stay in the `data:` body `Column`).

**Alternatives considered**:
- *New `recipeTagsProvider` FutureProvider.family*: Unnecessary complexity since tags are already on `RecipeSummary`. Rejected.
- *Horizontal scrolling row*: Tags overflow invisibly. Rejected — `Wrap` reflux is more accessible.
- *Chip (raw)*: Display-only, no tap affordance. Rejected — tapping to filter is more useful.
