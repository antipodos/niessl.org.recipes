# Data Model: Flutter Recipe App

**Branch**: `001-flutter-recipe-app` | **Date**: 2026-02-19
**Source**: spec.md entities + API structure from research.md

---

## Overview

The app has a read-only data model derived entirely from the dinner.niessl.org JSON
API. There is no user-generated data, no local writes beyond caching. The three core
entities map directly to the three API response shapes.

---

## Entities

### RecipeSummary

Represents a recipe as it appears in the browsable list. Populated from the recipes
index endpoint, enriched with tag membership derived from the tag indices.

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `name` | `String` | `/recipes/index.json` → `name` | Display name |
| `url` | `String` | `/recipes/index.json` → `url` | Unique key; used for detail fetch and tag lookup |
| `tags` | `List<String>` | Computed from tag indices | Tag names this recipe belongs to |

**Constraints**:
- `name` MUST be non-empty.
- `url` MUST be a valid HTTPS URL ending in `/index.json`.
- `tags` MAY be empty (recipe belongs to no tag).
- `url` is the natural primary key; it is guaranteed unique by Hugo's slug-based
  file structure.

**Dart representation**:
```dart
class RecipeSummary {
  final String name;
  final String url;
  final List<String> tags;

  const RecipeSummary({
    required this.name,
    required this.url,
    this.tags = const [],
  });
}
```

---

### RecipeDetail

The complete cooking content for a single recipe. Fetched on demand when the user
opens a recipe. The `recipe` field is raw Markdown and is rendered in the UI.

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `name` | `String` | `/recipes/{slug}/index.json` → `name` | Same as RecipeSummary.name |
| `recipe` | `String` | `/recipes/{slug}/index.json` → `recipe` | Markdown: `## Ingredients` + `## Directions` sections |

**Constraints**:
- `name` MUST be non-empty.
- `recipe` MUST be non-null; MAY be empty string (edge case: render a placeholder).

**Markdown structure** (observed pattern from API):
```markdown
## Ingredients

* [quantity] [ingredient]
* ...

## Directions

1. [step]
2. [step]
...
```

**Dart representation**:
```dart
class RecipeDetail {
  final String name;
  final String recipe;

  const RecipeDetail({required this.name, required this.recipe});
}
```

---

### Tag

A category label used to group recipes. Used exclusively for filter UI.

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `name` | `String` | `/tags/index.json` → `name` | Display label (e.g., "sweet") |
| `url` | `String` | `/tags/index.json` → `url` | Used to fetch recipes for this tag |

**Known tags** (as of 2026-02-19): `sweet` (20 recipes), `indian` (10 recipes),
`main`, `basis`, `snack`, `fish` (counts TBC).

**Dart representation**:
```dart
class Tag {
  final String name;
  final String url;

  const Tag({required this.name, required this.url});
}
```

---

## Runtime State

These are not persisted entities but the derived state that drives the UI.

### AppData (loaded on startup)

| Field | Type | Description |
|-------|------|-------------|
| `recipes` | `List<RecipeSummary>` | Full recipe list, sorted alphabetically by name |
| `tags` | `List<Tag>` | All available tags, sorted alphabetically |

**Tag-to-recipe mapping** (intermediate, built during loading):
```
Map<String, List<String>>   tagName → [recipeUrl, ...]
```
Used to attach tag membership to RecipeSummary objects before the UI renders.

### FilterState

| Field | Type | Description |
|-------|------|-------------|
| `searchQuery` | `String` | Current search text (empty = no filter) |
| `selectedTags` | `Set<String>` | Tag names currently selected |

**Derived**: `filteredRecipes` — computed from `AppData.recipes` + `FilterState`.
```
filteredRecipes = recipes
  .where(name contains searchQuery, case-insensitive)
  .where(tags is empty OR tags intersects selectedTags)
  .sorted(alphabetically by name)
```

---

## Loading Sequence

```
App start
  ├─ [parallel] GET /recipes/index.json    → raw recipe list
  ├─ [parallel] GET /tags/index.json       → tag list
  │
  └─ on both complete:
       [parallel × 6] GET /tags/{tag}/index.json  → recipe URLs per tag
       │
       └─ on all complete:
            Build tag→URL map
            Enrich RecipeSummary objects with tags
            Sort alphabetically
            Update UI (replace loading indicator with recipe list)
            Write to shared_preferences cache
```

**Cache-first strategy**: Before any network request, the service attempts to load
`AppData` from shared_preferences. If cache is present, the UI renders immediately
with stale data while the network refresh runs in the background.

---

## Caching Schema

| Key (shared_preferences) | Type | Content |
|--------------------------|------|---------|
| `cache_recipes_index` | `String` | JSON array of `{name, url}` |
| `cache_tags_map` | `String` | JSON object: `{ tagName: [url, ...] }` |
| `cache_recipe_{base64url}` | `String` | JSON object: `{name, recipe}` |

`base64url` is a URL-safe base64 encoding of the recipe URL used as a safe key.

---

## Validation Rules

| Rule | Enforcement |
|------|------------|
| `RecipeSummary.url` uniqueness | Enforced at build time by Hugo slug system |
| `RecipeSummary.name` non-empty | Assert in `fromJson()` factory; show placeholder if empty |
| `RecipeDetail.recipe` non-null | Null-safe Dart; treat empty string as "content unavailable" |
| Tag filter (OR logic) | Verified in unit test `filter_logic_test.dart` |
| Search (case-insensitive contains) | Verified in unit test `filter_logic_test.dart` |

---

## Out of Scope (data model)

- No user profile, authentication, or session data.
- No mutable recipe data (no user edits, ratings, notes).
- No images (the API provides text/markdown only).
- No pagination (full list loaded on startup).
