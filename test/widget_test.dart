import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animflix/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimflixApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home screen displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimflixApp());
    expect(find.text('Animflix'), findsOneWidget);
  });

  testWidgets('Search field is present', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimflixApp());
    expect(find.byType(TextField), findsOneWidget);
  });
}
