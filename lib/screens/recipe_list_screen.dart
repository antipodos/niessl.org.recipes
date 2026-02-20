import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
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
      appBar: AppBar(title: const Text('Recipes')),
      body: Column(
        children: [
          const SearchBarWidget(),
          const TagChipBar(),
          Expanded(
            child: filteredAsync.when(
              loading: () => const LoadingView(),
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
                        MaterialPageRoute<void>(
                          builder: (_) => RecipeDetailScreen(
                            url: recipes[i].url,
                            name: recipes[i].name,
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
