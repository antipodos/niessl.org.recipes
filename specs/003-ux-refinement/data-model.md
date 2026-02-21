# Data Model: UX Refinement (003-ux-refinement)

No new data entities are introduced in this feature. All changes are UI/presentation layer only. Existing entities are unchanged.

## Existing Entities (unchanged)

### RecipeSummary
- `name: String` — recipe display name
- `url: String` — canonical URL, used as provider key
- `tags: List<String>` — tag names (populated at startup by buildTagMap). **Used by detail screen to show FilterChips (new in this feature).**
- `picture: String?` — photo URL (used by CachedNetworkImage in tile and detail hero)

### RecipeDetail
- `name: String`
- `recipe: String` — markdown body
- `picture: String?`
- `source: String?`

### Tag
- `name: String` — display name and filter key
- `url: String` — tag index URL

## Interface Changes (new parameters on existing screens)

### RecipeDetailScreen (new parameter)
- `tags: List<String>` — added alongside existing `url`, `name`, `photoUrl`
- Source: passed from `RecipeSummary.tags` at navigation time
- No API change; no persistence change

## No new providers, no new models, no new API endpoints.
