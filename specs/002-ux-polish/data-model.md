# Data Model: UX Polish & Visual Refinement

**Branch**: `002-ux-polish` | **Date**: 2026-02-21

This feature makes additive changes to existing model entities only. No new entities are introduced.

---

## Modified Entity: RecipeSummary

**File**: `lib/models/recipe.dart`

| Field | Type | Required | Source | Change |
|-------|------|----------|--------|--------|
| name | String | yes | index JSON | existing |
| url | String | yes | index JSON | existing |
| tags | List\<String\> | yes | tag indices (enriched) | existing |
| picture | String? | no | index JSON `picture` | **NEW** |

**Validation rules**:
- `picture` may be absent from JSON (older recipes) or empty string → treat both as `null`.
- No format validation on the URL string; rendering delegates to `CachedNetworkImage`.

**Cache impact**: The cache key and serialisation format must be updated to round-trip `picture`. Existing cached entries lack `picture` and will be treated as `null` on first load after update (correct behaviour; background refresh populates the field).

---

## Modified Entity: RecipeDetail

**File**: `lib/models/recipe.dart`

| Field | Type | Required | Source | Change |
|-------|------|----------|--------|--------|
| name | String | yes | detail JSON | existing |
| recipe | String | yes | detail JSON | existing |
| picture | String? | no | detail JSON `picture` | **NEW** |
| source | String? | no | detail JSON `source` | **NEW** |

**Validation rules**:
- `picture` — same as RecipeSummary: absent or empty → `null`.
- `source` — may be absent or empty → `null`. When non-null, must be a valid absolute URL (validated at use-site before passing to `url_launcher`, not in the model).

**Cache impact**: Same as RecipeSummary. Existing cached detail entries lack `picture` and `source`; treated as `null` until re-fetched. Cache keys are unchanged (still keyed by base64-encoded recipe URL).

---

## Unchanged Entities

| Entity | Reason |
|--------|--------|
| Tag | No changes; tag filtering logic unaffected |

---

## Theme Constants (not a data model entity, but design tokens)

**File**: `lib/theme.dart`

New named constants replacing future raw hex values:

| Constant | Value | Purpose |
|----------|-------|---------|
| `_seedColor` | `Color(0xFFB85C38)` | existing — warm terracotta |
| `_warmCreamSurface` | `Color(0xFFF5EFE7)` | NEW — light mode surface tint |
| `_warmDarkSurface` | `Color(0xFF2B1F1A)` | NEW — dark mode surface tint |

---

## No API Contracts Required

This feature is purely client-side. The dinner.niessl.org API is read-only and already returns all required fields. No server-side schema changes and no OpenAPI/GraphQL contracts to define.
