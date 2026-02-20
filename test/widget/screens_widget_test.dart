import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niessl_recipes/models/recipe.dart';
import 'package:niessl_recipes/providers/providers.dart';
import 'package:niessl_recipes/screens/recipe_detail_screen.dart';
import 'package:niessl_recipes/screens/recipe_list_screen.dart';
import 'package:niessl_recipes/theme.dart';
import 'package:niessl_recipes/widgets/empty_state_view.dart';
import 'package:niessl_recipes/widgets/error_view.dart';
import 'package:niessl_recipes/widgets/loading_view.dart';
import 'package:niessl_recipes/widgets/recipe_tile.dart';
import 'package:niessl_recipes/widgets/search_bar_widget.dart';
import 'package:niessl_recipes/widgets/tag_chip_bar.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

final _recipes = [
  const RecipeSummary(
    name: 'Pancakes',
    url: 'https://dinner.niessl.org/recipes/pancakes/index.json',
    tags: ['sweet'],
  ),
  const RecipeSummary(
    name: 'Chicken Curry',
    url: 'https://dinner.niessl.org/recipes/curry/index.json',
    tags: ['indian', 'main'],
  ),
];

final _tags = [
  const Tag(
    name: 'sweet',
    url: 'https://dinner.niessl.org/tags/sweet/index.json',
  ),
  const Tag(
    name: 'indian',
    url: 'https://dinner.niessl.org/tags/indian/index.json',
  ),
];

const _detail = RecipeDetail(
  name: 'Pancakes',
  recipe: '## Ingredients\n- Flour\n- Eggs\n\n## Directions\nMix and cook.',
);

/// Builds a testable widget tree with Riverpod provider overrides.
Widget _buildWithOverrides(
  Widget child, {
  AsyncValue<List<RecipeSummary>> filteredRecipes = const AsyncValue.loading(),
  AsyncValue<List<Tag>> tags = const AsyncValue.loading(),
  RecipeDetail detail = _detail,
}) {
  return ProviderScope(
    overrides: [
      filteredRecipesProvider.overrideWith((_) => filteredRecipes),
      tagsProvider.overrideWith((_) => tags),
      recipeDetailProvider.overrideWith((_, __) => Future.value(detail)),
    ],
    child: MaterialApp(theme: appLightTheme, home: child),
  );
}

/// Stubs all wakelock_plus platform channel calls to no-ops.
void _stubWakelock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/wakelock'),
        (_) async => null,
      );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(_stubWakelock);

  // ─── LoadingView ───────────────────────────────────────────────────────────
  group('LoadingView', () {
    testWidgets('renders a CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingView())),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ─── ErrorView ─────────────────────────────────────────────────────────────
  group('ErrorView', () {
    testWidgets('shows message and Retry button', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Connection failed',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  // ─── EmptyStateView ────────────────────────────────────────────────────────
  group('EmptyStateView', () {
    testWidgets('shows "No recipes found" without hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyStateView())),
      );
      expect(find.text('No recipes found'), findsOneWidget);
    });

    testWidgets('shows hint text when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EmptyStateView(hint: 'Try removing filters')),
        ),
      );
      expect(find.text('No recipes found'), findsOneWidget);
      expect(find.text('Try removing filters'), findsOneWidget);
    });
  });

  // ─── RecipeTile ────────────────────────────────────────────────────────────
  group('RecipeTile', () {
    testWidgets('displays recipe name', (tester) async {
      final recipe = const RecipeSummary(
        name: 'Sourdough',
        url: 'https://x.com',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeTile(recipe: recipe, onTap: () {}),
          ),
        ),
      );
      expect(find.text('Sourdough'), findsOneWidget);
    });

    testWidgets('shows no trailing chips when tags are empty', (tester) async {
      final recipe = const RecipeSummary(
        name: 'Sourdough',
        url: 'https://x.com',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeTile(recipe: recipe, onTap: () {}),
          ),
        ),
      );
      expect(find.byType(Container), findsNothing); // tag chip containers
    });

    testWidgets('shows up to 2 tag chips when recipe has tags', (tester) async {
      final recipe = const RecipeSummary(
        name: 'Curry',
        url: 'https://x.com',
        tags: ['indian', 'main', 'spicy'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeTile(recipe: recipe, onTap: () {}),
          ),
        ),
      );
      expect(find.text('indian'), findsOneWidget);
      expect(find.text('main'), findsOneWidget);
      expect(find.text('spicy'), findsNothing); // only first 2 shown
    });

    testWidgets('calls onTap when the tile is tapped', (tester) async {
      bool tapped = false;
      final recipe = const RecipeSummary(
        name: 'Sourdough',
        url: 'https://x.com',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeTile(recipe: recipe, onTap: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });
  });

  // ─── TagChipBar ────────────────────────────────────────────────────────────
  group('TagChipBar', () {
    testWidgets('renders a FilterChip for each tag', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const Scaffold(body: TagChipBar()),
          tags: AsyncValue.data(_tags),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('sweet'), findsOneWidget);
      expect(find.text('indian'), findsOneWidget);
    });

    testWidgets('shows empty SizedBox while tags are loading', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const Scaffold(body: TagChipBar()),
          tags: const AsyncValue.loading(),
        ),
      );
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  // ─── RecipeListScreen ──────────────────────────────────────────────────────
  group('RecipeListScreen', () {
    testWidgets('shows LoadingView while recipes are loading', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: const AsyncValue.loading(),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows ErrorView on fetch error', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: const AsyncValue.error('timeout', StackTrace.empty),
        ),
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows list of RecipeTiles when data is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: AsyncValue.data(_recipes),
          tags: AsyncValue.data(_tags),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RecipeTile), findsNWidgets(2));
      expect(find.text('Pancakes'), findsOneWidget);
      expect(find.text('Chicken Curry'), findsOneWidget);
    });

    testWidgets('shows EmptyStateView when filtered list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: const AsyncValue.data([]),
          tags: AsyncValue.data(_tags),
        ),
      );
      expect(find.text('No recipes found'), findsOneWidget);
    });

    testWidgets('has AppBar titled "Recipes"', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: AsyncValue.data(_recipes),
          tags: AsyncValue.data(_tags),
        ),
      );
      expect(find.text('Recipes'), findsOneWidget);
    });

    testWidgets('search TextField is present', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: AsyncValue.data(_recipes),
          tags: AsyncValue.data(_tags),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('tapping a RecipeTile navigates to RecipeDetailScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: AsyncValue.data(_recipes),
          tags: AsyncValue.data(_tags),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RecipeTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  // ─── SearchBarWidget ───────────────────────────────────────────────────────
  group('SearchBarWidget', () {
    testWidgets('entering text shows clear (X) button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SearchBarWidget())),
        ),
      );
      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.enterText(find.byType(TextField), 'pancakes');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('tapping clear button empties the field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SearchBarWidget())),
        ),
      );

      await tester.enterText(find.byType(TextField), 'pancakes');
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsNothing);
    });
  });

  // ─── TagChipBar interactions ───────────────────────────────────────────────
  group('TagChipBar interactions', () {
    testWidgets('tapping a chip selects it', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const Scaffold(body: TagChipBar()),
          tags: AsyncValue.data(_tags),
        ),
      );
      await tester.pumpAndSettle();

      final before = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'sweet'),
      );
      expect(before.selected, isFalse);

      await tester.tap(find.widgetWithText(FilterChip, 'sweet'));
      await tester.pump();

      final after = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'sweet'),
      );
      expect(after.selected, isTrue);
    });
  });

  // ─── RecipeDetailScreen ────────────────────────────────────────────────────
  group('RecipeDetailScreen', () {
    Widget buildDetail({RecipeDetail? detail}) {
      return ProviderScope(
        overrides: [
          recipeDetailProvider.overrideWith(
            (_, __) => Future.value(detail ?? _detail),
          ),
        ],
        child: MaterialApp(
          theme: appLightTheme,
          home: const RecipeDetailScreen(
            url: 'https://dinner.niessl.org/recipes/pancakes/index.json',
            name: 'Pancakes',
          ),
        ),
      );
    }

    testWidgets('shows ErrorView when detail fetch fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeDetailProvider.overrideWith(
              (_, __) => Future<RecipeDetail>.error('Network error'),
            ),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(url: 'https://x.com', name: 'Pancakes'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows recipe name in AppBar', (tester) async {
      await tester.pumpWidget(buildDetail());
      await tester.pumpAndSettle();
      expect(find.text('Pancakes'), findsWidgets);
    });

    testWidgets('shows wakelock icon button (lightbulb_outline) by default', (
      tester,
    ) async {
      await tester.pumpWidget(buildDetail());
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('markdown content renders in SingleChildScrollView', (
      tester,
    ) async {
      await tester.pumpWidget(buildDetail());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
