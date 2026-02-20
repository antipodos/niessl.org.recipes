import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/providers.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String url;
  final String name;

  const RecipeDetailScreen({super.key, required this.url, required this.name});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _keepAwake = false;

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _toggleWakelock() async {
    final next = !_keepAwake;
    setState(() => _keepAwake = next);
    if (next) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(recipeDetailProvider(widget.url));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: Icon(_keepAwake ? Icons.lightbulb : Icons.lightbulb_outline),
            tooltip: _keepAwake ? 'Screen will stay on' : 'Keep screen on',
            onPressed: _toggleWakelock,
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(recipeDetailProvider(widget.url)),
        ),
        data: (detail) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
            data: detail.recipe,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
          ),
        ),
      ),
    );
  }
}
