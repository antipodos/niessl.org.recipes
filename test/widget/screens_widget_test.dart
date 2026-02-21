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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:niessl_recipes/widgets/equalizer_loading_view.dart';

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

final _recipeWithPhoto = const RecipeSummary(
  name: 'Pizza',
  url: 'https://dinner.niessl.org/recipes/pizza/index.json',
  picture: 'https://dinner.niessl.org/recipes/pizza/photo.jpg',
);

const _detailWithMedia = RecipeDetail(
  name: 'Pancakes',
  recipe: '## Ingredients\n- Flour\n- Eggs\n\n## Directions\nMix and cook.',
  picture: 'https://dinner.niessl.org/recipes/pancakes/photo.jpg',
  source: 'https://example.com/pancakes',
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
      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    // T013 — photo tile tests (fail until T018 implemented)
    testWidgets('with picture renders Hero and CachedNetworkImage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeTile(recipe: _recipeWithPhoto, onTap: () {}),
          ),
        ),
      );
      expect(find.byType(Hero), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets(
      'without picture renders Hero and restaurant icon placeholder',
      (tester) async {
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
        expect(find.byType(Hero), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      },
    );

    testWidgets('renders no FilterChip widgets', (tester) async {
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
      expect(find.byType(FilterChip), findsNothing);
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
    // T014 — updated loading state test (fails until T019 implemented)
    testWidgets('shows EqualizerLoadingView while recipes are loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: const AsyncValue.loading(),
        ),
      );
      expect(find.byType(EqualizerLoadingView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
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
      // Photo tiles are tall (AspectRatio 1.6); ListView.builder only builds
      // visible items, so only assert at least one tile is rendered.
      expect(find.byType(RecipeTile), findsAtLeastNWidgets(1));
      expect(find.text('Pancakes'), findsOneWidget);
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

    // T014 — updated title test (fails until T019 implemented)
    testWidgets('has AppBar titled "niessl.org recipes"', (tester) async {
      await tester.pumpWidget(
        _buildWithOverrides(
          const RecipeListScreen(),
          filteredRecipes: AsyncValue.data(_recipes),
          tags: AsyncValue.data(_tags),
        ),
      );
      expect(find.text('niessl.org recipes'), findsOneWidget);
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

  // ─── EqualizerLoadingView ─────────────────────────────────────────────────
  // T015 — fail until T017 creates the widget
  group('EqualizerLoadingView', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EqualizerLoadingView())),
      );
      expect(find.byType(EqualizerLoadingView), findsOneWidget);
    });

    testWidgets('contains AnimatedBuilder widgets in the subtree', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EqualizerLoadingView())),
      );
      expect(find.byType(AnimatedBuilder), findsWidgets);
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

    // T024 — updated toggle test (fails until T029 implemented)
    testWidgets('shows "Screen off" toggle label by default', (tester) async {
      await tester.pumpWidget(buildDetail());
      expect(find.text('Screen off'), findsOneWidget);
    });

    testWidgets('markdown content renders in SingleChildScrollView', (
      tester,
    ) async {
      await tester.pumpWidget(buildDetail());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    // T022 — loaded state with picture + source (fails until T028 implemented)
    testWidgets(
      'loaded state with media shows Hero, name heading, source link, Divider',
      (tester) async {
        await tester.pumpWidget(buildDetail(detail: _detailWithMedia));
        await tester.pumpAndSettle();
        // Name appears in AppBar AND as body heading = at least 2 matches
        expect(find.text('Pancakes'), findsAtLeastNWidgets(2));
        expect(find.byType(Hero), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
        expect(find.byType(Divider), findsOneWidget);
      },
    );

    // T023 — no source link when source is null (fails until T028 implemented)
    testWidgets(
      'loaded state without source shows no source link but has Divider',
      (tester) async {
        await tester.pumpWidget(buildDetail()); // _detail has no source
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.open_in_new), findsNothing);
        expect(find.byType(Divider), findsOneWidget);
      },
    );

    // T024 — snackbar feedback on toggle tap (fails until T029 implemented)
    testWidgets('tapping toggle shows SnackBar', (tester) async {
      await tester.pumpWidget(buildDetail());
      await tester.tap(find.text('Screen off'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
