import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/providers.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String url;
  final String name;
  final String? photoUrl; // T026 — passed from tile for Hero continuity
  final List<String> tags;

  const RecipeDetailScreen({
    super.key,
    required this.url,
    required this.name,
    this.photoUrl,
    this.tags = const [],
  });

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
    // T029 — show snackbar with feedback before updating state
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? 'Screen will stay on while cooking'
                : 'Screen timeout restored',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        // T027 — consistent typography for long recipe names
        title: Text(
          widget.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          // T029 — labelled TextButton.icon toggle with snackbar
          TextButton.icon(
            icon: Icon(_keepAwake ? Icons.visibility : Icons.visibility_off),
            label: Text(_keepAwake ? 'Screen on' : 'Screen off'),
            onPressed: _toggleWakelock,
            style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(recipeDetailProvider(widget.url)),
        ),
        data: (detail) {
          final hasValidSource =
              detail.source != null &&
              detail.source!.isNotEmpty &&
              detail.source! != 'unknown';
          final showOverlayBar =
              widget.photoUrl != null && widget.tags.isNotEmpty;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo header with Hero animation
                Hero(
                  tag: 'recipe_photo_${widget.url}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.photoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.restaurant,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.restaurant,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                        // Semi-transparent info bar — tags + source over photo
                        if (showOverlayBar)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.78),
                              padding: const EdgeInsets.all(8),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  ...widget.tags.map(
                                    (tag) => Semantics(
                                      label: tag,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.label_outline,
                                            size: 14,
                                            color: colorScheme.onSurface,
                                            semanticLabel: '',
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            tag,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.onSurface,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Recipe markdown with larger body text
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: detail.recipe,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 17,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                if (hasValidSource) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: GestureDetector(
                      onTap: () async {
                        await launchUrl(Uri.parse(detail.source!));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: colorScheme.primary,
                            semanticLabel: '',
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Uri.parse(detail.source!).host,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
