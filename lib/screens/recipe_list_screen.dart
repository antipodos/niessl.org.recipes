import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/equalizer_loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/recipe_tile.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/tag_chip_bar.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final _scrollController = ScrollController();

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
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(appDataProvider),
                  child: ListView.builder(
                    controller: _scrollController,
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
