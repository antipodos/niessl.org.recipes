import 'dart:convert';

class RecipeSummary {
  final String name;
  final String url;
  final List<String> tags;
  final String? picture;

  const RecipeSummary({
    required this.name,
    required this.url,
    this.tags = const [],
    this.picture,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    final pic = json['picture'] as String?;
    return RecipeSummary(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      picture: (pic != null && pic.isNotEmpty) ? pic : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'tags': tags,
    'picture': picture,
  };

  RecipeSummary copyWith({List<String>? tags}) {
    return RecipeSummary(
      name: name,
      url: url,
      tags: tags ?? this.tags,
      picture: picture,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSummary && name == other.name && url == other.url;

  @override
  int get hashCode => Object.hash(name, url);
}

class RecipeDetail {
  final String name;
  final String recipe;
  final String? picture;
  final String? source;

  const RecipeDetail({
    required this.name,
    required this.recipe,
    this.picture,
    this.source,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final pic = json['picture'] as String?;
    final src = json['source'] as String?;
    return RecipeDetail(
      name: json['name'] as String? ?? '',
      recipe: json['recipe'] as String? ?? '',
      picture: (pic != null && pic.isNotEmpty) ? pic : null,
      source: (src != null && src.isNotEmpty) ? src : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'recipe': recipe,
    'picture': picture,
    'source': source,
  };
}

class Tag {
  final String name;
  final String url;

  const Tag({required this.name, required this.url});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Tag && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Encodes a list of RecipeSummary objects to a JSON string for caching.
String encodeRecipes(List<RecipeSummary> recipes) =>
    jsonEncode(recipes.map((r) => r.toJson()).toList());

/// Decodes a JSON string back to a list of RecipeSummary objects.
List<RecipeSummary> decodeRecipes(String json) {
  final list = jsonDecode(json) as List<dynamic>;
  return list.cast<Map<String, dynamic>>().map(RecipeSummary.fromJson).toList();
}

/// Encodes a tag→[url] map to JSON string for caching.
String encodeTagMap(Map<String, List<String>> tagMap) => jsonEncode(tagMap);

/// Decodes a cached tag map JSON string.
Map<String, List<String>> decodeTagMap(String json) {
  final raw = jsonDecode(json) as Map<String, dynamic>;
  return raw.map((k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()));
}
