import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class TagChipBar extends ConsumerWidget {
  const TagChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    return tagsAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox(height: 48),
      data: (tags) => SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: tags
              .map(
                (tag) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(tag.name),
                    selected: selectedTags.contains(tag.name),
                    onSelected: (v) {
                      ref
                          .read(selectedTagsProvider.notifier)
                          .update(
                            (s) =>
                                v ? {...s, tag.name} : s.difference({tag.name}),
                          );
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
