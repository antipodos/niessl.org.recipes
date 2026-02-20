import 'package:flutter/material.dart';

import '../models/recipe.dart';

class RecipeTile extends StatelessWidget {
  final RecipeSummary recipe;
  final VoidCallback onTap;

  const RecipeTile({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '${recipe.name}, tap to view recipe',
      button: true,
      child: ListTile(
        title: Text(recipe.name, style: textTheme.bodyLarge),
        trailing: recipe.tags.isEmpty
            ? null
            : Wrap(
                spacing: 4,
                children: recipe.tags.take(2).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
        onTap: onTap,
      ),
    );
  }
}
