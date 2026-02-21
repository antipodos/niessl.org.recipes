import 'package:flutter_test/flutter_test.dart';
import 'package:niessl_recipes/models/recipe.dart';
import 'package:niessl_recipes/screens/recipe_list_screen.dart';

// T017 — fails until T018 adds pickRecipePictureUrls to recipe_list_screen.dart
void main() {
  group('pickRecipePictureUrls', () {
    final recipes = [
      const RecipeSummary(
        name: 'Pancakes',
        url: 'https://x.com/1',
        picture: 'https://x.com/1/photo.jpg',
      ),
      const RecipeSummary(name: 'Toast', url: 'https://x.com/2'),
      const RecipeSummary(
        name: 'Omelette',
        url: 'https://x.com/3',
        picture: 'https://x.com/3/photo.jpg',
      ),
      const RecipeSummary(
        name: 'Waffles',
        url: 'https://x.com/4',
        picture: 'https://x.com/4/photo.jpg',
      ),
    ];

    test('excludes recipes with null picture', () {
      final urls = pickRecipePictureUrls(recipes);
      expect(urls, isNot(contains('https://x.com/2')));
      expect(urls.length, 3);
    });

    test('returns URLs in original list order', () {
      final urls = pickRecipePictureUrls(recipes);
      expect(
        urls,
        equals([
          'https://x.com/1/photo.jpg',
          'https://x.com/3/photo.jpg',
          'https://x.com/4/photo.jpg',
        ]),
      );
    });

    test('respects limit (default 10)', () {
      final many = List.generate(
        15,
        (i) => RecipeSummary(
          name: 'Recipe $i',
          url: 'https://x.com/$i',
          picture: 'https://x.com/$i/photo.jpg',
        ),
      );
      final urls = pickRecipePictureUrls(many);
      expect(urls.length, 10);
    });

    test('handles fewer than limit recipes gracefully', () {
      final urls = pickRecipePictureUrls(recipes);
      expect(urls.length, lessThanOrEqualTo(10));
    });

    test('custom limit is respected', () {
      final urls = pickRecipePictureUrls(recipes, limit: 2);
      expect(urls.length, 2);
    });
  });
}
