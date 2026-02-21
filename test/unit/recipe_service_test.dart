import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niessl_recipes/models/recipe.dart';
import 'package:niessl_recipes/services/recipe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RecipeSummary.fromJson', () {
    test('parses valid JSON with tags', () {
      final json = {
        'name': 'Financiers',
        'url': 'https://example.com/financiers/index.json',
      };
      final summary = RecipeSummary.fromJson(json);
      expect(summary.name, 'Financiers');
      expect(summary.url, 'https://example.com/financiers/index.json');
      expect(summary.tags, isEmpty);
    });

    test('missing tags field defaults to empty list', () {
      final json = {
        'name': 'Test',
        'url': 'https://example.com/test/index.json',
      };
      final summary = RecipeSummary.fromJson(json);
      expect(summary.tags, isEmpty);
    });

    test('copyWith sets tags', () {
      final summary = RecipeSummary.fromJson({
        'name': 'Test',
        'url': 'https://example.com/test/index.json',
      });
      final enriched = summary.copyWith(tags: ['sweet', 'basis']);
      expect(enriched.tags, containsAll(['sweet', 'basis']));
      expect(enriched.name, summary.name);
    });
  });

  group('RecipeDetail.fromJson', () {
    test('parses valid JSON', () {
      final json = {
        'name': 'Financiers',
        'recipe': '## Ingredients\n\n* Butter',
      };
      final detail = RecipeDetail.fromJson(json);
      expect(detail.name, 'Financiers');
      expect(detail.recipe, contains('Ingredients'));
    });

    test('handles empty recipe string', () {
      final json = {'name': 'Empty', 'recipe': ''};
      final detail = RecipeDetail.fromJson(json);
      expect(detail.recipe, '');
    });
  });

  group('Tag.fromJson', () {
    test('parses valid JSON', () {
      final json = {
        'name': 'sweet',
        'url': 'https://example.com/tags/sweet/index.json',
      };
      final tag = Tag.fromJson(json);
      expect(tag.name, 'sweet');
      expect(tag.url, contains('sweet'));
    });
  });

  group('RecipeService.buildTagMap', () {
    test('builds correct tag→URL mapping', () {
      final tagResponses = {
        'sweet': [
          {
            'name': 'Financiers',
            'url': 'https://example.com/recipes/financiers/index.json',
          },
          {
            'name': 'Brownies',
            'url': 'https://example.com/recipes/brownies/index.json',
          },
        ],
        'indian': [
          {
            'name': 'Dal Tadka',
            'url': 'https://example.com/recipes/dal-tadka/index.json',
          },
        ],
      };

      final map = RecipeService.buildTagMap(tagResponses);
      expect(
        map['sweet'],
        containsAll([
          'https://example.com/recipes/financiers/index.json',
          'https://example.com/recipes/brownies/index.json',
        ]),
      );
      expect(
        map['indian'],
        contains('https://example.com/recipes/dal-tadka/index.json'),
      );
    });

    test('empty tag responses produces empty map', () {
      final map = RecipeService.buildTagMap({});
      expect(map, isEmpty);
    });
  });

  group('Cache serialization round-trip', () {
    test('RecipeSummary encodes and decodes correctly', () {
      final original = const RecipeSummary(
        name: 'Financiers',
        url: 'https://example.com/financiers/index.json',
        tags: ['sweet'],
      );
      final encoded = jsonEncode(original.toJson());
      final decoded = RecipeSummary.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.name, original.name);
      expect(decoded.url, original.url);
      expect(decoded.tags, original.tags);
    });

    test('Tag encodes and decodes correctly', () {
      const original = Tag(
        name: 'sweet',
        url: 'https://example.com/tags/sweet/index.json',
      );
      final encoded = jsonEncode(original.toJson());
      final decoded = Tag.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
      expect(decoded.name, original.name);
      expect(decoded.url, original.url);
    });
  });

  // ---------------------------------------------------------------------------
  // Model helpers (encode / decode / equality / hashCode)
  // ---------------------------------------------------------------------------
  group('encodeRecipes / decodeRecipes', () {
    test('round-trip preserves list', () {
      final original = [
        const RecipeSummary(
          name: 'Financiers',
          url: 'https://example.com/financiers/index.json',
          tags: ['sweet'],
        ),
        const RecipeSummary(name: 'Dal Tadka', url: 'https://example.com/dal'),
      ];
      final decoded = decodeRecipes(encodeRecipes(original));
      expect(decoded, hasLength(2));
      expect(decoded.first.name, 'Financiers');
      expect(decoded.first.tags, contains('sweet'));
    });
  });

  group('encodeTagMap / decodeTagMap', () {
    test('round-trip preserves map', () {
      final original = {
        'sweet': ['https://example.com/financiers/index.json'],
        'indian': [
          'https://example.com/dal/index.json',
          'https://example.com/curry/index.json',
        ],
      };
      final decoded = decodeTagMap(encodeTagMap(original));
      expect(
        decoded['sweet'],
        contains('https://example.com/financiers/index.json'),
      );
      expect(decoded['indian'], hasLength(2));
    });
  });

  group('RecipeSummary equality and hashCode', () {
    test('two summaries with same name/url are equal', () {
      const a = RecipeSummary(name: 'X', url: 'https://x.com');
      const b = RecipeSummary(name: 'X', url: 'https://x.com');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('summaries with different urls are not equal', () {
      const a = RecipeSummary(name: 'X', url: 'https://a.com');
      const b = RecipeSummary(name: 'X', url: 'https://b.com');
      expect(a, isNot(equals(b)));
    });
  });

  group('Tag equality and hashCode', () {
    test('two tags with same name are equal', () {
      const a = Tag(name: 'sweet', url: 'https://a.com');
      const b = Tag(name: 'sweet', url: 'https://b.com');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('tags with different names are not equal', () {
      const a = Tag(name: 'sweet', url: 'https://a.com');
      const b = Tag(name: 'indian', url: 'https://a.com');
      expect(a, isNot(equals(b)));
    });
  });

  group('RecipeDetail.toJson', () {
    test('serialises name and recipe', () {
      const detail = RecipeDetail(name: 'Cake', recipe: '# Cake');
      final json = detail.toJson();
      expect(json['name'], 'Cake');
      expect(json['recipe'], '# Cake');
    });
  });

  // T003: RecipeSummary picture field tests
  group('RecipeSummary.fromJson picture field', () {
    test('parses picture when present', () {
      final json = {
        'name': 'Aloo Matar',
        'url': 'https://dinner.niessl.org/recipes/aloo-matar/index.json',
        'picture':
            'https://dinner.niessl.org/recipes/aloo-matar/photo_200x200.jpg',
      };
      final summary = RecipeSummary.fromJson(json);
      expect(
        summary.picture,
        'https://dinner.niessl.org/recipes/aloo-matar/photo_200x200.jpg',
      );
    });

    test('picture is null when field absent', () {
      final json = {
        'name': 'No Photo',
        'url': 'https://dinner.niessl.org/recipes/no-photo/index.json',
      };
      final summary = RecipeSummary.fromJson(json);
      expect(summary.picture, isNull);
    });

    test('picture is null when field is empty string', () {
      final json = {
        'name': 'Empty Photo',
        'url': 'https://dinner.niessl.org/recipes/empty/index.json',
        'picture': '',
      };
      final summary = RecipeSummary.fromJson(json);
      expect(summary.picture, isNull);
    });

    test('cache round-trip preserves picture', () {
      final original = RecipeSummary.fromJson({
        'name': 'Aloo Matar',
        'url': 'https://dinner.niessl.org/recipes/aloo-matar/index.json',
        'picture':
            'https://dinner.niessl.org/recipes/aloo-matar/photo_200x200.jpg',
      });
      final encoded = jsonEncode(original.toJson());
      final decoded = RecipeSummary.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.picture, original.picture);
    });

    test('copyWith preserves picture', () {
      final original = RecipeSummary.fromJson({
        'name': 'Test',
        'url': 'https://example.com/test/index.json',
        'picture': 'https://example.com/photo.jpg',
      });
      final enriched = original.copyWith(tags: ['sweet']);
      expect(enriched.picture, original.picture);
    });
  });

  // T004: RecipeDetail picture + source field tests
  group('RecipeDetail.fromJson picture and source fields', () {
    test('parses picture and source when present', () {
      final json = {
        'name': 'Aloo Matar',
        'recipe': '## Ingredients',
        'picture': 'https://dinner.niessl.org/recipes/aloo-matar/photo.jpg',
        'source':
            'https://www.thecuriouschickpea.com/restaurant-style-aloo-matar',
      };
      final detail = RecipeDetail.fromJson(json);
      expect(
        detail.picture,
        'https://dinner.niessl.org/recipes/aloo-matar/photo.jpg',
      );
      expect(
        detail.source,
        'https://www.thecuriouschickpea.com/restaurant-style-aloo-matar',
      );
    });

    test('picture and source are null when fields absent', () {
      final json = {'name': 'Minimal', 'recipe': '## Ingredients'};
      final detail = RecipeDetail.fromJson(json);
      expect(detail.picture, isNull);
      expect(detail.source, isNull);
    });

    test('picture is null when empty string', () {
      final json = {
        'name': 'Test',
        'recipe': '## Ingredients',
        'picture': '',
        'source': 'https://example.com',
      };
      final detail = RecipeDetail.fromJson(json);
      expect(detail.picture, isNull);
    });

    test('source is null when empty string', () {
      final json = {
        'name': 'Test',
        'recipe': '## Ingredients',
        'picture': 'https://example.com/photo.jpg',
        'source': '',
      };
      final detail = RecipeDetail.fromJson(json);
      expect(detail.source, isNull);
    });

    test('cache round-trip preserves picture and source', () {
      final original = RecipeDetail.fromJson({
        'name': 'Aloo Matar',
        'recipe': '## Ingredients',
        'picture': 'https://dinner.niessl.org/recipes/aloo-matar/photo.jpg',
        'source': 'https://www.thecuriouschickpea.com/aloo-matar',
      });
      final encoded = jsonEncode(original.toJson());
      final decoded = RecipeDetail.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.picture, original.picture);
      expect(decoded.source, original.source);
    });
  });

  group('RecipeService HTTP fetching', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences_macos'),
            (call) async => null,
          );
    });

    test('fetchRecipeDetail parses response correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'name': 'Financiers',
            'recipe': '## Ingredients\n\n* Butter',
          }),
          200,
        );
      });
      final service = RecipeService(client: mockClient);
      final detail = await service.fetchRecipeDetail(
        'https://example.com/recipes/financiers/index.json',
      );
      expect(detail.name, 'Financiers');
      expect(detail.recipe, contains('Butter'));
    });

    test('fetchRecipeDetail handles literal newlines in recipe JSON', () async {
      // Hugo can emit literal (unescaped) control characters inside JSON
      // strings. The Dart \n in a raw string literal below is an actual 0x0A
      // byte — NOT the two-character escape sequence — so jsonDecode would
      // throw FormatException without sanitization.
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"name":"Financiers","recipe":"## Ingredients\n\n* Butter"}',
          200,
        );
      });
      final service = RecipeService(client: mockClient);
      final detail = await service.fetchRecipeDetail(
        'https://example.com/recipes/financiers/index.json',
      );
      expect(detail.name, 'Financiers');
      expect(detail.recipe, contains('Ingredients'));
    });

    test('fetchRecipeDetail throws on non-200 response', () async {
      SharedPreferences.setMockInitialValues({});
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final service = RecipeService(client: mockClient);
      await expectLater(
        service.fetchRecipeDetail(
          'https://example.com/recipes/missing/index.json',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchRecipeDetail returns cached detail without HTTP call', () async {
      const url = 'https://example.com/recipes/financiers/index.json';
      final cacheKey = 'cache_recipe_${base64Url.encode(utf8.encode(url))}';
      SharedPreferences.setMockInitialValues({
        cacheKey: jsonEncode({'name': 'Financiers', 'recipe': '# Cached'}),
      });

      int callCount = 0;
      final mockClient = MockClient((_) async {
        callCount++;
        return http.Response('{}', 200);
      });
      final service = RecipeService(client: mockClient);
      final detail = await service.fetchRecipeDetail(url);

      expect(detail.name, 'Financiers');
      expect(detail.recipe, '# Cached');
      expect(callCount, 0); // cache hit — no HTTP call
    });

    test('fetchAll fetches and enriches recipes on cache miss', () async {
      SharedPreferences.setMockInitialValues({});

      final mockClient = MockClient((request) async {
        final url = request.url.toString();
        if (url == 'https://dinner.niessl.org/recipes/index.json') {
          return http.Response(
            jsonEncode([
              {
                'name': 'Financiers',
                'url':
                    'https://dinner.niessl.org/recipes/financiers/index.json',
              },
              {
                'name': 'Dal Tadka',
                'url': 'https://dinner.niessl.org/recipes/dal-tadka/index.json',
              },
            ]),
            200,
          );
        } else if (url == 'https://dinner.niessl.org/tags/index.json') {
          return http.Response(
            jsonEncode([
              {
                'name': 'sweet',
                'url': 'https://dinner.niessl.org/tags/sweet/index.json',
              },
            ]),
            200,
          );
        } else if (url == 'https://dinner.niessl.org/tags/sweet/index.json') {
          return http.Response(
            jsonEncode([
              {
                'name': 'Financiers',
                'url':
                    'https://dinner.niessl.org/recipes/financiers/index.json',
              },
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = RecipeService(client: mockClient);
      final result = await service.fetchAll();

      expect(result.recipes, hasLength(2));
      expect(result.tags, hasLength(1));
      expect(result.tags.first.name, 'sweet');

      final financiers = result.recipes.firstWhere(
        (r) => r.name == 'Financiers',
      );
      expect(financiers.tags, contains('sweet'));

      final dalTadka = result.recipes.firstWhere((r) => r.name == 'Dal Tadka');
      expect(dalTadka.tags, isEmpty);

      // Alphabetically sorted: Dal Tadka comes first.
      expect(result.recipes.first.name, 'Dal Tadka');
    });

    test(
      'fetchAll returns cached data and triggers background refresh',
      () async {
        final cachedRecipes = encodeRecipes([
          const RecipeSummary(
            name: 'Financiers',
            url: 'https://dinner.niessl.org/recipes/financiers/index.json',
          ),
        ]);
        final cachedTagMap = encodeTagMap({
          'sweet': ['https://dinner.niessl.org/recipes/financiers/index.json'],
        });

        SharedPreferences.setMockInitialValues({
          'cache_recipes_index': cachedRecipes,
          'cache_tags_map': cachedTagMap,
        });

        // Background refresh calls — return minimal valid responses.
        final mockClient = MockClient((request) async {
          final url = request.url.toString();
          if (url.endsWith('recipes/index.json')) {
            return http.Response(jsonEncode([]), 200);
          } else if (url.endsWith('tags/index.json')) {
            return http.Response(jsonEncode([]), 200);
          }
          return http.Response(jsonEncode([]), 200);
        });

        final service = RecipeService(client: mockClient);
        final result = await service.fetchAll();

        // Returns cached data immediately.
        expect(result.recipes, hasLength(1));
        expect(result.recipes.first.name, 'Financiers');
        expect(result.recipes.first.tags, contains('sweet'));
      },
    );
  });
}
