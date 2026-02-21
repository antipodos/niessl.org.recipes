import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/equalizer_loading_view.dart';
import '../widgets/error_view.dart';
import 'recipe_list_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(appDataProvider);

    // Navigate to list once data is ready.
    ref.listen(appDataProvider, (_, next) {
      if (next.hasValue && context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const RecipeListScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: dataAsync.hasError
          ? ErrorView(
              message: dataAsync.error.toString(),
              onRetry: () => ref.invalidate(appDataProvider),
            )
          : const Center(child: EqualizerLoadingView()),
    );
  }
}
