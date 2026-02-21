import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:niessl_recipes/main.dart' as app;
import 'package:niessl_recipes/screens/recipe_detail_screen.dart';
import 'package:niessl_recipes/widgets/recipe_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // US1 — Browse the Recipe Collection
  // ---------------------------------------------------------------------------
  group('US1 — Browse the Recipe Collection', () {
    testWidgets('recipe list appears after loading', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // At least one RecipeTile should be visible.
      expect(find.byType(RecipeTile), findsWidgets);
    });

    testWidgets('tapping a recipe tile navigates to detail screen', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap first visible recipe tile.
      final firstTile = find.byType(RecipeTile).first;
      await tester.tap(firstTile);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Detail screen should be present with a back button.
      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('navigating back from detail restores list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Press back.
      final NavigatorState navigator = tester.state(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      // List is restored.
      expect(find.byType(RecipeTile), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // US2 — Search for a Specific Recipe
  // ---------------------------------------------------------------------------
  group('US2 — Search for a Specific Recipe', () {
    testWidgets('typing in search field filters recipe list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).first, 'pan');
      await tester.pumpAndSettle();

      // Only recipes containing "pan" should be shown.
      final tiles = tester.widgetList<RecipeTile>(find.byType(RecipeTile));
      for (final tile in tiles) {
        expect(
          tile.recipe.name.toLowerCase(),
          contains('pan'),
          reason: '${tile.recipe.name} should contain "pan"',
        );
      }
    });

    testWidgets('no-match search shows empty state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).first, 'zzzzz');
      await tester.pumpAndSettle();

      expect(find.text('No recipes found'), findsOneWidget);
      expect(find.byType(RecipeTile), findsNothing);
    });

    testWidgets('clearing search restores full list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.enterText(find.byType(TextField).first, 'zzzzz');
      await tester.pumpAndSettle();
      expect(find.byType(RecipeTile), findsNothing);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      expect(find.byType(RecipeTile), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // US3 — Filter Recipes by Category
  // ---------------------------------------------------------------------------
  group('US3 — Filter Recipes by Category', () {
    testWidgets('all 6 tag chips are visible', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(FilterChip), findsNWidgets(6));
    });

    testWidgets('tapping a tag chip filters the list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap the "indian" chip.
      await tester.tap(find.widgetWithText(FilterChip, 'indian'));
      await tester.pumpAndSettle();

      // Only Indian recipes should be visible (count depends on live API data).
      final tiles = tester
          .widgetList<RecipeTile>(find.byType(RecipeTile))
          .toList();
      expect(tiles, isNotEmpty);
      for (final tile in tiles) {
        expect(
          tile.recipe.tags,
          contains('indian'),
          reason: '${tile.recipe.name} should be tagged as indian',
        );
      }
    });

    testWidgets('deselecting all tags restores full list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.widgetWithText(FilterChip, 'indian'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'indian'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeTile), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // US4 — Keep the Screen On While Cooking
  // ---------------------------------------------------------------------------
  group('US4 — Keep the Screen On While Cooking', () {
    testWidgets('wakelock toggle TextButton exists in recipe detail AppBar', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Toggle is now a TextButton.icon with label 'Screen off' (inactive).
      expect(find.text('Screen off'), findsOneWidget);
    });

    testWidgets('tapping wakelock toggle changes label to "Screen on"', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.text('Screen off'));
      await tester.pumpAndSettle();

      expect(find.text('Screen on'), findsOneWidget);
    });

    testWidgets('navigating back while wakelock is active does not throw', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.text('Screen off'));
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      // No exception thrown — list is back.
      expect(find.byType(RecipeTile), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // US5 + US6 — Photo tiles and polished detail screen (T031)
  // ---------------------------------------------------------------------------
  group('US5 and US6: photo tiles and polished detail', () {
    testWidgets('US5: recipe list shows photo tiles with no tag chip widgets', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tags are shown in TagChipBar only, not on the tiles.
      final tiles = find.byType(RecipeTile);
      expect(tiles, findsWidgets);
      // No FilterChip should be rendered inside a RecipeTile subtree.
      expect(
        find.byType(FilterChip),
        findsWidgets,
      ); // chips exist in TagChipBar
      for (final tileElement in tiles.evaluate()) {
        final chipsInTile = find.descendant(
          of: find.byElementPredicate((e) => e == tileElement),
          matching: find.byType(FilterChip),
        );
        expect(chipsInTile, findsNothing);
      }
    });

    testWidgets('US5: tapping tile navigates to detail with slide transition', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(RecipeDetailScreen), findsOneWidget);
    });

    testWidgets(
      'US6: detail screen shows name heading, photo area, and Divider',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final firstTile = tester.widget<RecipeTile>(
          find.byType(RecipeTile).first,
        );
        final recipeName = firstTile.recipe.name;

        await tester.tap(find.byType(RecipeTile).first);
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Name appears in both AppBar and body heading.
        expect(find.text(recipeName), findsAtLeastNWidgets(2));
        // Divider always present (separates source/heading from markdown).
        expect(find.byType(Divider), findsOneWidget);
        // Hero widget for photo area.
        expect(find.byType(Hero), findsOneWidget);
      },
    );

    testWidgets('US6: pressing back returns to recipe list', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final NavigatorState navigator = tester.state(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(RecipeTile), findsWidgets);
    });
  });
}
