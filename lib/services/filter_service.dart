import '../models/recipe.dart';

/// Pure filtering logic — no dependencies, fully unit-testable.
class FilterService {
  FilterService._();

  /// Applies search query and tag filter to a list of recipes.
  /// - Search: case-insensitive substring match on name.
  /// - Tag filter: inclusive OR — recipe must belong to at least one selected tag.
  /// - Both filters are ANDed together.
  /// - Result is sorted alphabetically by name (case-insensitive).
  static List<RecipeSummary> apply(
    List<RecipeSummary> recipes, {
    required String query,
    required Set<String> selectedTags,
  }) {
    final lowerQuery = query.toLowerCase();

    final filtered =
        recipes.where((r) {
          final matchesSearch =
              lowerQuery.isEmpty || r.name.toLowerCase().contains(lowerQuery);
          final matchesTags =
              selectedTags.isEmpty || r.tags.any(selectedTags.contains);
          return matchesSearch && matchesTags;
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    return filtered;
  }
}
