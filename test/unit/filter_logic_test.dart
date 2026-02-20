import 'package:flutter_test/flutter_test.dart';
import 'package:niessl_recipes/models/recipe.dart';
import 'package:niessl_recipes/services/filter_service.dart';

void main() {
  final allRecipes = [
    const RecipeSummary(name: 'Financiers', url: 'u1', tags: ['sweet']),
    const RecipeSummary(
      name: 'Paneer Butter Masala',
      url: 'u2',
      tags: ['indian', 'main'],
    ),
    const RecipeSummary(name: 'Dal Tadka', url: 'u3', tags: ['indian']),
    const RecipeSummary(name: 'Brownies', url: 'u4', tags: ['sweet']),
    const RecipeSummary(name: 'Lime Pie', url: 'u5', tags: ['sweet']),
    const RecipeSummary(
      name: 'Aloo Matar',
      url: 'u6',
      tags: ['indian', 'main'],
    ),
    const RecipeSummary(
      name: 'Salmon Fillet',
      url: 'u7',
      tags: ['fish', 'main'],
    ),
    const RecipeSummary(name: 'Bread Basis', url: 'u8', tags: ['basis']),
  ];

  group('Search filter (case-insensitive)', () {
    test('empty query returns all recipes', () {
      final result = FilterService.apply(
        allRecipes,
        query: '',
        selectedTags: {},
      );
      expect(result, hasLength(allRecipes.length));
    });

    test('partial name match (lowercase query)', () {
      final result = FilterService.apply(
        allRecipes,
        query: 'pan',
        selectedTags: {},
      );
      expect(result.map((r) => r.name), contains('Paneer Butter Masala'));
      expect(result, hasLength(1));
    });

    test('case-insensitive match', () {
      final result = FilterService.apply(
        allRecipes,
        query: 'FINANCIERS',
        selectedTags: {},
      );
      expect(result.map((r) => r.name), contains('Financiers'));
    });

    test('no match returns empty list', () {
      final result = FilterService.apply(
        allRecipes,
        query: 'zzzzz',
        selectedTags: {},
      );
      expect(result, isEmpty);
    });
  });

  group('Tag filter (OR / inclusive)', () {
    test('no tags selected returns all recipes', () {
      final result = FilterService.apply(
        allRecipes,
        query: '',
        selectedTags: {},
      );
      expect(result, hasLength(allRecipes.length));
    });

    test('single tag filters to matching recipes', () {
      final result = FilterService.apply(
        allRecipes,
        query: '',
        selectedTags: {'sweet'},
      );
      expect(
        result.map((r) => r.name),
        containsAll(['Financiers', 'Brownies', 'Lime Pie']),
      );
      expect(result, hasLength(3));
    });

    test('two tags returns OR union', () {
      final result = FilterService.apply(
        allRecipes,
        query: '',
        selectedTags: {'sweet', 'indian'},
      );
      // sweet: Financiers, Brownies, Lime Pie (3)
      // indian: Paneer Butter Masala, Dal Tadka, Aloo Matar (3)
      expect(result, hasLength(6));
    });

    test('tag with no matches returns empty', () {
      final result = FilterService.apply(
        allRecipes,
        query: '',
        selectedTags: {'nonexistent'},
      );
      expect(result, isEmpty);
    });
  });

  group('Combined search + tag filter (AND across both)', () {
    test('search "masala" + indian tag returns only Indian masala recipes', () {
      final result = FilterService.apply(
        allRecipes,
        query: 'masala',
        selectedTags: {'indian'},
      );
      expect(result.map((r) => r.name), contains('Paneer Butter Masala'));
      expect(result, hasLength(1));
    });

    test('search with tag that produces no intersection returns empty', () {
      final result = FilterService.apply(
        allRecipes,
        query: 'financiers',
        selectedTags: {'indian'},
      );
      expect(result, isEmpty);
    });
  });

  group('Alphabetical sort', () {
    test('results are sorted alphabetically by name', () {
      final result = FilterService.apply(
        allRecipes,
        query: '',
        selectedTags: {},
      );
      final names = result.map((r) => r.name).toList();
      final sorted = [...names]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(names, sorted);
    });
  });
}
