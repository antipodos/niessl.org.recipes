import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe.dart';
import '../providers/providers.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/equalizer_loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/recipe_tile.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/tag_chip_bar.dart';
import 'recipe_detail_screen.dart';

/// Returns the picture URLs of the first [limit] recipes that have a photo.
/// Exported for testing; not part of the public API.
@visibleForTesting
List<String> pickRecipePictureUrls(
  List<RecipeSummary> recipes, {
  int limit = 10,
}) => recipes
    .where((r) => r.picture != null)
    .take(limit)
    .map((r) => r.picture!)
    .toList();

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final _scrollController = ScrollController();
  bool _prefetchDone = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredRecipesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('niessl.org recipes')),
      body: Column(
        children: [
          const SearchBarWidget(),
          const TagChipBar(),
          Expanded(
            child: filteredAsync.when(
              loading: () => const EqualizerLoadingView(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(appDataProvider),
              ),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const EmptyStateView(
                    hint: 'Try a different search or remove some filters',
                  );
                }
                if (!_prefetchDone) {
                  _prefetchDone = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      for (final url in pickRecipePictureUrls(recipes)) {
                        precacheImage(
                          CachedNetworkImageProvider(url),
                          context,
                        ).ignore();
                      }
                    }
                  });
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(appDataProvider),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: recipes.length,
                    itemBuilder: (_, i) => RecipeTile(
                      recipe: recipes[i],
                      onTap: () => Navigator.push(
                        context,
                        _RecipePageRoute(
                          child: RecipeDetailScreen(
                            url: recipes[i].url,
                            name: recipes[i].name,
                            photoUrl: recipes[i].picture,
                            tags: recipes[i].tags,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipePageRoute<T> extends PageRouteBuilder<T> {
  _RecipePageRoute({required Widget child})
    : super(
        pageBuilder: (_, __, ___) => child,
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) {
          final slide =
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              );
          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
}
