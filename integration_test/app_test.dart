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

      // Only Indian recipes (10 total) should be visible.
      final tiles = tester
          .widgetList<RecipeTile>(find.byType(RecipeTile))
          .toList();
      expect(tiles.length, 10);
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
    testWidgets('wakelock toggle button exists in recipe detail AppBar', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Wakelock toggle is an IconButton in the AppBar actions.
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('tapping wakelock toggle changes icon state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lightbulb), findsOneWidget);
    });

    testWidgets('navigating back while wakelock is active does not throw', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.byIcon(Icons.lightbulb_outline));
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
}
