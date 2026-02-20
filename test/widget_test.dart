import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niessl_recipes/main.dart';

void main() {
  testWidgets('app smoke test — RecipesApp renders without crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RecipesApp()));
    // App starts loading — no exception thrown.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
