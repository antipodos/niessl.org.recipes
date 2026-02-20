import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';
import '../services/filter_service.dart';
import '../services/recipe_service.dart';

/// Singleton recipe service instance.
final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

/// The full app data — recipe list enriched with tags, and tag list.
/// Cache-first: returns cached data on first call, refreshes in background.
final appDataProvider =
    FutureProvider<({List<RecipeSummary> recipes, List<Tag> tags})>((ref) {
      final service = ref.watch(recipeServiceProvider);
      return service.fetchAll();
    });

/// Full content for a single recipe, keyed by its URL.
final recipeDetailProvider = FutureProvider.autoDispose
    .family<RecipeDetail, String>((ref, url) {
      final service = ref.watch(recipeServiceProvider);
      return service.fetchRecipeDetail(url);
    });

/// Current search query string.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected tag names.
final selectedTagsProvider = StateProvider<Set<String>>((ref) => {});

/// Derived: filtered and sorted recipe list based on search + tags.
final filteredRecipesProvider = Provider<AsyncValue<List<RecipeSummary>>>((
  ref,
) {
  final appData = ref.watch(appDataProvider);
  final query = ref.watch(searchQueryProvider);
  final selectedTags = ref.watch(selectedTagsProvider);

  return appData.whenData(
    (data) => FilterService.apply(
      data.recipes,
      query: query,
      selectedTags: selectedTags,
    ),
  );
});

/// Tag list derived from appData (for the filter chip bar).
final tagsProvider = Provider<AsyncValue<List<Tag>>>((ref) {
  return ref.watch(appDataProvider).whenData((data) => data.tags);
});
