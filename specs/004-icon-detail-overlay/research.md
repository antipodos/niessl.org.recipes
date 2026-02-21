# Research: App Icon Branding & Detail Photo Overlay Redesign

**Branch**: `004-icon-detail-overlay` | **Date**: 2026-02-21

---

## R-001: Logo Asset

**Decision**: Use `https://niessl.org/img/logo.png` as the source asset.

**Rationale**: The website's only logo reference is `img/logo.png` (relative to the site root). No favicon, apple-touch-icon, or og:image meta tags are defined, so the logo PNG is the canonical brand asset.

**Format**: PNG. Background transparency unknown — will be verified when downloaded. If the logo has a solid background that clashes with the app icon adaptive background, a transparent-background version may need to be created manually.

**Alternatives considered**: None — this is the only logo on the site.

---

## R-002: App Icon Generation

**Decision**: Add `flutter_launcher_icons` as a dev dependency and configure it to generate adaptive icons (Android) and standard icons (iOS) from the logo PNG.

**Rationale**: `flutter_launcher_icons` is the de-facto standard Flutter tool for multi-platform icon generation. It produces all required density variants (mdpi → xxxhdpi) and Android adaptive icon layers from a single source image. The project already uses `flutter_native_splash` (same family of tooling), so the pattern is established.

**Configuration approach**:
- Source image: `assets/logo.png` (downloaded from niessl.org)
- Android adaptive icon: white background (`#FFFFFF`) with the logo as the foreground layer, padded to 70% to avoid clipping in the circle mask
- iOS: square PNG set, same source image
- Platforms: `android: true`, `ios: true`

**Alternatives considered**:
- Manual icon creation: rejected — tedious, error-prone, not reproducible
- `flutter_native_splash` for icons: not its purpose — it only handles the launch screen

---

## R-003: Splash Screen Branding

**Decision**: Add an `image` key to the existing `flutter_native_splash` configuration in `pubspec.yaml`, pointing to `assets/logo.png`. Re-run `dart run flutter_native_splash:create` after.

**Rationale**: `flutter_native_splash` already generates the native splash resources (Android 12 splash API + legacy drawable, iOS storyboard). Adding `image:` centers the logo on the warm cream / dark warm background that is already configured. This gives consistent branding between the icon and the splash with minimal change.

**Warm background colors** (already configured):
- Light: `#F5EFE7` (warm cream)
- Dark: `#2B1F1A` (warm dark brown)

**Logo sizing**: `image_full_screen: false` (default); logo will be displayed at its natural size centered. If the logo appears too large or small, `android_12.icon_background_color` and `android_12.color` can be adjusted without code changes.

**Alternatives considered**:
- Custom Dart splash animation (existing `EqualizerLoadingView`): this already runs after the native splash; adding the logo to the native splash layer is additive, not a replacement.

---

## R-004: Detail Screen — Photo Overlay Redesign

**Decision**: Replace the existing gradient scrim + recipe name overlay inside the Hero Stack with a semi-transparent white bar at the bottom of the photo containing tags and source.

**Current state** (from `recipe_detail_screen.dart`):
- `Positioned(bottom: 0)` gradient scrim (100 px height, `Colors.transparent` → `colorScheme.scrim` at 65%)
- `Positioned(bottom: 0)` text overlay showing `widget.name` in `headlineSmall`
- Below the photo: `FilterChip` widgets for tags (navigate + pop on tap)
- Below the photo: `InkWell` row for source (icon + hostname text)

**New design**:
- Remove gradient scrim
- Remove name text overlay
- Add `Positioned(bottom: 0)` semi-transparent white bar:
  - `Container` with `Colors.white.withValues(alpha: 0.78)` background
  - Internal `Padding(8 px all sides)`
  - `Wrap(spacing: 12, runSpacing: 4)` containing:
    - For each tag: `Row` with `Icon(Icons.label_outline, size: 14)` + `SizedBox(4)` + `Text(tag, bodySmall)`
    - If source present: `GestureDetector` wrapping `Row` with `Icon(Icons.open_in_new, size: 14)` + `SizedBox(4)` + `Text(hostname, bodySmall)`
  - Bar is only rendered when there is at least one tag OR a non-empty, non-"unknown" source
- Remove the `FilterChip` tag section below the photo entirely
- Remove the source `InkWell` section below the photo entirely
- Keep the `Divider` and markdown content unchanged
- Tags in the overlay bar are **read-only** — no filter navigation on tap (simplifies the overlay and removes the chip interaction pattern)

**Contrast rationale**: White at ~78% opacity gives a readable backdrop over both light and dark photo areas. The warm terracotta color scheme uses dark text (`onSurface`) which will be readable on the white bar.

**Alternatives considered**:
- Keep FilterChip for tags inside the bar: rejected — user explicitly requested "icon + text, not those buttons"
- Dark scrim bar instead of white: rejected — white matches the warm cream theme better and the user specified "semi-transparent white bar"
- Keep tags below the photo as plain text: rejected — user wants them moved onto the photo

---

## R-005: Affected Tests

**Widget tests requiring update** (in `test/widget/screens_widget_test.dart`):

| Test | Change needed |
|------|---------------|
| `shows FilterChip for each tag when tags provided` | Change to find plain text tags with label icon, not FilterChip |
| `recipe name appears inside Hero subtree when loaded` | Remove — name no longer overlaid on photo |
| `standalone name heading below photo is removed after overlay added` | Update to verify name NOT in Hero, but IS in AppBar |
| `loaded state with media shows Hero, name heading, source link, Divider` | Rename; verify source text in overlay bar, not below photo |
| `shows no FilterChip when tags is empty` | Keep — still valid (no FilterChip anywhere in detail screen) |

**Integration tests requiring update** (in `integration_test/app_test.dart`):

| Test | Change needed |
|------|---------------|
| `US4: tapping a detail tag chip returns to filtered list` | Tags are now read-only; test should be removed or replaced with a test verifying tags are displayed as plain text |
| `US6: detail screen shows name heading, photo area, and Divider` | Update: name heading is in AppBar only, not in Hero overlay |
