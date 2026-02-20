import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

const _cacheKeyRecipes = 'cache_recipes_index';
const _cacheKeyTagsMap = 'cache_tags_map';
const _cacheKeyRecipePrefix = 'cache_recipe_';
const _timeoutSeconds = 10;

/// Fetches and caches recipe data from dinner.niessl.org.
class RecipeService {
  final http.Client _client;

  RecipeService({http.Client? client}) : _client = client ?? http.Client();

  /// Loads all recipe summaries (with tag associations) and the tag list.
  ///
  /// Strategy:
  /// 1. Return cached data immediately if available.
  /// 2. Fetch fresh data in background and update cache.
  ///
  /// Callers that need fresh data should await this and then check the result.
  Future<({List<RecipeSummary> recipes, List<Tag> tags})> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRecipes = prefs.getString(_cacheKeyRecipes);
    final cachedTagsMap = prefs.getString(_cacheKeyTagsMap);

    if (cachedRecipes != null && cachedTagsMap != null) {
      final recipes = _buildEnrichedRecipes(
        decodeRecipes(cachedRecipes),
        decodeTagMap(cachedTagsMap),
      );
      // Fire-and-forget background refresh.
      _fetchAndCache(prefs).ignore();
      return (
        recipes: recipes,
        tags: _extractTags(decodeTagMap(cachedTagsMap)),
      );
    }

    return _fetchAndCache(prefs);
  }

  Future<({List<RecipeSummary> recipes, List<Tag> tags})> _fetchAndCache(
    SharedPreferences prefs,
  ) async {
    final timeout = const Duration(seconds: _timeoutSeconds);

    // Fetch recipe index and tag index in parallel.
    final results = await Future.wait([
      _client
          .get(Uri.parse('https://dinner.niessl.org/recipes/index.json'))
          .timeout(timeout),
      _client
          .get(Uri.parse('https://dinner.niessl.org/tags/index.json'))
          .timeout(timeout),
    ]);

    final recipesResponse = results[0];
    final tagsResponse = results[1];

    if (recipesResponse.statusCode != 200) {
      throw Exception('Failed to load recipes: ${recipesResponse.statusCode}');
    }
    if (tagsResponse.statusCode != 200) {
      throw Exception('Failed to load tags: ${tagsResponse.statusCode}');
    }

    final rawRecipes = (jsonDecode(recipesResponse.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(RecipeSummary.fromJson)
        .toList();

    final rawTags = (jsonDecode(tagsResponse.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Tag.fromJson)
        .toList();

    // Fetch all tag recipe lists in parallel.
    final tagFutures = rawTags.map(
      (tag) => _client
          .get(Uri.parse(tag.url))
          .timeout(timeout)
          .then(
            (res) => MapEntry(
              tag.name,
              res.statusCode == 200
                  ? (jsonDecode(res.body) as List<dynamic>)
                        .cast<Map<String, dynamic>>()
                        .map((e) => e['url'] as String)
                        .toList()
                  : <String>[],
            ),
          ),
    );

    final tagEntries = await Future.wait(tagFutures);
    final tagMap = Map<String, List<String>>.fromEntries(tagEntries);

    // Persist to cache.
    await prefs.setString(_cacheKeyRecipes, encodeRecipes(rawRecipes));
    await prefs.setString(_cacheKeyTagsMap, encodeTagMap(tagMap));

    final enrichedRecipes = _buildEnrichedRecipes(rawRecipes, tagMap);

    return (recipes: enrichedRecipes, tags: rawTags);
  }

  /// Fetches the full content for a single recipe, with cache.
  Future<RecipeDetail> fetchRecipeDetail(String url) async {
    final key = _cacheKeyRecipePrefix + base64Url.encode(utf8.encode(url));
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);

    if (cached != null) {
      return RecipeDetail.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }

    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: _timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('Failed to load recipe detail: ${response.statusCode}');
    }

    final detail = RecipeDetail.fromJson(
      jsonDecode(_sanitizeJson(response.body)) as Map<String, dynamic>,
    );
    await prefs.setString(key, jsonEncode(detail.toJson()));
    return detail;
  }

  // ---------------------------------------------------------------------------
  // Static helpers (also used by tests)
  // ---------------------------------------------------------------------------

  /// Builds a map from tag name → list of recipe URLs from per-tag responses.
  static Map<String, List<String>> buildTagMap(
    Map<String, List<Map<String, dynamic>>> tagResponses,
  ) {
    return tagResponses.map(
      (tagName, recipes) =>
          MapEntry(tagName, recipes.map((r) => r['url'] as String).toList()),
    );
  }

  /// Sanitizes a JSON string that may contain literal (unescaped) control
  /// characters inside string values — a known quirk of Hugo's JSON output.
  static String _sanitizeJson(String raw) {
    final buf = StringBuffer();
    var inString = false;
    var escaped = false;
    for (var i = 0; i < raw.length; i++) {
      final c = raw.codeUnitAt(i);
      if (escaped) {
        escaped = false;
        buf.writeCharCode(c);
      } else if (c == 0x5C && inString) {
        escaped = true;
        buf.writeCharCode(c);
      } else if (c == 0x22) {
        inString = !inString;
        buf.writeCharCode(c);
      } else if (inString && c < 0x20) {
        switch (c) {
          case 0x0A:
            buf.write(r'\n');
          case 0x0D:
            buf.write(r'\r');
          case 0x09:
            buf.write(r'\t');
          default:
            buf.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
        }
      } else {
        buf.writeCharCode(c);
      }
    }
    return buf.toString();
  }

  /// Enriches recipe summaries with their tag memberships.
  static List<RecipeSummary> _buildEnrichedRecipes(
    List<RecipeSummary> recipes,
    Map<String, List<String>> tagMap,
  ) {
    // Build reverse map: recipeUrl → tags
    final urlToTags = <String, List<String>>{};
    for (final entry in tagMap.entries) {
      for (final url in entry.value) {
        urlToTags.putIfAbsent(url, () => []).add(entry.key);
      }
    }

    return recipes
        .map((r) => r.copyWith(tags: urlToTags[r.url] ?? const []))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static List<Tag> _extractTags(Map<String, List<String>> tagMap) {
    return tagMap.keys.map((name) => Tag(name: name, url: '')).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
