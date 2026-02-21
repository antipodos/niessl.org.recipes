# Data Model: App Icon Branding & Detail Photo Overlay Redesign

**Branch**: `004-icon-detail-overlay` | **Date**: 2026-02-21

---

## Overview

This feature introduces no new data entities and no changes to the API or data layer. All changes are confined to:

1. **Static assets** — the logo PNG added to `assets/`
2. **Build configuration** — `pubspec.yaml` entries for icon/splash tooling
3. **UI rendering** — how `RecipeDetail` and tag strings are displayed on the detail screen

---

## Existing Entities (unchanged)

### RecipeSummary

| Field | Type | Notes |
|-------|------|-------|
| name | String | Recipe display name |
| url | String | Unique key |
| picture | String? | Optional photo URL |
| tags | List\<String\> | Tag names — passed to detail screen |

### RecipeDetail

| Field | Type | Notes |
|-------|------|-------|
| name | String | Recipe display name |
| recipe | String | Markdown content |
| picture | String? | Optional photo URL |
| source | String? | Optional attribution URL — displayed in overlay bar; filtered if null, empty, or `"unknown"` |

---

## Display Logic Changes (Detail Screen)

The following rendering rules change for the detail screen; no model fields change:

### Photo Overlay Bar — Display Conditions

| Condition | Result |
|-----------|--------|
| `photoUrl == null` | Bar not rendered |
| `photoUrl != null` AND tags empty AND no valid source | Bar not rendered |
| `photoUrl != null` AND tags non-empty | Tags shown in bar |
| `photoUrl != null` AND source valid (non-null, non-empty, not "unknown") | Source shown in bar |

### Tag Item (read-only, inside overlay bar)

```
Icon(Icons.label_outline, size: 14) + SizedBox(4) + Text(tagName, bodySmall)
```

No tap handler — tags in this location are informational only.

### Source Item (tappable, inside overlay bar)

```
GestureDetector(onTap: launchUrl) wrapping:
  Icon(Icons.open_in_new, size: 14) + SizedBox(4) + Text(hostname, bodySmall)
```

Source filtering: `detail.source != null && detail.source!.isNotEmpty && detail.source! != "unknown"`

---

## Static Assets

| Asset | Path | Source |
|-------|------|--------|
| Logo PNG | `assets/logo.png` | Downloaded from `https://niessl.org/img/logo.png` |

This asset is used by:
- `flutter_launcher_icons` → generates `android/app/src/main/res/mipmap-*/` and iOS `Assets.xcassets/AppIcon.appiconset/`
- `flutter_native_splash` → centers logo on the native splash screen backgrounds
